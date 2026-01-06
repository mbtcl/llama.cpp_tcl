#include "cpptcl/cpptcl.h"
#include "llama.h"
#include "ggml.h"
#include "common/common.h"
#include "common/sampling.h"

#include <vector>
#include <string>
#include <stdexcept>
#include <iostream>
#include <memory>
#include <mutex>

using namespace Tcl;

// 全局状态管理
static struct LlamaBackend {
    bool initialized = false;
    std::mutex mutex;

    void init() {
        std::lock_guard<std::mutex> lock(mutex);
        if (!initialized) {
            llama_backend_init();
            ggml_numa_init(GGML_NUMA_STRATEGY_DISTRIBUTE);  // Enable NUMA if available
            initialized = true;
        }
    }

    ~LlamaBackend() {
        if (initialized) {
            llama_backend_free();
        }
    }
} g_backend;

// 结构体：封装完整推理状态
struct LlamaSession {
    llama_model*              model = nullptr;
    llama_context*            ctx   = nullptr;
    common_sampler*           smpl  = nullptr;
    std::vector<llama_token>  tokens;
    int                       n_past = 0;
    int                       n_ctx = 0;

    ~LlamaSession() {
        if (smpl)  common_sampler_free(smpl);
        if (ctx)   llama_free(ctx);
        if (model) llama_model_free(model);
    }
};

// 创建会话
object llama_create(const object& args) {
    if (args.size() < 1) {
        throw tcl_error("Usage: llama_create model_path ?n_ctx? ?n_gpu_layers?");
    }

    // 确保backend已初始化
    g_backend.init();

    std::string model_path = args.at(0).get<std::string>();
    int n_ctx = args.size() > 1 ? args.at(1).get<int>() : 2048;
    int n_gpu_layers = args.size() > 2 ? args.at(2).get<int>() : 0;

    // 1. Model
    llama_model_params mparams = llama_model_default_params();
    mparams.n_gpu_layers = n_gpu_layers;
    llama_model* model = llama_load_model_from_file(model_path.c_str(), mparams);
    if (!model) {
        throw tcl_error(std::string("Failed to load model: ") + model_path);
    }

    // 2. Context
    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx = n_ctx;
    cparams.n_threads = 4;
    llama_context* ctx = llama_new_context_with_model(model, cparams);
    if (!ctx) {
        llama_model_free(model);
        throw tcl_error("Failed to create context");
    }

    // 3. Sampling
    common_params_sampling sparams;
    sparams.temp = 0.7f;
    sparams.top_p = 0.95f;
    sparams.penalty_repeat = 1.3f;  // 更强的重复惩罚
    sparams.penalty_present = 0.0f;  // 不惩罚present tokens
    common_sampler* smpl = common_sampler_init(model, sparams);
    if (!smpl) {
        llama_free(ctx);
        llama_model_free(model);
        throw tcl_error("Failed to create sampler");
    }

    LlamaSession* session = new LlamaSession{model, ctx, smpl, {}, 0, n_ctx};
    return object(reinterpret_cast<intptr_t>(session));
}

// 处理 Prompt
object llama_prompt(const object& args) {
    if (args.size() < 2) throw tcl_error("Usage: llama_prompt handle prompt");

    intptr_t ptr = args.at(0).get<intptr_t>();
    std::string prompt = args.at(1).get<std::string>();
    LlamaSession* session = reinterpret_cast<LlamaSession*>(ptr);
    if (!session || !session->ctx) throw tcl_error("Invalid session handle");

    const llama_vocab* vocab = llama_model_get_vocab(session->model);

    // Tokenize
    std::vector<llama_token> prompt_tokens;
    int text_len = static_cast<int>(prompt.size());

    // 第一次调用获取所需的 token 数量
    int n_tokens = llama_tokenize(vocab, prompt.c_str(), text_len, NULL, 0, true, true);

    // 如果返回负数，表示缓冲区不够，需要分配更多空间
    if (n_tokens < 0) {
        prompt_tokens.resize(-n_tokens);
        n_tokens = llama_tokenize(vocab, prompt.c_str(), text_len, prompt_tokens.data(), -n_tokens, true, true);
        if (n_tokens < 0) throw tcl_error("Tokenization failed");
    } else {
        prompt_tokens.resize(n_tokens);
        llama_tokenize(vocab, prompt.c_str(), text_len, prompt_tokens.data(), n_tokens, true, true);
    }

    // Batch Decode
    struct llama_batch batch = llama_batch_init(n_tokens, 0, 1);
    for (int i = 0; i < n_tokens; i++) {
        common_batch_add(batch, prompt_tokens[i], session->n_past + i, {0}, false);
    }
    // 确保最后一个 token 的 logits 被计算
    batch.n_tokens = n_tokens;
    if (n_tokens > 0) batch.logits[n_tokens - 1] = true;

    if (llama_decode(session->ctx, batch) != 0) {
        llama_batch_free(batch);
        throw tcl_error("llama_decode failed during prompt");
    }

    session->tokens.insert(session->tokens.end(), prompt_tokens.begin(), prompt_tokens.end());
    session->n_past += n_tokens;

    llama_batch_free(batch);
    return object();
}

// 生成文本 (流式版)
object llama_generate(const object& args) {
    if (args.size() < 1) throw tcl_error("Usage: llama_generate handle ?max_tokens? ?temp? ?top_p? ?callback?");

    intptr_t ptr = args.at(0).get<intptr_t>();
    int max_tokens = args.size() > 1 ? args.at(1).get<int>() : 256;
    double temp = args.size() > 2 ? args.at(2).get<double>() : 0.7;
    double top_p = args.size() > 3 ? args.at(3).get<double>() : 0.95;
    std::string callback_proc = args.size() > 4 ? args.at(4).get<std::string>() : "";

    LlamaSession* session = reinterpret_cast<LlamaSession*>(ptr);
    if (!session || !session->ctx) throw tcl_error("Invalid session handle");

    const llama_vocab* vocab = llama_model_get_vocab(session->model);
    llama_token eos_token = llama_vocab_eos(vocab);

    std::string output;
    bool user_interrupted = false;
    bool in_thinking = false;  // 是否在thinking模式

    // 重复检测 - 更激进的策略
    int duplicate_sentence_count = 0;
    std::string last_sentence_end;
    const int MAX_DUPLICATE_SENTENCES = 2;  // 最多允许2个重复句子

    for (int i = 0; i < max_tokens && !user_interrupted; ++i) {
        // Create a batch for the next token
        struct llama_batch batch = llama_batch_init(1, 0, 1);
        common_batch_add(batch, session->tokens.back(), session->n_past, {0}, true);
        batch.logits[0] = true;  // Request logits for this position

        // Decode to get logits
        if (llama_decode(session->ctx, batch) != 0) {
            llama_batch_free(batch);
            throw tcl_error("llama_decode failed during generation");
        }

        // Sample using the newly computed logits
        llama_token id = common_sampler_sample(session->smpl, session->ctx, 0);
        if (id == eos_token) break;

        // Token to Text
        char piece[256];
        int n = llama_token_to_piece(vocab, id, piece, sizeof(piece), 0, true);
        if (n <= 0) continue;

        std::string text_piece(piece, n);

        // 检查是否是ChatML结束标记 <|im_end|>
        if (text_piece.find("<|im_end|>") != std::string::npos) {
            // 跳过这个token，继续生成
            common_sampler_accept(session->smpl, id, true);
            llama_batch_free(batch);
            session->tokens.push_back(id);
            session->n_past++;
            continue;
        }

        // 检测thinking标签
        if (text_piece.find("<thinking>") != std::string::npos) {
            in_thinking = true;
            // 跳过这个token
            common_sampler_accept(session->smpl, id, true);
            llama_batch_free(batch);
            session->tokens.push_back(id);
            session->n_past++;
            continue;
        }

        if (in_thinking) {
            // 检测thinking结束
            if (text_piece.find("</thinking>") != std::string::npos) {
                in_thinking = false;
            }
            // 跳过thinking内容
            common_sampler_accept(session->smpl, id, true);
            llama_batch_free(batch);
            session->tokens.push_back(id);
            session->n_past++;
            continue;
        }

        output += text_piece;

        // 重复检测1：检测句子级别重复（以标点符号分隔）
        if (text_piece.find("。") != std::string::npos ||
            text_piece.find("？") != std::string::npos ||
            text_piece.find("!") != std::string::npos ||
            text_piece.find("\n\n") != std::string::npos) {

            // 检查这句话是否之前出现过
            std::string sentence_end = output.substr(output.length() > 200 ? output.length() - 200 : 0);

            // 如果最近200个字符在之前出现过，说明在重复
            if (output.length() > 400) {
                size_t pos = output.rfind(sentence_end, output.length() - 400 - sentence_end.length());
                if (pos != std::string::npos) {
                    duplicate_sentence_count++;
                    if (duplicate_sentence_count > MAX_DUPLICATE_SENTENCES) {
                        // 检测到重复句子模式，停止生成
                        break;
                    }
                }
            }
        }

        // 重复检测2：检测短词组快速重复（不依赖标点符号）
        if (output.length() > 100) {
            // 检查最近的30个字符是否在输出中重复出现5次以上
            std::string recent = output.substr(output.length() - 30);

            // 统计recent在output中出现的次数
            int count = 0;
            size_t pos = 0;
            while ((pos = output.find(recent, pos)) != std::string::npos) {
                count++;
                pos += recent.length();
                if (count >= 6) {  // 出现6次以上（包括当前这次）
                    // 检测到短词组重复，停止生成
                    goto end_generation;
                }
            }
        }

        // 回调显示（流式）
        if (!callback_proc.empty()) {
            try {
                Tcl_Obj* cmd[2];
                cmd[0] = Tcl_NewStringObj(callback_proc.c_str(), -1);
                cmd[1] = Tcl_NewStringObj(text_piece.c_str(), text_piece.size());

                Tcl_IncrRefCount(cmd[0]);
                Tcl_IncrRefCount(cmd[1]);

                int rc = Tcl_EvalObjv(interpreter::defaultInterpreter->get(), 2, cmd, 0);

                Tcl_DecrRefCount(cmd[0]);
                Tcl_DecrRefCount(cmd[1]);

                if (rc != TCL_OK) {
                    user_interrupted = true;
                }
            } catch (...) {
                user_interrupted = true;
            }
        }

        common_sampler_accept(session->smpl, id, true);

        // Free the batch
        llama_batch_free(batch);

        // Add the new token to the session
        session->tokens.push_back(id);
        session->n_past++;
    }

end_generation:

    if (user_interrupted) {
        return object(output + "\n[Interrupted]");
    }

    return object(output);
}

// 销毁会话
object llama_destroy(const object& args) {
    if (args.size() < 1) throw tcl_error("Usage: llama_destroy handle");
    intptr_t ptr = args.at(0).get<intptr_t>();
    LlamaSession* session = reinterpret_cast<LlamaSession*>(ptr);
    delete session;
    return object();
}

// 获取版本信息
object llama_version(const object& args) {
    return object(std::string("llama-tcl 1.0.0 (based on llama.cpp)"));
}

// 设置采样参数
object llama_set_sampler(object const &args) {
    if (args.size() < 3) {
        throw tcl_error("Usage: llama_set_sampler handle temp top_p ?repeat_penalty?");
    }

    intptr_t ptr = args.at(0).get<intptr_t>();
    double temp = args.at(1).get<double>();
    double top_p = args.at(2).get<double>();
    double repeat_penalty = args.size() > 3 ? args.at(3).get<double>() : 1.0;

    LlamaSession* session = reinterpret_cast<LlamaSession*>(ptr);
    if (!session || !session->smpl) throw tcl_error("Invalid session handle");

    // 重新初始化sampler
    common_sampler_free(session->smpl);

    common_params_sampling sparams;
    sparams.temp = static_cast<float>(temp);
    sparams.top_p = static_cast<float>(top_p);
    sparams.penalty_repeat = static_cast<float>(repeat_penalty);

    session->smpl = common_sampler_init(session->model, sparams);
    if (!session->smpl) {
        throw tcl_error("Failed to reinitialize sampler");
    }

    return object();
}

// 注册模块
CPPTCL_MODULE(Llama, i) {
    i.def("llama_create",    llama_create, variadic());
    i.def("llama_prompt",    llama_prompt, variadic());
    i.def("llama_generate",  llama_generate, variadic());
    i.def("llama_destroy",   llama_destroy, variadic());
    i.def("llama_version",   llama_version, variadic());
    // llama_set_sampler temporarily disabled due to template ambiguity
}

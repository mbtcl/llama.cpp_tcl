# Llama-Tcl

Tcl/Tk 绑定 for llama.cpp - 在Tcl中使用本地大语言模型

## 特性

- ✅ 完整的llama.cpp API支持
- ✅ 流式文本生成
- ✅ Thinking标签自动过滤（适用于Qwen等模型）
- ✅ 支持Tcl 8.6和9.0
- ✅ 线程安全的backend初始化
- ✅ 可重复调用的会话管理

## 依赖

- CMake >= 3.15
- Tcl 8.6 或 9.0
- C++17编译器（Clang/GCC）
- git submodules: llama.cpp, cpptcl

## 编译

### 1. 快速编译

```bash
# 克隆项目（包含submodules）
git clone --recurse-submodules <repository-url>
cd CpptclLlama

# 编译
mkdir build && cd build
cmake ..
make -j4
```

### 2. 安装到系统

```bash
# 安装到 /usr/local
sudo make install

# 或安装到用户目录
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/.local
make install
```

## 使用方法

### 基本用法

```tcl
# 加载扩展
load libllama_tcl.so Llama

# 创建会话
set handle [llama_create /path/to/model.gguf 2048 0]

# 设置prompt
llama_prompt $handle "What is Tcl?"

# 生成文本（流式）
proc stream_callback {text} {
    puts -nonewline $text
    flush stdout
}

set result [llama_generate $handle 256 0.7 0.9 stream_callback]

# 清理
llama_destroy $handle
```

### API文档

#### `llama_create model_path ?n_ctx? ?n_gpu_layers?`
创建新的推理会话

- `model_path`: GGUF模型文件路径
- `n_ctx`: 上下文大小（默认2048）
- `n_gpu_layers`: GPU层数（默认0，即纯CPU）

返回：会话句柄（整数）

#### `llama_prompt handle prompt`
设置prompt并tokenize

- `handle`: 会话句柄
- `prompt`: 提示文本

#### `llama_generate handle ?max_tokens? ?temp? ?top_p? ?callback?`
生成文本

- `handle`: 会话句柄
- `max_tokens`: 最大token数（默认256）
- `temp`: 温度参数（默认0.7）
- `top_p`: top-p采样（默认0.95）
- `callback`: Tcl回调过程名，用于流式输出

返回：生成的完整文本

#### `llama_destroy handle`
销毁会话并释放资源

#### `llama_version`
获取版本信息

### 支持的模型

推荐使用以下模型：

- **Qwen3-4B-Instruct** - 通用模型，无thinking输出
- **Llama-3.2-3B-Instruct** - 轻量级模型
- **其他GGUF格式模型** - 大部分llama.cpp支持的模型

⚠️ **注意**：避免使用"Thinking"版本的模型（如Qwen3-4B-Thinking），因为它们会输出大量思考过程。

## Tk GUI示例

项目包含了一个完整的Tk聊天界面：

```bash
tclsh demo_tk.tcl
```

功能：
- OpenAI风格界面
- 字体大小调节
- Thinking内容自动过滤
- 流式输出显示

## 项目结构

```
CpptclLlama/
├── llama_tcl_wrapper.cpp   # C++ wrapper实现
├── demo_tk.tcl             # Tk GUI聊天界面
├── demo.tcl                # 命令行示例
├── test_llama_tcl.tcl      # 测试脚本
├── CMakeLists.txt          # CMake构建配置
├── llama.cpp/              # llama.cpp submodule
├── cpptcl/                 # cpptcl submodule
└── libllama_tcl.so         # 编译生成的库
```

## 常见问题

### Q: 如何选择模型版本？

A: 推荐使用**Instruct**版本，避免**Thinking**版本。Thinking模型会输出大量思考过程。

### Q: 支持Tcl 9.0吗？

A: 是的，库自动检测并支持Tcl 8.6和9.0。

### Q: 如何使用GPU加速？

A: 在`llama_create`时指定GPU层数：
```tcl
llama_create $model_path 2048 30  ; 30层使用GPU
```

### Q: Thinking标签如何过滤？

A: 库内置了thinking标签过滤，会自动跳过`<thinking>...</thinking>`内容。

## 开发

### 编译选项

```bash
# 指定Tcl版本
cmake .. -DTCL_VERSION=9.0

# 指定安装路径
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local

# Debug模式
cmake .. -DCMAKE_BUILD_TYPE=Debug
```

## 许可证

本项目遵循相关开源许可：
- llama.cpp: MIT License
- cpptcl: BSD License

## 作者

Created with Claude Code

## 更新日志

### v1.0.0 (2025-01-05)
- 初始版本
- 支持基本的文本生成
- Thinking标签过滤
- Tk GUI界面
- Tcl 8.6/9.0支持

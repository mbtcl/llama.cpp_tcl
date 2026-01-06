# 快速开始指南

## 1. 安装库

### 选项A：安装到系统（推荐）

```bash
cd /Users/vajra/Clang/CpptclLlama
./install.sh
```

### 选项B：安装到用户目录

```bash
./install.sh $HOME/.local
```

### 选项C：手动安装

```bash
cd build
sudo cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
sudo make install
```

## 2. 下载模型

推荐使用 **Qwen3-4B-Instruct** 模型（非Thinking版本）：

```bash
# 从ModelScope下载（国内推荐）
# https://modelscope.cn/models/Qwen/Qwen3-4B-Instruct-GGUF

# 或从HuggingFace下载
# https://huggingface.co/Qwen/Qwen3-4B-GGUF
```

## 3. 测试安装

```bash
# 运行测试脚本
tclsh test_llama_tcl.tcl
```

## 4. 使用GUI聊天

```bash
tclsh demo_tk.tcl
```

## 5. 在代码中使用

```tcl
#!/usr/bin/env tclsh

# 加载库
load libllama_tcl.so Llama

# 创建会话
set handle [llama_create /path/to/qwen3-4b-instruct.gguf 2048 0]

# 设置prompt
llama_prompt $handle "你好"

# 定义回调函数（流式输出）
proc on_text {text} {
    puts -nonewline $text
    flush stdout
}

# 生成文本
set result [llama_generate $handle 512 0.7 0.9 on_text]

# 清理
llama_destroy $handle
```

## API速查表

| 命令 | 参数 | 说明 |
|------|------|------|
| `llama_create` | model_path n_ctx n_gpu_layers | 创建会话 |
| `llama_prompt` | handle prompt | 设置prompt |
| `llama_generate` | handle max_tokens temp top_p callback | 生成文本 |
| `llama_destroy` | handle | 销毁会话 |
| `llama_version` | - | 获取版本信息 |

## 常见问题

**Q: 提示找不到库？**
```tcl
# 方法1：使用绝对路径
load /usr/local/lib/libllama_tcl.so Llama

# 方法2：设置环境变量
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# 方法3：添加到 ~/.tclshrc
echo 'load /usr/local/lib/libllama_tcl.so Llama' >> ~/.tclshrc
```

**Q: 模型输出thinking内容？**
A: 请使用 **Instruct** 版本模型，避免使用 **Thinking** 版本。

**Q: 响应很慢？**
A: Qwen3-4B-Instruct模型响应较快。Thinking模型会输出大量思考过程。

## 多版本Tcl支持

库自动支持Tcl 8.6和9.0：

```bash
# 使用Tcl 8.6
tclsh8.6 demo_tk.tcl

# 使用Tcl 9.0
tclsh9.0 demo_tk.tcl
```

## 性能优化

### 启用GPU加速

```tcl
# 使用30层GPU
set handle [llama_create $model_path 2048 30]
```

### 调整采样参数

```tcl
# 更有创造性（高温度）
llama_generate $handle 512 0.9 0.95 callback

# 更确定性（低温度）
llama_generate $handle 512 0.3 0.8 callback
```

## 下一步

- 查看 [README.md](README.md) 了解完整文档
- 查看 [demo_tk.tcl](demo_tk.tcl) 学习GUI实现
- 查看 [demo.tcl](demo.tcl) 学习基本用法

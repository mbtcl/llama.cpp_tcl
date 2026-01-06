# 加载扩展 (确保编译生成的 libllama_tcl.dylib 在当前目录或系统路径中)
# 如果你的文件名不同，请修改 load 参数
catch {load ./libllama_tcl.dylib Llama}

puts "=== Tcl + llama.cpp Demo ==="

# 请修改这里的路径为你的模型路径
set model_path "/Users/vajra/.llama/models/qwen3-4b.gguf"

if {![file exists $model_path]} {
    puts "Error: Model file not found at $model_path"
    puts "Please download a gguf model and update the path in the script."
    exit
}

# 1. 创建会话 (Context Size 2048, 使用 0 层 GPU 或根据显存调整)
puts "Loading model..."
set handle [llama_create $model_path 2048 0]
puts "Model loaded."

# 2. 定义流式回调函数
proc stream_print {text} {
    puts -nonewline $text
    flush stdout
}

# 3. 输入 Prompt
set prompt "Question: Why is the sky blue?\nAnswer:"
puts "\n\nPrompt: $prompt"
llama_prompt $handle $prompt

# 4. 生成 (带流式回调)
puts "Generating: "
set result [llama_generate $handle 128 0.6 0.9 stream_print]

puts "\n\nFinished."
puts "Full Result:\n$result"

# 5. 清理
llama_destroy $handle


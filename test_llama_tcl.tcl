#!/usr/bin/env tclsh

# 测试llama-tcl库的基本功能

# 加载扩展
catch {load ./libllama_tcl.so Llama}

puts "=== Llama-Tcl Test Script ==="
puts ""

# 测试1: 版本信息
puts "Test 1: Version"
if {[catch {llama_version} ver]} {
    puts "  ❌ Failed: $ver"
} else {
    puts "  ✓ Version: $ver"
}
puts ""

# 测试2: 创建会话
puts "Test 2: Create Session"
set model_path "/Users/vajra/.llama/models/qwen3-4b-instruct.gguf"
if {![file exists $model_path]} {
    puts "  ⚠ Model not found: $model_path"
    puts "  Please download the Instruct model and update the path."
    puts ""
    puts "  To install system-wide:"
    puts "    cd /Users/vajra/Clang/CpptclLlama/build"
    puts "    sudo make install"
    puts ""
    exit
}

if {[catch {llama_create $model_path 2048 0} handle]} {
    puts "  ❌ Failed: $handle"
    exit 1
} else {
    puts "  ✓ Session created: $handle"
}
puts ""

# 测试3: 设置prompt
puts "Test 3: Set Prompt"
set test_prompt "Hello, how are you?"
if {[catch {llama_prompt $handle $test_prompt} err]} {
    puts "  ❌ Failed: $err"
} else {
    puts "  ✓ Prompt set"
}
puts ""

# 测试4: 生成文本
puts "Test 4: Generate Text"
if {[catch {llama_generate $handle 50 0.7 0.9} result]} {
    puts "  ❌ Failed: $result"
} else {
    puts "  ✓ Generated: $result"
}
puts ""

# 测试5: 清理
puts "Test 5: Cleanup"
if {[catch {llama_destroy $handle} err]} {
    puts "  ❌ Failed: $err"
} else {
    puts "  ✓ Session destroyed"
}
puts ""

puts "=== All Tests Completed ==="

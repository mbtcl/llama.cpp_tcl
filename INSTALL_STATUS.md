# ⚠️ 重要：Tcl版本兼容性说明

## 当前状态

✅ **编译成功** - llama-tcl库已成功编译
✅ **Tcl 8.6兼容** - 在Tcl 8.6下工作正常
❌ **Tcl 9.0不兼容** - 由于cpptcl的stub库问题，暂时不支持Tcl 9.0

## 测试结果

```bash
# ✅ 使用Tcl 8.6 - 成功
/opt/homebrew/Cellar/tcl-tk@8/8.6.17/bin/tclsh8.6 <<EOF
load ./libllama_tcl.so Llama
llama_version
EOF
# 输出: llama-tcl 1.0.0 (based on llama.cpp)

# ❌ 使用Tcl 9.0 - 失败（stub初始化错误）
tclsh
load ./libllama_tcl.so Llama
# 错误: Failed to initialize stubs
```

## 快速开始

### 方法1: 使用Tcl 8.6（推荐）

```bash
# 使用完整路径运行
/opt/homebrew/Cellar/tcl-tk@8/8.6.17/bin/tclsh8.6 demo_tk.tcl

# 或创建别名
alias tclsh8.6=/opt/homebrew/Cellar/tcl-tk@8/8.6.17/bin/tclsh8.6
tclsh8.6 demo_tk.tcl
```

### 方法2: 直接使用当前编译的库

```bash
cd /Users/vajra/Clang/CpptclLlama
/opt/homebrew/Cellar/tcl-tk@8/8.6.17/bin/tclsh8.6 test_llama_tcl.tcl
```

## 系统安装（Tcl 8.6）

如果你想安装到系统供Tcl 8.6使用：

```bash
cd /Users/vajra/Clang/CpptclLlama
sudo ./install_system.sh
```

安装后，在Tcl 8.6中使用：

```tcl
#!/usr/bin/env tclsh8.6
load /usr/local/lib/libllama_tcl.so Llama
# ...
```

## 为什么不支持Tcl 9.0？

cpptcl库使用Tcl的stub库机制来避免直接链接Tcl。当前编译的cpptcl链接到了Tcl 8.6的stub库，所以只能在Tcl 8.6下运行。

### 未来解决方案

要支持Tcl 9.0，需要：
1. 重新编译cpptcl并链接Tcl 9.0的stub库
2. 或者修改cpptcl不使用stub库，直接链接Tcl框架
3. 等待cpptcl官方更新支持Tcl 9.0

## 验证安装

```bash
# 使用Tcl 8.6测试
/opt/homebrew/Cellar/tcl-tk@8/8.6.17/bin/tclsh8.6 <<EOF
load ./libllama_tcl.so Llama
puts "Version: [llama_version]"
puts "✓ All good!"
EOF
```

## 运行GUI

```bash
cd /Users/vajra/Clang/CpptclLlama
/opt/homebrew/Cellar/tcl-tk@8/8.6.17/bin/tclsh8.6 demo_tk.tcl
```

**记得先下载Qwen3-4B-Instruct模型！**

## 总结

- ✅ 库已编译成功
- ✅ 支持Tcl 8.6
- ⚠️  暂不支持Tcl 9.0
- 💡 使用Tcl 8.6运行所有功能

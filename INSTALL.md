# 系统安装指南

## 一键安装（推荐）

**将cpptcl和llama-tcl都安装到系统**

```bash
cd /Users/vajra/Clang/CpptclLlama
sudo ./install_system.sh
```

这个脚本会自动：
1. 编译并安装cpptcl到 `/usr/local`
2. 编译并安装llama-tcl到 `/usr/local`
3. 验证安装是否成功

## 手动安装

如果你想手动控制安装过程：

### 1. 安装cpptcl

```bash
cd /Users/vajra/Clang/CpptclLlama/cpptcl
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCPPTCL_INSTALL=ON
make -j4
sudo make install
```

### 2. 安装llama-tcl

```bash
cd /Users/vajra/Clang/CpptclLlama
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j4
sudo make install
```

## 安装后的文件结构

```
/usr/local/
├── include/
│   └── cpptcl/
│       ├── cpptcl.h
│       ├── cpptcl_object.h
│       └── version.h
├── lib/
│   ├── libcpptcl.dylib              (或 libcpptcl.so)
│   ├── libcpptcl_static.a
│   ├── libcpptcl_runtime.a
│   ├── libllama_tcl.so              (或 .dylib)
│   ├── cmake/
│   │   └── cpptcl/
│   │       ├── cpptcl-config.cmake
│   │       ├── cpptcl-config-version.cmake
│   │       └── cpptcl-targets.cmake
│   └── pkgconfig/
│       └── llama-tcl.pc
└── share/
    └── doc/
        └── cpptcl/  (如果有文档)
```

## 验证安装

### 方法1: 使用测试脚本

```bash
tclsh test_llama_tcl.tcl
```

### 方法2: 在Tcl中测试

```bash
tclsh
```

然后在Tcl shell中：

```tcl
# 加载llama-tcl
load /usr/local/lib/libllama_tcl.so Llama

# 测试版本
llama_version
# 输出: llama-tcl 1.0.0 (based on llama.cpp)

# 如果能执行到这里，说明安装成功！
```

### 方法3: 使用pkg-config

```bash
# 查看cpptcl信息
pkg-config --modversion cpptcl

# 查看llama-tcl信息
pkg-config --modversion llama-tcl

# 获取编译标志
pkg-config --cflags --libs llama-tcl
```

## 在新项目中使用

### Tcl脚本中

```tcl
#!/usr/bin/env tclsh

# 现在可以直接加载，不需要指定完整路径
load /usr/local/lib/libllama_tcl.so Llama

set handle [llama_create /path/to/model.gguf 2048 0]
# ...
```

或者在 `~/.tclshrc` 中添加：

```tcl
load /usr/local/lib/libllama_tcl.so Llama
```

这样每次启动tclsh都会自动加载。

### CMake项目中使用cpptcl

```cmake
cmake_minimum_required(VERSION 3.15)
project(MyTclExtension)

find_package(cpptcl REQUIRED)
find_package(TCL REQUIRED)

add_library(myext SHARED myext.cpp)
target_link_libraries(myext
    cpptcl::cpptcl
    ${TCL_LIBRARY}
)
```

## 卸载

### 卸载llama-tcl

```bash
sudo rm /usr/local/lib/libllama_tcl.*
sudo rm /usr/local/lib/pkgconfig/llama-tcl.pc
```

### 卸载cpptcl

```bash
sudo rm -rf /usr/local/include/cpptcl
sudo rm /usr/local/lib/libcpptcl.*
sudo rm -rf /usr/local/lib/cmake/cpptcl
```

## 故障排查

### 问题1: 找不到库文件

```bash
# 检查库是否存在
ls -l /usr/local/lib/libllama_tcl.*

# 如果存在但系统找不到，更新动态库路径
echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/usrlocal.conf
sudo ldconfig
```

### 问题2: Tcl找不到扩展

```tcl
# 在Tcl中检查加载路径
puts $auto_path

# 如果/usr/local/lib不在其中，添加到环境变量
set env(LD_LIBRARY_PATH) /usr/local/lib:$env(LD_LIBRARY_PATH)
```

### 问题3: 权限错误

```bash
# 确保库文件有正确的权限
sudo chmod 644 /usr/local/lib/libllama_tcl.so
sudo chmod 755 /usr/local/lib
```

## 系统兼容性

| 系统 | 安装路径 | 状态 |
|------|---------|------|
| macOS (Homebrew) | `/usr/local` | ✅ 支持 |
| Linux | `/usr/local` 或 `/usr` | ✅ 支持 |
| 其他Unix | 自定义前缀 | ✅ 支持 |

## 多版本Tcl支持

安装的库同时支持：
- Tcl 8.6
- Tcl 9.0

系统会自动检测并使用合适的版本。

## 下一步

1. **测试安装**: 运行 `tclsh test_llama_tcl.tcl`
2. **运行GUI**: `tclsh demo_tk.tcl`
3. **创建自己的扩展**: 参考 `CPPTCL_USAGE.md`
4. **查看文档**: `README.md` 和 `QUICKSTART.md`

## 需要帮助？

如果遇到问题：
1. 检查安装日志
2. 查看测试输出
3. 阅读 `QUICKSTART.md` 中的常见问题
4. 查看cpptcl官方文档: `cpptcl/doc/`

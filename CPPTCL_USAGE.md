# cpptcl - C++/Tcl 互操作库

## 什么是cpptcl？

**cpptcl** 是一个独立的C++库，用于在C++和Tcl之间创建桥梁。它让你可以：
- 在C++中轻松创建Tcl扩展
- 从C++调用Tcl代码
- 从Tcl调用C++函数
- 自动处理类型转换

**版本**: 2.2.8
**仓库**: https://github.com/flightaware/cpptcl
**许可证**: BSD

## 在你的项目中使用cpptcl

### 方法1: 作为CMake子项目（推荐）

```cmake
# 你的CMakeLists.txt
add_subdirectory(cpptcl)  # 假设cpptcl在项目根目录

target_link_libraries(your_target cpptcl::cpptcl)
```

### 方法2: 安装到系统后使用

#### 安装cpptcl

```bash
cd /path/to/cpptcl
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
sudo make install
```

#### 在其他项目中使用

```cmake
find_package(cpptcl REQUIRED)
find_package(TCL REQUIRED)

add_executable(myapp main.cpp)
target_link_libraries(myapp
    cpptcl::cpptcl
    ${TCL_LIBRARY}
)
```

### 方法3: 使用pkg-config（如果可用）

```bash
pkg-config --cflags --libs cpptcl
```

## 基本用法示例

### 示例1: 暴露C++函数给Tcl

```cpp
#include "cpptcl/cpptcl.h"
#include <string>

using namespace Tcl;

// C++函数
int add(int a, int b) {
    return a + b;
}

// 注册为Tcl命令
CPPTCL_MODULE(MyModule, i) {
    i.def("add", add);  // Tcl中可以调用: add 3 5
}
```

编译为Tcl扩展：
```bash
g++ -shared -fPIC myextension.cpp -lcpptcl -ltcl -o mymodule.so
```

在Tcl中使用：
```tcl
load ./mymodule.so MyModule
puts [add 3 5]  ;# 输出: 8
```

### 示例2: 使用可变参数

```cpp
object sum_all(object const &argv) {
    int sum = 0;
    for (size_t i = 0; i < argv.size(); ++i) {
        sum += argv.at(i).get<int>();
    }
    return object(sum);
}

CPPTCL_MODULE(MyModule, i) {
    i.def("sum", sum_all, variadic());
}
```

### 示例3: 处理复杂类型

```cpp
#include <vector>
#include "cpptcl/cpptcl.h"

using namespace Tcl;

// 返回列表
object get_numbers() {
    std::vector<int> nums = {1, 2, 3, 4, 5};
    object result;
    for (int n : nums) {
        result.append(object(n));
    }
    return result;
}

// 接收多个参数
object process_data(object const &args) {
    if (args.size() < 2) {
        throw tcl_error("Usage: process_data name value");
    }

    std::string name = args.at(0).get<std::string>();
    double value = args.at(1).get<double>();

    // 处理数据...
    return object(std::string("Processed: ") + name);
}

CPPTCL_MODULE(MyModule, i) {
    i.def("get_numbers", get_numbers);
    i.def("process_data", process_data, variadic());
}
```

## 在llama-tcl中的使用

在 `llama_tcl_wrapper.cpp` 中：

```cpp
#include "cpptcl/cpptcl.h"

using namespace Tcl;

// 定义回调函数
object llama_create(object const &args) {
    // 参数处理
    std::string model_path = args.at(0).get<std::string>();
    int n_ctx = args.size() > 1 ? args.at(1).get<int>() : 2048;

    // ... 创建会话 ...

    return object(reinterpret_cast<intptr_t>(session));
}

// 注册模块
CPPTCL_MODULE(Llama, i) {
    i.def("llama_create", llama_create, variadic());
    i.def("llama_prompt", llama_prompt, variadic());
    i.def("llama_generate", llama_generate, variadic());
}
```

## cpptcl提供的库类型

| 库名 | 类型 | 用途 |
|------|------|------|
| `cpptcl::cpptcl` | 共享库 | 动态链接，推荐用于扩展 |
| `cpptcl::cpptcl_static` | 静态库 | 静态链接到可执行文件 |
| `cpptcl::cpptcl_runtime` | 运行时 | 包含Tcl C API，完整功能 |

## 构建选项

```bash
# 只构建库，不构建测试和示例
cmake .. -DCPPTCL_TEST=OFF -DCPPTCL_EXAMPLES=OFF

# 启用安装（作为子项目时需要）
cmake .. -DCPPTCL_INSTALL=ON

# 指定Tcl版本
cmake .. -DTCL_VERSION_MAJOR=9 -DTCL_VERSION_MINOR=0
```

## 类型转换

cpptcl自动处理以下类型转换：

| C++类型 | Tcl类型 |
|---------|---------|
| `int`, `long` | integer |
| `double`, `float` | double |
| `std::string` | string |
| `bool` | boolean |
| `std::vector<T>` | list |
| 自定义类 | 需要特殊处理 |

## 错误处理

```cpp
object my_function(object const &args) {
    if (args.size() < 1) {
        throw tcl_error("Missing arguments");
    }

    try {
        // 你的代码
        return object(result);
    } catch (const std::exception &e) {
        throw tcl_error(std::string("Error: ") + e.what());
    }
}
```

## 文档和资源

- **完整文档**: `cpptcl/doc/` 目录
- **示例**: `cpptcl/examples/` 目录
- **测试**: `cpptcl/test/` 目录
- **GitHub**: https://github.com/flightaware/cpptcl

## 常见问题

### Q: 如何调试cpptcl扩展？

A: 使用Tcl的`errorInfo`变量：
```tcl
set result [catch {my_func} errMsg]
puts $errorInfo
```

### Q: 如何传递回调函数？

A: 使用字符串传递Tcl过程名，然后在C++中调用：
```cpp
// Tcl:
proc my_callback {text} {
    puts "Got: $text"
}
my_func "my_callback"

// C++:
std::string callback_name = args.at(0).get<std::string>();
// 然后使用 Tcl_EvalObjv 调用
```

### Q: 支持哪些C++标准？

A: C++11及以上（CMake设置：`cxx_std_11`）

## 总结

cpptcl是一个成熟、稳定的库，可以让你的C++代码与Tcl轻松互操作。它被广泛用于生产环境，特别是在需要将高性能C++代码暴露给Tcl脚本使用时。

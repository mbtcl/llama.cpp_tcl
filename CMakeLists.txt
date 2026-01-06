cmake_minimum_required(VERSION 3.15)
project(LlamaTcl VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

# 支持多个Tcl版本
set(TCL_MIN_VERSION 8.6)
set(TCL_MAX_VERSION 9.9)

# 查找可用的Tcl版本
# 首先尝试使用系统框架（Tcl 9.0或8.6）
foreach(ver 9.0 8.6)
    find_package(TCL ${ver} QUIET)
    if (TCL_FOUND)
        set(TCL_VERSION_FOUND ${ver})
        break()
    endif()
endforeach()

# 如果找到了，优先使用系统框架的Tcl
if (TCL_FOUND)
    message(STATUS "Found Tcl ${TCL_VERSION_FOUND}: ${TCL_LIBRARY}")
else()
    message(FATAL_ERROR "Tcl 8.6 or 9.0 not found")
endif()

# ==============================================================================
# 1. 引入并配置 llama.cpp
# ==============================================================================
add_subdirectory(llama.cpp)

# ==============================================================================
# 2. 引入并配置 cpptcl
# ==============================================================================
add_subdirectory(cpptcl)

# ==============================================================================
# 3. 构建 Tcl 扩展
# ==============================================================================
add_library(llama_tcl SHARED
    llama_tcl_wrapper.cpp
)

# 配置头文件路径
target_include_directories(llama_tcl PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/common
    ${CMAKE_CURRENT_SOURCE_DIR}/cpptcl
)

# 链接库
target_link_libraries(llama_tcl PRIVATE
    llama
    common
    cpptcl::cpptcl
    ${TCL_LIBRARY}
)

# 在macOS上，确保使用Tcl框架而不是stub
if(APPLE)
    target_link_libraries(llama_tcl PRIVATE
        "-framework Tcl"
    )
endif()

# 设置输出名称
if (APPLE)
    set_target_properties(llama_tcl PROPERTIES
        SUFFIX ".so"
        PREFIX "lib"
    )
elseif (UNIX)
    set_target_properties(llama_tcl PROPERTIES
        PREFIX ""
        SUFFIX ".so"
    )
endif()

# 安装规则
include(GNUInstallDirs)

# 安装库文件
install(TARGETS llama_tcl
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# 获取Tcl安装路径
execute_process(
    COMMAND ${TCL_TCLSH} -clock::seconds
    OUTPUT_VARIABLE TCL_TIME
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
    COMMAND ${TCL_TCLSH} -e "puts [file normalize [file join $::tcl_library ..]]"
    OUTPUT_VARIABLE TCL_PREFIX
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

message(STATUS "Tcl installation prefix: ${TCL_PREFIX}")

# 安装到Tcl的lib目录
install(TARGETS llama_tcl
    LIBRARY DESTINATION ${TCL_PREFIX}/lib
)

# 创建pkg-config文件
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/llama-tcl.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/llama-tcl.pc
    @ONLY
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/llama-tcl.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

# 打印安装信息
message(STATUS "==========================================")
message(STATUS "Llama-Tcl Configuration Summary")
message(STATUS "==========================================")
message(STATUS "Version:           ${PROJECT_VERSION}")
message(STATUS "Tcl version:       ${TCL_VERSION_FOUND}")
message(STATUS "Tcl library:       ${TCL_LIBRARY}")
message(STATUS "Tcl prefix:        ${TCL_PREFIX}")
message(STATUS "Install prefix:    ${CMAKE_INSTALL_PREFIX}")
message(STATUS "==========================================")

#!/bin/bash

# 系统安装脚本 - 安装cpptcl和llama-tcl到系统

set -e

INSTALL_PREFIX="/usr/local"

echo "=========================================="
echo "cpptcl & llama-tcl System Installation"
echo "=========================================="
echo ""
echo "This script will install:"
echo "  1. cpptcl to $INSTALL_PREFIX"
echo "  2. llama-tcl to $INSTALL_PREFIX"
echo ""
echo "Requirements:"
echo "  - sudo/root privileges"
echo "  - Tcl 8.6 or 9.0"
echo ""

# 检查是否有sudo权限
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges."
    echo "Please run: sudo ./install_system.sh"
    exit 1
fi

# ==============================================================================
# 步骤1: 安装cpptcl
# ==============================================================================
echo ""
echo "=========================================="
echo "Step 1: Installing cpptcl"
echo "=========================================="
echo ""

cd cpptcl
if [ ! -d "build" ]; then
    echo "Creating build directory..."
    mkdir build
fi

cd build
echo "Configuring cpptcl..."
cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
         -DCPPTCL_INSTALL=ON \
         -DCPPTCL_TEST=OFF \
         -DCPPTCL_EXAMPLES=OFF \
         >/dev/null 2>&1

echo "Building cpptcl..."
make -j4 >/dev/null 2>&1

echo "Installing cpptcl..."
make install >/dev/null 2>&1

echo "✓ cpptcl installed to $INSTALL_PREFIX"

cd ../..

# ==============================================================================
# 步骤2: 安装llama-tcl
# ==============================================================================
echo ""
echo "=========================================="
echo "Step 2: Installing llama-tcl"
echo "=========================================="
echo ""

if [ ! -d "build" ]; then
    echo "Creating build directory..."
    mkdir build
fi

cd build
echo "Configuring llama-tcl..."
cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
         -DLLAMA_BUILD_COMMON=ON \
         >/dev/null 2>&1

echo "Building llama-tcl..."
make -j4 >/dev/null 2>&1

echo "Installing llama-tcl..."
make install >/dev/null 2>&1

echo "✓ llama-tcl installed to $INSTALL_PREFIX"

cd ..

# ==============================================================================
# 步骤3: 验证安装
# ==============================================================================
echo ""
echo "=========================================="
echo "Step 3: Verifying Installation"
echo "=========================================="
echo ""

# 检查文件是否存在
if [ -f "$INSTALL_PREFIX/lib/libcpptcl.dylib" ] || [ -f "$INSTALL_PREFIX/lib/libcpptcl.so" ]; then
    echo "✓ cpptcl library found"
else
    echo "✗ cpptcl library NOT found"
    exit 1
fi

if [ -f "$INSTALL_PREFIX/lib/libllama_tcl.so" ] || [ -f "$INSTALL_PREFIX/lib/libllama_tcl.dylib" ]; then
    echo "✓ llama-tcl library found"
else
    echo "✗ llama-tcl library NOT found"
    exit 1
fi

# 检查头文件
if [ -d "$INSTALL_PREFIX/include/cpptcl" ]; then
    echo "✓ cpptcl headers found"
else
    echo "✗ cpptcl headers NOT found"
fi

# 检查cmake配置
if [ -f "$INSTALL_PREFIX/lib/cmake/cpptcl/cpptcl-config.cmake" ]; then
    echo "✓ cpptcl cmake config found"
else
    echo "✗ cpptcl cmake config NOT found"
fi

# ==============================================================================
# 完成
# ==============================================================================
echo ""
echo "=========================================="
echo "Installation Completed Successfully!"
echo "=========================================="
echo ""
echo "Installed libraries:"
echo "  - cpptcl:      $INSTALL_PREFIX/lib/libcpptcl.*"
echo "  - llama-tcl:   $INSTALL_PREFIX/lib/libllama_tcl.*"
echo ""
echo "Headers:"
echo "  - cpptcl:      $INSTALL_PREFIX/include/cpptcl/"
echo ""
echo "CMake configs:"
echo "  - cpptcl:      $INSTALL_PREFIX/lib/cmake/cpptcl/"
echo ""
echo "To use in Tcl:"
echo "  load $INSTALL_PREFIX/lib/libllama_tcl.so Llama"
echo ""
echo "To use in CMake:"
echo "  find_package(cpptcl REQUIRED)"
echo "  target_link_libraries(your_target cpptcl::cpptcl)"
echo ""
echo "=========================================="

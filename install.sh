#!/bin/bash

# Llama-Tcl 安装脚本

set -e

INSTALL_PREFIX=${1:-"/usr/local"}

echo "=========================================="
echo "Llama-Tcl Installation Script"
echo "=========================================="
echo "Install prefix: $INSTALL_PREFIX"
echo ""

# 检查权限
if [ "$INSTALL_PREFIX" = "/usr/local" ] || [ "$INSTALL_PREFIX" = "/usr" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "❌ Error: Installing to $INSTALL_PREFIX requires root privileges"
        echo "   Please run: sudo ./install.sh"
        echo "   Or install to user directory: ./install.sh \$HOME/.local"
        exit 1
    fi
fi

# 进入构建目录
cd "$(dirname "$0")/build"

if [ ! -f "libllama_tcl.so" ]; then
    echo "❌ Error: Library not found. Please run 'make' first."
    exit 1
fi

# 安装
echo "Installing to $INSTALL_PREFIX..."
cmake .. -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" >/dev/null 2>&1
make install

echo ""
echo "=========================================="
echo "Installation completed!"
echo "=========================================="
echo ""
echo "Library installed to: $INSTALL_PREFIX/lib/"
echo ""
echo "To use in Tcl:"
echo "  load $INSTALL_PREFIX/lib/libllama_tcl.so Llama"
echo ""
echo "Or add to your ~/.tclshrc:"
echo "  load $INSTALL_PREFIX/lib/libllama_tcl.so Llama"
echo ""

# 获取Tcl版本
TCL_VER=$(echo 'puts $tcl_version' | tclsh)
echo "Detected Tcl version: $TCL_VER"
echo ""

# 测试安装
echo "Testing installation..."
if tclsh <<EOF
catch {load $INSTALL_PREFIX/lib/libllama_tcl.so Llama} err
if {[info commands llama_version] ne ""} {
    puts "✓ Installation successful!"
    puts "  Version: [llama_version]"
    exit 0
} else {
    puts "❌ Installation test failed: $err"
    exit 1
}
EOF
then
    echo ""
    echo "You can now use llama-tcl in your Tcl scripts!"
else
    echo ""
    echo "⚠ Installation test failed. Check the error messages above."
    exit 1
fi

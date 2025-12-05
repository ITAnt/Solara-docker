#!/bin/bash

# 本地开发环境设置脚本

echo "=========================================="
echo "Solara Music 本地环境设置"
echo "=========================================="

# 创建下载目录
DOWNLOAD_DIR="./downloads"

if [ ! -d "$DOWNLOAD_DIR" ]; then
    mkdir -p "$DOWNLOAD_DIR"
    echo "✓ 创建下载目录: $DOWNLOAD_DIR"
else
    echo "✓ 下载目录已存在: $DOWNLOAD_DIR"
fi

# 设置权限
chmod 755 "$DOWNLOAD_DIR"
echo "✓ 设置目录权限: 755"

echo ""
echo "=========================================="
echo "设置完成！"
echo "=========================================="
echo ""
echo "运行应用:"
echo "  npm start"
echo ""
echo "或使用自定义下载目录:"
echo "  DOWNLOAD_DIR=./downloads npm start"
echo ""

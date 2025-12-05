#!/bin/bash

# Docker 清理脚本 - 清理旧镜像和构建缓存

set -e

# 配置变量
IMAGE_NAME="solara-music"
VERSION="1.0.0"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker 清理脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 显示当前镜像
echo -e "${BLUE}当前 ${IMAGE_NAME} 镜像:${NC}"
docker images | grep ${IMAGE_NAME} || echo "没有找到相关镜像"
echo ""

# 询问是否继续
read -p "是否清理所有 ${IMAGE_NAME} 镜像? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}已取消${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}开始清理...${NC}"
echo -e "${BLUE}========================================${NC}"

# 删除指定版本的镜像
echo -e "${BLUE}删除 ${IMAGE_NAME}:${VERSION}-amd64...${NC}"
docker rmi ${IMAGE_NAME}:${VERSION}-amd64 2>/dev/null && echo -e "${GREEN}✓ 已删除${NC}" || echo -e "${YELLOW}⚠ 镜像不存在${NC}"

echo -e "${BLUE}删除 ${IMAGE_NAME}:${VERSION}-arm64...${NC}"
docker rmi ${IMAGE_NAME}:${VERSION}-arm64 2>/dev/null && echo -e "${GREEN}✓ 已删除${NC}" || echo -e "${YELLOW}⚠ 镜像不存在${NC}"

# 删除所有相关镜像（包括旧版本）
echo ""
echo -e "${BLUE}删除所有 ${IMAGE_NAME} 相关镜像...${NC}"
docker images | grep ${IMAGE_NAME} | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null && echo -e "${GREEN}✓ 已删除${NC}" || echo -e "${YELLOW}⚠ 没有更多镜像${NC}"

# 清理悬空镜像（dangling images）
echo ""
echo -e "${BLUE}清理悬空镜像...${NC}"
docker image prune -f && echo -e "${GREEN}✓ 已清理${NC}"

# 询问是否清理构建缓存
echo ""
read -p "是否清理 Docker 构建缓存? 这会影响所有项目的构建速度 (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}清理构建缓存...${NC}"
    docker builder prune -f && echo -e "${GREEN}✓ 已清理${NC}"
fi

# 询问是否删除 buildx builder
echo ""
read -p "是否删除 buildx builder? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}删除 buildx builder...${NC}"
    docker buildx rm multiarch-builder 2>/dev/null && echo -e "${GREEN}✓ 已删除${NC}" || echo -e "${YELLOW}⚠ Builder 不存在${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}清理完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 显示清理后的镜像列表
echo -e "${BLUE}当前 Docker 镜像:${NC}"
docker images | head -10
echo ""

# 显示磁盘使用情况
echo -e "${BLUE}Docker 磁盘使用情况:${NC}"
docker system df
echo ""

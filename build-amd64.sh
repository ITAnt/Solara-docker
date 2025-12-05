#!/bin/bash

# 构建 AMD64 架构 Docker 镜像脚本

set -e

# 配置变量
IMAGE_NAME="solara-music"
VERSION="1.0.0"
OUTPUT_DIR="./docker-images"

# Docker 镜像代理列表（按优先级排序）
DOCKER_MIRRORS=(
    "https://docker.1ms.run"
    "https://docker.xuanyuan.me"
)

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Solara Music AMD64 镜像构建脚本${NC}"
echo -e "${BLUE}========================================${NC}"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker 已安装${NC}"

# 检查 buildx 是否可用
if ! docker buildx version &> /dev/null; then
    echo -e "${RED}错误: Docker Buildx 未安装或未启用${NC}"
    echo "请运行: docker buildx install"
    exit 1
fi

echo -e "${GREEN}✓ Docker Buildx 已就绪${NC}"

# 检查是否存在旧镜像
if docker images | grep -q "${IMAGE_NAME}:${VERSION}-amd64"; then
    echo -e "${YELLOW}⚠ 发现旧的 AMD64 镜像${NC}"
    echo -e "${BLUE}删除旧镜像...${NC}"
    docker rmi -f ${IMAGE_NAME}:${VERSION}-amd64 2>/dev/null || true
    echo -e "${GREEN}✓ 已删除旧镜像${NC}"
fi

# 清理悬空镜像
echo -e "${BLUE}清理悬空镜像...${NC}"
docker image prune -f > /dev/null 2>&1
echo -e "${GREEN}✓ 已清理悬空镜像${NC}"

# 检测是否可以访问 Docker Hub
echo -e "${BLUE}检测网络连接...${NC}"
if timeout 3 curl -s https://hub.docker.com > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 可以直接访问 Docker Hub${NC}"
    USE_MIRROR=false
    DOCKERFILE="dockerfile"
else
    echo -e "${YELLOW}⚠ 无法访问 Docker Hub，将使用镜像代理${NC}"
    USE_MIRROR=true
    DOCKERFILE="dockerfile.mirror"
    
    # 测试镜像代理可用性
    echo -e "${BLUE}测试镜像代理...${NC}"
    MIRROR_AVAILABLE=false
    for mirror in "${DOCKER_MIRRORS[@]}"; do
        if timeout 3 curl -s "${mirror}" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 镜像代理可用: ${mirror}${NC}"
            MIRROR_AVAILABLE=true
            break
        else
            echo -e "${YELLOW}⚠ 镜像代理不可用: ${mirror}${NC}"
        fi
    done
    
    if [ "$MIRROR_AVAILABLE" = false ]; then
        echo -e "${RED}错误: 所有镜像代理均不可用${NC}"
        echo -e "${YELLOW}提示: 请检查网络连接或使用 VPN${NC}"
        exit 1
    fi
fi

# 创建并使用 buildx builder
echo -e "${BLUE}创建 buildx builder...${NC}"
docker buildx create --name multiarch-builder --use --bootstrap 2>/dev/null || docker buildx use multiarch-builder

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}开始构建 AMD64 镜像...${NC}"
echo -e "${BLUE}使用 Dockerfile: ${DOCKERFILE}${NC}"
echo -e "${BLUE}========================================${NC}"

# 构建 AMD64 架构镜像
docker buildx build \
    --platform linux/amd64 \
    -t ${IMAGE_NAME}:${VERSION}-amd64 \
    -f ${DOCKERFILE} \
    --load \
    .

echo -e "${GREEN}✓ AMD64 镜像构建完成${NC}"

# 构建后清理悬空镜像
echo -e "${BLUE}清理构建产生的悬空镜像...${NC}"
docker image prune -f > /dev/null 2>&1
echo -e "${GREEN}✓ 已清理${NC}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}导出镜像为 tar 文件...${NC}"
echo -e "${BLUE}========================================${NC}"

# 导出 AMD64 镜像
OUTPUT_FILE="${OUTPUT_DIR}/${IMAGE_NAME}-${VERSION}-amd64.tar"

# 如果文件已存在，先删除
if [ -f "${OUTPUT_FILE}" ]; then
    echo -e "${YELLOW}删除旧的 tar 文件...${NC}"
    rm -f "${OUTPUT_FILE}"
fi

docker save ${IMAGE_NAME}:${VERSION}-amd64 -o ${OUTPUT_FILE}
echo -e "${GREEN}✓ 已保存: ${OUTPUT_FILE}${NC}"

# 显示文件信息
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}构建完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}输出文件: ${OUTPUT_FILE}${NC}"
echo ""
ls -lh ${OUTPUT_FILE}

echo ""
echo -e "${BLUE}使用方法:${NC}"
echo -e "  导入镜像: docker load -i ${OUTPUT_FILE}"
echo ""
echo -e "${BLUE}运行容器:${NC}"
echo -e "  docker run -d -p 3001:3001 -v ./downloads:/download --name solara-music ${IMAGE_NAME}:${VERSION}-amd64"
echo ""

# Docker 镜像构建指南

本项目提供了两个独立的脚本，分别用于构建 ARM64 和 AMD64 架构的 Docker 镜像。

## 特性

- ✅ 自动检测网络连接
- ✅ 智能选择 Docker 镜像代理
- ✅ 支持国内镜像加速（docker.1ms.run、docker.xuanyuan.me）
- ✅ 自动配置 npm 镜像源
- ✅ 分离构建 AMD64 和 ARM64 架构

## 前置要求

1. 安装 Docker Desktop（Mac）或 Docker Engine（Linux）
2. 启用 Docker Buildx（Docker Desktop 默认已启用）
3. 确保 Docker 服务正在运行
4. 安装 curl（用于网络检测）

### 检查 Buildx 是否可用

```bash
docker buildx version
```

如果未安装，运行：
```bash
docker buildx install
```

## 镜像代理说明

脚本会自动检测网络环境：

1. **可以访问 Docker Hub**：直接使用官方镜像（`dockerfile`）
2. **无法访问 Docker Hub**：自动使用镜像代理（`dockerfile.mirror`）

使用的镜像代理（按优先级）：
- https://docker.1ms.run
- https://docker.xuanyuan.me

镜像代理版本还会自动配置 npm 镜像源为 `https://registry.npmmirror.com`

## 使用方法

### 构建 AMD64 架构镜像

```bash
# 添加执行权限
chmod +x build-amd64.sh

# 运行脚本
./build-amd64.sh
```

### 构建 ARM64 架构镜像

```bash
# 添加执行权限
chmod +x build-arm64.sh

# 运行脚本
./build-arm64.sh
```

### 同时构建两个架构

```bash
# 添加执行权限
chmod +x build-amd64.sh build-arm64.sh

# 依次构建
./build-amd64.sh && ./build-arm64.sh
```

### 重新构建（清理后构建）

如果镜像越来越大，建议先清理再构建：

```bash
# 清理旧镜像
./clean-docker.sh

# 重新构建
./build-amd64.sh
./build-arm64.sh
```

构建脚本会自动：
- 删除同版本的旧镜像
- 覆盖已存在的 tar 文件

## 构建输出

脚本会在 `docker-images/` 目录下生成以下文件：

- `solara-music-1.0.0-amd64.tar` - AMD64 架构镜像（约 160MB）
- `solara-music-1.0.0-arm64.tar` - ARM64 架构镜像（约 160MB）

### 镜像大小说明

- **基础镜像**: node:18-alpine (~55MB)
- **应用代码**: ~5MB
- **依赖包**: ~100MB
- **总大小**: ~160MB

这是正常的大小。如果发现镜像越来越大：
1. 检查是否有悬空镜像：`docker images -f "dangling=true"`
2. 运行清理脚本：`./clean-docker.sh`
3. 确保 `.dockerignore` 文件存在并正确配置

## 导入镜像

```bash
# AMD64 架构
docker load -i docker-images/solara-music-1.0.0-amd64.tar

# ARM64 架构
docker load -i docker-images/solara-music-1.0.0-arm64.tar
```

## 运行容器

### 基本运行

```bash
# AMD64
docker run -d -p 3001:3001 -v ./downloads:/download --name solara-music solara-music:1.0.0-amd64

# ARM64
docker run -d -p 3001:3001 -v ./downloads:/download --name solara-music solara-music:1.0.0-arm64
```

### 带环境变量运行

```bash
docker run -d \
  -p 3001:3001 \
  -e SOLARA_PASSWORD=your_password \
  -e PORT=3001 \
  -e DOWNLOAD_DIR=/download \
  -v ./downloads:/download \
  --name solara-music \
  solara-music:1.0.0-amd64
```

### 使用 Docker Compose

```bash
docker-compose -f docker-compose.example.yml up -d
```

## 架构说明

- **AMD64 (x86_64)**: 适用于大多数 PC、服务器和云平台（Intel/AMD 处理器）
- **ARM64 (aarch64)**: 适用于 Apple Silicon (M1/M2/M3)、树莓派 4/5、AWS Graviton 等

## 常见问题

### 1. 网络检测失败

如果脚本提示"所有镜像代理均不可用"：
- 检查网络连接
- 尝试手动访问镜像代理网站
- 使用 VPN 或代理
- 手动指定 Dockerfile：`docker buildx build -f dockerfile.mirror ...`

### 2. 构建失败：平台不支持

如果遇到 "platform not supported" 错误，可能需要安装 QEMU：

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
```

### 3. 构建速度慢

跨平台构建（如在 AMD64 上构建 ARM64）会使用模拟器，速度较慢是正常现象。建议：
- 在对应架构的机器上构建（如在 Apple Silicon 上构建 ARM64）
- 或者使用云服务器进行构建
- 使用镜像代理可以加速基础镜像下载

### 4. 内存不足

构建镜像需要较多内存，建议为 Docker 分配至少 4GB 内存。

### 5. 无法加载镜像到本地

使用 `--load` 参数时，Docker Buildx 可能无法加载跨平台镜像。解决方案：
- 在对应架构的机器上构建
- 或者使用 `--output type=docker,dest=file.tar` 参数

### 6. npm 安装依赖失败

如果使用镜像代理版本仍然失败：
- 检查 npm 镜像源是否可用
- 手动修改 `dockerfile.mirror` 中的 npm registry
- 或者在本地先运行 `npm install` 生成 `node_modules`

## 数据持久化

容器使用 `/download` 目录存储下载的文件，建议挂载到宿主机：

```bash
# 创建本地下载目录
mkdir -p ./downloads

# 运行容器时挂载
docker run -d \
  -p 3001:3001 \
  -v ./downloads:/download \
  --name solara-music \
  solara-music:1.0.0-amd64
```

**权限说明：**
- 容器使用 root 用户运行，确保有权限写入挂载的目录
- 无需手动设置权限

## 清理

### 使用清理脚本（推荐）

```bash
# 添加执行权限
chmod +x clean-docker.sh

# 运行清理脚本
./clean-docker.sh
```

清理脚本会：
- 删除所有 solara-music 镜像
- 清理悬空镜像
- 可选：清理构建缓存
- 可选：删除 buildx builder

### 手动清理

删除构建的镜像：
```bash
docker rmi solara-music:1.0.0-amd64
docker rmi solara-music:1.0.0-arm64
```

删除 buildx builder：
```bash
docker buildx rm multiarch-builder
```

清理输出文件：
```bash
rm -rf docker-images
```

清理所有悬空镜像：
```bash
docker image prune -f
```

清理构建缓存：
```bash
docker builder prune -f
```

## 高级用法

### 同时构建并推送到 Docker Hub

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t username/solara-music:1.0.0 \
  --push \
  .
```

### 构建并推送到私有仓库

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t registry.example.com/solara-music:1.0.0 \
  --push \
  .
```

### 自定义镜像名称和版本

编辑脚本中的变量：

```bash
IMAGE_NAME="your-app-name"
VERSION="2.0.0"
```

### 强制使用镜像代理

如果想强制使用镜像代理（即使可以访问 Docker Hub）：

```bash
docker buildx build \
  --platform linux/amd64 \
  -t solara-music:1.0.0-amd64 \
  -f dockerfile.mirror \
  --load \
  .
```

### 手动配置 Docker 镜像代理

如果想全局配置 Docker 镜像代理，编辑 `/etc/docker/daemon.json`：

```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me"
  ]
}
```

然后重启 Docker：
```bash
sudo systemctl restart docker
```

## 环境变量说明

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| PORT | 3001 | 服务端口 |
| SOLARA_PASSWORD | Solara123 | 登录密码 |
| DOWNLOAD_DIR | /download | 下载目录 |
| NODE_ENV | production | 运行环境 |
| SESSION_KEYS | 自动生成 | Session 密钥（多个用逗号分隔） |

## 技术支持

如有问题，请查看：
- Docker 官方文档: https://docs.docker.com/
- Docker Buildx 文档: https://docs.docker.com/buildx/

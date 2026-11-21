#!/usr/bin/env sh
set -e

cd "$(dirname "$0")"

# ====================== 配置区域 ======================
IMAGE_NAME="van-nav"
IMAGE_TAG="${IMAGE_TAG:-$(tr -d '[:space:]' < version.txt)}"
DOCKER_HUB_USER_NAME="${DOCKER_HUB_USER_NAME:-dengdg}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
# 仅本地构建不推送时设为 1
SKIP_PUSH="${SKIP_PUSH:-0}"
# ======================================================

FULL_IMAGE="${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"
LATEST_IMAGE="${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:latest"
TAG_AMD64="${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:${IMAGE_TAG}-amd64"
TAG_ARM64="${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:${IMAGE_TAG}-arm64"

echo "==================== 多平台镜像构建 ===================="
echo "镜像名称: $FULL_IMAGE"
echo "目标架构: $PLATFORMS"
echo "推送: $([ "$SKIP_PUSH" = "1" ] && echo "否" || echo "是")"
echo "========================================================"

# 确保有 buildx 构建器
if ! docker buildx ls 2>/dev/null | grep -q "mybuilder"; then
  echo "[1/3] 创建 buildx 构建器 mybuilder"
  docker buildx create --name mybuilder --use --bootstrap \
    --driver docker-container \
    --config ./buildkitd.toml
else
  echo "[1/3] 使用已有 buildx 构建器 mybuilder"
  docker buildx use mybuilder
fi

if [ "$SKIP_PUSH" = "1" ]; then
  # 仅本地：按架构分别 --load（buildx 多平台 --push 才能一次出多架构；--load 只能单架构）
  echo "[2/3] 本地构建 linux/amd64"
  docker buildx build --builder mybuilder --platform linux/amd64 -t "${IMAGE_NAME}:${IMAGE_TAG}-amd64" --load .

  echo "[2/3] 本地构建 linux/arm64"
  docker buildx build --builder mybuilder --platform linux/arm64 -t "${IMAGE_NAME}:${IMAGE_TAG}-arm64" --load .

  echo "[3/3] 本地镜像已就绪："
  docker images "${IMAGE_NAME}"
else
  echo "[1/2] 登录 DockerHub"
  docker login

  echo "[2/2] 多架构构建并推送"
  docker buildx build \
    --builder mybuilder \
    --platform "$PLATFORMS" \
    -t "$FULL_IMAGE" \
    -t "$LATEST_IMAGE" \
    --progress=plain \
    --push \
    .

  echo "完成"
  echo "  版本镜像: $FULL_IMAGE"
  echo "  latest:   $LATEST_IMAGE"
fi

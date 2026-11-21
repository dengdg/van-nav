#!/usr/bin/env sh
set -e

cd "$(dirname "$0")"

# 镜像名
IMAGE_NAME="van-nav"

# 镜像Tag
IMAGE_TAG="${IMAGE_TAG:-0.0.3.1}"

# DockerHub用户名
DOCKER_HUB_USER_NAME="${DOCKER_HUB_USER_NAME:-dengdg}"

# 本地镜像名和Tag
LOCAL_IMAGE_AND_TAG="${IMAGE_NAME}:${IMAGE_TAG}"

# Push到仓库中的镜像名和Tag
PUSH_IMAGE_AND_TAG="${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# 使用带 registry 镜像加速的 buildx 构建器（见 buildkitd.toml）
BUILDER_NAME="mybuilder"

ensure_builder() {
  if ! docker buildx ls 2>/dev/null | grep -q "$BUILDER_NAME"; then
    echo "创建 buildx 构建器 $BUILDER_NAME"
    docker buildx create \
      --name "$BUILDER_NAME" \
      --use \
      --bootstrap \
      --driver docker-container \
      --config ./buildkitd.toml
  else
    docker buildx use "$BUILDER_NAME"
  fi
}

echo "构建镜像"
ensure_builder
docker buildx build \
  --builder "$BUILDER_NAME" \
  --load \
  -t "$LOCAL_IMAGE_AND_TAG" \
  .

echo "登录"
docker login

echo "打标签 $PUSH_IMAGE_AND_TAG"
docker tag "$LOCAL_IMAGE_AND_TAG" "$PUSH_IMAGE_AND_TAG"

echo "上传镜像"
docker push "$PUSH_IMAGE_AND_TAG"

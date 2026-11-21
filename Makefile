# van-nav 构建 / 推送 / Docker Hub Overview 编排
#
# 用法示例:
#   make help
#   make build                 # 构建前端 + Go 二进制
#   make image                 # 多平台构建并推送镜像
#   make overview              # 用 DOCKERHUB.md 更新 Docker Hub Overview
#                               # (sh: update-overview.sh / Windows: update-overview.ps1)
#   make publish               # 推送镜像 + 更新 Overview
#   make local                 # 仅本地构建镜像（不推送）
#   make push                  # 简易单架构构建推送（upload-image.sh）
#
# 常用环境变量:
#   IMAGE_NAME=van-nav
#   DOCKER_HUB_USER_NAME=dengdg
#   IMAGE_TAG=0.0.3            # 默认读 version.txt
#   DOCKERHUB_TOKEN=...        # 更新 Overview 必需
#   README_FILE=DOCKERHUB.md   # Overview 文档（默认）
#   SHORT_DESCRIPTION=...      # 可选，覆盖自动提取的短描述

IMAGE_NAME            ?= van-nav
DOCKER_HUB_USER_NAME  ?= dengdg
IMAGE_TAG             ?= $(shell tr -d '[:space:]' < version.txt)
export IMAGE_NAME DOCKER_HUB_USER_NAME IMAGE_TAG

.PHONY: help build image push overview publish local clean

help:
	@echo "Targets:"
	@echo "  make build     构建前端 + Go 二进制 (build.sh)"
	@echo "  make image     多平台构建并推送镜像 (build-image.sh)"
	@echo "  make push      简易构建推送 (upload-image.sh)"
	@echo "  make overview  用 DOCKERHUB.md 更新 Docker Hub Overview"
	@echo "                 sh: ./update-overview.sh | Windows: ./update-overview.ps1"
	@echo "  make publish   image + overview（推镜像并同步 Hub 文档）"
	@echo "  make local     仅本地构建镜像，不推送"
	@echo "  make clean     清理构建产物"
	@echo ""
	@echo "Current: IMAGE_NAME=$(IMAGE_NAME) DOCKER_HUB_USER_NAME=$(DOCKER_HUB_USER_NAME) IMAGE_TAG=$(IMAGE_TAG)"

build:
	./build.sh

image:
	./build-image.sh

push:
	./upload-image.sh

overview:
	./update-overview.sh

# 推镜像成功后再刷新 Overview
publish: image overview
	@echo "完成：镜像已推送，Overview 已同步 DOCKERHUB.md"

local:
	SKIP_PUSH=1 ./build-image.sh

clean:
	rm -f nav
	rm -rf public

<#
Windows PowerShell 多平台镜像构建推送脚本
支持 linux/amd64 + linux/arm64 双架构，一键构建推送DockerHub
#>
# ====================== 配置区域 ======================

# 设置代理
$env:HTTP_PROXY="http://127.0.0.1:7890"
$env:HTTPS_PROXY="http://127.0.0.1:7890"
$env:ALL_PROXY="socks5://127.0.0.1:7890"

$IMAGE_NAME = "van-nav"
$IMAGE_TAG = "0.0.3"
$DOCKER_HUB_USER_NAME = "dengdg"
$PLATFORMS = "linux/amd64,linux/arm64"
$PLATFORMS_ARM64 = "linux/arm64"
$PLATFORMS_AMD64 = "linux/amd64"
# ======================================================
$FULL_VERSION_TAG = "${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"
$FULL_LATEST_TAG = "${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:latest"

$TAG_AMD64 = "${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:${IMAGE_TAG}-amd64"
$TAG_ARM64 = "${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:${IMAGE_TAG}-arm64"
$TAG_LATEST = "${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:latest"

Write-Host "==================== 多平台镜像构建开始 ====================" -ForegroundColor Cyan
Write-Host "镜像名称: $FULL_VERSION_TAG"
Write-Host "目标架构: $PLATFORMS"
Write-Host "==========================================================" -ForegroundColor Cyan

# 登录DockerHub
Write-Host "`n[步骤1] 登录DockerHub" -ForegroundColor Yellow
docker login

# 初始化buildx构建器
Write-Host "`n[步骤2] 初始化多架构构建器buildx" -ForegroundColor Yellow
$builderCheck = docker buildx ls | Select-String "mybuilder"
if (-not $builderCheck) {
    Write-Host "不存在 mybuilder“
    docker buildx create --name mybuilder --use --bootstrap
}
docker buildx use mybuilder

# 多平台构建并直接推送
Write-Host "`n[步骤3] 多架构构建并推送镜像至DockerHub" -ForegroundColor Yellow
#    --pull=false `
#    --push `
#    --load `

docker buildx build `
    --platform $PLATFORMS `
    -t $FULL_VERSION_TAG `
    -t $FULL_LATEST_TAG `
    --progress=plain `
    --push `
    .
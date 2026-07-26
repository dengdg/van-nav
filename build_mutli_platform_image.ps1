<#
Windows PowerShell 多平台镜像构建推送脚本
支持 linux/amd64 + linux/arm64 双架构，一键构建推送DockerHub
#>
# ====================== 配置区域 ======================
$IMAGE_NAME = "van-nav"
$IMAGE_TAG = "0.0.2"
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

#docker buildx build `
#    --platform $PLATFORMS `
#    -t $FULL_VERSION_TAG `
#    -t $FULL_LATEST_TAG `
#    --progress=plain `
#    --push `
#    .

# 执行结果校验
#if ($LASTEXITCODE -eq 0) {
#    Write-Host "`n✅ 构建&推送完成！版本镜像：$FULL_VERSION_TAG" -ForegroundColor Green
#    Write-Host "✅ 同步latest标签：$FULL_LATEST_TAG" -ForegroundColor Green
#}
#else {
#    Write-Host "`n❌ 构建或推送失败，请检查日志！" -ForegroundColor Red
#    exit 1
#}


Write-Host "===== 构建 linux/amd64 本地镜像 =====" -ForegroundColor Cyan
docker buildx build `
    --platform linux/amd64 `
    -t $TAG_AMD64 `
    --progress=plain `
    --load `
    .

Write-Host "`n===== 构建 linux/arm64 本地镜像 =====" -ForegroundColor Cyan
docker buildx build `
    --platform linux/arm64 `
    -t $TAG_ARM64 `
    --progress=plain `
    --load `
    .


Write-Host "`n✅ 双架构镜像已保存到本地docker images" -ForegroundColor Green
Write-Host "===== 手动推送命令（复制执行） ====="
Write-Host "docker login"
Write-Host "docker push $TAG_AMD64"

docker push $TAG_AMD64

Write-Host "docker push $TAG_ARM64"
docker push $TAG_ARM64

Write-Host "# 合并多架构清单（必须推送两个单架构后执行）"
Write-Host "docker buildx imagetools create -t $FULL_VERSION_TAG $TAG_AMD64 $TAG_ARM64"
docker buildx imagetools create -t $FULL_VERSION_TAG $TAG_AMD64 $TAG_ARM64

Write-Host "docker buildx imagetools create -t $TAG_LATEST $TAG_AMD64 $TAG_ARM64"
docker buildx imagetools create -t $FULL_LATEST_TAG $TAG_AMD64 $TAG_ARM64

Write-Host "docker push $FULL_VERSION_TAG"
docker push $FULL_VERSION_TAG

Write-Host "docker push $FULL_LATEST_TAG"
docker push $FULL_LATEST_TAG

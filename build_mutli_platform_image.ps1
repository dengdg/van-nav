<#
Windows PowerShell 多平台镜像构建推送脚本
支持 linux/amd64 + linux/arm64 双架构，一键构建推送DockerHub
#>
# ====================== 配置区域 ======================
$IMAGE_NAME = "van-nav"
$DOCKER_HUB_USER_NAME = "dengdg"
$PLATFORMS = "linux/amd64,linux/arm64"
# ======================================================

# 版本号取自 version.txt（可用环境变量 IMAGE_TAG 覆盖）
if (-not $env:IMAGE_TAG) {
    $versionFile = Join-Path $PSScriptRoot "version.txt"
    if (-not (Test-Path $versionFile)) {
        Write-Host "❌ 未找到 version.txt：$versionFile" -ForegroundColor Red
        exit 1
    }
    $env:IMAGE_TAG = (Get-Content $versionFile -Raw).Trim()
}
$IMAGE_TAG = $env:IMAGE_TAG
if (-not $IMAGE_TAG) {
    Write-Host "❌ version.txt 中的版本号为空" -ForegroundColor Red
    exit 1
}

$FULL_VERSION_TAG = "${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"
$FULL_LATEST_TAG = "${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:latest"

Write-Host "==================== 多平台镜像构建开始 ====================" -ForegroundColor Cyan
Write-Host "镜像名称: $FULL_VERSION_TAG"
Write-Host "目标架构: $PLATFORMS"
Write-Host "==========================================================" -ForegroundColor Cyan

# 登录DockerHub
Write-Host "`n[步骤1] 登录DockerHub" -ForegroundColor Yellow
docker login
if ($LASTEXITCODE -ne 0) { Write-Host "❌ DockerHub 登录失败" -ForegroundColor Red; exit 1 }

# 初始化buildx构建器
Write-Host "`n[步骤2] 初始化多架构构建器buildx" -ForegroundColor Yellow
$builderCheck = docker buildx ls | Select-String "mybuilder"
if (-not $builderCheck) {
    Write-Host "不存在 mybuilder"
    docker buildx create --name mybuilder --use --bootstrap
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ 创建 buildx 构建器失败" -ForegroundColor Red; exit 1 }
}
docker buildx use mybuilder
if ($LASTEXITCODE -ne 0) { Write-Host "❌ 切换 buildx 构建器失败" -ForegroundColor Red; exit 1 }

# 多平台构建并直接推送（--push 是唯一正确出多架构 manifest 的方式；--load 仅支持单架构）
Write-Host "`n[步骤3] 多架构构建并推送镜像至DockerHub" -ForegroundColor Yellow
docker buildx build `
    --builder mybuilder `
    --platform $PLATFORMS `
    -t $FULL_VERSION_TAG `
    -t $FULL_LATEST_TAG `
    --progress=plain `
    --push `
    .
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ 构建或推送失败，请检查日志！" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ 构建&推送完成！" -ForegroundColor Green
Write-Host "  版本镜像: $FULL_VERSION_TAG"
Write-Host "  latest:   $FULL_LATEST_TAG"

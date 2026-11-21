# 更新 Docker Hub 仓库 Overview（读取 DOCKERHUB.md，PATCH Hub API）
# 认证：先 POST /v2/auth/token 用用户名+PAT 换短期 bearer，再 PATCH 仓库描述
# 用法示例:
#   $env:DOCKERHUB_TOKEN = "xxx"          # Personal Access Token
#   $env:DOCKERHUB_USERNAME = "dengdg"    # 登录用户名（默认取 DOCKER_HUB_USER_NAME）
#   .\update-overview.ps1
#   .\update-overview.ps1 -DockerHubUserName mereith -ImageName van-nav
# 可选环境变量: IMAGE_NAME, DOCKER_HUB_USER_NAME, DOCKERHUB_USERNAME, README_FILE, SHORT_DESCRIPTION, DOCKERHUB_TOKEN

param(
    [string]$ImageName = $(if ($env:IMAGE_NAME) { $env:IMAGE_NAME } else { "van-nav" }),
    [string]$DockerHubUserName = $(if ($env:DOCKER_HUB_USER_NAME) { $env:DOCKER_HUB_USER_NAME } else { "dengdg" }),
    [string]$UserName = "",
    [string]$ReadmeFile = $(if ($env:README_FILE) { $env:README_FILE } else { "DOCKERHUB.md" }),
    [string]$ShortDescription = $(if ($env:SHORT_DESCRIPTION) { $env:SHORT_DESCRIPTION } else { "" }),
    [string]$Token = $(if ($env:DOCKERHUB_TOKEN) { $env:DOCKERHUB_TOKEN } else { "" })
)

$ErrorActionPreference = "Stop"

# 始终在脚本所在目录执行
Set-Location -Path $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($UserName)) {
    if ($env:DOCKERHUB_USERNAME) {
        $UserName = $env:DOCKERHUB_USERNAME
    }
    else {
        $UserName = $DockerHubUserName
    }
}

$RepoPath = "$DockerHubUserName/$ImageName"
$ApiUrl = "https://hub.docker.com/v2/repositories/$RepoPath/"
$AuthUrl = "https://hub.docker.com/v2/auth/token"

if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Host "错误：未设置 DOCKERHUB_TOKEN" -ForegroundColor Red
    Write-Host "请在 Docker Hub -> Account Settings -> Personal access tokens 创建（Read & Write），" -ForegroundColor Red
    Write-Host "然后设置 `$env:DOCKERHUB_TOKEN = 'xxx' 再执行本脚本。" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $ReadmeFile)) {
    Write-Host "错误：找不到 README 文件: $ReadmeFile" -ForegroundColor Red
    exit 1
}

# 自动提取短描述：跳过标题/空行/HTML/图片/引用/代码块，取第一段正文
if ([string]::IsNullOrWhiteSpace($ShortDescription)) {
    $lines = Get-Content -Path $ReadmeFile -Encoding UTF8
    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t -eq "") { continue }
        if ($t.StartsWith("#")) { continue }
        if ($t.StartsWith("<")) { continue }
        if ($t.StartsWith("!")) { continue }
        if ($t.StartsWith(">")) { continue }
        if ($t.StartsWith('```')) { continue }
        if ($t -eq "---") { continue }
        $ShortDescription = $t
        break
    }
}

# Docker Hub 短描述上限为 100 **字节**（UTF-8），中文约 3 字节/字；在字符边界截断
$utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($ShortDescription)
if ($utf8Bytes.Length -gt 100) {
    $n = 100
    while ($n -gt 0 -and (($utf8Bytes[$n] -band 0xC0) -eq 0x80)) {
        $n--
    }
    $ShortDescription = [System.Text.Encoding]::UTF8.GetString($utf8Bytes, 0, $n)
}

$fullDescription = Get-Content -Path $ReadmeFile -Raw -Encoding UTF8

Write-Host "==================== 更新 Docker Hub Overview ===================="
Write-Host "仓库:     $RepoPath"
Write-Host "文档:     $ReadmeFile"
Write-Host "短描述:   $ShortDescription"
Write-Host "================================================================"

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# 1) 用户名 + PAT -> 短期 bearer（PAT 不能直接当 Bearer）
Write-Host "获取 access token..."
$authBodyObj = [ordered]@{
    identifier = $UserName
    secret     = $Token
}
$authJson = $authBodyObj | ConvertTo-Json -Depth 2
$authBytes = $utf8NoBom.GetBytes($authJson)

try {
    $authResp = Invoke-WebRequest `
        -Uri $AuthUrl `
        -Method Post `
        -Headers @{
            "Accept" = "application/json"
        } `
        -ContentType "application/json; charset=utf-8" `
        -Body $authBytes `
        -UseBasicParsing
}
catch {
    $statusCode = 0
    $respBody = $null
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $respBody = $reader.ReadToEnd()
        }
        catch { }
    }
    Write-Host "失败：获取 access token HTTP $statusCode" -ForegroundColor Red
    if ($respBody) { Write-Host $respBody }
    exit 1
}

$authData = $authResp.Content | ConvertFrom-Json
$accessToken = $authData.access_token
if ([string]::IsNullOrWhiteSpace($accessToken)) {
    Write-Host "失败：响应中没有 access_token" -ForegroundColor Red
    Write-Host $authResp.Content
    exit 1
}

# 2) 用 access token 更新仓库描述
$bodyObj = [ordered]@{
    description      = $ShortDescription
    full_description = $fullDescription
}
$json = $bodyObj | ConvertTo-Json -Depth 2
$bytes = $utf8NoBom.GetBytes($json)

try {
    $resp = Invoke-WebRequest `
        -Uri $ApiUrl `
        -Method Patch `
        -Headers @{
            "Authorization" = "Bearer $accessToken"
            "Accept"        = "application/json"
        } `
        -ContentType "application/json; charset=utf-8" `
        -Body $bytes `
        -UseBasicParsing
    $statusCode = [int]$resp.StatusCode
}
catch {
    $statusCode = 0
    $respBody = $null
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $respBody = $reader.ReadToEnd()
        }
        catch { }
    }
    if ($statusCode -in 200, 202) {
        Write-Host "成功：Docker Hub Overview 已更新（HTTP $statusCode）"
        Write-Host "页面地址: https://hub.docker.com/r/$RepoPath"
        exit 0
    }
    Write-Host "失败：HTTP $statusCode" -ForegroundColor Red
    if ($respBody) { Write-Host $respBody }
    exit 1
}

if ($statusCode -in 200, 202) {
    Write-Host "成功：Docker Hub Overview 已更新（HTTP $statusCode）"
    Write-Host "页面地址: https://hub.docker.com/r/$RepoPath"
}
else {
    Write-Host "失败：HTTP $statusCode" -ForegroundColor Red
    if ($resp.Content) { Write-Host $resp.Content }
    exit 1
}

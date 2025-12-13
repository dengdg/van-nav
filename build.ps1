# 输出提示信息：清空原有数据
Write-Host "清空原有数据"

# 删除 public 目录（-Recurse 递归删除，-Force 强制删除，忽略不存在的目录）
if (Test-Path ./public)
{
    Remove-Item -Recurse -Force ./public
}

# 创建 public/admin 目录（-Force 确保父目录也被创建）
New-Item -ItemType Directory -Force -Path public/admin | Out-Null

# 输出提示信息：构建用户页面
Write-Host "构建用户页面"

# 进入 ui/website 目录执行 yarn build，然后返回上级目录
Set-Location -Path ui/website
pnpm build-win
Set-Location -Path ../../

# 复制 ui/website/build 下的所有文件到 public 目录
Copy-Item -Recurse -Force ui/website/build/* public/

# 输出提示信息：构建管理页面
Write-Host "构建管理页面"

# 进入 ui/admin 目录执行 yarn build，然后返回上级目录
Set-Location -Path ui/admin
pnpm build
Set-Location -Path ../../

# 复制 ui/admin/dist 下的所有文件到 public/admin 目录
Copy-Item -Recurse -Force ui/admin/dist/* public/admin/

# 替换 public/admin/index.html 中的 /assets 为 /admin/assets
# 兼容 PowerShell Core (Linux/macOS) 和 Windows PowerShell
$indexHtmlPath = "public/admin/index.html"
if ($IsCoreCLR)
{
    # PowerShell Core (跨平台) 使用 -Raw 读取整个文件，-Replace 替换
    (Get-Content -Raw -Path $indexHtmlPath) -replace '\/assets', '/admin/assets' | Set-Content -Path $indexHtmlPath -NoNewline
}
else
{
    # Windows PowerShell 处理编码问题（避免中文乱码）
    (Get-Content -Raw -Path $indexHtmlPath -Encoding UTF8) -replace '\/assets', '/admin/assets' | Set-Content -Path $indexHtmlPath -Encoding UTF8 -NoNewline
}

# 输出提示信息：构建前端数据完成
Write-Host "构建前端数据完成"

# 编译 Go 项目
go build .
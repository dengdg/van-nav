#!/usr/bin/env sh
set -e

# 始终在仓库根目录执行（脚本所在目录）
cd "$(dirname "$0")"

echo "清空原有数据"
rm -rf ./public
mkdir -p public/admin

# 选择包管理器：优先 yarn / pnpm，否则回退 npm
if command -v yarn >/dev/null 2>&1; then
  PM="yarn"
elif command -v pnpm >/dev/null 2>&1; then
  PM="pnpm"
elif command -v npm >/dev/null 2>&1; then
  PM="npm"
else
  echo "错误：未找到 yarn/pnpm/npm，请先安装 Node.js" >&2
  exit 1
fi
echo "使用包管理器: $PM"

# 在指定目录安装依赖并构建（子 shell，避免 cd 影响外层）
build_ui() {
  dir="$1"
  (
    cd "$dir"
    echo "安装依赖 ($PM) in $dir"
    "$PM" install
    echo "构建 $dir"
    "$PM" run build
  )
}

echo "构建用户页面"
build_ui ui/website
cp -r ui/website/build/* public/

echo "构建管理页面"
build_ui ui/admin
cp -r ui/admin/dist/* public/admin/

# 兼容 macOS(BSD) 与 Linux(GNU) 的原地替换
# 先写 .bak 再删除，两边 sed -i 行为一致
sed -i.bak 's/\/assets/\/admin\/assets/g' public/admin/index.html
rm -f public/admin/index.html.bak

echo "构建前端数据完成"

go build .

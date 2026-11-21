#!/usr/bin/env sh
set -e

cd "$(dirname "$0")"

# ====================== 配置区域 ======================
IMAGE_NAME="${IMAGE_NAME:-van-nav}"
DOCKER_HUB_USER_NAME="${DOCKER_HUB_USER_NAME:-dengdg}"
# 登录用户名（一般与 namespace 相同；组织下可不同）
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-$DOCKER_HUB_USER_NAME}"
# Docker Hub Overview 专用文档（相对仓库根目录）
README_FILE="${README_FILE:-DOCKERHUB.md}"
# 短描述（列表页一行）；留空则自动从文档首个正文段落截取
SHORT_DESCRIPTION="${SHORT_DESCRIPTION:-}"
# ======================================================

REPO_PATH="${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}"
API_URL="https://hub.docker.com/v2/repositories/${REPO_PATH}/"
AUTH_URL="https://hub.docker.com/v2/auth/token"

if [ -z "${DOCKERHUB_TOKEN:-}" ]; then
  echo "错误：未设置 DOCKERHUB_TOKEN" >&2
  echo "请在 Docker Hub → Account Settings → Personal access tokens 创建（Read & Write），" >&2
  echo "然后： export DOCKERHUB_TOKEN=xxx  再执行本脚本。" >&2
  exit 1
fi

if [ ! -f "$README_FILE" ]; then
  echo "错误：找不到 README 文件: $README_FILE" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "错误：未找到 jq，请先安装（macOS: brew install jq）" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "错误：未找到 curl" >&2
  exit 1
fi

# 自动提取短描述：跳过标题/空行/HTML/图片/引用/代码块，取第一段正文（再按 100 字节截断）
if [ -z "$SHORT_DESCRIPTION" ]; then
  SHORT_DESCRIPTION=$(
    awk '
      /^[[:space:]]*$/ { next }
      /^#/ { next }
      /^</ { next }
      /^!/ { next }
      /^>/ { next }
      /^```/ { next }
      /^---/ { next }
      { print; exit }
    ' "$README_FILE"
  )
fi

# Docker Hub 短描述上限为 100 **字节**（UTF-8），中文约 3 字节/字
truncate_utf8() {
  printf '%s' "$1" | python3 -c '
import sys
data = sys.stdin.buffer.read()
n = int(sys.argv[1])
if len(data) > n:
    while n > 0 and (data[n] & 0xC0) == 0x80:
        n -= 1
    data = data[:n]
sys.stdout.buffer.write(data)
' "$2"
}
if command -v python3 >/dev/null 2>&1; then
  SHORT_DESCRIPTION=$(truncate_utf8 "$SHORT_DESCRIPTION" 100)
else
  # 无 python3 时粗截（可能仍略超，仅兜底）
  SHORT_DESCRIPTION=$(printf '%s' "$SHORT_DESCRIPTION" | cut -c1-30)
fi

echo "==================== 更新 Docker Hub Overview ===================="
echo "仓库:     $REPO_PATH"
echo "文档:     $README_FILE"
echo "短描述:   $SHORT_DESCRIPTION"
echo "================================================================"

# 1) 用用户名 + PAT 换取短期 bearer（PAT 不能直接当 Authorization: Bearer）
echo "获取 access token..."
AUTH_BODY=$(jq -n \
  --arg id "$DOCKERHUB_USERNAME" \
  --arg secret "$DOCKERHUB_TOKEN" \
  '{identifier: $id, secret: $secret}')

AUTH_RESP=$(mktemp)
BODY_FILE=$(mktemp)
RESP_FILE=$(mktemp)
trap 'rm -f "$AUTH_RESP" "$BODY_FILE" "$RESP_FILE"' EXIT

AUTH_HTTP=$(curl -sS -o "$AUTH_RESP" -w '%{http_code}' \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  --data-binary "$AUTH_BODY" \
  "$AUTH_URL")

if [ "$AUTH_HTTP" != "200" ]; then
  echo "失败：获取 access token HTTP $AUTH_HTTP" >&2
  cat "$AUTH_RESP" >&2
  echo >&2
  exit 1
fi

ACCESS_TOKEN=$(jq -r '.access_token // empty' "$AUTH_RESP")
if [ -z "$ACCESS_TOKEN" ]; then
  echo "失败：响应中没有 access_token" >&2
  cat "$AUTH_RESP" >&2
  exit 1
fi

# 2) 用 access token 更新仓库描述
jq -n \
  --rawfile md "$README_FILE" \
  --arg short "$SHORT_DESCRIPTION" \
  '{full_description: $md, description: $short}' >"$BODY_FILE"

HTTP_CODE=$(curl -sS -o "$RESP_FILE" -w '%{http_code}' \
  -X PATCH \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-binary @"$BODY_FILE" \
  "$API_URL")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
  echo "成功：Docker Hub Overview 已更新（HTTP $HTTP_CODE）"
  echo "页面地址: https://hub.docker.com/r/${REPO_PATH}"
else
  echo "失败：HTTP $HTTP_CODE" >&2
  cat "$RESP_FILE" >&2
  echo >&2
  exit 1
fi

# 输出提示信息：清空原有数据

# 镜像名
$IMAGE_NAME = "van-nav"

# 镜像Tage
$IMEGE_TAG = "0.0.1"

# DockerHub用户名
$DOCKER_HUB_USER_NAME = "dengdg"

# 本地镜像名和Tag
$LOCAL_IMATE_AND_TAG = "${IMAGE_NAME}:${IMEGE_TAG}"

# Push到仓库中的镜像名和Tag
$PUSH_IMAGE_AND_TAG = "${DOCKER_HUB_USER_NAME}/${IMAGE_NAME}:${IMEGE_TAG}"

Write-Host "构建镜像"
docker build -t $LOCAL_IMATE_AND_TAG .

Write-Host "登录"
docker login

## 构建镜像包
Write-Host "构建上传镜像包"
## 格式：docker tag 原镜像名/镜像ID DockerHub用户名/新镜像名:标签
docker tag $LOCAL_IMATE_AND_TAG $PUSH_IMAGE_AND_TAG

Write-Host "上传镜像"
# 上传镜像
docker push $PUSH_IMAGE_AND_TAG
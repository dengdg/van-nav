
docker buildx rm mybuilder

#docker buildx create `
#    --name mybuilder `
#    --use `
#    --bootstrap `
#    --driver docker-container `
#    --config ./buildkitd.toml `
#    --driver-opt network=host


# 这种方式不行
#docker buildx create `
#    --name mybuilder `
#    --use `
#    --bootstrap `
#    --driver docker-container `
#    --driver-opt network=host


docker buildx create `
    --name mybuilder `
    --use `
    --bootstrap `
    --driver docker-container `
    --config ./buildkitd.toml `
    --driver-opt "env.HTTP_PROXY=http://host.docker.internal:7890" `
    --driver-opt "env.HTTPS_PROXY=http://host.docker.internal:7890" `



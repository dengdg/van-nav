FROM --platform=$BUILDPLATFORM node:18-alpine AS fe-builder
WORKDIR /app

# 国内网络加速
RUN npm config set registry https://registry.npmmirror.com

# 固定 pnpm 9.x：pnpm 10+ 默认拦截 esbuild 等依赖的 build 脚本，会导致 vite 构建失败
RUN npm install -g pnpm@9

COPY . .

RUN cd /app && cd ui/admin && pnpm install && pnpm build && cd ../..
RUN cd ui/website && pnpm install && pnpm build && cd ../..
RUN cd /app && mkdir -p public/admin
RUN cp -r ui/website/build/* public/
RUN cp -r ui/admin/dist/* public/admin/
RUN sed -i 's/\/assets/\/admin\/assets/g' public/admin/index.html


FROM --platform=$BUILDPLATFORM golang:alpine AS binary-builder
ARG TARGETOS
ARG TARGETARCH
ENV GOPROXY=https://goproxy.cn,direct \
    GOSUMDB=off
RUN apk --no-cache --no-progress add git
WORKDIR /app
COPY . .
COPY --from=fe-builder /app/public /app/public
RUN cd /app && ls -la && go mod tidy && GOOS=$TARGETOS GOARCH=$TARGETARCH go build .


FROM alpine:latest
ENV TZ="Asia/Shanghai"
RUN apk --no-cache --no-progress add \
    ca-certificates \
    tzdata && \
    cp "/usr/share/zoneinfo/$TZ" /etc/localtime && \
    echo "Asia/Shanghai" >  /etc/timezone
WORKDIR /app
COPY --from=binary-builder /app/nav /app/

VOLUME ["/app/data"]
EXPOSE 6412
ENTRYPOINT [ "/app/nav" ]

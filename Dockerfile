FROM node:18-alpine AS fe-builder
WORKDIR /app
# RUN apk add --no-cache g++ gcc make python3
COPY . .

RUN npm install -g pnpm
RUN cd /app && cd ui/admin && pnpm install && pnpm build && cd ../..
#RUN cd /app && cd ui/admin && yarn install && yarn build && cd ../..
RUN cd ui/website && pnpm install && pnpm build && cd ../..
#RUN #cd ui/website && yarn install && yarn build && cd ../..
RUN cd /app && mkdir -p public/admin
RUN cp -r ui/website/build/* public/
RUN cp -r ui/admin/dist/* public/admin/
RUN sed -i 's/\/assets/\/admin\/assets/g' public/admin/index.html


FROM golang:alpine AS binary-builder
RUN apk --no-cache --no-progress add  git
WORKDIR /app
COPY . .
COPY --from=fe-builder /app/public /app/public
RUN cd /app && ls -la && go mod tidy && go build .



FROM alpine:latest
ENV TZ="Asia/Shanghai"
RUN apk --no-cache --no-progress add \
    ca-certificates \
    tzdata && \
    cp "/usr/share/zoneinfo/$TZ" /etc/localtime && \
    echo "$TZ" >  /etc/timezone
WORKDIR /app
COPY --from=binary-builder /app/nav /app/

VOLUME ["/app/data"]
EXPOSE 6412
ENTRYPOINT [ "/app/nav" ]

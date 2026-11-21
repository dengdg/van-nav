# Van Nav

轻量导航站 / 起始页，支持搜索引擎集成、拼音模糊搜索、暗色主题与浏览器插件，适合作为浏览器主页。

感谢作者：[mereithhh/van-nav](https://github.com/mereithhh/van-nav)

## 本镜像改动

相对上游主要改动如下（当前仅此一项）：

- **去掉自动获取网站图标**：部分内网 / 隔离网络环境下无法访问外网图标源，自动抓取会失败或卡住；本镜像不再自动拉取 favicon，图标请自行配置或使用默认样式。

其余功能与上游保持一致。

## 功能

- 搜索引擎集成，可直接当主页用
- 拼音模糊搜索；回车打开第一个结果
- 暗色 / 亮色 / 跟随系统主题
- 自动抓取站点标题与描述（图标改为不自动获取，见上方「本镜像改动」）
- 导入导出、自定义跳转方式
- 支持登录后可见的隐藏卡片
- PWA：可安装、离线可用
- 配套浏览器插件与 API

## Docker CLI

```bash
docker pull dengdg/van-nav:latest

docker run -d \
  --name van-nav \
  --restart always \
  -p 6412:6412 \
  -v /path/to/your/data:/app/data \
  dengdg/van-nav:latest
```

浏览器打开 [http://localhost:6412](http://localhost:6412)。

- 默认端口：`6412`
- 默认账号密码：`admin` / `admin`（首次登录后请修改）
- 数据目录：容器内 `/app/data`（数据库 `nav.db`）

## docker-compose

```yaml
services:
  van-nav:
    image: dengdg/van-nav:latest
    container_name: van-nav
    restart: always
    ports:
      - "6412:6412"
    volumes:
      - ./data:/app/data
```

```bash
docker compose up -d
```

## 链接

- 在线体验（上游 demo）：[demo](https://demo-tools.mereith.com)（账号密码均为 `admin`）
- 原作者 GitHub：https://github.com/mereithhh/van-nav

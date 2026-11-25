# Docker 部署

项目提供前端镜像构建模板，后端可按需自写 Dockerfile（基于 `php:8.2-fpm`/CLI 镜像运行 Webman）。

## 后台前端（admin）镜像

仓库内置 `template/admin/build/deploy/Dockerfile`（多阶段，Node 22 构建 + Nginx 托管）：

```dockerfile
FROM node:22-slim AS builder
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV NODE_OPTIONS=--max-old-space-size=8192
RUN npm i -g corepack
WORKDIR /app
COPY . /app
RUN pnpm install --frozen-lockfile
RUN pnpm run build

FROM nginx:stable-alpine AS production
RUN echo "types { application/javascript js mjs; }" > /etc/nginx/conf.d/mjs.conf \
    && rm -rf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/build/deploy/nginx.conf /etc/nginx/nginx.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

构建运行：

```bash
cd template/admin
docker build -t madong-admin -f build/deploy/Dockerfile .
docker run -d -p 8080:8080 madong-admin
```

## 前台前端（web）镜像

仓库内置 `template/web/Dockerfile`（Nuxt 构建，默认 SSR 输出）：

```dockerfile
FROM node:20-alpine as build-stage
WORKDIR /app
RUN corepack enable
COPY .npmrc package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-alpine as production-stage
WORKDIR /app
COPY --from=build-stage /app/.output ./.output
EXPOSE 3000
CMD ["node", ".output/server/index.mjs"]
```

> 当前 `nuxt.config.ts` 配置 `ssr: false`，如需纯静态可改为拷贝 `.output/public` 给 Nginx；若开启 SSR，则用上述 Node 运行命令。

## 后端镜像（示例）

仓库未内置后端 Dockerfile，可参考以下最小实现：

```dockerfile
FROM php:8.2-cli
RUN apt-get update && apt-get install -y \
    libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pcntl posix pdo_mysql mbstring \
    && pecl install redis && docker-php-ext-enable redis
WORKDIR /app
COPY backend /app
RUN composer install --no-dev --optimize-autoloader
EXPOSE 8500
CMD ["php", "webman", "start"]
```

## 编排建议

- 用 `docker-compose.yml` 组合：`webman`（后端）、`admin`（Nginx 静态）、`web`（Nuxt/静态）、`mysql`、`redis`。
- 后端容器需 `depends_on` MySQL/Redis 健康后再 `php webman start`。
- 静态产物（admin/web/install）也可直接放到后端 `public/` 由 Webman 单容器托管，简化部署。

> 容器环境同样遵循「常驻内存改代码要重启」原则；CI 中把构建与重启分开，避免热更不一致。

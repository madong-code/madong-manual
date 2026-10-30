# Nginx 反代

Nginx 在 80/443 统一收口，把 API 反代到后端 Webman（8500），静态资源直接托管。以下为生产参考配置（基于 `template/admin/build/deploy/nginx.conf` 改造）。

```nginx
server {
    listen 80;
    server_name your.domain.com;

    # 后台静态站（也可由 Webman 直接服务 public/admin）
    location /admin/ {
        alias /var/www/mdadmin/template/admin/dist/;
        try_files $uri $uri/ /admin/index.html;
        index index.html;
    }

    # 前台静态站
    location / {
        alias /var/www/mdadmin/template/web/.output/public/;
        try_files $uri $uri/ /index.html;
    }

    # 后台接口
    location /adminapi/ {
        proxy_pass http://127.0.0.1:8500;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;       # SSE 流式必需，关闭 nginx 响应缓冲
        proxy_read_timeout 300s;   # AI 对话/导出可能耗时，与后端上游超时对齐
    }

    # 前台接口
    location /api/ {
        proxy_pass http://127.0.0.1:8500;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;       # SSE 流式必需，关闭 nginx 响应缓冲
        proxy_read_timeout 300s;   # 不设置时默认 60s，会掐断长回复
    }

    # 安装向导
    location /install/ {
        alias /var/www/mdadmin/template/install/dist/;
        try_files $uri $uri/ /install/index.html;
    }
}
```

要点：

- API 反代务必带 `X-Forwarded-*` 头，否则后端取到的客户端 IP / 协议不正确。
- `proxy_buffering off` 必须开启：AI 对话走 SSE 流式输出，nginx 默认缓冲会把整段回复攒齐才下发，前端表现为长时间白屏等待。后端虽已发送 `X-Accel-Buffering: no`，但显式关闭最稳妥。
- `proxy_read_timeout 300s` 调大，避免 SSE 进度流、AI 长回复、数据导出被提前断开（nginx 默认 60s）。
- 若 admin/web 直接放在 `backend/public/`，可去掉对应 `location` 静态块，由 Webman 托管。
- 生产建议开启 HTTPS（Let's Encrypt），并在 443 server 内做同样的反代。

## 静态站 MIME

Nuxt/Vben 产物含 `.mjs` 等模块脚本，Nginx 需识别：

```nginx
types {
    application/javascript js mjs;
}
```

官方 `nginx.conf` 已包含该配置，拷贝部署即可。

# Supervisor 进程守护

用 Supervisor 守护 Webman 与 Nuxt（SSR）进程，崩溃自动重启。参考仓库 `docs/guide/deploy/supervisor.md`。

## Webman 配置

```ini
[program:madong-webman]
command=php /path/to/backend/webman start
directory=/path/to/backend
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/madong/webman.log
```

> `webman start` 自身已多进程（worker count 默认 cpu*4），Supervisor 只需管 1 个主进程。

## Nuxt SSR 配置（仅在开启 SSR 时）

```ini
[program:madong-web]
command=node /path/to/template/web/.output/server/index.mjs
directory=/path/to/template/web
autostart=true
autorestart=true
user=www-data
environment=NODE_ENV="production"
stdout_logfile=/var/log/madong/web.log
```

## 常用命令

```bash
supervisorctl reread
supervisorctl update
supervisorctl start madong-webman
supervisorctl status
```

## 注意

- `madong-scheduler` 进程由 Webman 自身管理（`config/process.php` 中），**无需** Supervisor 单独配。
- 生产关闭 `monitor`（`config/process.php` 的 monitor 段，或用 `.env` 注释）。
- 日志轮转配 `logrotate`，避免磁盘写满。
- 修改业务代码后：`supervisorctl restart madong-webman`（常驻内存需重启生效）。

# 部署常见问题

**Q1：502 Bad Gateway？**
A：Nginx 反代的 8500 端口未监听（后端没启动或被重启）。`supervisorctl status madong-webman` 确认进程存在。

**Q2：SSE 进度中途断开？**
A：Nginx `proxy_read_timeout` 太小。调到 120s 以上（见[部署 - Nginx](deploy/nginx.md)）。

**Q3：静态资源 MIME 错误（.mjs 下载不执行）？**
A：Nginx 未识别 `application/javascript js mjs`。在 `types` 块加入该映射（仓库 `nginx.conf` 已含）。

**Q4：改完代码线上没变？**
A：常驻内存，需 `supervisorctl restart madong-webman`（或 `php start.php restart`）。CI 中构建与重启分开。

**Q5：上传/导出大文件超时？**
A：调大 `proxy_read_timeout` 与 PHP `max_execution_time`；导出走 SSE 时确保不被代理断开。

**Q6：计划任务没执行？**
A：`madong-scheduler` 由 Webman 在 `process.php` 中管理（监听 2001），无需 Supervisor 单独配；确认 `start.php` 启动包含了该进程。

**Q7：Redis 连接失败？**
A：`.env` 的 `REDIS_*` 三个连接组与 `config/redis.php` 对应；改后重启。确保 Redis 服务可达且密码正确。

**Q8：Docker 构建慢 / 失败？**
A：使用锁文件 `--frozen-lockfile`；admin 构建设 `NODE_OPTIONS` 加大内存上限；注意 `pnpm` 需 corepack 启用。

# 概述与快速开始

## 概述

Madong 极速后台开发框架的后端是一个**常驻内存**的 Webman 应用。与传统 PHP-FPM「每次请求重新加载全部代码」不同，Webman 启动后将所有类加载进内存并常驻，由多进程（Worker）复用，因此：

- 性能高：无重复 autoload / 框架引导开销。
- 有状态：单例、静态变量、连接池会在进程生命周期内保持。
- 改代码需重启：修改业务代码后必须重启服务才能生效（开发期可开 `monitor` 自动重载）。

## 环境要求

| 项目 | 版本 |
| --- | --- |
| PHP | >= 8.2 |
| 扩展 | `pcntl`、`posix`、`redis`、`pdo_mysql`、`mbstring`、`openssl` 等 |
| 数据库 | MySQL 5.7+ / 8.0 |
| 缓存 | Redis（默认 3 个连接组） |
| Composer | >= 2.0 |

## 启动服务

Windows：

```bash
cd backend
php windows.php
```

Linux / macOS：

```bash
cd backend
php start.php start          # 调试模式（单进程，便于看报错）
php start.php start -d       # 守护进程模式
php start.php stop           # 停止
php start.php restart        # 重启（改代码后执行）
```

启动后：

- 后台 HTTP 服务监听 `http://0.0.0.0:8500`。
- 计划任务（madong-scheduler）监听 `127.0.0.1:2001`。
- 访问后台接口：`http://localhost:8500/adminapi/...`
- 访问接口文档：`http://localhost:8500/adminapi/openapi`

## 第一个请求

打开 `http://localhost:8500/adminapi/openapi` 即可看到基于注解自动生成的 Swagger 文档。所有后台接口都在 `app/adminapi/controller` 下以注解方式声明。

## 常见问题

- **改了代码没生效？** 执行 `php start.php restart`（或确认 `monitor` 进程已开启自动重载）。
- **端口被占用？** 修改 `backend/config/process.php` 中的 `listen` 地址后重启。
- **静态资源 404？** 前端 `admin`/`web`/`install` 构建产物需放到 `backend/public/` 对应目录。

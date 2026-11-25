# 后端 · 安装与运行

---

## 1. 环境要求

- PHP ≥ 8.2，扩展：`pdo_mysql`、`redis`、`pcntl`、`posix`、`mbstring`、`openssl`、`ctype`、`json`、`tokenizer`
- Composer 2.x
- MySQL ≥ 8.0、Redis ≥ 7.0

---

## 2. 安装依赖

```bash
cd backend
composer install
cp .env.example .env          # 填写数据库 / Redis / JWT 等配置
```

> 依赖定义见 `composer.json`，**请勿手改 `vendor/`**。内核代码在 `core/`，业务在 `app/`。

---

## 3. 配置数据库与 Redis

编辑 `.env`：

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=madong
DB_USER=root
DB_PASSWORD=******
DB_PREFIX=mic_            # 表前缀

REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
```

---

## 4. 执行迁移与初始化

```bash
# 执行 Phinx 迁移建表
php phinx migrate

# 初始化字典 / 菜单 / 角色等基础数据（如有 seed）
php phinx seed:run
```

> 迁移文件位于 `app/migration/`（业务）与 `core/` 内置迁移；详见 [basic/migration.md](./migration.md)。

---

## 5. 启动

```bash
# 开发（调试模式）
php webman start

# 守护进程
php webman start -d

# 仅启动指定进程（见 config/process.php）
php webman start webman
php webman start monitor
php webman start madong-scheduler
```

`process.php` 定义了三个核心进程：
- `webman`：HTTP 服务
- `monitor`：文件变更监控（开发用，`.env` 中 `monitor` 段默认**被注释**以关闭，生产务必关闭）
- `madong-scheduler`：定时任务 + 队列消费

---

## 6. 验证

```bash
curl http://127.0.0.1:8500/adminapi/ping
```

或直接访问后端根路径，返回 JSON 即启动成功。

---

## 7. 常见启动失败

| 现象 | 原因 | 解决 |
| ---- | ---- | ---- |
| `Class not found` | 未 `composer dump-autoload` | 改了类/命名空间后执行 `composer dump-autoload` |
| 端口占用 | 8500 被占用 | 改 `config/server.php` 的 `listen` 或释放端口 |
| 连接 Redis 失败 | Redis 未启动 / 密码错 | 检查 `.env` 与 `config/redis.php` |
| 路由 404 | 控制器未加 Swagger 注解 / 路由未注册 | 见 [basic/route.md](./route.md) |

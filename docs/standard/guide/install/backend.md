# 2.3 后端安装

## 2.3.1 安装依赖

```bash
cd backend
composer install
```

国内网络建议先切换镜像：

```bash
composer config -g repos.packagist composer https://mirrors.aliyun.com/composer/
```

## 2.3.2 配置 `.env`

`backend/.env` 是后端唯一的环境入口文件，仓库内已提供一份可用的默认配置：

```ini
# 应用环境
APP_ENV=local
APP_DEBUG=false

# 数据库
DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=madong
DB_USERNAME=root
DB_PASSWORD=root
DB_PREFIX=md_

# 主 Redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# 队列 Redis
QUEUE_REDIS_HOST=redis://127.0.0.1:6379
QUEUE_REDIS_PORT=6379
QUEUE_REDIS_PASSWORD=
QUEUE_REDIS_DB=0
QUEUE_REDIS_PREFIX=queue

# 自定义缓存 Redis
CACHE_CUSTOM_REDIS_HOST=127.0.0.1
CACHE_CUSTOM_REDIS_PORT=6379
CACHE_CUSTOM_REDIS_PASSWORD=
CACHE_CUSTOM_REDIS_DB=0
CACHE_CUSTOM_REDIS_PREFIX=cache_custom

# 功能开关
APP_TASK_ENABLED=false      # 定时任务
CAPTCHA_ENABLED=false       # 登录验证码
CAPTCHA_MODE=session        # 验证码模式
RECYCLE_BIN_ENABLED=true    # 回收站
```

### 配置项说明

| 变量 | 说明 |
| --- | --- |
| `APP_ENV` | `local` / `production`，影响错误展示与部分默认行为 |
| `APP_DEBUG` | 生产环境务必设为 `false` |
| `DB_PREFIX` | 表前缀，安装后不可随意变更 |
| `QUEUE_REDIS_HOST` | 注意此项使用 **URI 形式**（`redis://host:port`） |
| `APP_TASK_ENABLED` | 是否启用定时任务进程 |
| `CAPTCHA_ENABLED` | 关闭后登录接口不校验图形验证码，便于本地联调 |
| `RECYCLE_BIN_ENABLED` | 删除数据是否进入回收站（软删除） |

> `.env` 属于本地配置，**不要提交到版本库**。

## 2.3.3 目录权限（Linux）

```bash
chmod -R 777 runtime public
```

`runtime/` 存放日志、缓存与编译产物；`public/` 存放上传文件，二者都需要可写。

## 2.3.4 启动服务

### Windows

```bash
php windows.php
```

窗口保持打开即为运行中，`Ctrl + C` 停止。

> Windows 缺少 `pcntl`/`posix`，**不支持** `start.php` 的守护模式。

### Linux / macOS

```bash
php start.php start        # 前台运行（调试用，日志直接输出）
php start.php start -d     # 守护进程方式运行
php start.php stop         # 停止
php start.php restart      # 重启
php start.php reload       # 平滑重载（不断开连接）
php start.php status       # 查看进程状态
php start.php connections  # 查看连接数
```

启动成功后监听：

```
http://0.0.0.0:8500
```

端口定义在 `backend/config/process.php`：

```php
'webman' => [
    'handler' => Http::class,
    'listen'  => 'http://0.0.0.0:8500',
    'count'   => 4,
    // ...
],
```

如需改端口，修改此处 `listen` 后重启，并同步调整前端代理目标。

## 2.3.5 进程构成

`config/process.php` 中默认编排三类进程：

| 进程 | 说明 |
| --- | --- |
| `webman` | HTTP 服务，进程数 `4` |
| `monitor` | 文件变更热重载 + 内存监控。监控 `app/`、`config/`、`core/`、`support/`、`resource/` 以及各插件的 `app`/`config`/`api` 目录 |
| `madong-scheduler` | 任务调度服务，监听 `127.0.0.1:2001`（`core.infrastructure.scheduler.listen`） |
| `redis-queue consumer` | 队列消费进程，由 `config/plugin/webman/redis-queue/process.php` 注册，默认 8 个进程，消费 `app/queue/redis` 下的任务 |

> `monitor` 的文件热重载仅在 **Linux/macOS 且非 `-d` 模式**下生效（源码中判断 `DIRECTORY_SEPARATOR === '/'`）。Windows 下 `php windows.php` 自带文件监控。

## 2.3.6 验证是否启动成功

```bash
curl http://127.0.0.1:8500
```

能返回响应（哪怕是 404 JSON）即说明服务已运行。若连接被拒绝，检查：

1. 端口 8500 是否被占用
2. `runtime/logs/` 下的 `stdout.log`、`workerman.log` 错误信息
3. `.env` 中数据库/Redis 是否可连通

## 2.3.7 命令行工具

```bash
php webman                 # 查看全部可用命令
php webman route:list      # 查看已注册路由
```

更多命令见 [4.1.2 快速开始](../backend/getting-started/quickstart.md)。

## 2.3.8 数据库初始化与安装

后端启动后**先不要**手动导入 SQL——建表、初始数据、管理员账号与 `install.lock` 统一由安装流程完成。

### 方式一：命令行安装（推荐）

```bash
cd backend

# 交互式安装
php webman install:madong

# 非交互：默认库名 madong、表前缀 ma_
php webman install:madong -y

# 参数化安装
php webman install:madong \
  --db-host=127.0.0.1 --db-port=3306 --db-name=madong \
  --db-user=root --db-pass=your-password --db-prefix=ma_ \
  --admin-username=admin --admin-password=your-password
```

常用选项：`--db-*`（数据库连接）、`--db-prefix`（默认 `ma_`）、`--admin-*`、`--install-database=1|0`（默认 1）、`--build-project=1|0`、`--skip-env-check`、`-y` 非交互。已生成 `install.lock` 时会拒绝重复安装。

### 方式二：在线安装向导

浏览器访问 `http://127.0.0.1:8500/install`，按页面提示完成，详见 [2.5 安装向导](wizard.md)。

### 方式三：数据库迁移（备选）

自研迁移命令 `madong-migrate` 用于表结构版本管理（配置见 `backend/phinx.php`）：

```bash
php webman madong-migrate status
php webman madong-migrate up
php webman madong-migrate up --seed
php webman madong-migrate rollback
```

> 迁移只处理表结构与种子数据，不会创建管理员账号和 `install.lock`，首次安装仍应使用方式一或方式二。
>
> 下一节：[2.4 前端安装](frontend.md)

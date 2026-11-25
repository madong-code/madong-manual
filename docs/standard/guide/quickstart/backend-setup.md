# 后端启动

本页介绍如何启动 Madong 后端服务（`backend/`）。完整安装说明以 [2.3 后端安装](../install/backend.md) 为准。

> 前置条件：已完成 [环境准备](./environment.md)。

---

## 一、安装依赖

```bash
cd backend
composer install
```

如果速度慢，先切换国内镜像：

```bash
composer config -g repos.packagist composer https://mirrors.aliyun.com/composer/
composer install
```

> 生产环境用 `composer install --no-dev --optimize-autoloader`。

---

## 二、配置环境变量

### 2.1 配置 `.env`

仓库中已提供 `backend/.env` 默认配置（仓库内**没有** `.example.env`），直接编辑其中的数据库与 Redis 配置即可。若文件遗失，可参考 [2.3 后端安装](../install/backend.md) 中的示例重建。

### 2.2 编辑 `.env`

```ini
# ── 应用环境 ──────────────────────────────
APP_ENV=local
APP_DEBUG=true            # 开发环境建议 true，生产必须 false

# ── 数据库 ────────────────────────────────
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=madong        # 需提前创建
DB_USERNAME=root
DB_PASSWORD=root
DB_PREFIX=md_             # 表前缀

# ── Redis（缓存/会话）─────────────────────
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=null       # 无密码填 null
REDIS_DB=0

# ── Redis（队列）──────────────────────────
QUEUE_REDIS_HOST=redis://127.0.0.1:6379
QUEUE_REDIS_PORT=6379
QUEUE_REDIS_PASSWORD=null
QUEUE_REDIS_DB=0
QUEUE_REDIS_PREFIX=queue

# ── Redis（自定义缓存）────────────────────
CACHE_CUSTOM_REDIS_HOST=127.0.0.1
CACHE_CUSTOM_REDIS_PORT=6379
CACHE_CUSTOM_REDIS_PASSWORD=null
CACHE_CUSTOM_REDIS_DB=0
CACHE_CUSTOM_REDIS_PREFIX=cache_custom

# ── 功能开关 ──────────────────────────────
APP_TASK_ENABLED=false    # 定时任务，开发环境建议关闭
CAPTCHA_ENABLED=false     # 图形验证码，开发环境建议关闭
CAPTCHA_MODE=session
RECYCLE_BIN_ENABLED=true  # 回收站
```

**配置要点**：

| 配置 | 开发环境 | 生产环境 |
| --- | --- | --- |
| `APP_DEBUG` | `true` | `false`（**必须**，否则泄露堆栈） |
| `CAPTCHA_ENABLED` | `false`（免验证码，方便调试） | `true` |
| `APP_TASK_ENABLED` | `false` | 按需 |
| `DB_PREFIX` | 安装后**不可更改** | 同左 |

> ⚠️ `.env` 含敏感信息，已在 `.gitignore` 中，**切勿提交**。

---

## 三、启动服务

### 3.1 Linux / macOS

```bash
cd backend

php start.php start        # 前台运行（开发，Ctrl+C 停止）
php start.php start -d     # 守护进程（生产）
```

### 3.2 Windows

Windows 不支持 `pcntl`/`posix`，需使用专用脚本：

```bash
cd backend

php windows.php
```

> Windows 下无守护模式与多进程，仅建议开发使用。生产请用 Linux 或 Docker。

### 3.3 启动成功标志

看到类似输出即成功：

```
Workerman[start.php] start in DEBUG mode
------------------------------------------- WORKERMAN -------------------------------------------
Workerman version:5.x.x          PHP version:8.2.x
--------------------------------------------- WORKERS -------------------------------------------
proto   user      worker             listen                    processes    status
tcp     root      webman             http://0.0.0.0:8500        N            [OK]
tcp     root      monitor            none                       1            [OK]
tcp     root      madong-scheduler   text://127.0.0.1:2001      1            [OK]
--------------------------------------------------------------------------------------------------
```

---

## 四、进程说明

`config/process.php` 定义了三个进程：

| 进程 | 处理器 | 监听 | 进程数 | 作用 |
| --- | --- | --- | --- | --- |
| `webman` | `app\process\Http` | `http://0.0.0.0:8500` | `4` | HTTP 服务主进程 |
| `monitor` | `app\process\Monitor` | — | 1 | 文件变更热重载 + 内存监控 |
| `madong-scheduler` | `core\infrastructure\scheduler\SchedulerServer` | `text://127.0.0.1:2001` | 1 | 任务调度服务 |

### 4.1 默认端口

**HTTP 服务默认监听 `8500`**。修改方式：编辑 `config/process.php` 中 `webman.listen`。

### 4.2 热重载监控范围

`monitor` 进程监控以下目录，文件变更自动重载：

```
app/            业务代码
config/         配置
process/        进程
support/        支撑文件
resource/       资源
core/           内核
plugin/*/app    插件业务代码
plugin/*/config 插件配置
plugin/*/api    插件接口
core/*/config   内核配置
```

监控扩展名：`.php`、`.html`、`.htm`、`.env`

> 📌 注意：
> - `.env` 的监控被**刻意注释**（`config/process.php` 第 49 行），避免安装过程中因 `.env` 变更导致进程重启失联。**改完 `.env` 需手动重启**。
> - 热重载仅在 **Linux/macOS 且非守护模式**（未加 `-d`）时生效：`'enable_file_monitor' => !in_array('-d', $argv) && DIRECTORY_SEPARATOR === '/'`。

### 4.3 服务器参数

`config/server.php`：

| 配置 | 值 | 说明 |
| --- | --- | --- |
| `stop_timeout` | `2` | 停止超时（秒） |
| `pid_file` | `runtime/webman.pid` | PID 文件 |
| `status_file` | `runtime/webman.status` | 状态文件 |
| `stdout_file` | `runtime/logs/stdout.log` | 标准输出日志 |
| `log_file` | `runtime/logs/workerman.log` | Workerman 日志 |
| `max_package_size` | `10MB` | 最大包体积（影响上传大小） |

---

## 五、常用命令

```bash
php start.php start        # 启动（前台）
php start.php start -d     # 启动（守护）
php start.php stop         # 停止
php start.php restart      # 重启
php start.php restart -d   # 重启（守护）
php start.php reload       # 平滑重载（不中断连接）
php start.php status       # 查看运行状态
php start.php connections  # 查看连接数
```

**`reload` 与 `restart` 的区别**：

| 命令 | 行为 | 适用 |
| --- | --- | --- |
| `reload` | 平滑重载业务代码，不断开连接 | 修改 `app/` 业务代码 |
| `restart` | 完全重启所有进程 | 修改 `config/`、`.env`、`process.php` |

> 修改 `.env` 或 `config/process.php` **必须 `restart`**，`reload` 不生效。

---

## 六、验证服务

```bash
# 检查端口监听
netstat -tlnp | grep 8500        # Linux
netstat -ano | findstr 8500      # Windows

# 请求测试
curl http://127.0.0.1:8500
```

---

## 七、日志排查

```
backend/runtime/logs/
├── stdout.log         # 标准输出（启动信息、echo 内容）
├── workerman.log      # Workerman 进程日志
└── ...                # 应用日志（按 config/log.php 配置）
```

```bash
tail -f runtime/logs/stdout.log
tail -f runtime/logs/workerman.log
```

---

## 八、常见启动问题

**Q：`Address already in use`（端口被占用）**

```bash
# 查找占用进程
lsof -i:8500                     # Linux/macOS
netstat -ano | findstr 8500      # Windows

# 处理：结束占用进程，或修改 config/process.php 的监听端口
```

**Q：`SQLSTATE[HY000] [2002] Connection refused`**
A：MySQL 未启动或 `.env` 中 `DB_HOST`/`DB_PORT` 配置错误。

**Q：`Connection refused [tcp://127.0.0.1:6379]`**
A：Redis 未启动。执行 `redis-cli ping` 确认。

**Q：`Class "Redis" not found`**
A：PHP 未安装 redis 扩展，见 [环境准备](./environment.md#二php-环境)。

**Q：修改代码不生效**
A：
- 确认是否在守护模式（`-d`）下运行——守护模式关闭热重载。
- Windows 下热重载不生效（`DIRECTORY_SEPARATOR !== '/'`）。
- 修改 `.env` 或配置文件需 `restart`。

**Q：`runtime` 目录权限错误**

```bash
chmod -R 777 runtime storage
```

更多见 [FAQ · 后端问题](../faq/backend.md)。

---

## 九、下一步

- [前端启动](./frontend-setup.md)
- [初始化安装](./installation.md)
- [后端配置说明](../backend/getting-started/configuration.md)

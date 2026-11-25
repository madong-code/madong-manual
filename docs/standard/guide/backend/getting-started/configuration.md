# 配置体系

Webman 配置全部位于 `backend/config/`，通过 `config('key.subkey')` 读取。配置在启动时常驻内存，修改后需重启。

## 常用配置文件

| 文件 | 说明 |
| --- | --- |
| `config/process.php` | 进程与端口：`http://0.0.0.0:8500`、monitor、madong-scheduler `127.0.0.1:2001` |
| `config/route.php` | 全局路由（含 `/admin`、`/web`、`/install` 静态资源、关闭默认路由） |
| `config/app.php` | 应用名、默认语言 `lang`、时区等 |
| `config/database.php` | 数据库连接（默认 `mysql`，表前缀 `md_`） |
| `config/redis.php` | Redis 连接（默认 3 个组：默认、缓存、队列） |
| `config/translation.php` | 国际化：locale、回退语言、语言包路径 |
| `config/middleware.php` | 全局/模块中间件 |
| `config/terminal.php` | Web 终端配置（包管理器、前后端程序目录映射） |
| `config/review.php` | 内容审核流程配置 |
| `.env` | 环境变量（数据库、Redis、JWT 密钥等），运行期注入配置 |

## 读取配置

```php
use support\Request;

$name = config('app.name');
$port = config('process.websocket.listen'); // 视实际 key 而定
$dsn  = config('database.connections.mysql.host');
```

## 环境变量

`.env` 中的变量通过 `env('KEY', 'default')` 读取，框架在 `config/*` 中引用。例如：

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=madong
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=
```

修改 `.env` 后同样**需要重启**服务，因为常驻内存不会自动重新读取。

## 自定义配置

新增业务配置：在 `config/` 下新建 `mymodule.php` 返回数组，业务中使用 `config('mymodule.key')` 读取即可，无需注册。

> 注意：不要在 `core/` 目录新增或修改配置，框架核心与配置约定保持只读。

# 2.2 环境要求

## 2.2.1 版本要求总览

| 组件 | 要求 | 校验命令 |
| --- | --- | --- |
| PHP | **>= 8.2** (CLI) | `php -v` |
| Composer | 2.x | `composer -V` |
| MySQL | 5.7+ / 8.0+ | `mysql --version` |
| Redis | 5.0+ | `redis-server --version` |
| Node.js | **^22.18.0 或 ^24.x** | `node -v` |
| pnpm | **>= 10**（推荐 10.33.4） | `pnpm -v` |

> 版本约束来自 `backend/composer.json` 的 `require.php`，以及 `template/admin/package.json` 的 `engines` / `packageManager`。

## 2.2.2 PHP 扩展

必需扩展：

```
pdo  pdo_mysql  redis  json  mbstring  openssl  curl  fileinfo  gd  zip  posix(Linux)  pcntl(Linux)
```

检查已安装扩展：

```bash
php -m
```

### 常见缺失项

| 扩展 | 用途 | 缺失后果 |
| --- | --- | --- |
| `redis` | 缓存、队列、会话 | 启动即报错 |
| `gd` | 图形验证码、图片处理 | 验证码不可用 |
| `zip` | 插件安装、导入导出 | 插件安装失败 |
| `pcntl` / `posix` | 多进程管理（**仅 Linux/macOS**） | 无法以 daemon 方式运行 |
| `fileinfo` | 上传文件类型识别 | 上传校验异常 |

> **Windows 无 `pcntl`/`posix`**，因此 Windows 下必须用 `php windows.php` 启动，不能用 `php start.php start -d`。

### 需要禁用的配置

Webman 依赖 `pcntl_*`、`proc_open` 等函数，请确认 `php.ini` 的 `disable_functions` 中**没有**禁用它们：

```ini
; 错误示例 —— 需要移除这些
disable_functions = pcntl_signal,pcntl_fork,proc_open,exec
```

## 2.2.3 数据库准备

创建数据库（字符集建议 `utf8mb4`），库名可按实际项目调整，CLI 安装命令默认使用 `madong`：

```sql
CREATE DATABASE `madong`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
```

表前缀由 `backend/.env` 的 `DB_PREFIX` 决定：CLI 安装命令 `install:madong` 默认 `ma_`，仓库自带的 `.env` 使用 `md_`，安装向导会在测试数据库连接时按填写值写回。**表前缀安装完成后不可更改**，请在安装前确定。

## 2.2.4 Redis 准备

后端在多处使用 Redis，`.env` 中分为三组配置：

| 组 | 前缀 | 用途 |
| --- | --- | --- |
| 主 Redis | `REDIS_*` | 通用缓存、会话 |
| 队列 Redis | `QUEUE_REDIS_*` | `webman/redis-queue` 队列 |
| 自定义缓存 | `CACHE_CUSTOM_REDIS_*` | 业务自定义缓存空间 |

三组可以指向同一个 Redis 实例，通过 `DB` 编号或 `PREFIX` 隔离。

## 2.2.5 Node 与 pnpm

前端强制使用 pnpm（`preinstall` 中配置了 `only-allow pnpm`），使用 npm/yarn 会直接报错。

```bash
# 通过 corepack 启用（推荐，版本随项目锁定）
corepack enable
corepack prepare pnpm@10.33.4 --activate

# 或全局安装
npm i -g pnpm@10
```

## 2.2.6 推荐开发工具

| 类型 | 推荐 |
| --- | --- |
| 一键环境（Windows） | phpStudy / Laragon（注意选择 PHP 8.2+ 且启用 CLI） |
| 一键环境（Linux） | 宝塔面板 / Docker |
| IDE | PhpStorm、VS Code |
| VS Code 插件 | PHP Intelephense、Vue - Official、Oxc、Tailwind CSS IntelliSense |

## 2.2.7 环境自检清单

在开始安装前逐条确认：

- [ ] `php -v` 显示 8.2 或更高
- [ ] `php -m` 包含 `pdo_mysql`、`redis`、`gd`、`zip`、`mbstring`
- [ ] `php.ini` 未禁用 `pcntl_*` / `proc_open`
- [ ] MySQL 可连接，目标数据库已创建
- [ ] Redis 可连接（`redis-cli ping` 返回 `PONG`）
- [ ] `node -v` 为 22.18+ 或 24.x
- [ ] `pnpm -v` 为 10+

> 下一节：[2.3 后端安装](backend.md)

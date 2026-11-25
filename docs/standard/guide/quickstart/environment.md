# 环境准备

---

## 一、环境要求

| 软件 | 最低版本 | 推荐版本 | 用途 |
| --- | --- | --- | --- |
| PHP | 8.2 | 8.2 / 8.3 | 后端运行时 |
| Composer | 2.0 | 最新 2.x | PHP 依赖管理 |
| Node.js | 22.18.0 | 22 LTS / 24 | 前端构建 |
| pnpm | 10.0.0 | 10.33.4 | 前端包管理（**强制**） |
| MySQL | 5.7 | 8.0 | 业务数据库 |
| Redis | 5.0 | 7.x | 缓存/队列/会话 |
| Git | 2.x | 最新 | 版本控制 |

> `template/admin/package.json` 中已锁定：
> ```json
> "engines": { "node": "^22.18.0 || ^24.0.0", "pnpm": ">=10.0.0" },
> "packageManager": "pnpm@10.33.4"
> ```
> 且 `preinstall` 脚本执行 `npx only-allow pnpm`，使用 npm/yarn 会直接报错。

---

## 二、PHP 环境

### 2.1 必需扩展

`composer.json` 中显式声明的扩展：

| 扩展 | 用途 |
| --- | --- |
| `ext-pdo` | 数据库连接 |
| `ext-redis` | Redis 客户端 |
| `ext-gd` | 图形处理（验证码、图片） |
| `ext-zip` | 压缩包处理（插件安装、导出） |

**建议同时开启**：

| 扩展 | 用途 |
| --- | --- |
| `ext-mbstring` | 多字节字符串 |
| `ext-openssl` | 加密、HTTPS |
| `ext-json` | JSON 处理 |
| `ext-curl` | HTTP 请求 |
| `ext-fileinfo` | 文件类型识别 |
| `ext-bcmath` | 高精度计算 |
| `ext-pcntl` | 进程控制（**Linux 必需**，Windows 不支持） |
| `ext-posix` | 进程管理（**Linux 必需**） |
| `ext-event` | 性能优化（可选，`suggest` 中推荐） |

### 2.2 检查扩展

```bash
php -v                       # 查看版本，需 >= 8.2
php -m                       # 列出已装扩展
php -m | grep -E "pdo|redis|gd|zip|pcntl|posix"   # Linux/macOS
php -m | Select-String "pdo|redis|gd|zip"          # Windows PowerShell
```

### 2.3 安装（Ubuntu/Debian）

```bash
sudo apt update
sudo apt install -y php8.2-cli php8.2-fpm php8.2-mysql php8.2-redis \
  php8.2-gd php8.2-zip php8.2-mbstring php8.2-curl php8.2-bcmath \
  php8.2-xml php8.2-opcache
```

### 2.4 安装（CentOS/RHEL）

```bash
sudo yum install -y epel-release
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo dnf module reset php
sudo dnf module install php:remi-8.2
sudo yum install -y php-cli php-mysqlnd php-redis php-gd php-zip \
  php-mbstring php-bcmath php-opcache
```

### 2.5 安装（macOS）

```bash
brew install php@8.2
brew link php@8.2 --force
pecl install redis
```

### 2.6 安装（Windows）

1. 从 [windows.php.net](https://windows.php.net/download/) 下载 **PHP 8.2 Thread Safe (TS) x64**。
2. 解压至 `C:\php82`，将该路径加入系统 `PATH`。
3. 复制 `php.ini-development` 为 `php.ini`，开启扩展：

```ini
extension_dir = "ext"
extension=pdo_mysql
extension=gd
extension=zip
extension=mbstring
extension=openssl
extension=curl
extension=fileinfo
extension=bcmath
```

4. Redis 扩展需单独下载 `php_redis.dll`（注意匹配 PHP 版本、TS/NTS、位数），放入 `ext/` 后在 `php.ini` 添加 `extension=redis`。

> ⚠️ **Windows 限制**：不支持 `pcntl`/`posix`，无法使用多进程与守护模式。项目提供 `php windows.php` 专用启动方式，**仅建议用于开发**，生产环境请用 Linux。

### 2.7 Composer

```bash
# Linux/macOS
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# 验证
composer -V

# 国内加速（推荐）
composer config -g repos.packagist composer https://mirrors.aliyun.com/composer/
```

---

## 三、Node.js 环境

### 3.1 安装 Node

推荐用版本管理器，便于切换：

```bash
# nvm (Linux/macOS)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install 22
nvm use 22

# fnm（跨平台，更快）
fnm install 22
fnm use 22
```

Windows 可用 [nvm-windows](https://github.com/coreybutler/nvm-windows) 或直接下载安装包。

> 项目根有 `.node-version` 文件，fnm/nvm 可自动切换到指定版本。

### 3.2 安装 pnpm

```bash
# 方式一：corepack（Node 内置，推荐）
corepack enable
corepack prepare pnpm@10.33.4 --activate

# 方式二：npm 全局安装
npm install -g pnpm@10.33.4

# 验证
node -v      # 需 >= 22.18.0
pnpm -v      # 需 >= 10.0.0
```

### 3.3 国内加速

```bash
pnpm config set registry https://registry.npmmirror.com
```

---

## 四、MySQL

### 4.1 安装

```bash
# Ubuntu/Debian
sudo apt install -y mysql-server

# CentOS
sudo yum install -y mysql-server

# macOS
brew install mysql && brew services start mysql
```

### 4.2 创建数据库

```sql
CREATE DATABASE madong
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE USER 'madong'@'localhost' IDENTIFIED BY '你的密码';
GRANT ALL PRIVILEGES ON madong.* TO 'madong'@'localhost';
FLUSH PRIVILEGES;
```

> **务必使用 `utf8mb4`**，否则无法存储 emoji 等四字节字符。

### 4.3 推荐配置

`my.cnf` / `my.ini`：

```ini
[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
max_connections = 500
innodb_buffer_pool_size = 1G       # 建议为物理内存的 50%~70%

# 开发环境便于排查慢查询
slow_query_log = 1
long_query_time = 1
```

---

## 五、Redis

### 5.1 安装

```bash
# Ubuntu/Debian
sudo apt install -y redis-server

# CentOS
sudo yum install -y redis

# macOS
brew install redis && brew services start redis

# Windows：推荐使用 WSL2，或下载 Memurai / Redis for Windows 移植版
```

### 5.2 验证

```bash
redis-cli ping     # 返回 PONG 即正常
```

### 5.3 说明

项目使用 Redis 承担三类职责，`.env` 中可分别配置：

| 用途 | 环境变量前缀 | 说明 |
| --- | --- | --- |
| 通用缓存/会话 | `REDIS_*` | 主 Redis |
| 消息队列 | `QUEUE_REDIS_*` | 可独立实例，避免队列积压影响缓存 |
| 自定义缓存 | `CACHE_CUSTOM_REDIS_*` | 业务专用缓存 |

生产环境建议为队列单独分配 Redis 实例或 DB 编号。

---

## 六、开发工具推荐

### 6.1 IDE

| IDE | 说明 |
| --- | --- |
| PhpStorm | PHP 开发首选，对 Webman 支持良好 |
| VS Code | 轻量，前后端通吃 |

项目已内置 `.vscode/`（前端）与 `.idea/`（后端）配置。

### 6.2 VS Code 插件

**前端**：

- Vue - Official（Volar）
- TypeScript Vue Plugin
- Tailwind CSS IntelliSense
- oxc（Oxlint 支持）
- Stylelint
- EditorConfig for VS Code

**后端**：

- PHP Intelephense
- PHP Debug（Xdebug）
- Composer

### 6.3 调试工具

| 工具 | 用途 |
| --- | --- |
| Xdebug | PHP 断点调试（项目根有 `xdebug.log`） |
| Vue DevTools | 前端调试（设 `VITE_DEVTOOLS=true` 启用） |
| Apifox / Postman | 接口调试 |
| Redis Insight | Redis 可视化 |
| Navicat / DBeaver | 数据库可视化 |

---

## 七、环境检查清单

在进入下一步前，逐项确认：

```bash
php -v                                    # ✅ >= 8.2
php -m | grep -E "pdo_mysql|redis|gd|zip" # ✅ 扩展齐全
composer -V                               # ✅ >= 2.0
node -v                                   # ✅ >= 22.18.0
pnpm -v                                   # ✅ >= 10.0.0
mysql --version                           # ✅ >= 5.7
redis-cli ping                            # ✅ PONG
```

全部通过 → [后端启动](./backend-setup.md)

---

## 八、常见环境问题

**Q：`php -m` 看不到 redis 扩展**
A：Linux 用 `pecl install redis` 后在 `php.ini` 添加 `extension=redis`；Windows 需下载与 PHP 版本/TS-NTS/位数完全匹配的 `php_redis.dll`。

**Q：Composer 安装依赖极慢或超时**
A：切换国内镜像：`composer config -g repos.packagist composer https://mirrors.aliyun.com/composer/`。

**Q：`pnpm install` 报 `Unsupported engine`**
A：Node 版本不符合 `^22.18.0 || ^24.0.0`，请升级 Node。

**Q：执行 `npm install` 直接报错退出**
A：项目 `preinstall` 强制 `only-allow pnpm`，必须使用 pnpm。

**Q：Windows 下启动报 `pcntl` 相关错误**
A：Windows 不支持该扩展，请使用 `php windows.php` 启动，或改用 WSL2 / Docker。

更多问题见 [FAQ](../faq/index.md)。

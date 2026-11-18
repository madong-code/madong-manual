# 初始化安装

MDAdmin 提供可视化安装引导，完成环境检测、数据库配置、建表初始化与管理员创建。

---

## 一、安装状态判定

系统通过 `backend/install.lock` 文件判断是否已安装：

| 状态 | 表现 |
| --- | --- |
| `install.lock` 不存在 | 未安装，可执行安装引导 |
| `install.lock` 存在 | 已安装，安装接口返回「系统已安装」并附带安装时间 |

`install.lock` 内容为安装时间戳。

> 🔁 **重新安装**：删除 `backend/install.lock`，并清空数据库，即可重新走安装流程。

---

## 二、安装接口

安装逻辑位于：

- 控制器：`backend/app/install/controller/Index.php`
- 服务：`backend/core/business/install/InstallService.php`

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/install/check` | 检查安装状态 |
| GET | `/install/agreement` | 获取许可协议 |
| GET | `/install/environment` | 检查系统环境 |
| POST | `/install/test-database` | 测试数据库连接（成功后写入 `.env`） |
| POST | `/install/validate-config` | 验证数据库 + 管理员配置 |
| GET | `/install` | 执行安装（SSE 流式返回进度） |

---

## 三、安装流程

```
① 检查安装状态   GET /install/check
        ↓  未安装
② 阅读许可协议   GET /install/agreement
        ↓
③ 环境检测      GET /install/environment
        ↓  通过
④ 数据库配置    POST /install/test-database
        ↓  连接成功，自动写入 .env
⑤ 管理员配置    POST /install/validate-config
        ↓  校验通过
⑥ 执行安装      GET /install  （SSE 实时输出进度）
        ↓
⑦ 生成 install.lock，安装完成
```

### 3.1 检查安装状态

```http
GET /install/check
```

未安装：

```json
{ "code": 0, "msg": "系统未安装", "data": { "installed": false } }
```

已安装：

```json
{
  "code": 1,
  "msg": "系统已安装",
  "data": { "installed": true, "install_time": "2026-08-06 10:00:00" }
}
```

### 3.2 环境检测

```http
GET /install/environment
```

检测 PHP 版本、必需扩展、目录写权限等。**必须全部通过**才能继续。

常见检测项：

| 检测项 | 要求 |
| --- | --- |
| PHP 版本 | >= 8.2 |
| `pdo_mysql` 扩展 | 已安装 |
| `redis` 扩展 | 已安装 |
| `gd` 扩展 | 已安装 |
| `zip` 扩展 | 已安装 |
| `runtime/` 目录 | 可写 |
| `storage/` 目录 | 可写 |
| `.env` 文件 | 可写 |

### 3.3 数据库配置

```http
POST /install/test-database
Content-Type: application/json

{
  "host": "127.0.0.1",
  "port": 3306,
  "database": "madong",
  "username": "root",
  "password": "root",
  "prefix": "md_"
}
```

该接口会：

1. 调用 `validateDatabaseConfig()` 校验配置格式。
2. 调用 `testDatabaseConnection()` 实际连接测试。
3. **连接成功后调用 `saveDatabaseConfig()` 将配置写入 `.env`**，为后续步骤准备。

> ⚠️ **表前缀 `prefix` 安装后不可更改**，请谨慎确定（默认 `md_`）。

### 3.4 管理员配置校验

```http
POST /install/validate-config
Content-Type: application/json

{
  "database": { "host": "127.0.0.1", "port": 3306, "database": "madong", "username": "root", "password": "root", "prefix": "md_" },
  "admin":    { "username": "admin", "password": "你的密码", "email": "admin@example.com" }
}
```

分别调用 `validateDatabaseConfig()` 与 `validateAdminConfig()`，任一失败返回对应错误明细。

### 3.5 执行安装

```http
GET /install
```

**该接口以 SSE（Server-Sent Events）流式返回安装进度**：

```php
$connection->send(new Response(200, [
    'Content-Type'  => 'text/event-stream',
    'Cache-Control' => 'no-cache',
    'Connection'    => 'keep-alive',
    // ...
], "\r\n"));

$generator = $this->installService->install($data);
foreach ($generator as $chunk) {
    $connection->send($chunk);
}
```

前端应使用 `EventSource` 或流式读取来实时展示进度，而非普通 AJAX。

---

## 四、安装做了什么

`core/business/install/InstallService.php` 通过多个 Trait 分工完成：

| Trait | 职责 |
| --- | --- |
| `InstallDatabaseTrait` | 创建数据表、导入结构与基础数据 |
| `MenuTrait` | 初始化系统菜单 |
| `AdminTrait` | 创建超级管理员账号 |
| `ConfigTrait` | 写入系统配置项 |
| `DictTrait` | 初始化数据字典 |

安装完成后生成 `install.lock`。

### 4.1 前端模板组织模式

系统安装与插件安装共用 `backend/config/install.php` 作为唯一事实来源，通过 `core/business/install/InstallConfigResolver` 解析，避免两处各自维护模板路径。

| 模式 | admin | platform | web | 说明 |
| --- | --- | --- | --- | --- |
| `mono`（单仓双端） | `template/mono/apps/admin` | `template/mono/apps/platform` | `template/web` | admin/platform 共享 monorepo 依赖 |
| `separated`（分离双端，默认） | `template/admin` | `template/platform` | `template/web` | 三端各自独立仓库 |

`web` 是两种模式共用的通用模板，不随模式变化。

配置结构（关键部分）：

```php
// backend/config/install.php
return [
    'default_mode' => 'separated',
    'modes' => [
        'mono'      => ['templates' => ['admin' => 'mono/apps/admin', 'platform' => 'mono/apps/platform']],
        'separated' => ['templates' => ['admin' => 'admin', 'platform' => 'platform']],
    ],
    'common_templates' => ['web' => 'web'],
    'template_meta' => [
        'admin'    => ['label' => '管理端', 'plugin_dir' => 'src/plugin', 'build_dir' => 'dist', 'default' => true],
        'platform' => ['label' => '平台端', 'plugin_dir' => 'src/plugin', 'build_dir' => 'dist', 'default' => true],
        'web'      => ['label' => '会员端', 'plugin_dir' => 'src/plugin', 'build_dir' => '.output/public', 'default' => false],
    ],
    'plugin_distribution' => [
        'default_templates' => ['admin', 'platform'],
        'install_order' => ['backend', 'menus', 'frontend', 'mark'],
    ],
];
```

查找机制（模式决定路径、模板只声明元数据、三者解耦）：

```
templatePath(模板, 模式) = template/ + modes[模式].templates[模板]
                        未命中时 = template/ + common_templates[模板]

插件落盘目录 = templatePath(模板, 模式) + template_meta[模板].plugin_dir + /<插件标识>
```

新增一种组织方式，只需在 `modes` 增加一组路径映射并在 `template_meta` 声明元数据，无需改动加载代码。配置缺失时回退为 `separated` + admin/platform，旧部署不会报错。

### 4.2 四阶段安装进度

`GET /install` 与 CLI 共用 `InstallService::install()`，进度按四个阶段输出（百分比节点保持不变，SSE 事件契约不变）：

| 阶段 | 进度文案前缀 | 主要工作 |
| --- | --- | --- |
| 环境准备 | `[1/4 环境准备]` | 安装状态校验、环境检测、数据库/管理员参数校验、数据库连接测试 |
| 依赖安装 | `[2/4 依赖安装]` | 建表与基础数据（或仅初始化管理员）、可选的前端依赖安装与构建/文件迁移 |
| 配置初始化 | `[3/4 配置初始化]` | 写入 `.env` |
| 安装验证 | `[4/4 安装验证]` | 创建 `install.lock` 并派发完成事件 |

前端构建为可选步骤，失败仅输出 `warning` 事件并继续安装，可稍后在后台「终端 → 重新发布」中单独构建。

---

## 五、通过前端安装端安装

项目提供独立的安装引导前端 `template/mono/apps/install`：

```bash
cd template/mono/apps/install
pnpm dev
```

按界面提示依次完成：许可协议 → 环境检测 → 数据库配置 → 管理员设置 → 执行安装。

详见 [前端 → 安装端](../frontend/mono/install/intro.md)。

---

## 六、手动安装（跳过引导）

若引导流程受阻，可手动完成：

### 6.1 配置 `.env`

参考 [后端启动 · 配置环境变量](./backend-setup.md#二配置环境变量)。

### 6.2 执行数据库迁移

```bash
cd backend
vendor/bin/phinx migrate
```

迁移配置见 `backend/phinx.php`。

### 6.3 使用安装命令

```bash
# 默认 separated（取 config/install.php 的 default_mode）
php webman install:madong -y --build-project=1

# 指定 mono 单仓模式
php webman install:madong -y --build-project=1 --mode=mono

# 显式指定前端模板清单（逗号分隔）
php webman install:madong -y --build-project=1 --mode=separated --templates=admin,platform,web
```

`--mode` 可选 `mono` / `separated`，`--templates` 为逗号分隔的模板名；两者不传时均由 `config/install.php` 决定。查看可用命令：

```bash
php webman list
```

### 6.4 创建 lock 文件

```bash
echo "$(date '+%Y-%m-%d %H:%M:%S')" > install.lock
```

---

## 七、安装后验证

1. **后端**：访问 `http://127.0.0.1:8500`，服务正常响应。
2. **数据库**：确认表已创建（前缀 `md_`），`md_system_user` 等表有初始数据。
3. **前端**：访问 `http://localhost:5777`，能进入登录页。
4. **登录**：使用安装时设置的管理员账号密码登录。

---

## 八、安装常见问题

**Q：提示"系统已安装"但我想重装**
A：删除 `backend/install.lock`，并清空数据库（或换个库名），重新走流程。

**Q：环境检测不通过**
A：按提示补齐 PHP 扩展或修正目录权限：

```bash
chmod -R 777 runtime storage
chmod 666 .env
```

**Q：数据库连接测试失败**
A：
1. 确认 MySQL 已启动：`systemctl status mysql`。
2. 确认库已创建且字符集为 `utf8mb4`。
3. 确认账号有该库的完整权限。
4. 确认 `host`/`port` 正确（Docker 环境注意不能用 `127.0.0.1`）。

**Q：安装过程中断/超时**
A：安装走 SSE 长连接，检查：
- Nginx 是否关闭了缓冲（需 `proxy_buffering off;`）。
- 反向代理超时时间是否过短。
- 直接访问后端端口（绕过 Nginx）重试。

**Q：安装后管理员无法登录**
A：
1. 确认 `.env` 中 `CAPTCHA_ENABLED` 与前端是否一致。
2. 检查 Redis 是否正常（会话/令牌依赖 Redis）。
3. 查看 `runtime/logs/` 日志。

**Q：安装后菜单为空**
A：`MenuTrait` 未执行成功，检查安装日志；可尝试删除 lock 后重装。

更多见 [FAQ](../faq/index.md)。

---

## 九、下一步

- [开发第一个功能](./first-feature.md)
- [代码生成器](../plugin/codegen.md)
- [后端配置说明](../backend/getting-started/configuration.md)

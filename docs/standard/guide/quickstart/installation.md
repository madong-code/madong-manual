# 初始化安装

安装完成**环境检测 → 数据库建表 → 初始化数据 → 创建管理员 → 生成 `install.lock`** 的全过程。完整说明以 [2.5 安装向导](../install/wizard.md) 和 [2.3 后端安装](../install/backend.md) 为准。

---

## 一、安装状态判定

系统通过 `backend/install.lock` 判断是否已安装：

| 状态 | 表现 |
| --- | --- |
| 不存在 | 未安装，可执行安装 |
| 存在 | 已安装，安装接口返回「系统已安装」并附带安装时间 |

`install.lock` 内容为安装时间。重新安装时删除该文件并清空数据库即可。

---

## 二、安装方式

### 2.1 命令行安装（推荐）

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

常用选项：`--db-*`、`--db-prefix`（默认 `ma_`）、`--admin-*`、`--install-database=1|0`（默认 1）、`--build-project=1|0`、`--skip-env-check`、`-y` 非交互。已存在 `install.lock` 时会拒绝重复安装。

### 2.2 在线安装向导

后端启动后访问：

```
http://127.0.0.1:8500/install
```

向导页面由后端静态资源提供，**无需启动 `template/install/`**（该目录为空）。按页面提示依次完成许可协议 → 环境检测 → 数据库配置 → 管理员设置 → 执行安装。

---

## 三、后端接口

实现位置：控制器 `backend/app/install/controller/Index.php`，服务 `core/business/install/InstallService.php`。

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/install/check` | 检查安装状态 |
| GET | `/install/agreement` | 获取许可协议 |
| GET | `/install/environment` | 检测运行环境 |
| POST | `/install/test-database` | 测试数据库连接（成功后写入 `.env`） |
| POST | `/install/validate-config` | 校验数据库 + 管理员配置 |
| GET | `/install` | 执行安装（SSE 流式返回进度） |

安装过程以 `text/event-stream` 流式返回进度，前端需使用 `EventSource` 或流式读取，而非普通 AJAX。

---

## 四、数据库初始化（备选方式）

自研迁移命令 `madong-migrate` 用于表结构版本管理：

```bash
cd backend
php webman madong-migrate status
php webman madong-migrate up
php webman madong-migrate up --seed
php webman madong-migrate rollback
```

> 迁移只处理表结构与种子数据，不会创建管理员账号和 `install.lock`，首次安装仍应使用 `install:madong` 或在线向导。

---

## 五、安装后验证

1. **后端**：访问 `http://127.0.0.1:8500`，服务正常响应。
2. **数据库**：确认业务表已创建，表前缀与安装时填写一致。
3. **前端**：访问 `http://localhost:5500`，能进入登录页。
4. **登录**：使用安装时设置的管理员账号密码登录。

---

## 六、常见问题

**Q：提示「系统已安装」但我想重装**
A：删除 `backend/install.lock`，并清空数据库（或换个库名），重新走流程。

**Q：环境检测不通过**
A：按提示补齐 PHP 扩展或修正目录权限：

```bash
chmod -R 777 runtime public
```

**Q：数据库连接测试失败**
A：确认 MySQL 已启动、库已创建且字符集为 `utf8mb4`、账号有该库完整权限、`host`/`port` 正确（Docker 环境注意不能用 `127.0.0.1`）。

**Q：安装过程中断 / 进度卡住**
A：安装走 SSE 长连接，检查 Nginx 是否关闭缓冲（`proxy_buffering off;`）、代理超时是否过短；开发期可直连后端端口重试。

**Q：安装后管理员无法登录**
A：确认 Redis 正常（会话/令牌依赖 Redis），查看 `runtime/logs/` 日志。

更多见 [2.5 安装向导 · 安装失败排查](../install/wizard.md) 与 [FAQ](../faq/index.md)。

---

## 七、下一步

- [开发第一个功能](./first-feature.md)
- [代码生成器](../dev-guide/codegen.md)
- [后端配置说明](../backend/getting-started/configuration.md)

# MCP 工具

框架内置 MCP（Model Context Protocol）服务端，让 Trae、Cursor、Claude Code 等支持 MCP 的 AI 客户端能够直接调用系统内部工具。

## 作用

在 AI 编辑器的 Agent 对话中，AI 可以直接执行系统暴露的工具 —— 例如查询系统状态、验证调用者身份、调用业务查询，而不需要你手动复制粘贴或切换终端。典型用途：

- **AI 编辑器联调**：开发时让 Agent 直接调用后端工具验证逻辑
- **CI / 脚本**：以 API Key 机器身份查询系统信息
- **智能运维**：结合 Agent 做系统状态巡检

## 能做什么

- 端点：`/mcp`（Streamable HTTP 传输，POST 收发 JSON-RPC）
- 工具发现：`#[McpTool]` 属性标注即自动注册，无需手工登记
- 鉴权：API Key / 后台 JWT / 匿名 三通道，工具可见性随身份权限过滤
- **租户双模式**（SaaS 专属）：平台级身份不做租户过滤；API Key 可绑定 `tenant_id`，或请求携带 `X-Tenant-Id`，调用期间自动注入租户上下文并切到对应租户库

内置工具分三类权限等级，开箱即用：

**L1 框架内置**（`core/communication/mcp/tool/`，随框架自带）：

| 工具名 | 权限 | 说明 |
|--------|------|------|
| `ping` | 匿名 | 连通性测试，恒定返回 `pong` |
| `system_info` | 匿名 | 系统运行信息，`section` 可选 overview / php / time |
| `health_check` | 需登录 | 健康检查（数据库 / Redis 等依赖连通性） |
| `cache_status` | 需登录 | 缓存运行状态概览 |
| `queue_status` | 需登录 | 队列积压与消费状态 |
| `server_monitor` | 需登录 | 服务器资源信息（disk/cpu/memory/redis/php） |
| `current_user` | 需登录 | 返回当前调用者身份概要，用于验证鉴权链路 |
| `scheduler_status` | 需登录 | 定时调度任务状态 |
| `tool_catalog` | 需登录 | 列出当前已注册的全部 MCP 工具，支持关键词过滤 |
| `menu_catalog` | 需登录 | 菜单与权限码清单（type=3 为按钮权限码），开发工具时选取真实权限码 |
| `dict_catalog` | 需登录 | 业务字典及枚举项，理解状态码/枚举值含义 |
| `plugin_list` | 需登录 | 本地插件清单（版本/描述/安装状态） |
| `route_list` | 需登录 | 列出后端已注册 HTTP 路由（方法/路径/回调），联调确认端点 |
| `db_schema` | 需登录 | 数据库表结构查询（表清单/字段清单），支持逻辑表名自动补前缀；可在配置中关闭 |
| `log_tail` | 需登录 | 读取运行日志尾部并支持关键词过滤，排障定位；可在配置中关闭 |
| `code_search` | 需登录 | 在 app/ 与 core/ 内检索 PHP 源码，返回文件/行号/片段 |
| `cache_clear` | `mcp:cache:clear` | 清理指定缓存 |
| `config_read` | `mcp:config:read` | 读取系统配置项 |
| `admin_account_query` | `mcp:admin:query` | 管理账号信息查询 |
| `db_query` | `mcp:db:query` | CI 场景受限 SQL 查询（字段隔离 + 租户表守卫） |
| `job_trigger` | `mcp:job:trigger` | 触发指定任务 |

**L2 项目业务示范**（`app/mcp/`）：`admin_user_list`（`system:admin:list`）、`role_list`（`system:role:list`）—— 业务工具写法参考。

**L3 插件提供**（`plugin/<name>/app/mcp/`）：插件安装后自动被发现注册，数据范围跟随调用者身份，可作为插件对外 AI 能力的出口。

## 怎么用（快速路径）

1. 确认 `config/mcp.php` 中 `enable => true`，启动后端服务（默认端口 8500）；
2. 在 AI 编辑器中添加 MCP Server（url `http://127.0.0.1:8500/mcp` + 鉴权头），见[编辑器接入](ide.md)；
3. 在挂载了 MCP 工具的智能体对话中发起调用（如「调用 madong 的 ping 工具」）。

业务工具的开发见[自定义工具](custom-tools.md)，生产部署策略见[生产环境](production.md)，问题排查见[常见问题](faq.md)。

## 定位与建议

MCP 当前定位为**开发联调与内部工具场景**（编辑器助手、CI、运维脚本），不建议直接暴露公网。

- **开发环境**：开启，供 AI 编辑器辅助开发、调试业务工具
- **生产环境**：默认不使用时将 `enable` 置为 `false`（端点返回 404，不暴露存在性）；确需使用时按[生产环境](production.md)一节加固

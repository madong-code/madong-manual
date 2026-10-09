# 常见问题

**Trae 面板绿灯但不调用工具？**
MCP 面板绿灯只代表连接成功。工具必须挂载到智能体（智能体编辑页 > 工具 - MCP 勾选），且要在挂载后的**新对话**中调用；旧对话可能未注入工具列表。服务端日志无 `tools/call` 记录即可确认是客户端侧问题。

**调用返回 401 Invalid MCP API key？**
请求头 key 与 `auth.api_keys` 键不一致，或该通道已关闭。核对编辑器配置与服务端配置是否完全一致。

**新增工具后客户端看不到？**
确认文件在被扫描目录中、类名与文件路径符合 autoload 映射、`#[McpTool]` 标注在方法上；用 `madong-mcp:list` 验证（该命令结果与端点一致）。改完文件后清单会按 mtime 自动重建，无需手工清缓存。

**匿名能看到工具但业务工具看不到？**
工具按身份权限过滤属正常行为。检查调用身份：匿名仅可见公开工具；JWT 身份的权限码与后台角色菜单一致；API Key 身份看 `permissions` 配置。

**工具查到的数据不对/为空？**
检查租户上下文来源：API Key 的 `tenant_id`、请求头 `X-Tenant-Id` 与 JWT 携带的当前租户，按此优先级生效。平台级身份（未绑定租户）查询不附加租户条件，租户级身份自动切库；`APP_TENANT_ENABLED=false` 单体模式下全部走默认连接。

**日志出现 Unknown method "notifications/trae/session_stop" 警告？**
Trae 的私有会话通知，MCP 标准未定义该方法，SDK 记录警告但不影响功能，可忽略。

**Windows 下 CLI 带 JSON 参数报错？**
PowerShell 需转义双引号：`php webman madong-mcp:call system_info '{\"section\":\"time\"}'`。

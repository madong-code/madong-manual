# 编辑器接入

## 接入 Trae

1. 确认 `config/mcp.php` 中 `enable => true`，服务已启动（默认端口 8500）；
2. Trae：设置 > MCP > 添加 > 手动添加，粘贴（**key 与服务端 `api_keys` 一致**）：

```json
{
  "mcpServers": {
    "madong": {
      "url": "http://127.0.0.1:8500/mcp",
      "headers": {
        "X-Mcp-Api-Key": "dev-editor-key-local"
      }
    }
  }
}
```

3. 添加成功后面板显示绿灯和工具列表，**但这只是连接成功**；
4. 关键一步：MCP 工具必须挂载到**智能体**上才会被调用 —— 在智能体创建/编辑页的「工具 - MCP」中勾选 `madong`，然后在该智能体的对话里发起调用（如「调用 madong 的 ping 工具」）。

排查技巧：服务端日志 `runtime/logs/webman-*.log` 会记录每次 `/mcp` 请求与方法；`runtime/mcp/sessions/` 可查看活跃会话。若 Agent 不调用工具，先看日志里有无 `tools/call` —— 没有则是客户端侧（智能体未挂载工具/旧会话未注入工具列表），不是服务端问题。

也可以不经编辑器直接 CLI 验证（见下节），排除客户端因素。

## 适配其它 MCP 客户端

服务端实现了标准的 **Streamable HTTP** 单端点传输，凡是支持该传输的客户端均可直接接入，无需改动服务端。判断依据：客户端配置里能写 `url`（或 `serverUrl`）字段，即为原生支持 HTTP。

下文给出各客户端的接入配置（`url` 为 `http://<host>:8500/mcp`，`X-Mcp-Api-Key` 换成你服务端 `api_keys` 中的 key；需指定租户时追加 `X-Tenant-Id` 请求头）。

### 直接支持（推荐）

**Cursor** — 项目级 `.cursor/mcp.json`：

```json
{
  "mcpServers": {
    "madong": {
      "url": "http://127.0.0.1:8500/mcp",
      "headers": { "X-Mcp-Api-Key": "dev-editor-key-local" }
    }
  }
}
```

> 注意 Cursor 对全部 MCP 工具总数有 40 个上限，超出的会被静默丢弃；项目里按需启用，不要一次挂太多。

**VS Code + GitHub Copilot** — 项目级 `.vscode/mcp.json`（需显式 `type: http`）：

```json
{
  "servers": {
    "madong": {
      "type": "http",
      "url": "http://127.0.0.1:8500/mcp",
      "headers": { "X-Mcp-Api-Key": "dev-editor-key-local" }
    }
  }
}
```

**Claude Code（命令行）**：

```bash
claude mcp add --transport http madong http://127.0.0.1:8500/mcp \
  --header "X-Mcp-Api-Key: dev-editor-key-local"
```

**Windsurf** — `~/.codeium/windsurf/mcp_config.json`（字段名为 `serverUrl`）：

```json
{
  "mcpServers": {
    "madong": {
      "serverUrl": "http://127.0.0.1:8500/mcp",
      "headers": { "X-Mcp-Api-Key": "dev-editor-key-local" }
    }
  }
}
```

**JetBrains / Cline / Continue.dev / Warp / Gemini CLI** 等同样原生支持 Streamable HTTP，按其 MCP 设置面板填入 URL 与 headers 即可（Cline 通过 UI，Continue 用 `config.yaml`，Gemini CLI／OpenAI Codex 为 CLI+TOML）。

### 受限客户端

| 客户端 | 限制 | 建议 |
|--------|------|------|
| **Claude Desktop**（JSON 配置） | 只支持 stdio，HTTP 需经 `mcp-remote` 桥接；Connectors UI 走 OAuth 不支持自定义 header | 需 gateway 转发统一注入 key，或只用匿名公开工具 |
| **ChatGPT**（Developer Mode Apps） | 仅付费档且 OAuth 为主，不携带自定义 header | 同上 |

> 匿名通道是兼容性兜底：无法注入自定义 header 的客户端仍可调用 `permission: null` 的公开工具（`ping` / `system_info`）。若需给泛用客户端暴露鉴权工具，需服务端补 OAuth（RFC 8414 / 7591）支持，属可选演进。

## CLI 调试

```bash
php webman madong-mcp:list                    # 列出全部工具（名称/权限/来源/描述）
php webman madong-mcp:call ping               # 直接调用工具
php webman madong-mcp:call system_info '{"section":"time"}'  # 带 JSON 参数
php webman madong-mcp:serve                   # 启动 STDIO 模式服务器（本地脚本直连）
```

`madong-mcp:call` 走完整发现与调用链路但不做权限过滤，适合开发期自测工具逻辑。

> Windows 控制台无稳定阻塞 STDIN，`madong-mcp:serve` 建议在 Linux/macOS 使用，或改走 HTTP 端点。

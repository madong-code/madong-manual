# 配置说明

配置文件：`config/mcp.php`（webman 自动加载为 `config('mcp.*')`）。

```php
return [
    // 总开关：false 时端点返回 404
    'enable' => true,

    // MCP 端点路径（仅文档用途，实际路由注册见 config/route.php 引入的 core/communication/mcp/route.php）
    'endpoint' => '/mcp',

    // MCP 客户端 initialize 时返回的服务器标识
    'server_name' => 'madong',
    'server_version' => '1.0.0',

    // 会话存储：file（默认）| redis（需 webman/redis，多进程/分布式建议 redis）
    'session' => [
        'store' => 'file',
        'path' => runtime_path('mcp/sessions'),
        'ttl' => 3600,
    ],

    // 鉴权：X-Mcp-Api-Key 优先于 Bearer JWT；均无则匿名（仅可见公开工具）
    'auth' => [
        'jwt' => true,          // Bearer JWT 通道开关
        'api_key' => true,      // API Key 通道开关

        // key => 身份定义（key 请使用强随机值，见生产环境）
        // tenant_id（SaaS 专属，可选）：该 key 绑定的租户；缺省/null 表示平台级（不注入租户上下文）
        'api_keys' => [
            'dev-editor-key-local' => [
                'id' => 0,
                'name' => 'dev-editor',
                'permissions' => ['*'], // ['*'] 表示超级权限；否则为权限码数组
                'scopes' => [],
                'tenant_id' => null,
            ],
        ],

        // Bearer JWT -> McpUser 解析器（默认桥接后台 admin 账号与菜单权限码）
        'identity_resolver' => \app\mcp\MadongIdentityResolver::class,
    ],

    // 内置可选工具开关（关闭后调用返回 enabled=false 提示；工具仍会注册，便于客户端感知）
    'tools' => [
        'db_schema' => true,
        'log_tail'  => true,
    ],

    // 工具扫描目录：相对路径基于 base_path()，支持 glob
    'discovery' => [
        'dirs' => [
            'app/mcp',
            'plugin/*/app/mcp',
            __DIR__ . '/../core/communication/mcp/tool',
        ],
        // 工具清单缓存（按被扫文件 mtime 指纹自动失效，一般无需手工清理）
        'manifest' => runtime_path('mcp/manifest.php'),
    ],
];
```

## 关键配置项

| 配置 | 说明 |
|------|------|
| `enable` | 总开关。关闭后端点 404，CLI 命令仍可用（便于本地排查） |
| `session.store` | 单机部署用 `file` 即可；多进程共享会话或分布式部署用 `redis` |
| `auth.jwt` | 开启后可用后台登录 token 直接调用，权限与后台一致 |
| `auth.api_keys` | 配置式机器身份，适合编辑器/CI；**凭证只写在服务端配置里** |
| `auth.api_keys.*.tenant_id` | SaaS 专属：key 绑定租户；null 表示平台级身份 |
| `tools.*` | 内置可选工具开关，当前支持 `db_schema`（库表结构）、`log_tail`（日志读取）两类敏感查询；置 `false` 后调用返回 `enabled=false` 提示，不抛错 |
| `discovery.dirs` | 新增工具目录时在此登记，支持 `plugin/*/app/mcp` glob 写法 |

## 身份与鉴权

同一请求按以下顺序解析身份，解析成功即停止：

1. **`X-Mcp-Api-Key: <key>`**：在 `auth.api_keys` 查表构造机器身份（不依赖后台会话，适合编辑器/CI）；
2. **`Authorization: Bearer <JWT>`**：复用后台登录 token，经 `identity_resolver` 校验并解析出 admin 账号及其菜单权限码（超管为 `['*']`）；
3. **匿名**：未携带任何凭证时仅可见 `permission: null` 的工具。

注意：**提供了凭证但凭证无效时会直接拒绝（401）**，不会静默降级为匿名；对应通道开关关闭时携带该通道凭证同样 401。

工具可见性由 `#[McpTool]` 的 `permission` 参数声明，**不可见即不可调用**（服务端直接过滤，不依赖客户端自觉）：

| permission 取值 | 语义 |
|------|------|
| `null` | 匿名可访问（公开工具） |
| `false` | 仅需登录，不要求权限码 |
| `'order:query'` | 需要对应菜单权限码 |
| `['a:b', 'c:d']` | 需同时拥有多个权限码（and 语义） |

## 租户上下文（SaaS 专属）

租户来源按以下优先级判定：

1. **身份绑定的租户**：API Key 的 `tenant_id` 配置，或 JWT 中携带的当前租户（`extra.current_tenant.id`）；
2. **请求头 `X-Tenant-Id`**：身份未绑定租户时可经请求头指定；
3. **平台级**：以上均无时不注入租户上下文，数据查询不做租户过滤（与 `TenantScope` 无租户上下文时行为一致）。

注入租户后，工具内的模型查询自动落到对应租户库（database 隔离）或自动附加租户字段条件（field 隔离）；`APP_TENANT_ENABLED=false` 单体模式下全部走 no-op/默认连接。

`db_query` 工具有额外守卫：已绑定租户时拒绝查询租户表，防止跨租户读取。

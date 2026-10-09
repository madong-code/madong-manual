# 自定义工具

## 放在哪里

| 层级 | 目录 | 说明 |
|------|------|------|
| L1 框架内置 | `core/communication/mcp/tool/` | 随框架分发，一般不在此新增 |
| L2 项目业务工具 | `app/mcp/` | 全局业务，推荐按模块分子目录如 `app/mcp/order/` |
| L3 插件提供 | `plugin/<name>/app/mcp/` | 随插件安装自动被发现（已在扫描目录中） |

目录已在 `discovery.dirs` 中登记，**新建 PHP 文件后即被自动发现**，清单缓存按文件 mtime 指纹自动失效，无需手工清缓存。

L2 现成示范可参考 `app/mcp/AdminUserListTool.php`、`app/mcp/RoleListTool.php`。

## 最小示例

```php
<?php
declare(strict_types=1);

namespace app\mcp\order;

use core\communication\mcp\attribute\McpTool;
use core\communication\mcp\security\McpUser;

final class OrderQueryTool
{
    public function __construct(
        private readonly ?McpUser $user = null, // 调用者身份经构造器注入，匿名时为 null
    ) {
    }

    #[McpTool(
        name: 'order_query',
        title: '订单查询',
        description: '按订单号查询订单概要，返回状态与金额。',
        inputSchema: [
            'type' => 'object',
            'properties' => [
                'orderNo' => ['type' => 'string', 'description' => '订单号'],
            ],
            'required' => ['orderNo'],
        ],
        permission: 'order:query',
    )]
    public function orderQuery(string $orderNo): array
    {
        return ['orderNo' => $orderNo, 'status' => 'paid'];
    }
}
```

## 属性参数

| 参数 | 必填 | 说明 |
|------|------|------|
| `name` | 是 | 工具名，全局唯一，建议 `<模块>_<动作>` 蛇形命名 |
| `title` | 否 | UI 展示名 |
| `description` | 建议 | **给 LLM 看的**，说清用途、返回内容、参数含义，直接影响 Agent 是否正确选用该工具 |
| `inputSchema` | 否 | JSON Schema（draft 2020-12），默认空对象 |
| `permission` | 否 | 权限控制，取值见[配置说明](configuration.md#身份与鉴权)，默认 `null`（匿名） |

## 编写规则与注意事项

- **参数注入是按名字的**：方法参数名必须与 `inputSchema.properties` 键一致，SDK 按命名参数注入。参数改名时两边同步改。
- **返回值**：数组/对象会作为结构化内容返回给客户端；标量作为文本返回。建议返回数组，内容对 LLM 友好（不要返回整页 HTML 之类）。
- **身份判断用 `$this->user`**：工具实例由框架按请求构造，当前调用者身份已注入。**不要在工具方法里读全局 `request()`** —— CLI 与 STDIO 场景没有 HTTP 请求上下文。
- **复用服务层**：工具应是薄封装，业务逻辑写在 Service 里，工具方法只做参数转换与调用。避免把业务逻辑堆进工具类。
- **租户隔离交给框架**：平台级查询不过滤、租户级查询自动切库/附加字段条件，工具内**不要**手工写 `tenant_id` 条件；确需平台级聚合时用业务 Dao 的显式主库连接，并注意结果中可能混合多租户数据。
- **插件工具走插件统一装配入口**：复用插件 SDK 时使用插件提供的工厂/客户端，**不要直接让容器自动装配 SDK** —— SDK 依赖的引擎配置无法被自动注入，会得到空配置并报「服务未注册」。
- **幂等与副作用**：LLM 可能重复调用同一工具；写操作工具（创建/修改/删除，如 `cache_clear` / `job_trigger`）要特别谨慎，建议控制权限码到最小，或在描述中说明副作用。
- **异常**：抛出异常会被转换为工具执行错误返回给客户端（不中断服务）；参数校验失败建议返回明确的错误信息便于 LLM 自行纠正。
- **命名冲突**：`name` 全局唯一，插件与主项目重名时后注册的会覆盖，建议插件工具名带插件前缀。

## 验证流程

```bash
php webman madong-mcp:list                    # 1. 确认工具被发现、权限标注正确
php webman madong-mcp:call order_query '{"orderNo":"SO001"}'  # 2. 验证执行结果
```

3. 重启编辑器对话（或重建智能体）让客户端重新拉取工具列表；
4. 在挂载了 madong 的智能体里实测调用。

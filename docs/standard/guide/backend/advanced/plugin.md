# 应用插件

后端插件机制基于 Webman 的插件规范：**Webman 启动时自动扫描 `backend/plugin/` 目录并注册路由与配置**，无需手动引入。

> 重要：运行时后端只读取 `backend/plugin/`。`madong-market/*` 或 `template/*` 里的同名目录只是插件**模板源/安装包**，重新安装/同步时才会写入运行时目录，两边内容需保持一致。

## 内置插件（标准版）

| 目录 | 标识 | 说明 |
| --- | --- | --- |
| `cms/` | `cms` | CMS 内容管理：栏目/内容/单页/标签/轮播/友链/评论/SEO/布局编排，付费阅读、会员订阅与打赏经 `pay` 收单 |
| `codegen/` | `codegen` | 代码生成器：导入数据表、配置字段、预览/部署/下载，生成后台 CRUD 前后端代码 |
| `demo/` | `demo` | 示例插件：面向调试与测试，安装即用 |
| `logviewer/` | `logviewer` | 日志查看器：读取 runtime 日志，搜索过滤、详情阅读、行跳转与流式下载 |
| `pay/` | `pay` | 统一支付：微信/支付宝/模拟渠道，两阶段收单、退款、异步回调与领域事件解耦 |
| `portal/` | `portal` | 门户官网：应用市场/社区问答/知识库文档/会员中心（系统内置，禁止卸载） |
| `roport/` | `report` | 自动化报表：多数据源视图、PDF/Excel 报表、定时调度、失败重试告警与邮件分发（注意目录名与标识不同） |
| `workflow/` | `workflow` | 工作流引擎：低代码节点编排、审批智能化、全程可追踪 |

## 目录约定

```
backend/plugin/{plugin_name}/
├── config/
│   ├── info.php           # 插件元信息：标识/版本/描述/依赖/卸载策略（必填）
│   ├── route.php          # 插件路由（按 Webman 插件规范）
│   ├── review.php         # 审核类型扩展（可选）
│   └── ...                # 其它配置（自动被系统扫描合并）
├── app/                   # 插件业务代码（controller/service/dao/model...）
├── resource/              # 安装资源：template 前端模板源 / database 迁移 / data 初始数据
└── Install.php            # 安装/卸载脚本入口
```

## 插件如何被加载

1. Webman 启动（`start.php` / `windows.php`）扫描 `backend/plugin/` 下每个子目录。
2. 读取 `config/route.php` 注册路由；读取 `config/*.php` 合并进全局配置（如 `review.php` 的 `scan_plugins`）。
3. 插件业务类遵循与核心一致的 PSR-4 自动加载。

## config/info.php 字段说明

插件元信息与安装/卸载行为的唯一声明处，后台插件列表亦据此展示。

### 基础信息

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `name` | ✅ | 插件标识，**必须与目录名对应**，系统按此加载（如 `roport/` 目录的标识为 `report`） |
| `identifier` | ✅ | 唯一标识符，安装记录与插件市场使用 |
| `type` | ✅ | 插件类型，当前统一 `madong:app`（应用型插件） |
| `version` | ✅ | 插件独立版本号，与主程序版本无关；安装/更新时与插件市场远端版本做 `version_compare` 比对 |
| `description` | ✅ | 功能描述，后台插件列表展示 |
| `author` / `author_email` / `website` | – | 作者与站点信息 |

### 依赖声明

| 字段 | 说明 |
| --- | --- |
| `support_app` | 依赖的其它插件，如 cms 声明 `['pay']`（付费能力经 pay 收单） |
| `require.composer` | 后端 composer 依赖，安装时自动合并进根 `composer.json` 并提示 `composer install`，如 pay 的 `yansongda/pay => 3.7` |
| `npm_require` | 前端 npm 依赖，键支持 `admin` / `web`，安装时合并进对应端 `package.json`，如 workflow 的 `@logicflow/core` |

### 卸载策略 `uninstall`

| 键 | 说明 |
| --- | --- |
| `undeletable` | `true` = 系统内置插件：卸载接口直接拦截（提示"该插件为系统内置插件"），插件包不允许删除（如 portal、pay） |
| `drop_tables` | `true` = 卸载时回滚迁移/删除数据表；业务数据型插件应置 `false` 保留数据（如 portal、workflow），开发期可置 `true` 便于卸载即清库 |
| `remove_dependencies` | `true` = 卸载时移除合并进主程序的 composer/npm 依赖 |
| `remove_upload` | `true` = 卸载时按 `sys_upload.source = plugin:<name>` 精确回收上传附件，并按 `{dirname}/<name>/` 前缀兜底清理历史存量（由 `plugin.uninstalled` 监听器执行） |

### 资源与扩展端点

| 字段 | 说明 |
| --- | --- |
| `resource` | 资源路径声明：`menu` 菜单初始数据（约定 `data/menu`）、`migration`、`seed`、`template` 模板源 |
| `template` | 额外前端端点（独立于 admin/web 的自有前端，如 uniapp 小程序端），端点名 => 项目内路径前缀，如 cms 的 `'cms' => 'template/cms'`；与框架 appConfig、`Install.php resolveExtraTarget()` 同一约定 |
| `deploy_scope` | 分发范围：`both` 标准版与 SAAS 共用 / `standard` 仅标准版 / `saas` 仅 SAAS（如 logviewer） |

## 审核类型扩展（插件示例）

`config/review.php` 在系统侧 `scan_plugins => true` 时，会自动扫描各插件 `config/review.php` 并合并 `types` 与 `field_mappings`。例如 cms / portal 在各自 `config/review.php` 中声明审核类型，无需改核心。

## 新建插件

1. 在 `backend/plugin/` 下建立 `{plugin_name}/` 目录结构，先写 `config/info.php`。
2. 编写 `config/route.php` 定义路由（参考 Webman 插件路由规范）。
3. 在 `app/` 下按四层架构组织业务代码（Controller→Service→Dao→Model）。
4. 需要依赖时在 `info.php` 的 `require` / `npm_require` / `support_app` 声明，安装时自动合并。
5. 如需扩展系统能力（如审核类型），在 `config/{feature}.php` 提供与系统一致的键结构，系统自动合并。
6. 重启后端使插件生效（`php start.php restart`）。

> 注意：插件后端代码必须放在 `backend/plugin/` 下，否则请求会 404；同时确保与模板源保持同步以便重新安装。

# 三形态共用仓库整合方案（feature/shared-repo-integration）

> 分支：`feature/shared-repo-integration`（基于 main）
> 关联前端分支：`template/admin` 仓 `feature/tenant-adaptation`（见 template/admin/docs/tenant-adaptation.md）

## 1. 背景与目标

madong 产品存在三种运行形态，历史上分散在两个仓库，目标是以本仓库（madong-admin-saas）后端为**共用基座**，通过配置开关区分形态：

| 形态 | 后端基座 | 配套前端 | 隔离方式 |
|---|---|---|---|
| 标准版（single） | 本仓库 backend（`APP_TENANT_ENABLED=false`） | madong-single / template/admin | 单租户，无隔离 |
| 多租户（saas） | 本仓库 backend（`APP_TENANT_ENABLED=true`） | template/admin 租户分支、mono 的 apps/admin | 字段隔离（tenant_id） |
| 库隔离（进阶） | 本仓库 backend | 同上 | 独立库（saas_tenant_{id}），租户级 `database_mode` 控制 |

前端三模板保持现状：`template/admin`（标准版 UI + 租户适配分支）、`template/mono`（单体大仓 admin+platform 双 app）、`template/platform`（平台端 starter）。

## 2. 架构依据（实证结论）

- **形态开关已内建**：`config/tenant.php` 的 `mode` 由 `APP_TENANT_ENABLED` 驱动，false 时为 `single`。
- **single 旁路完整**（无需补丁，本次已逐点验证）：
  - `core/business/tenant/scope/TenantScope::apply()`：`isSingleMode()` 直接返回，不追加租户过滤；
  - `TenantContext`：`isSingleMode/hasTenant/isInitialized/isTenantEnabled/getIsolationMode/getConnectionName` 全部有 single 旁路；
  - 中间件：`TenantMiddleware`、`TenantIdentifyMiddleware`、`TenantSiteSwitchMiddleware`、`PlatformSwitchMiddleware` 在 single 模式跳过；`SubscriptionMiddleware` 经 `isInitialized()`（single 恒 false）跳过；`SiteSwitchMiddleware` 仅单体模式生效；
  - `TenantConnectionManager` 仅在租户 `database_mode=database` 且经 `TenantMiddleware` 注入后激活。
- **业务层同源**：adminapi 183 vs 186 文件、api 33 vs 32，90%+ 与标准版（madong-single 配套后端）一致；core 七域同构；config 28 个文件基本一致。

## 3. 本次改动清单（后端）

### 3.1 标准版能力吸收
- 新增迁移 `resource/database/migrations/2026_11_13_000001_absorb_standard_upgrade_columns.php`（幂等）：
  - `member.last_active_time`（活跃时间，节流更新）；
  - `sys_upload.source`（附件来源归属，插件卸载精确回收）；
  - `sys_plugin.support_app` varchar(32)→varchar(255)（前置依赖多值语义修正）。
  - 注：`sys_upload.space` 已由 `2026_09_27_000002_add_space_to_upload_table` 覆盖，不重复。
- `composer.json` require 新增 `dompdf/dompdf: 3.0`、`yansongda/pay: 3.7`（标准版能力：PDF 导出、支付）；`madong/workflow`（私有包）**不进 require**，作为可选能力按需引入。
- `composer.json` config 新增 `use-github-api: false`（规避 api.github.com dist 拉取不稳定）。

### 3.2 配置整理（.example.env）
- 新增"运行形态开关"注释段（standard/saas 两种取值与前端配套说明）；
- 补齐标准版键组：`JWT_ALGO/JWT_ACCESS_TTL/JWT_REFRESH_TTL/JWT_LOGIN_MODE`、`PLAYGROUND_ENABLE`。

## 4. 启动方式对照

| 平台 | 命令 | 说明 |
|---|---|---|
| Linux/macOS | `php start.php start -d` | 守护进程；`stop/restart/reload/status` |
| Windows | `php windows.php` | 前台运行（start.php 在 Windows 会提示转用 windows.php） |
| Windows 脚本 | `windows.bat` | 封装 windows.php |

冒烟验证路径（两形态通用）：
- `GET /adminapi/auth/tenant-mode`：标准形态返回 `{"enabled":false,...}`，租户形态返回 `{"enabled":true,...}`；
- `GET /adminapi/auth/site-info`：登录前平台站点信息。

## 5. 数据库迁移策略

- 主库：`resource/database/migrations`（13 个既有 + 1 个本次吸收迁移）；迁移执行器为自定义命令 **`php webman madong-migrate up|status|rollback`**（按文件名序执行，日志记录在 `runtime/migrations/main/default-migrations.log`，目标库由 `.env` 的 `DB_DATABASE` 驱动）。
- 注意：根目录 `phinx.php` 为遗留配置（robmorgan/phinx 直跑返回 "no available migrations"，不识别 `2026_MM_DD_NNNNNN_name.php` 带下划线文件名格式），实际迁移请勿使用 phinx，统一走 `madong-migrate`。
- 租户库隔离：复用同一迁移目录（`config/tenant.php` `database_isolation.migration_path`），开租户时统一建库（`tenant:migrate-data` / `TenantMigrationService`）。
- 标准版存量库（`md_admin`/utf8）切换到本基座时：新建 `madong_saas` 库（utf8mb4）执行全量迁移，或仅执行吸收迁移（幂等）。
- **迁移实测**：临时库 `madong_saas_verify`（utf8mb4）全量迁移 14/14 通过，二次执行 "No pending migrations"（幂等）；吸收迁移三列落地实证：`member.last_active_time int` + 索引、`sys_upload.source varchar(64) default 'default'` + 索引、`sys_plugin.support_app varchar(255)`；共 76 张表，采样表 collation `utf8mb4_unicode_ci`。

## 6. 风险与后续建议

| 项 | 状态 | 说明 |
|---|---|---|
| vendor 落盘（dompdf/yansongda） | 遗留 | 本机 composer 写 vendor/tmp zip 被拦截（疑似杀软），lock 已就绪；`composer install` 在解除拦截后补齐即可，代码零引用不影响运行 |
| madong/workflow | 遗留 | 私有包未纳入；标准形态需要工作流能力时单独引入（repositories + require） |
| permissions.json 差异 | 记录 | saas 版含 platform 端与租户权限（107KB vs 70KB）；标准形态菜单可用性已由 tenant-mode/site-info 冒烟覆盖，完整菜单回归建议联调时抽查 |
| 同名迁移内容差异 | 记录 | 两仓同名迁移（create_system_tables 等）存在行级差异（租户列等），以本仓为准；标准版库并入时按本仓迁移为准执行 |
| 依赖版本写法 | 已统一 | 按 saas 风格精确版本（mcp/sdk 0.8 等） |
| 字符集 | 已统一 | utf8mb4（madong_saas） |
| phpunit | 通过 | 63 tests / 125 assertions OK |
| 迁移 | 实测通过 | 临时库全量 14/14 + 幂等复跑 + 吸收迁移三列/索引/字符集落地实证（见第 5 节） |
| typecheck（前端） | 净改善 | main 13 个存量 TS 错误 → 分支 6 个（零引入） |
| build（前端） | 通过 | vite production 构建通过（补齐 push-vue.js 依赖闭包后），仅基线既有 chunk 警告 |

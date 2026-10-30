# 插件 · 生命周期

插件经历 安装 → 启用 → 使用 → 升级 → 卸载 五个阶段。

---

## 1. 安装（Installing → Installed）

安装前置检查通过后，`Install.php` 作为入口，安装流程一般做：
0. **前置依赖校验**（v5.1.3 起）：按 `info.php` 的 `support_app` 逐项检查前置插件是否已安装（`config/installed.php`），支持 string 单依赖 / array 多依赖，**任一未安装即阻断安装**，错误消息列出全部缺失依赖（见[应用插件 → 依赖声明](../backend/advanced/plugin.md#依赖声明)）。
1. 复制前端模板 `resource/template/admin/**` → `template/admin/src/**`；`info.php` 声明了额外端点（`template` 键，v5.1.3 起，如 h5/uniapp）时同步分发到 `{前缀}/{插件名}`。
2. 执行数据库建表（`resource/database/` 或迁移）。
3. 写入初始数据（菜单、权限码、字典）。
4. 注册路由/事件监听器。
5. 触发 `plugin.installed` 事件。

命令行与后台面板安装共用同一校验链路（`PluginInstallService::install → installCheck`），检查失败的原因会聚合到错误消息中。

> 安装期间 `.env` 监控被临时关闭（`config/process.php` 中 `.env` 注释避免安装失联）。

---

## 2. 启用 / 禁用

- 启用：插件后端代码被 Webman 扫描加载，前端路由合并。
- 禁用：停止加载（路由/菜单移除），数据保留。

---

## 3. 升级（Updating → Updated）

- 覆盖插件目录代码与模板。
- 执行增量迁移（新表/新字段）。
- 同步前端模板（注意用户自定义冲突）。
- 触发 `plugin.updated` 事件。

---

## 4. 卸载（Uninstalling → Uninstalled）

卸载行为由插件 `config/info.php` 的 `uninstall` 配置驱动（字段说明见[应用插件 → info.php 字段](../backend/advanced/plugin.md#configinfophp-字段说明)）：

- `undeletable=true`：系统内置插件，卸载接口直接拦截、包不允许删除（portal、pay）。
- `drop_tables`：是否回滚迁移/删除数据表；业务数据型插件置 `false` 保留数据。
- `remove_dependencies`：是否移除合并进主程序的 composer/npm 依赖。
- `remove_upload`：是否按 `sys_upload.source = plugin:<name>` 回收上传附件。

通用流程：移除前端模板与路由 → 按 `uninstall` 配置清理 → 触发 `plugin.uninstalled` 事件。

---

## 5. 事件钩子

`config/event.php` 预留：

```php
'plugin.installing'  => [],
'plugin.installed'   => [],
'plugin.uninstalling' => [],
'plugin.uninstalled'  => [],
'plugin.updating'     => [],
'plugin.updated'      => [],
```

实际监听由插件自身注册。

---

## 6. 约定

- 安装/卸载必须**幂等**，重复执行不产生破坏。
- 卸载默认保留用户数据，彻底清理需显式确认。
- 模板源（`resource/template`）与运行时（`template/admin`）保持一致，便于重新同步；开发期用 `madong-plugin:transfer {name} resource` 把运行时前端回写模板源（额外端点一并处理），详见[应用插件 → 开发期前端同步](../backend/advanced/plugin.md#开发期前端同步madong-plugintransfer)。

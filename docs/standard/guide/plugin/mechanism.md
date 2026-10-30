# 插件 · 机制

---

## 1. 后端扫描注册

Webman 启动时会自动扫描 `plugin/*/app/` 目录，注册该插件下的：
- 控制器与路由（经 Swagger 注解，见 [`backend/basic/route.md`](../backend/basic/route.md)）
- 中间件、事件监听器
- Service/Dao/Model（经 PHP-DI 自动装配）

> 插件后端**无需手动 require**，放对目录即生效（与 `app/` 业务代码机制一致）。

---

## 2. 前端挂载

插件前端以「模板源」形式存在于 `resource/template/`：
- `template/admin/` → 合并进后台前端 `template/admin/`（views/lang/routes）
- `template/web/` → 合并进门户前端 `template/web/`
- 额外端点（h5/uniapp 等，v5.1.3 起由 `info.php` 的 `template` 键声明）→ 合并进 `{前缀}/{插件名}`（如 `template/cms/src/plugin/cms`）

安装时由安装流程把模板复制到对应运行时前端目录；开发期用 `php webman madong-plugin:transfer {name} resource` 把运行时前端回写模板源（详见[应用插件 → 开发期前端同步](../backend/advanced/plugin.md#开发期前端同步madong-plugintransfer)）。

---

## 3. 配置与 Install.php

- `config/info.php`：**插件元信息唯一声明处**——标识（`name` 必须与目录对应）、独立版本号、描述、依赖（`support_app` / `require.composer` / `npm_require`）、卸载策略（`uninstall.undeletable` / `drop_tables` / `remove_dependencies` / `remove_upload`）、资源路径与额外前端端点。字段详情见[应用插件 → info.php 字段说明](../backend/advanced/plugin.md#configinfophp-字段说明)。
- `config/` 其它文件：插件自身配置（如菜单定义、权限码、路由前缀、审核类型扩展）。
- `Install.php`：插件安装/卸载入口，负责执行建表、写初始数据、注册菜单/权限等。

---

## 4. 事件钩子

插件生命周期通过事件解耦（见 [`backend/advanced/event.md`](../backend/advanced/event.md)）：
`plugin.installing` / `plugin.installed` / `plugin.uninstalling` / `plugin.uninstalled` / `plugin.updating` / `plugin.updated`（当前在 `config/event.php` 中为空数组，供插件动态注册）。

---

## 5. 命名空间

插件后端命名空间以 `plugin\<name>\` 开头，区别于业务 `app\`。例如：
`plugin\demo\app\adminapi\controller\XxxController`。

> 具体命名空间约定以插件实际代码为准；新增插件请遵循 `plugin/<name>/app/...` 目录对应的命名空间。

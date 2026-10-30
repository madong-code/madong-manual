# 插件 · 前端

插件前端以「模板源」存在于 `plugin/<name>/resource/template/`，安装时合并进运行时前端。

---

## 1. 目录结构

```text
plugin/<name>/resource/template/
├── admin/                      # 后台前端模板
│   ├── views/                  # 页面（与 template/admin/src/views 一致结构）
│   ├── lang/                   # i18n 文案（json）
│   ├── routes/                 # 路由定义（index.ts）
│   └── page.vue                # 入口页
└── web/                        # 门户前端模板
```

以 `demo` 插件为例：
- `resource/template/admin/views/`：84 个 `.vue` 页面
- `resource/template/admin/lang/`：108 个 `.json` 文案
- `resource/template/admin/routes/index.ts`：路由注册
- `resource/template/web/`：门户模板

---

## 2. 页面与路由

- 页面沿用后台前端的 `useCrud` + `CrudSchema` 模式（见 [`frontend/admin-ele/index.md`](../frontend/admin-ele/index.md)）。
- 路由在 `routes/index.ts` 声明，`meta` 携带 `title`/`icon`/`authority`，与运行时 `views/**` 的 `PluginRouteScanner` 机制一致（见 [`frontend/common/router.md`](../frontend/common/router.md)）。

---

## 3. 文案

- `lang/*.json` 为多语言文案，安装时合并进 `template/admin/src/lang/`（或对应模块）。
- 文案 key 与运行时 i18n 体系一致（见 [`frontend/common/i18n.md`](../frontend/common/i18n.md)）。

---

## 4. 安装同步

- 安装插件：复制 `resource/template/admin/**` → `template/admin/src/**`。
- 升级插件：覆盖式同步（保留用户自定义需谨慎）。
- 开发期可直接把 `resource/template/admin/` 作为源维护，安装时同步到运行时。

---

## 5. 多套 UI 兼容

- 若插件需适配多套 UI（Element Plus / AntD / Naive），`resource/template/admin/` 下按 `adapter/` 抽象组织，业务 `views` 复用。
- 详见 [`frontend/common/add-new-ui.md`](../frontend/common/add-new-ui.md)。

---

## 6. 额外前端端点（h5 / uniapp 等独立前端）

> 本节能力为 **v5.1.3 起支持**（`template` 声明、安装分发、transfer 回写与打包完整性告警）。

插件可携带独立前端（如 cms 的 uniapp 小程序端 `template/cms`），声明在 `info.php` 的 `template` 键：

```php
'template' => [
    'cms' => 'template/cms/src/plugin',   // 端点名 => 项目内路径前缀，插件子树 = {前缀}/{插件名}
],
```

- **安装分发**：`Install.php` 将 `resource/template/{端点}/**` 复制到 `{前缀}/{插件名}`（与 admin/web 内置端同一链路，`resolveExtraTarget()` 解析目标）
- **开发期回写**：`php webman madong-plugin:transfer {name} resource` 把 `{前缀}/{插件名}` clean 镜像回 `resource/template/{端点}/`
- **打包交付**：`madong-plugin:transfer {name} extract` 导出时额外端点资源随插件整包带出（缺失时告警）；`full` 部署时对称分发
- 未声明 `template` 的插件默认只处理 admin/web；同步范围仅限插件子树，子树外文件（uniapp 的 `pages.json` 注册、`locale` 等）需按插件安装逻辑自行处理
- 字段详情与场景表见[应用插件 → 资源与扩展端点](../backend/advanced/plugin.md#资源与扩展端点)、[开发期前端同步](../backend/advanced/plugin.md#开发期前端同步madong-plugintransfer)

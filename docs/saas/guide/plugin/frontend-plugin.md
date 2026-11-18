# 插件 · 前端

插件前端以「模板源」存在于 `plugin/<name>/resource/template/`，安装时由后端按 `config/install.php` 解析目标目录并合并进运行时前端。

---

## 1. 目录结构

```text
plugin/<name>/resource/template/
├── admin/                      # 管理端模板（views / api / lang / routes / page.vue）
├── platform/                   # 平台端模板（结构同 admin）
└── web/                        # 会员端门户模板（Nuxt：api / views / components）
```

每个端点目录可包含：

- `views/`：页面，与对应前端的 `src/views` 结构一致
- `api/`：接口封装（admin/platform 用 `requestClient`，web 用 `$fetch`）
- `lang/`：i18n 文案（json）
- `routes/`：路由定义（`index.ts`）
- `page.vue`：入口页

安装后落盘到对应前端的 `src/plugin/<插件标识>/`，前端通过 glob 自动扫描发现。

---

## 2. 模板注册、发现、分发、集成四环节

| 环节 | 机制 | 落点 |
| --- | --- | --- |
| 注册 | 插件包按约定提供 `resource/template/{admin,platform,web}/` 目录；manifest（`config/info.php`）仅声明元数据，不写死路径 | 插件包 |
| 发现 | `TemplateTrait::copyTemplates()` 遍历 `TEMPLATE_ENDPOINTS = ['admin','platform','web']`，逐个检查源目录是否存在 | `core/business/plugin/traits/TemplateTrait.php` |
| 分发 | `InstallConfigResolver::templatePath(模板, 模式)` + `template_meta[模板].plugin_dir` 解析落盘目录并复制文件 | `backend/config/install.php`、`core/business/install/InstallConfigResolver.php` |
| 集成 | 前端 glob 扫描 `src/plugin/**`：admin/platform 见 `vite.config.ts`，web 见 `nuxt.config.ts`（`srcDir: 'src'`） | 各前端模板 |

插件 `Install.php` 通过 `importTemplates()` / `deletePluginTemplates()` 触发分发与清理。

---

## 3. 双模式落盘路径

默认模式为 `separated`，可通过命令参数 `--template-mode`（插件安装/卸载）覆盖。

| 端点 | mono | separated |
| --- | --- | --- |
| admin | `template/mono/apps/admin/src/plugin/<name>` | `template/admin/src/plugin/<name>` |
| platform | `template/mono/apps/platform/src/plugin/<name>` | `template/platform/src/plugin/<name>` |
| web | `template/web/src/plugin/<name>` | `template/web/src/plugin/<name>` |

> **web 路径收敛**：web 为 Nuxt 应用且 `srcDir: 'src'`，插件扫描目录是 `src/plugin`。旧文档中的 `template/web/app/plugin` 已是死路径，现已统一修正为 `src/plugin`。
>
> 安装时清理当前模式的落盘目录；卸载时清理**所有模式**的目录（含 `plugin_dir`），避免切换模式后残留幽灵目录。

---

## 4. 插件默认分发目标

`config/install.php` 的 `plugin_distribution.default_templates` 默认为 `['admin', 'platform']`（双端共用），web 为可选。安装顺序为 `backend → menus → frontend → mark`，`installed` 标记必须在最后写入。

CLI 示例：

```bash
php webman madong-plugin:install <key> --template-mode=mono
php webman madong-plugin:install <key> --template-mode=separated
php webman madong-plugin:uninstall <key> --template-mode=separated -y
```

在线插件安装支持 `template_mode` 查询参数；不传时取 `config/install.php` 的默认值。

---

## 5. 页面与路由

- 页面沿用对应前端的 `useCrud` + `CrudSchema` 模式。
- 路由在 `routes/index.ts` 声明，`meta` 携带 `title`/`icon`/`authority`，与运行时 `views/**` 的 `PluginRouteScanner` 机制一致。

---

## 6. 文案

`lang/*.json` 为多语言文案，安装时合并进对应前端的 `src/lang/`，key 与运行时 i18n 体系一致。

---

## 7. 升级与多套 UI 兼容

- 升级插件：覆盖式同步（保留用户自定义需谨慎）。
- 开发期可直接把 `resource/template/{endpoint}/` 作为源维护，安装时同步到运行时。
- 若插件需适配多套 UI（Element Plus / AntD / Naive），`resource/template/admin/` 下按 `adapter/` 抽象组织，业务 `views` 复用。

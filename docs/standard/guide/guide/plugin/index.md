# 插件系统总览

Madong 极速后台开发框架支持**插件化扩展**：业务模块可打包为插件，独立安装/卸载/升级，前后端一体化分发。

---

## 1. 插件存放位置

```text
backend/plugin/
├── demo/            # 示例插件（含前端模板 + 后端代码）
└── codegen/         # 代码生成器插件（自动生成 CRUD 前后端代码）
```

每个插件目录结构：

```text
plugin/<name>/
├── app/                 # 后端运行时代码
│   ├── adminapi/        # 后台接口（controller/validate/schema/route）
│   ├── api/             # C 端接口
│   ├── dao/ model/ service/
│   └── generator/       # 代码生成逻辑（如 codegen 插件）
├── config/              # 插件配置
├── resource/            # 安装资源（模板源）
│   ├── template/admin/  # 后台前端模板（views/lang/routes/page.vue）
│   ├── template/web/    # 门户前端模板
│   ├── database/        # 建表 SQL / 迁移
│   └── data/            # 初始数据
└── Install.php          # 安装/卸载脚本入口
```

---

## 2. 关键区别：模板源 vs 运行时

> ⚠️ **极易混淆**，务必分清：

| 位置 | 角色 | 何时读取 |
| ---- | ---- | ---- |
| `plugin/<name>/app/**` | **后端运行时** | Webman 启动即扫描注册路由/控制器 |
| `plugin/<name>/resource/template/**` | **前端模板源 / 安装源** | 仅安装/同步时复制到 `template/admin` 等运行时前端 |
| `template/admin/**` | 前端**运行时**（被 dev server 加载） | 开发/构建时 |

**结论**：改后端代码必须改 `plugin/<name>/app/` 下（运行时）；前端模板改 `resource/template/admin/` 并保持与 `template/admin/` 一致以便重新安装同步。`madong-market/portal/*` 类似，仅作模板/安装源，运行时后端不读它（见 memory 中 portal 插件经验）。

---

## 3. 章节导航

| 章节 | 说明 |
| ---- | ---- |
| [机制](./mechanism.md) | 插件如何被扫描与注册 |
| [后端插件](./backend-plugin.md) | 后端代码组织 |
| [前端插件](./frontend-plugin.md) | 前端模板与路由/视图 |
| [生命周期](./lifecycle.md) | 安装/启用/卸载/升级 |
| [代码生成](./codegen.md) | codegen 插件用法 |

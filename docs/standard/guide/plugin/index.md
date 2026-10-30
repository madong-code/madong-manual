# 插件系统总览

MDAdmin 支持**插件化扩展**：业务模块可打包为插件，独立安装/卸载/升级，前后端一体化分发。

---

## 1. 插件存放位置

标准版内置插件（元信息见各插件 `config/info.php`，字段说明见[应用插件 → info.php 字段](../backend/advanced/plugin.md#configinfophp-字段说明)）：

```text
backend/plugin/
├── cms/             # CMS 内容管理（栏目/内容/单页/SEO/布局编排，付费能力经 pay 收单）
├── codegen/         # 代码生成器插件（自动生成 CRUD 前后端代码）
├── demo/            # 示例插件（调试与测试用）
├── logviewer/       # 日志查看器（runtime 日志搜索/阅读/下载）
├── pay/             # 统一支付（收单/退款/回调，领域事件解耦）
├── portal/          # 门户官网（应用市场/问答/文档/会员，系统内置不可卸载）
├── roport/          # 自动化报表（标识为 report，PDF/Excel/定时调度/邮件分发）
└── workflow/        # 工作流引擎（低代码节点编排/审批）
```

每个插件目录结构：

```text
plugin/<name>/
├── app/                 # 后端运行时代码
│   ├── adminapi/        # 后台接口（controller/validate/schema/route）
│   ├── api/             # C 端接口
│   └── dao/ model/ service/
├── config/              # 插件配置
│   └── info.php         # ⭐ 插件元信息（标识/版本/依赖/卸载策略，必填）
├── resource/            # 安装资源（模板源）
│   ├── template/        # 前端模板源（admin/web/额外端点）
│   ├── database/        # 迁移与种子
│   └── data/            # 初始数据（约定 data/menu 菜单）
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
| [代码生成](../dev-guide/codegen.md) | codegen 插件用法 |

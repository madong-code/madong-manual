# Madong 极速后台开发框架文档

Madong 是一套基于 **Webman（PHP）+ Vue 3（TypeScript）** 的前后端分离极速开发框架，后端以插件化 + 分层架构支撑业务快速迭代，前端提供 single / aura 两套管理端 UI 与独立的门户端。

## 一、文档导航

| 序号 | 板块 | 说明 | 入口 |
| --- | --- | --- | --- |
| 01 | 项目介绍 | 项目定位、技术栈、整体架构、目录总览 | [进入](guide/intro/index.md) |
| 02 | 安装指南 | 源码获取、环境要求、前后端安装、安装向导 | [进入](guide/install/index.md) |
| 03 | 前端开发 | admin 后台端、web 门户端 | [进入](guide/frontend/index.md) |
| 04 | 后端开发 | 架构分层、基础用法、进阶能力、MCP 工具 | [进入](guide/backend/index.md) |
| 05 | 二开指南 | 开发流程、新增模块、代码生成器、编码规范 | [进入](guide/dev-guide/index.md) |
| 06 | Skills | 目录索引、使用方式与自定义编写 | [进入](guide/skills/index.md) |
| 07 | 部署 | 部署总览、Nginx、进程守护、Docker | [进入](guide/deploy/index.md) |
| 08 | 常见问题 | 后端 / 前端 / 部署 FAQ | [进入](guide/faq/index.md) |
| 09 | 更新日志 | 版本记录与升级指引 | [进入](guide/changelog/index.md) |
| — | 文档站使用 | 本地预览、部署、新增文档、图片约定 | [使用文档](guide/usage.md) |

## 二、快速开始（安装）

从零跑通本地开发环境的顺序：

1. [2.1 源码获取与下载](guide/install/source.md) — 获取服务端与前端模板源码，或用 `madong-download:template` 命令下载
2. [2.2 环境要求](guide/install/environment.md) — PHP 8.2+、MySQL、Redis、Node 22+、pnpm 10+
3. [2.3 后端安装](guide/install/backend.md) — Composer 依赖、`.env` 配置、启动 8500 端口
4. [2.4 前端安装](guide/install/frontend.md) — admin（5500）/ web 两端启动
5. [2.5 安装向导](guide/install/wizard.md) — 建表、初始化数据、创建管理员

## 三、按角色推荐阅读路径

### 新成员

1. [项目概述](guide/intro/index.md)
2. [技术栈](guide/intro/tech-stack.md)
3. [整体架构](guide/intro/architecture.md)
4. [安装指南](guide/install/index.md)

### 前端开发

1. [前端总览](guide/frontend/index.md)
2. [admin 快速上手](guide/frontend/admin/getting-started.md)
3. [admin 目录结构](guide/frontend/admin/directory.md)
4. [CRUD 页面开发](guide/frontend/admin/crud.md)

### 后端开发

1. [后端总览](guide/backend/index.md)
2. [快速开始](guide/backend/getting-started/quickstart.md)
3. [架构概览](guide/backend/getting-started/architecture.md)
4. [控制器](guide/backend/basic/controller.md)

### 运维部署

1. [部署总览](guide/deploy/index.md)
2. [后端部署](guide/deploy/backend.md)
3. [Nginx 配置](guide/deploy/nginx.md)
4. [进程守护](guide/deploy/supervisor.md)

## 四、资源与图片约定

- 静态图片统一放在 `assets/img/`，按板块分子目录存放。
- 文档中用相对路径引用：`![说明](../assets/img/frontend/login-flow.png)`。
- `assets/libs/` 存放 Docsify 运行时依赖，由站点自动加载，**不要手动编辑**。
- 站点基于 Docsify 构建，`.md` 源文件直接渲染，无需打包；部署时把整个文档目录放到静态服务器即可。

---

## 五、文档维护约定

1. **一节一文件**：新增 `.md` 后同步登记 `_sidebar.md`，否则不会出现在导航中。
2. **代码即文档**：示例命令与配置项必须来自真实源码，不臆造 API。
3. **改代码同步改文档**：涉及目录结构、配置项、接口约定的改动需同步更新。
4. **图片归资源区**：图片统一放 `assets/img/`，不在文档目录散落。

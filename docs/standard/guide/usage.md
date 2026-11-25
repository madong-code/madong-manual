# 文档站使用文档

本文档说明 **Madong 文档站**本身的使用方式：如何在本地预览、如何部署到服务器（Nginx / 小皮等）、如何新增与编辑文档、以及静态资源的存放约定。

文档站基于 [Docsify](https://docsify.js.org/) 构建，**直接读取 `.md` 源文件渲染，无需打包、无需构建**。

---

## 一、目录结构

```
docs/
├── index.html            # 站点入口（Docsify 配置 + 本地依赖引用）
├── README.md             # 首页（站点自动加载）
├── _sidebar.md           # 左侧导航（Markdown 缩进表示层级）
├── _navbar.md            # 顶部导航栏
├── _coverpage.md         # 封面页
├── guide/                # 文档区（所有 .md 源）
│   ├── usage.md          # 本文档
│   ├── intro/            # 项目介绍
│   ├── install/          # 安装指南（含 2.1 源码获取与下载）
│   ├── quickstart/       # 快速开始（安装细节以 install/ 为准）
│   ├── frontend/         # 前端文档
│   ├── backend/          # 后端文档
│   ├── plugin/           # 插件开发
│   ├── dev-guide/        # 开发规范
│   ├── deploy/           # 部署运维
│   ├── faq/              # 常见问题
│   └── changelog/        # 更新日志
└── assets/               # 资源区
    ├── libs/             # Docsify 运行时依赖（JS/CSS/Prism 语言包），勿手动编辑
    ├── img/              # 静态图片，按板块分子目录存放
    └── custom.css        # 自定义样式
```

> ⚠️ 不要改动 `assets/libs/`：它是 Docsify 离线运行所需的第三方文件，站点加载时自动引用。
> 入口在根 `index.html`，文档内容在 `guide/`，**导航只需编辑 `_sidebar.md`**。

---

## 二、本地预览

Docsify 在浏览器中通过 `fetch` 读取 `.md`，因此**不能直接双击 `index.html`（`file://`）打开**——浏览器会拦截本地文件读取，表现为空白或 404。

需在 `docs/` 目录下起一个本地静态服务（任选其一，看完即可关闭，无需打包）：

```bash
# 方式 A：Python（一般系统自带）
cd path/to/madong/manual/docs/standard
python -m http.server 4000
# 浏览器打开 http://localhost:4000/

# 方式 B：Node
npx serve -l 4000 .
# 浏览器打开 http://localhost:4000/
```

此方案为**完全离线**，断网也能正常渲染（依赖已本地化在 `assets/libs/`）。

---

## 三、部署到服务器

部署即"把 `docs/` 整目录放到任意静态服务器根下"，不需要构建步骤。站点入口为 `index.html`（根目录）。

### 3.1 小皮 / phpStudy（已验证）

在「网站」中添加站点，将**网站根目录指向 `docs/`**，并将**入口/默认文档设为 `index.html`**（或在「网站目录」的默认首页里把 `index.html` 置顶）即可，访问站点地址即看到文档站。

### 3.2 Nginx

```nginx
server {
    listen 80;
    server_name docs.example.com;
    root /path/to/madong/manual/docs/standard;   # 指向文档站目录
    index index.html;

    location / {
        # Docsify 是前端路由（hash 模式），目录请求回落到入口
        try_files $uri $uri/ /index.html;
    }
}
```

如需放到子路径（如 `https://host/docs/`），把 `root` 设为 `docs/` 的上一级，并 `location /docs/ { ... }` 即可，无需改代码。

### 3.3 对象存储 / GitHub Pages

将 `docs/` 整目录上传，开启静态网站托管，入口文件设为 `index.html`。

---

## 四、新增 / 编辑文档

1. **新增一个文档**：在 `guide/` 对应板块目录新建 `.md` 文件，例如 `guide/backend/basic/cache.md`。
2. **加入导航**：编辑 `_sidebar.md`，在合适分组下加一行 `- [缓存](guide/backend/basic/cache.md)`（缩进 2 空格表示子级）。
3. **编辑内容**：直接改 `.md` 源文件，保存后刷新浏览器即生效，无需重新构建。
4. **首页**：站点加载 `README.md`，作为欢迎页与总导航。

> 文档源即 `.md` 文件，不要把转换后的 HTML 再放进仓库。
>
> 安装相关改动请同步核对 `install/` 与 `quickstart/`，以 `install/` 为权威；命令与端口以源码为准，详见 [2.1 源码获取与下载](install/source.md) 与 [2.3 后端安装](install/backend.md)。

---

## 五、静态图片约定

- **存放位置**：统一放在 `docs/assets/img/`，建议按板块分子目录，例如 `docs/assets/img/frontend/`。
- **引用方式**：在 `guide/` 下的 `.md` 中用**相对路径**引用，跨层级都不会出错：
  ```md
  ![登录流程图](../assets/img/frontend/login-flow.png)
  ```
- 不要在文档目录里散落图片文件，一律归入 `assets/img/`。

---

## 六、离线说明

- 站点所有依赖（Docsify 核心、主题、搜索、字数统计、Prism 语言包）均已本地化在 `assets/libs/`，**不依赖任何 CDN**。
- 为避免 Docsify 在语言未注册时回退到 CDN 拉取 Prism 语言包，`index.html` 中已内置插件禁用该行为（离线必需）。

---

## 七、常见问题

| 现象 | 原因 | 解决 |
| --- | --- | --- |
| 双击 `index.html` 空白 / 404 | `file://` 下浏览器禁止 `fetch` 本地 `.md` | 用「本地预览」章节的一行命令起静态服务 |
| 访问子路径 404 | 导航用了站点根路径解析 `.md` | 部署时按「三、部署」配置 `try_files` / 根目录指向 `docs/` |
| 某篇文章 404 | `_sidebar.md` 里的路径写错或文件不存在 | 检查链接路径与文件是否真实存在 |
| 搜索无结果 | 搜索索引基于已加载页面 | 先访问过对应页面，或确认 `search.paths` 配置 |

---

## 八、相关文件速查

| 文件 | 作用 |
| --- | --- |
| `index.html` | 站点入口与 Docsify 配置（根目录） |
| `_sidebar.md` | 左侧导航（Markdown 缩进表示层级） |
| `_navbar.md` | 顶部导航栏 |
| `_coverpage.md` | 封面页 |
| `README.md` | 首页与总导航 |
| `assets/libs/` | 运行时依赖（勿改） |
| `assets/img/` | 静态图片 |
| `assets/custom.css` | 自定义样式 |

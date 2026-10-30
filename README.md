<div align="center">

<img src="assets/img/logo.png" alt="Madong Logo" width="120" />

# Madong 文档中心

Madong 极速后台开发框架（Webman + Vue 3）的**多手册文档站**

[![Docsify](https://img.shields.io/badge/Docsify-2ECE6E?logo=readthedocs&logoColor=white)](https://docsify.js.org)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-自动发布-222222?logo=github&logoColor=white)](https://pages.github.com)
[![Backend](https://img.shields.io/badge/Madong-v5.1.0-2488C9)](https://github.com/madong-code/madong-admin)

**中文** | [English](./README.en.md)

</div>

Madong 极速后台开发框架（Webman + Vue 3）的多手册文档站。每个应用 / 插件是一册自包含文档（独立目录），从门户首页进入。

- 在线文档（GitHub Pages）：`https://<your-org>.github.io/<repo>/`
- 站点形态对齐 [workerman.net/doc](https://www.workerman.net/doc)：首页是手册卡片索引，每册独立。

## 目录结构

```
docs/                      # 发布根（GitHub Pages 指向此目录）
├── index.html             # 手册门户首页（卡片索引）
├── docs.json           # 手册注册表（单一事实源）
├── assets/                # 站点级共享：运行时 libs / 主题 / 门禁 / 门户脚本
├── docs/
│   ├── _template/         # 新手册脚手架（复制即用）
│   ├── standard/          # 标准版手册（单租户）
│   └── saas/              # 多租户版手册
├── AI-GUIDE.md            # 面向 AI / 贡献者：如何新增手册、追加板块
└── CONTRIBUTING.md        # 文档维护约定
```

## 本地预览

```bash
# 方式一：docsify-cli（推荐，带热更新）
npx docsify-cli serve docs

# 方式二：Python 静态服务
cd docs && python -m http.server 4000
# 浏览器访问 http://localhost:4000/
```

> 注意：Docsify 使用 hash 路由（`#/...`），直接打开 `file://` 可能因跨目录 fetch 受限，请用本地静态服务预览。

## 访问密钥

站点设有一道**前端密钥门禁**（防君子，非服务端鉴权）。门禁已由「整站单密钥」升级为**多手册 / 文档级**：

- 每册手册可在自己的 `index.html` 里用 `window.__MANUAL__.access`（对象式）声明**独立密钥策略**；
- 手册内可**排除**某些文档（设为 `public` 免密公开），其余走密钥模式，而不是整册一刀切；
- 单个文档可指定**独立密钥**（在 `rules` 里 `access:'protected'` 并指向自定义 `keyId`），实现「某几篇文档单独加密」。

密钥为前端弱校验，请勿在公开 Pages 放置敏感内容。

```js
// 手册 index.html —— 对象式门禁配置
window.__MANUAL__ = {
  id: 'standard',
  name: '标准版手册',
  homepage: 'README.md',
  access: {
    default: 'protected',     // 该手册默认模式：'public' 全册免密 / 'protected' 走密钥
    keyId: 'default',         // 默认密钥策略：'default' = 站点级共享密钥
    rules: [                  // 文档级规则，按顺序命中首个（* 单层 / ** 任意深度）
      { match: 'guide/intro/**', access: 'public' },                 // 排除：介绍整节免密
      { match: 'guide/internal/**', access: 'protected', keyId: 'vip' } // 独立密钥
    ],
    policies: {               // 手册独立密钥策略（未列则回落站点默认）
      vip: { salt: 'madong-docs', hash: '<摘要>', title: '内部资料', tip: '请输入内部资料密钥' }
    }
  }
};
DocsifyGate.bind();
```

改密钥：浏览器控制台 `await DocsifyGate.compute('新密钥')` 取默认盐摘要；自定义 `salt` 时用 `await DocsifyGate.compute('新密钥', '你的salt')`，回填对应策略的 `hash` 即可（也可本地用 PowerShell 算 SHA-256）。详见 [AI-GUIDE.md](docs/AI-GUIDE.md)。

## 新增一册手册

复制 `docs/_template/` → 改名（如 `workflow`），在 `meta.json` 填好元信息，再在 `docs.json` 注册一行即可。详见 [AI-GUIDE.md](docs/AI-GUIDE.md)。

## 发布

推送到 `main` 分支即触发 GitHub Actions 构建并发布到 Pages（见 `.github/workflows/pages.yml`）。

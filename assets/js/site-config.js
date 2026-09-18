/**
 * 站点级公共 UI 配置（品牌 / 版权 / 页脚链接）
 *
 * 放在 assets/js/ 下（与 docs-boot.js 同目录），确保 IDE 内置 webview 也能加载
 * —— 部分 webview 仅白名单 assets/ 目录，config/ 等新建目录会被 CSP 拦截。
 * docs-boot.js 启动时会读取 window.SITE_CONFIG（缺失则回退内置默认值）。
 *
 * 修改后硬刷新（Ctrl/Cmd+Shift+R）即可生效。
 */
window.SITE_CONFIG = {
  title: 'Madong',
  copyright: '© 2026 Madong 极速开发框架 · 文档由 Docsify 驱动',
  logo: '/assets/img/logo.png', // 留空则使用文字 Logo "M"
  footerLinks: [
    { text: '文档中心', url: '/' },
    { text: '使用文档', url: '/使用文档.html' },
    { text: 'GitHub',  url: 'https://github.com/madong-code',  target: '_blank' },
    { text: 'Gitee',   url: 'https://gitee.com/motion-code',   target: '_blank' },
    { text: 'GitCode', url: 'https://gitcode.com/motion-code', target: '_blank' }
  ],

  // 百度统计（hm.baidu.com）：开发/预览请保持 enabled=false，上线前填 id 再打开
  analytics: {
    baidu: {
      enabled: false,       // 总开关
      id: '',               // 百度统计站点 ID（hm.js? 后那串）
      trackSpaRoutes: true, // 上报 SPA 路由切换（docsify hash 路由必须开）
      hosts: []             // 生效域名白名单，留空=不限制；如 ['example.com', '.example.com']
    }
  }
};

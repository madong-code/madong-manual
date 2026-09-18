/**
 * 可定义顶部导航栏：读取 nav.json 渲染顶栏（sticky 玻璃风）。
 *
 * - 数据源：manual/nav.json（与 docs.json 解耦，单一事实源）
 * - 支持：普通链接 / 外链(external) / 下拉弹窗(dropdown) / 右侧 CTA(actions) / 工具(tools: theme,search)
 * - 资源根反推：通过本脚本自身的 src 反推 manual 根目录，
 *   因此 index.html(根) 与 pages/*.html(子目录) 都能正确加载 nav.json / assets，
 *   天然兼容 GitHub Pages 子路径部署与目录分层。
 * - 主题切换复用 theme.js 的键：localStorage['madong.docs.theme'] = { mode, color }
 *
 * 引入方式（在 <head> 或 <body> 顶部，且需先引入 site-config.js）：
 *   <script src="assets/js/site-config.js"></script>
 *   <script src="assets/js/navbar.js"></script>
 */
(function () {
  'use strict';

  /* ---------- 资源根反推 ---------- */
  function getBase() {
    var scripts = document.getElementsByTagName('script');
    for (var i = 0; i < scripts.length; i++) {
      var s = scripts[i].src || '';
      var m = s.match(/(.*\/)assets\/js\/navbar\.js(?:\?.*)?$/);
      if (m) return m[1]; // 例："/manual/" 或 "http://h/manual/"
    }
    return './';
  }
  var BASE = getBase();

  function withBase(u) {
    if (!u) return u;
    if (/^(https?:)?\/\//i.test(u)) return u; // 外链原样
    if (u.charAt(0) === '/') u = u.slice(1);  // 去前导斜杠，配合 BASE 兼容子路径部署
    return BASE + u;
  }

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  /* ---------- 主题（状态全部来自共享引擎 MadongTheme，门户不另存一份） ---------- */
  var Theme = window.MadongTheme || {
    getPref: function () { return { mode: 'light', color: 'blue' }; },
    toggleMode: function () {},
    setColor: function () {},
    ensureDefault: function () {},
    subscribe: function () {}
  };
  function syncColorDots() {
    var active = Theme.getPref().color || 'blue';
    document.querySelectorAll('.theme-switch__dot').forEach(function (dot) {
      dot.classList.toggle('active', dot.getAttribute('data-color') === active);
    });
  }

  /* ---------- 链接渲染 ---------- */
  function linkAttrs(item) {
    var ext = item.external || /^(https?:)?\/\//i.test(item.url || '');
    var href = withBase(item.url);
    var a = ' href="' + esc(href) + '"';
    if (ext) a += ' target="_blank" rel="noopener noreferrer"';
    return { ext: ext, html: a };
  }

  function renderLink(item) {
    var la = linkAttrs(item);
    var cls = 'nav__link';
    if (item.primary) cls += ' nav__link--primary';
    var label = esc(item.text);
    if (la.ext) label += ' <span class="nav__ext" aria-hidden="true">↗</span>';
    return '<a class="' + cls + '"' + la.html + '>' + label + '</a>';
  }

  function renderAction(item) {
    var la = linkAttrs(item);
    var cls = 'nav__action' + (item.primary ? ' nav__action--primary' : '');
    var label = esc(item.text);
    if (la.ext) label += ' <span class="nav__ext" aria-hidden="true">↗</span>';
    return '<a class="' + cls + '"' + la.html + '>' + label + '</a>';
  }

  function renderDrop(item) {
    var items = (item.items || []).map(function (it) {
      var la = linkAttrs(it);
      var desc = it.desc ? '<span class="nav__drop-desc">' + esc(it.desc) + '</span>' : '';
      var label = esc(it.text);
      if (la.ext) label += ' <span class="nav__ext" aria-hidden="true">↗</span>';
      return '<a class="nav__drop-item"' + la.html + '>' +
        '<span class="nav__drop-name">' + label + '</span>' + desc + '</a>';
    }).join('');
    return '' +
      '<div class="nav__drop">' +
      '  <button class="nav__link nav__drop-toggle" type="button" aria-haspopup="true" aria-expanded="false">' +
      esc(item.text) + ' <span class="nav__caret" aria-hidden="true">▾</span></button>' +
      '  <div class="nav__drop-menu" role="menu">' + items + '</div>' +
      '</div>';
  }

  /* ---------- 工具（主题 / 搜索） ---------- */
  var SVG = {
    sun: '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><line x1="12" y1="2" x2="12" y2="4"/><line x1="12" y1="20" x2="12" y2="22"/><line x1="4.93" y1="4.93" x2="6.34" y2="6.34"/><line x1="17.66" y1="17.66" x2="19.07" y2="19.07"/><line x1="2" y1="12" x2="4" y2="12"/><line x1="20" y1="12" x2="22" y2="12"/><line x1="4.93" y1="19.07" x2="6.34" y2="17.66"/><line x1="17.66" y1="6.34" x2="19.07" y2="4.93"/></svg>',
    moon: '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>',
    search: '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>',
    palette: '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 2a10 10 0 1 0 0 20c.8 0 1.5-.7 1.5-1.5 0-.4-.2-.8-.4-1.1-.3-.3-.4-.7-.4-1.1 0-.8.7-1.5 1.5-1.5h2c3 0 5.3-2.4 5.3-5.3C21.5 6 17.2 2 12 2z"/><circle cx="7" cy="11" r="1" fill="currentColor"/><circle cx="9" cy="7" r="1" fill="currentColor"/><circle cx="14" cy="6" r="1" fill="currentColor"/><circle cx="18" cy="10" r="1" fill="currentColor"/></svg>',
    menu: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>',
    close: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>'
  };

  var COLOR_OPTIONS = [
    { key: 'blue',  hex: '#2f6bff' },
    { key: 'green', hex: '#1e9e63' },
    { key: 'purple', hex: '#7c4dff' },
    { key: 'orange', hex: '#e8841e' },
    { key: 'teal',  hex: '#14a3a3' }
  ];

  function renderThemePopover() {
    var dots = COLOR_OPTIONS.map(function (c) {
      return '<button class="theme-switch__dot" type="button" data-color="' + c.key + '" title="' + c.key + '" aria-label="主题色 ' + c.key + '" style="--dot:' + c.hex + '"></button>';
    }).join('');
    return '' +
      '<div class="theme-switch__panel nav__theme-popover" role="dialog" aria-label="主题设置" hidden>' +
      '  <div class="theme-switch__section">' +
      '    <div class="theme-switch__label">主题色</div>' +
      '    <div class="theme-switch__colors">' + dots + '</div>' +
      '  </div>' +
      '  <div class="theme-switch__section">' +
      '    <div class="theme-switch__label">外观</div>' +
      '    <button class="theme-switch__mode" type="button" title="切换深色 / 浅色" aria-label="切换深色 / 浅色">' + SVG.sun + '</button>' +
      '  </div>' +
      '</div>';
  }

  function renderTools(tools) {
    if (!tools || !tools.length) return '';
    var html = '<div class="nav__tools">';
    tools.forEach(function (t) {
      if (t === 'theme' || (t && t.type === 'theme')) {
        html += '<button class="nav__tool nav__palette" type="button" title="主题" aria-label="主题">' + SVG.palette + '</button>';
        html += renderThemePopover();
      } else if (t === 'search' || (t && t.type === 'search')) {
        html += '<button class="nav__tool nav__search-btn" type="button" title="搜索" aria-label="搜索">' + SVG.search + '</button>';
      }
    });
    html += '</div>';
    return html;
  }

  /* ---------- 页脚（复用 SITE_CONFIG） ---------- */
  function renderFooter() {
    var mount = document.getElementById('site-footer');
    if (!mount) return;
    var cfg = window.SITE_CONFIG || {};
    var copy = cfg.copyright || '© ' + new Date().getFullYear() + ' Madong';
    var links = (cfg.footerLinks || []).map(function (l) {
      var ext = /^(https?:)?\/\//i.test(l.url || '');
      var a = ' href="' + esc(l.url) + '"';
      if (ext) a += ' target="_blank" rel="noopener noreferrer"';
      var label = esc(l.text) + (ext ? ' <span class="nav__ext" aria-hidden="true">↗</span>' : '');
      return '<a' + a + '>' + label + '</a>';
    }).join('');
    mount.innerHTML =
      '<div class="site-footer__inner">' +
      '  <span class="site-footer__copy">' + esc(copy) + '</span>' +
      '  <span class="site-footer__links">' + links + '</span>' +
      '</div>';
  }

  /* ---------- 主渲染 ---------- */
  function render(cfg) {
    var header = document.createElement('header');
    header.className = 'nav';
    header.id = 'site-nav';

    var brand = cfg.brand || {};
    var logoSrc = brand.logo ? withBase(brand.logo) : '';
    if (!logoSrc && window.SITE_CONFIG && window.SITE_CONFIG.logo) {
      logoSrc = withBase(window.SITE_CONFIG.logo);
    }
    var mark = logoSrc
      ? '<img class="nav__brand-img" src="' + esc(logoSrc) + '" alt="" ' +
        'onerror="this.style.display=\'none\';this.parentNode.classList.add(\'nav__brand-mark--fallback\')" />'
      : '';
    var brandHtml = '<a class="nav__brand" href="' + esc(withBase(brand.url || 'index.html')) + '">' +
      '<span class="nav__brand-mark">' + mark + '<span class="nav__brand-initial">' + esc((brand.text || 'M').charAt(0)) + '</span></span>' +
      '<span class="nav__brand-text">' + esc(brand.text || 'Madong') + '</span></a>';

    var navHtml = (cfg.nav || []).map(function (item) {
      if (item.type === 'dropdown') return renderDrop(item);
      return renderLink(item);
    }).join('');

    var actionsHtml = (cfg.actions || []).map(renderAction).join('');
    var toolsHtml = renderTools(cfg.tools);

    header.innerHTML =
      '<div class="nav__inner">' +
      '  ' + brandHtml +
      '  <nav class="nav__links" aria-label="主导航">' + navHtml + '</nav>' +
      '  <div class="nav__right">' + actionsHtml + toolsHtml +
      '    <button class="nav__tool nav__burger" type="button" aria-label="菜单">' + SVG.menu + '</button>' +
      '  </div>' +
      '  <div class="nav__search" hidden>' +
      '    <input class="nav__search-input" type="search" placeholder="搜索手册、指南…（回车前往文档中心）" aria-label="搜索" />' +
      '  </div>' +
      '</div>' +
      '<div class="nav__drawer" hidden></div>';

    // 插入到 body 顶部
    document.body.insertBefore(header, document.body.firstChild);

    bindEvents(header, cfg);
    renderFooter();
    // 门户默认：浅色 + 蓝；仅当没有已保存偏好时才生效（共享引擎负责持久化）
    Theme.ensureDefault({ mode: 'light', color: 'blue' });
    syncColorDots();
  }

  /* ---------- 交互 ---------- */
  function bindEvents(header, cfg) {
    // 下拉弹窗：click 切换，外点关闭
    header.querySelectorAll('.nav__drop-toggle').forEach(function (btn) {
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        var drop = btn.parentNode;
        var open = drop.classList.toggle('open');
        btn.setAttribute('aria-expanded', open ? 'true' : 'false');
      });
    });
    // 移动端抽屉
    var burger = header.querySelector('.nav__burger');
    var drawer = header.querySelector('.nav__drawer');
    burger.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      var open = drawer.hasAttribute('hidden');
      if (open) {
        buildDrawer(drawer, cfg);
        drawer.removeAttribute('hidden');
        header.classList.add('nav--drawer-open');
      } else {
        drawer.setAttribute('hidden', '');
        header.classList.remove('nav--drawer-open');
      }
    });
    // 搜索展开
    var searchBtn = header.querySelector('.nav__search-btn');
    var searchBox = header.querySelector('.nav__search');
    var searchInput = header.querySelector('.nav__search-input');
    searchBtn.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      var open = searchBox.hasAttribute('hidden');
      if (themePop) themePop.hidden = true;
      if (open) {
        searchBox.removeAttribute('hidden');
        setTimeout(function () { searchInput.focus(); }, 30);
      } else {
        searchBox.setAttribute('hidden', '');
      }
    });
    searchInput.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') {
        var q = encodeURIComponent(searchInput.value.trim());
        var url = withBase('pages/portal.html') + (q ? ('?q=' + q) : '');
        window.location.href = url;
      }
    });
    // 主题设置弹窗（主题色 + 外观）—— 交互委托给共享引擎 MadongTheme
    var paletteBtn = header.querySelector('.nav__palette');
    var themePop = header.querySelector('.nav__theme-popover');
    var modeBtn = header.querySelector('.theme-switch__mode');
    if (paletteBtn && themePop) {
      paletteBtn.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        var open = themePop.hasAttribute('hidden');
        if (!searchBox.hasAttribute('hidden')) searchBox.setAttribute('hidden', '');
        themePop.hidden = !open;
      });
      themePop.querySelectorAll('.theme-switch__dot').forEach(function (dot) {
        dot.addEventListener('click', function (e) {
          e.preventDefault();
          e.stopPropagation();
          Theme.setColor(dot.getAttribute('data-color'));
        });
      });
    }
    function syncModeIcon() {
      if (!modeBtn) return;
      // 与文档导航栏保持一致：显示当前模式（深色=月亮 / 浅色=太阳）
      modeBtn.innerHTML = Theme.getPref().mode === 'dark' ? SVG.moon : SVG.sun;
    }
    syncModeIcon();
    if (modeBtn) {
      modeBtn.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        Theme.toggleMode();
        syncModeIcon();
      });
    }
    // 跨标签页 / 其他页面改动主题时，同步本页 UI
    Theme.subscribe(function () { syncColorDots(); syncModeIcon(); });

    // 全局：点外面关闭下拉 / 抽屉 / 搜索
    document.addEventListener('click', function (e) {
      if (!header.contains(e.target)) {
        header.querySelectorAll('.nav__drop.open').forEach(function (d) {
          d.classList.remove('open');
          var t = d.querySelector('.nav__drop-toggle');
          if (t) t.setAttribute('aria-expanded', 'false');
        });
        if (!drawer.hasAttribute('hidden')) { drawer.setAttribute('hidden', ''); header.classList.remove('nav--drawer-open'); }
        if (!searchBox.hasAttribute('hidden')) searchBox.setAttribute('hidden', '');
        if (themePop && !themePop.hasAttribute('hidden')) themePop.hidden = true;
      }
    });

    // 滚动：导航栏收缩
    var ticking = false;
    window.addEventListener('scroll', function () {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(function () {
        header.classList.toggle('nav--scrolled', window.scrollY > 12);
        ticking = false;
      });
    }, { passive: true });
  }

  function buildDrawer(drawer, cfg) {
    var html = '';
    (cfg.nav || []).forEach(function (item) {
      if (item.type === 'dropdown') {
        var sub = (item.items || []).map(function (it) {
          var la = linkAttrs(it);
          return '<a class="nav__drawer-item" ' + la.html + '>' + esc(it.text) + '</a>';
        }).join('');
        html += '<div class="nav__drawer-group"><div class="nav__drawer-title">' + esc(item.text) + '</div>' + sub + '</div>';
      } else {
        var la = linkAttrs(item);
        html += '<a class="nav__drawer-item" ' + la.html + '>' + esc(item.text) + '</a>';
      }
    });
    if (cfg.actions && cfg.actions.length) {
      html += '<div class="nav__drawer-actions">' +
        cfg.actions.map(function (a) {
          var la = linkAttrs(a);
          return '<a class="nav__action ' + (a.primary ? 'nav__action--primary' : '') + '" ' + la.html + '>' + esc(a.text) + '</a>';
        }).join('') + '</div>';
    }
    drawer.innerHTML = html;
  }

  /* ---------- 启动 ---------- */
  function init() {
    fetch(withBase('nav.json'), { cache: 'no-store' })
      .then(function (r) { return r.json(); })
      .then(function (cfg) { render(cfg); })
      .catch(function () {
        // 兜底：即便 nav.json 拉取失败，也渲染一个最小品牌顶栏
        render({ brand: { text: 'Madong', url: 'index.html' }, nav: [], actions: [], tools: [] });
      });
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();

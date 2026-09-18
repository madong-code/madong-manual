/**
 * 手册主题系统：深/浅主题 + 多品牌色
 * ------------------------------------------------------------------
 * - 偏好持久化到 localStorage（madong.docs.theme = { mode, color }）
 * - 通过 <html data-theme="dark|light" data-color="blue|..."> 控制样式
 * - 切换器：顶栏触发按钮 + body 级 portal 面板（分「主题色」「外观」两区）
 *   面板挂到 document.body 并 position:fixed，避免被右侧 TOC（z-index:40）盖住
 *
 * 引入位置：手册 index.html 中，docs-boot.js 之后、docsify.min.js 之前。
 */
(function () {
  // 主题状态全部来自共享引擎 MadongTheme（theme-core.js），文档侧不另存一份
  var Theme = window.MadongTheme || {
    getPref: function () { return { mode: 'dark', color: 'blue' }; },
    toggleMode: function () {}, setColor: function () {},
    ensureDefault: function () {}, subscribe: function () {}
  };
  // 仅用于渲染色点 UI（key + 展示色）
  var COLORS = [
    { key: 'blue',   dot: '#2f6bff' },
    { key: 'green',  dot: '#1e9e63' },
    { key: 'purple', dot: '#7c4dff' },
    { key: 'orange', dot: '#e8841e' },
    { key: 'teal',   dot: '#14a3a3' }
  ];

  var SVG = {
    palette: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 2a10 10 0 1 0 0 20c.8 0 1.5-.7 1.5-1.5 0-.4-.2-.8-.4-1.1-.3-.3-.4-.7-.4-1.1 0-.8.7-1.5 1.5-1.5h2c3 0 5.3-2.4 5.3-5.3C21.5 6 17.2 2 12 2z"/><circle cx="7"  cy="11" r="1" fill="currentColor"/><circle cx="9"  cy="7"  r="1" fill="currentColor"/><circle cx="14" cy="6"  r="1" fill="currentColor"/><circle cx="18" cy="10" r="1" fill="currentColor"/></svg>',
    moon:    '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>',
    sun:     '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><line x1="12" y1="2"  x2="12" y2="4"/><line x1="12" y1="20" x2="12" y2="22"/><line x1="4.93"  y1="4.93"  x2="6.34"  y2="6.34"/><line x1="17.66" y1="17.66" x2="19.07" y2="19.07"/><line x1="2"  y1="12" x2="4"  y2="12"/><line x1="20" y1="12" x2="22" y2="12"/><line x1="4.93"  y1="19.07" x2="6.34"  y2="17.66"/><line x1="17.66" y1="6.34"  x2="19.07" y2="4.93"/></svg>'
  };

  // ---- 面板（body portal） ----
  var panelEl = null;

  function buildPanel() {
    var panel = document.createElement('div');
    panel.className = 'theme-switch__panel';

    // 主题色区块
    var sec1 = document.createElement('div');
    sec1.className = 'theme-switch__section';
    var lbl1 = document.createElement('div');
    lbl1.className = 'theme-switch__label';
    lbl1.textContent = '主题色';
    var colors = document.createElement('div');
    colors.className = 'theme-switch__colors';
    COLORS.forEach(function (c) {
      var dot = document.createElement('button');
      dot.type = 'button';
      dot.className = 'theme-switch__dot';
      dot.dataset.color = c.key;
      dot.title = c.key + ' 主题色';
      dot.style.setProperty('--dot', c.dot);
      dot.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        Theme.setColor(c.key);
        syncUI();
      });
      colors.appendChild(dot);
    });
    sec1.appendChild(lbl1);
    sec1.appendChild(colors);

    // 外观区块
    var sec2 = document.createElement('div');
    sec2.className = 'theme-switch__section';
    var lbl2 = document.createElement('div');
    lbl2.className = 'theme-switch__label';
    lbl2.textContent = '外观';
    var modeBtn = document.createElement('button');
    modeBtn.type = 'button';
    modeBtn.className = 'theme-switch__mode';
    modeBtn.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      Theme.toggleMode();
      syncUI();
    });
    sec2.appendChild(lbl2);
    sec2.appendChild(modeBtn);

    panel.appendChild(sec1);
    panel.appendChild(sec2);
    return panel;
  }

  function ensurePanel() {
    if (panelEl && panelEl.parentNode === document.body) return panelEl;
    panelEl = buildPanel();
    document.body.appendChild(panelEl);
    return panelEl;
  }

  function positionPanel() {
    var trigger = document.querySelector('.theme-switch__trigger');
    if (!trigger) return;
    var panel = ensurePanel();
    // 临时可见以便读取尺寸
    var prevVis = panel.style.visibility;
    var prevDisp = panel.style.display;
    if (prevDisp === 'none') {
      panel.style.visibility = 'hidden';
      panel.style.display = 'block';
    }
    var rect = trigger.getBoundingClientRect();
    var panelW = panel.offsetWidth;
    var panelH = panel.offsetHeight;
    var top = rect.bottom + 10;
    var right = window.innerWidth - rect.right;
    // 视口内边距保护
    if (right < 8) right = 8;
    if (right + panelW > window.innerWidth - 8) {
      right = Math.max(8, window.innerWidth - 8 - panelW);
    }
    // 底部空间不够则翻到触发按钮上方
    if (top + panelH > window.innerHeight - 8) {
      top = rect.top - panelH - 10;
      if (top < 8) top = 8;
    }
    panel.style.top = top + 'px';
    panel.style.right = right + 'px';
    // 恢复可见性
    if (prevDisp === 'none') {
      panel.style.visibility = prevVis;
    }
  }

  function openPanel() {
    var li = document.getElementById('theme-switch');
    if (!li) return;
    ensurePanel();
    syncUI();
    panelEl.style.display = 'block';
    positionPanel();
    li.classList.add('open');
  }

  function closePanel() {
    var li = document.getElementById('theme-switch');
    if (li) li.classList.remove('open');
    if (panelEl) panelEl.style.display = 'none';
  }

  function syncUI() {
    if (!panelEl) return;
    var pref = Theme.getPref();
    var modeBtn = panelEl.querySelector('.theme-switch__mode');
    if (modeBtn) {
      modeBtn.innerHTML = pref.mode === 'dark' ? SVG.moon : SVG.sun;
      modeBtn.title = pref.mode === 'dark' ? '当前深色，点击切换深/浅' : '当前浅色，点击切换深/浅';
    }
    panelEl.querySelectorAll('.theme-switch__dot').forEach(function (d) {
      d.classList.toggle('active', d.dataset.color === pref.color);
    });
  }

  // ---- 顶栏触发按钮 ----
  function buildTrigger() {
    var li = document.createElement('li');
    li.className = 'theme-switch';
    li.id = 'theme-switch';

    var trigger = document.createElement('button');
    trigger.type = 'button';
    trigger.className = 'theme-switch__trigger';
    trigger.title = '主题设置';
    trigger.innerHTML = SVG.palette;
    trigger.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      var li2 = document.getElementById('theme-switch');
      if (li2 && li2.classList.contains('open')) closePanel();
      else openPanel();
    });

    li.appendChild(trigger);
    return li;
  }

  function inject() {
    if (document.getElementById('theme-switch')) {
      syncUI();
      return;
    }
    var ul = document.querySelector('.app-nav > ul');
    if (!ul) return;
    ul.appendChild(buildTrigger());
    syncUI();
  }

  // ---- 全局事件：点外面关闭 / 滚动关闭 / resize 重定位 ----
  if (!window.__themeSwitchGlobalBound) {
    window.__themeSwitchGlobalBound = true;
    document.addEventListener('click', function (e) {
      var li = document.getElementById('theme-switch');
      if (!li || !li.classList.contains('open')) return;
      var trigger = li.querySelector('.theme-switch__trigger');
      if (trigger && trigger.contains(e.target)) return;
      if (panelEl && panelEl.contains(e.target)) return;
      closePanel();
    });
    window.addEventListener('scroll', function () {
      var li = document.getElementById('theme-switch');
      if (li && li.classList.contains('open')) closePanel();
    }, { passive: true });
    window.addEventListener('resize', function () {
      var li = document.getElementById('theme-switch');
      if (li && li.classList.contains('open')) positionPanel();
    });
  }

  // ---- 注册到 Docsify ----
  function registerDocsify() {
    if (!window.$docsify) return false;
    if (!window.$docsify.plugins) window.$docsify.plugins = [];
    window.$docsify.plugins.push(function (hook) {
      hook.mounted(function () { inject(); });
      hook.doneEach(function () { inject(); });
    });
    return true;
  }

  if (!registerDocsify()) {
    var tries = 0;
    var timer = setInterval(function () {
      inject();
      if (document.getElementById('theme-switch') || tries++ > 50) clearInterval(timer);
    }, 150);
  }

  // 跨标签页 / 门户改动主题时，同步本页 UI
  Theme.subscribe(function () { syncUI(); });

  // 文档默认：深色 + 蓝；仅当没有已保存偏好时才生效（共享引擎负责持久化）
  Theme.ensureDefault({ mode: 'dark', color: 'blue' });
})();

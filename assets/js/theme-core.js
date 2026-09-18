/**
 * 共享主题引擎（门户 portal 与 文档 docs 唯一主题状态来源）
 * ------------------------------------------------------------------
 * - 偏好持久化到 localStorage：madong.docs.theme = { mode, color }
 * - 通过 <html data-theme="dark|light" data-color="blue|..."> 控制样式
 * - 暴露 window.MadongTheme，供门户(navbar.js)与文档(theme.js)调用
 * - 脚本同步执行即应用已保存偏好，避免首屏闪烁
 * - 默认模式/颜色由各自站点在 control 层通过 ensureDefault() 决定，
 *   本文件不硬编码任何站点默认值，保证门户与文档控制相互隔离。
 *
 * 引入位置：需在 navbar.js / theme.js 之前加载（建议放在 <head>）。
 */
(function () {
  'use strict';

  var STORE_KEY = 'madong.docs.theme';
  var MODES = ['dark', 'light'];
  var COLORS = ['blue', 'green', 'purple', 'orange', 'teal'];

  function read() {
    var p = { mode: '', color: '' };
    try {
      var t = JSON.parse(localStorage.getItem(STORE_KEY) || '{}') || {};
      if (MODES.indexOf(t.mode) !== -1) p.mode = t.mode;
      if (COLORS.indexOf(t.color) !== -1) p.color = t.color;
    } catch (e) {}
    return p;
  }

  var pref = read();

  function apply(p) {
    var r = document.documentElement;
    if (p.mode) r.setAttribute('data-theme', p.mode);
    if (p.color) r.setAttribute('data-color', p.color);
  }
  apply(pref);

  var subs = [];
  function persist() {
    try { localStorage.setItem(STORE_KEY, JSON.stringify(pref)); } catch (e) {}
    apply(pref);
    subs.forEach(function (fn) { try { fn(pref); } catch (e) {} });
  }

  function setMode(mode) {
    if (MODES.indexOf(mode) === -1) return;
    pref.mode = mode;
    persist();
  }
  function toggleMode() {
    setMode(pref.mode === 'dark' ? 'light' : 'dark');
  }
  function setColor(color) {
    if (COLORS.indexOf(color) === -1) return;
    pref.color = color;
    persist();
  }
  // 仅当尚未保存过偏好时写入站点默认值（门户/文档各自不同）
  function ensureDefault(def) {
    var changed = false;
    if (!pref.mode && def && MODES.indexOf(def.mode) !== -1) { pref.mode = def.mode; changed = true; }
    if (!pref.color && def && COLORS.indexOf(def.color) !== -1) { pref.color = def.color; changed = true; }
    if (changed) persist();
  }
  function subscribe(fn) {
    if (typeof fn === 'function') subs.push(fn);
  }

  // 跨标签页同步
  window.addEventListener('storage', function (e) {
    if (e.key !== STORE_KEY || !e.newValue) return;
    try {
      var t = JSON.parse(e.newValue) || {};
      if (MODES.indexOf(t.mode) !== -1) pref.mode = t.mode;
      if (COLORS.indexOf(t.color) !== -1) pref.color = t.color;
      apply(pref);
      subs.forEach(function (fn) { try { fn(pref); } catch (err) {} });
    } catch (err) {}
  });

  window.MadongTheme = {
    STORE_KEY: STORE_KEY,
    MODES: MODES,
    COLORS: COLORS,
    getPref: function () { return { mode: pref.mode, color: pref.color }; },
    setMode: setMode,
    toggleMode: toggleMode,
    setColor: setColor,
    ensureDefault: ensureDefault,
    subscribe: subscribe
  };
})();

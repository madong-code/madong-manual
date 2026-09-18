/**
 * 文档中心：读取 docs.json 渲染手册卡片
 * - 按 type 分组（应用手册 / 插件手册）
 * - 支持名称/描述/标签搜索 + 状态筛选
 * - 无 JS / fetch 失败时由 #portal-fallback 兜底
 *
 * 资源根反推：通过本脚本自身 src 反推 manual 根目录，
 * 因此放在 pages/ 子目录或子路径部署时也能正确加载 docs.json 与卡片链接。
 */
(function () {
  var TYPE_LABEL = { app: '应用手册', plugin: '插件手册', guide: '指南' };
  var STATUS_LABEL = { active: '在用', wip: '建设中', deprecated: '已废弃' };
  var state = { kw: '', status: 'all' };

  function el(id) { return document.getElementById(id); }

  /* 资源根反推（与 navbar.js 同源策略） */
  function getBase() {
    var scripts = document.getElementsByTagName('script');
    for (var i = 0; i < scripts.length; i++) {
      var s = scripts[i].src || '';
      var m = s.match(/(.*\/)assets\/js\/portal\.js(?:\?.*)?$/);
      if (m) return m[1];
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

  function badge(status) {
    var cls = { active: 'badge--active', wip: 'badge--wip', deprecated: 'badge--deprecated' }[status] || 'badge--deprecated';
    return '<span class="badge ' + cls + '">' + (STATUS_LABEL[status] || status) + '</span>';
  }

  function card(m) {
    var tags = (m.tags || []).map(function (t) { return '<span class="card__tag">' + esc(t) + '</span>'; }).join('');
    var icon = (m.name || '?').trim().charAt(0);
    return '' +
      '<a class="card" href="' + withBase(m.entry) + '" data-name="' + esc(m.name) + '" data-desc="' + esc(m.desc || '') + '" data-tags="' + esc((m.tags || []).join(' ')) + '" data-status="' + (m.status || '') + '">' +
      '  <div class="card__head">' +
      '    <div class="card__icon">' + esc(icon) + '</div>' +
      '    <div>' +
      '      <div class="card__name">' + esc(m.name) + '</div>' +
      '      <div class="card__meta">' + badge(m.status) + '<span class="badge badge--ver">' + esc(m.version || '') + '</span></div>' +
      '    </div>' +
      '  </div>' +
      '  <div class="card__desc">' + esc(m.desc || '') + '</div>' +
      '  <div class="card__tags">' + tags + '</div>' +
      '  <span class="card__enter">进入手册 <span class="arrow">→</span></span>' +
      '</a>';
  }

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  function render(list) {
    var groups = {};
    (list || []).forEach(function (m) {
      var t = m.type || 'guide';
      (groups[t] = groups[t] || []).push(m);
    });
    var html = '';
    Object.keys(groups).forEach(function (t) {
      html += '<section class="portal__group" data-group="' + t + '">' +
        '<h2 class="portal__group-title">' + (TYPE_LABEL[t] || t) + '</h2>' +
        '<div class="portal__grid">' + groups[t].map(card).join('') + '</div></section>';
    });
    var mount = el('portal-mount');
    mount.innerHTML = html || '<p style="color:#8a93a6">暂无手册</p>';
    applyFilter();
  }

  function applyFilter() {
    var cards = document.querySelectorAll('#portal-mount .card');
    cards.forEach(function (c) {
      var hay = (c.dataset.name + ' ' + c.dataset.desc + ' ' + c.dataset.tags).toLowerCase();
      var okKw = !state.kw || hay.indexOf(state.kw.toLowerCase()) !== -1;
      var okSt = state.status === 'all' || c.dataset.status === state.status;
      c.style.display = (okKw && okSt) ? '' : 'none';
    });
    document.querySelectorAll('#portal-mount .portal__group').forEach(function (g) {
      var any = [].slice.call(g.querySelectorAll('.card')).some(function (c) { return c.style.display !== 'none'; });
      g.style.display = any ? '' : 'none';
    });
  }

  function bindControls() {
    var search = el('portal-search');
    if (search) search.addEventListener('input', function () { state.kw = search.value; applyFilter(); });
    document.querySelectorAll('.portal__chip').forEach(function (chip) {
      chip.addEventListener('click', function () {
        document.querySelectorAll('.portal__chip').forEach(function (c) { c.classList.remove('active'); });
        chip.classList.add('active');
        state.status = chip.dataset.status;
        applyFilter();
      });
    });
  }

  function init() {
    var fb = el('portal-fallback');
    if (fb) fb.style.display = 'none';

    // 支持从导航搜索带 ?q= 预填
    try {
      var q = new URLSearchParams(location.search).get('q');
      if (q) {
        var box = el('portal-search');
        if (box) { box.value = q; state.kw = q; }
      }
    } catch (e) {}

    fetch(withBase('docs.json'), { cache: 'no-store' })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        render(data.docs || []);
        bindControls();
      })
      .catch(function () {
        if (fb) fb.style.display = '';
      });
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();

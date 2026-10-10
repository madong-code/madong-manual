# Madong Documentation Center

The **multi-manual documentation site** for the Madong rapid admin framework (Webman + Vue 3). Each application / plugin is a self-contained manual (its own directory), entered from the portal homepage.

- Online docs (GitHub Pages): `https://<your-org>.github.io/<repo>/`
- Site shape aligns with [workerman.net/doc](https://www.workerman.net/doc): the homepage is a card index of manuals, each manual is independent.

## Directory Structure

```
docs/                      # Publish root (GitHub Pages points here)
├── index.html             # Manual portal homepage (card index)
├── docs.json              # Manual registry (single source of truth)
├── assets/                # Site-wide shared: runtime libs / theme / gate / portal scripts
├── docs/
│   ├── _template/         # New manual scaffold (copy and use)
│   ├── standard/          # Standard edition manual (single-tenant)
│   └── saas/              # Multi-tenant (SaaS) edition manual
├── AI-GUIDE.md            # For AI / contributors: how to add a manual or append a section
└── CONTRIBUTING.md        # Documentation maintenance conventions
```

## Local Preview

```bash
# Option 1: docsify-cli (recommended, with hot reload)
npx docsify-cli serve docs

# Option 2: Python static server
cd docs && python -m http.server 4000
# Open http://localhost:4000/ in the browser
```

> Note: Docsify uses hash routing (`#/...`). Opening `file://` directly may be blocked by cross-directory fetch restrictions — use a local static server for preview.

## Access Keys

The site has a **front-end key gate** (to deter casual access, not server-side authentication). The gate has been upgraded from a "single site-wide key" to a **per-manual / per-document** model:

- Each manual can declare its **own key policy** via `window.__MANUAL__.access` (object form) in its `index.html`;
- Documents inside a manual can be **excluded** (set to `public`, no key required), while the rest use the key mode — instead of a blanket rule for the whole manual;
- A single document can specify an **independent key** (set `access:'protected'` in `rules` and point to a custom `keyId`), achieving "encrypt only a few documents".

The key is a weak front-end check; do not put sensitive content on a public Pages site.

```js
// Manual index.html —— object-style gate config
window.__MANUAL__ = {
  id: 'standard',
  name: 'Standard Edition Manual',
  homepage: 'README.md',
  access: {
    default: 'protected',     // Default mode for this manual: 'public' = whole manual open / 'protected' = key required
    keyId: 'default',         // Default key policy: 'default' = site-wide shared key
    rules: [                  // Document-level rules, first match wins (* single level / ** any depth)
      { match: 'guide/intro/**', access: 'public' },                 // Exclude: whole intro section open
      { match: 'guide/internal/**', access: 'protected', keyId: 'vip' } // Independent key
    ],
    policies: {               // Manual-specific key policies (falls back to site default if not listed)
      vip: { salt: 'madong-docs', hash: '<digest>', title: 'Internal', tip: 'Enter the internal key' }
    }
  }
};
DocsifyGate.bind();
```

Change a key: in the browser console run `await DocsifyGate.compute('new-key')` to get the default-salt digest; when using a custom `salt`, use `await DocsifyGate.compute('new-key', 'your-salt')` and paste the result into the corresponding policy's `hash` (you can also compute SHA-256 locally with PowerShell). See [AI-GUIDE.md](docs/AI-GUIDE.md).

## Add a New Manual

Copy `docs/_template/` → rename (e.g. `workflow`), fill in the meta in `meta.json`, then register one line in `docs.json`. See [AI-GUIDE.md](docs/AI-GUIDE.md).

## Publishing

Pushing to the `main` branch triggers the GitHub Actions build and publishes to Pages (see `.github/workflows/pages.yml`).

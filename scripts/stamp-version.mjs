/**
 * 把 package.json 的 assetVersion 写入门户页本地资源引用（?v=xxx）。
 * - 仅处理门户页：index.html、pages/portal.html（文档页走 ?_t= 不缓存，不参与）
 * - 只改本地 assets/ 资源（跳过 assets/libs/ 第三方与外链 http(s)）
 * - 幂等：已有 ?v= 的替换值，没有的补上
 *
 * 用法：npm run stamp
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');

const pkg = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
const ver = pkg.assetVersion || pkg.version || '0';

// 门户页清单（文档页不参与版本号）
const targets = ['index.html', 'pages/portal.html'];

// 匹配 src/href="...assets/xxx"（可选已有 ?v=），重写为 ?v=<ver>
const re = /((?:src|href)="[^"]*?)(assets\/(?!libs\/)[^"?]*?)(?:\?v=[^"&]*)?"/g;

let changed = 0;
for (const rel of targets) {
  const file = join(root, rel);
  if (!existsSync(file)) {
    console.warn('skip (not found):', rel);
    continue;
  }
  const src = readFileSync(file, 'utf8');
  const out = src.replace(re, (_m, p1, p2) => `${p1}${p2}?v=${ver}"`);
  if (out !== src) {
    writeFileSync(file, out, 'utf8');
    changed++;
    console.log('stamped', rel, '->', ver);
  } else {
    console.log('no change', rel);
  }
}
console.log(`assetVersion=${ver} · files changed=${changed}`);

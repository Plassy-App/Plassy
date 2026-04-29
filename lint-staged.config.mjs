/**
 * Runs ESLint with each package's local config and dependencies.
 * Paths from lint-staged are repo-relative (e.g. fromfeed-app/app/index.tsx).
 */

function stripPrefix(files, prefix) {
  const p = `${prefix}/`;
  return files.map((f) => (f.startsWith(p) ? f.slice(p.length) : f));
}

function quote(files) {
  return files.map((f) => `"${f.replace(/"/g, '\\"')}"`).join(' ');
}

export default {
  'fromfeed-app/**/*.{js,jsx,ts,tsx}': (files) => {
    const rel = stripPrefix(files, 'fromfeed-app');
    if (rel.length === 0) return [];
    return `pnpm --dir fromfeed-app exec eslint --fix ${quote(rel)}`;
  },
  'fromfeed-backend/**/*.ts': (files) => {
    const rel = stripPrefix(files, 'fromfeed-backend');
    if (rel.length === 0) return [];
    return `cd fromfeed-backend && bunx eslint --fix ${quote(rel)}`;
  },
  'fromfeed-contracts/**/*.{ts,mts,cts}': (files) => {
    const rel = stripPrefix(files, 'fromfeed-contracts');
    if (rel.length === 0) return [];
    return `cd fromfeed-contracts && bunx eslint --fix ${quote(rel)}`;
  },
  'fromfeed-frontend/**/*.{js,jsx,ts,tsx,mjs,cjs}': (files) => {
    const rel = stripPrefix(files, 'fromfeed-frontend');
    if (rel.length === 0) return [];
    return `cd fromfeed-frontend && npx eslint --fix ${quote(rel)}`;
  },
};

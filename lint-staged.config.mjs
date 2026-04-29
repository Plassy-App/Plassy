/**
 * Runs ESLint with each package's local config and dependencies.
 * Paths from lint-staged are repo-relative (e.g. plassy-app/app/index.tsx).
 */

function stripPrefix(files, prefix) {
  const p = `${prefix}/`;
  return files.map((f) => (f.startsWith(p) ? f.slice(p.length) : f));
}

function quote(files) {
  return files.map((f) => `"${f.replace(/"/g, '\\"')}"`).join(' ');
}

export default {
  'plassy-app/**/*.{js,jsx,ts,tsx}': (files) => {
    const rel = stripPrefix(files, 'plassy-app');
    if (rel.length === 0) return [];
    return `pnpm --dir plassy-app exec eslint --fix ${quote(rel)}`;
  },
  'plassy-backend/**/*.ts': (files) => {
    const rel = stripPrefix(files, 'plassy-backend');
    if (rel.length === 0) return [];
    return `cd plassy-backend && bunx eslint --fix ${quote(rel)}`;
  },
  'plassy-contracts/**/*.{ts,mts,cts}': (files) => {
    const rel = stripPrefix(files, 'plassy-contracts');
    if (rel.length === 0) return [];
    return `cd plassy-contracts && bunx eslint --fix ${quote(rel)}`;
  },
  'plassy-frontend/**/*.{js,jsx,ts,tsx,mjs,cjs}': (files) => {
    const rel = stripPrefix(files, 'plassy-frontend');
    if (rel.length === 0) return [];
    return `cd plassy-frontend && npx eslint --fix ${quote(rel)}`;
  },
};

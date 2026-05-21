/**
 * Runs ESLint with each package's local config and dependencies.
 * Paths from lint-staged are repo-relative (e.g. plassy-app/app/index.tsx).
 */

function stripPrefix(files, prefix) {
  const p = `${prefix}/`;
  return files.map((f) => (f.startsWith(p) ? f.slice(p.length) : f));
}

function quote(files) {
  return files.map((f) => `"${f.replace(/"/g, '\\"')}"`).join(" ");
}

function typecheckCommand(packageDir, files) {
  const rel = stripPrefix(files, packageDir);
  if (rel.length === 0) return null;
  return `cd ${packageDir} && bun run typecheck`;
}

function jestCommands({ packageDir, files, extensions }) {
  const rel = stripPrefix(files, packageDir);
  if (rel.length === 0) return [];

  const extPattern = extensions.join("|");
  const isTestFile = (file) =>
    file.startsWith("__tests__/") ||
    new RegExp(`\\.test\\.(${extPattern})$`).test(file);

  const tests = rel.filter(isTestFile);
  const sources = rel.filter((file) => !isTestFile(file));
  const cmds = [];

  if (tests.length > 0) {
    cmds.push(`cd ${packageDir} && bunx jest ${quote(tests)}`);
  }
  if (sources.length > 0) {
    cmds.push(
      `cd ${packageDir} && bunx jest --findRelatedTests --passWithNoTests ${quote(sources)}`,
    );
  }

  return cmds;
}

export default {
  "plassy-app/**/*.{js,jsx,ts,tsx}": (files) => {
    const rel = stripPrefix(files, "plassy-app");
    if (rel.length === 0) return [];
    const typecheck = typecheckCommand("plassy-app", files);
    return [
      `cd plassy-app && bunx eslint --fix ${quote(rel)}`,
      ...(typecheck ? [typecheck] : []),
      ...jestCommands({
        packageDir: "plassy-app",
        files,
        extensions: ["ts", "tsx"],
      }),
    ];
  },
  "plassy-backend/**/*.ts": (files) => {
    const rel = stripPrefix(files, "plassy-backend");
    if (rel.length === 0) return [];
    const typecheck = typecheckCommand("plassy-backend", files);
    return [
      `cd plassy-backend && bunx eslint --fix ${quote(rel)}`,
      ...(typecheck ? [typecheck] : []),
      ...jestCommands({
        packageDir: "plassy-backend",
        files,
        extensions: ["ts"],
      }),
    ];
  },
  "plassy-contracts/**/*.{ts,mts,cts}": (files) => {
    const rel = stripPrefix(files, "plassy-contracts");
    if (rel.length === 0) return [];
    const typecheck = typecheckCommand("plassy-contracts", files);
    return [
      `cd plassy-contracts && bunx eslint --fix ${quote(rel)}`,
      ...(typecheck ? [typecheck] : []),
      ...jestCommands({
        packageDir: "plassy-contracts",
        files,
        extensions: ["ts"],
      }),
    ];
  },
  "plassy-frontend/**/*.{js,jsx,ts,tsx,mjs,cjs}": (files) => {
    const rel = stripPrefix(files, "plassy-frontend");
    if (rel.length === 0) return [];
    const typecheck = typecheckCommand("plassy-frontend", files);
    return [
      `cd plassy-frontend && bunx eslint --fix ${quote(rel)}`,
      ...(typecheck ? [typecheck] : []),
      ...jestCommands({
        packageDir: "plassy-frontend",
        files,
        extensions: ["ts", "tsx"],
      }),
    ];
  },
  "plassy-scraper/**/*.ts": (files) => {
    const rel = stripPrefix(files, "plassy-scraper");
    if (rel.length === 0) return [];
    const typecheck = typecheckCommand("plassy-scraper", files);
    return [
      `cd plassy-scraper && bunx eslint --fix ${quote(rel)}`,
      ...(typecheck ? [typecheck] : []),
      ...jestCommands({
        packageDir: "plassy-scraper",
        files,
        extensions: ["ts"],
      }),
    ];
  },
};

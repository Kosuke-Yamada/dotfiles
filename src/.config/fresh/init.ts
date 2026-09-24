// ==========================================================================
// Fresh 起動スクリプト (https://getfresh.dev/docs/configuration/init)
// --------------------------------------------------------------------------
// LaTeX 支援:
//   - .tex / .bib / .sty / .cls の保存時に latexmk でビルド
//     （ルートに .latexmkrc があるプロジェクトのみ対象）
//   - コマンド「LaTeX: SyncTeX Forward Search」でカーソル行を Skim に表示
//   - 逆方向（Skim → Fresh）は ~/.local/bin/fresh-synctex が担当
// ==========================================================================

const ed = getEditor();

const TEXBIN = "/Library/TeX/texbin";
const DISPLAYLINE = "/Applications/Skim.app/Contents/SharedSupport/displayline";
const LATEX_EXTS = [".tex", ".bib", ".sty", ".cls"];
const PDF_RELATIVE = ["build", "main.pdf"];

// .latexmkrc を持つ最も近い祖先ディレクトリを返す
const findLatexRoot = (path: string): string | null => {
  let dir = ed.pathDirname(path);
  while (true) {
    if (ed.fileExists(ed.pathJoin(dir, ".latexmkrc"))) return dir;
    const parent = ed.pathDirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
};

// Fresh 起動後に MacTeX を入れた場合でも見つかるよう texbin を PATH の先頭に足す
const texPath = (): string => `PATH=${TEXBIN}:${ed.getEnv("PATH") ?? "/usr/bin:/bin"}`;

// -file-line-error 形式（file:line: message）の最初のエラー行
const firstError = (log: string): string | null =>
  log.split("\n").find((l) => /^[^\s:]+:\d+: /.test(l)) ?? null;

// ビルド中に再保存されたら、終了後にもう 1 回だけ走らせる
const buildState = new Map<string, { running: boolean; pending: boolean }>();

const buildLatex = async (root: string): Promise<void> => {
  const state = buildState.get(root) ?? { running: false, pending: false };
  buildState.set(root, state);
  if (state.running) {
    state.pending = true;
    return;
  }
  state.running = true;
  ed.setStatus("LaTeX: ビルド中…");
  try {
    const result = await ed.spawnProcess("/usr/bin/env", [texPath(), "latexmk"], root);
    if (result.exit_code === 0) {
      ed.setStatus("LaTeX: ビルド成功");
    } else {
      const error = firstError(result.stdout) ?? result.stderr.trim().split("\n").pop() ?? "";
      ed.setStatus(`LaTeX: ビルド失敗 (exit ${result.exit_code}) ${error}`);
    }
  } catch (e) {
    ed.setStatus(`LaTeX: latexmk を起動できません: ${String(e)}`);
  } finally {
    state.running = false;
  }
  if (state.pending) {
    state.pending = false;
    await buildLatex(root);
  }
};

registerHandler("latex_on_save", (args: { path: string; buffer_id: number }) => {
  if (!LATEX_EXTS.includes(ed.pathExtname(args.path))) return;
  const root = findLatexRoot(args.path);
  if (root !== null) void buildLatex(root);
});
ed.on("after_file_save", "latex_on_save");

registerHandler("latex_forward_search", async () => {
  const path = ed.getBufferPath(ed.getActiveBufferId());
  const root = path ? findLatexRoot(path) : null;
  if (root === null || ed.pathExtname(path) !== ".tex") {
    ed.setStatus("LaTeX: .latexmkrc のあるプロジェクトの .tex ファイルではありません");
    return;
  }
  const line = ed.getPrimaryCursor()?.line;
  if (line === null || line === undefined) {
    ed.setStatus("LaTeX: カーソル行を取得できません");
    return;
  }
  const pdf = ed.pathJoin(root, ...PDF_RELATIVE);
  if (!ed.fileExists(pdf)) {
    ed.setStatus(`LaTeX: ${pdf} がありません（先に保存してビルドしてください）`);
    return;
  }
  const result = await ed.spawnProcess(DISPLAYLINE, ["-r", "-b", String(line + 1), pdf, path]);
  if (result.exit_code !== 0) {
    ed.setStatus(`LaTeX: displayline 失敗: ${result.stderr.trim()}`);
  }
});
ed.registerCommand(
  "LaTeX: SyncTeX Forward Search",
  "カーソル行に対応する PDF の位置を Skim で表示",
  "latex_forward_search",
);

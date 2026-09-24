// ==========================================================================
// Fresh 起動スクリプト (https://getfresh.dev/docs/configuration/init)
// --------------------------------------------------------------------------
// LaTeX 支援:
//   - コマンド「LaTeX: SyncTeX Forward Search」でカーソル行を Skim に表示
//   - 逆方向（Skim → Fresh）は ~/.local/bin/fresh-synctex が担当
// ==========================================================================

const ed = getEditor();

const DISPLAYLINE = "/Applications/Skim.app/Contents/SharedSupport/displayline";
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
    ed.setStatus(`LaTeX: ${pdf} がありません（先にビルドしてください）`);
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

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

// Fresh の子プロセスは Fresh の終了と一緒に止まるため、latexmk はバックグラウンドの
// サブシェルに切り離して起動する（保存直後に Fresh を閉じてもビルドが最後まで走る）。
//   - lockf で同一プロジェクトのビルドを直列化（連続保存で latexmk が競合しない）
//   - 失敗時は Fresh が閉じていても気づけるよう macOS 通知に最初のエラー行を出す
//   - Fresh 起動後に MacTeX を入れた場合でも見つかるよう texbin を PATH の先頭に足す
const BUILD_SCRIPT = `
trap '' HUP
export PATH="${TEXBIN}:$PATH"
mkdir -p build
if ! /usr/bin/lockf build/.latexmk.lock latexmk >build/latexmk-on-save.log 2>&1; then
  err=$(grep -m1 -E '^[^[:space:]:]+:[0-9]+: ' build/main.log | tr -d '"\\\\')
  osascript -e "display notification \\"\${err:-build/latexmk-on-save.log を確認してください}\\" with title \\"LaTeX: ビルド失敗\\""
fi
`;

const buildLatex = async (root: string): Promise<void> => {
  try {
    const result = await ed.spawnProcess(
      "/bin/sh",
      ["-c", `(${BUILD_SCRIPT}) </dev/null >/dev/null 2>&1 &`],
      root,
    );
    ed.setStatus(
      result.exit_code === 0
        ? "LaTeX: ビルド開始（失敗時は macOS 通知）"
        : `LaTeX: ビルドを起動できません (exit ${result.exit_code}) ${result.stderr.trim()}`,
    );
  } catch (e) {
    ed.setStatus(`LaTeX: ビルドを起動できません: ${String(e)}`);
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

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { closeOverlay, focused, hc, nextCommand, notify, openOverlay, panes, props, run, theme } from "herdr";

/** @typedef {{key: string, label: string, command: string, args?: Record<string, unknown>}} Binding */
/** @type {Binding[]} */
const BINDINGS = [
  { key: "i", label: "移動先を選択", command: "mod.open", args: { name: "picker" } },
  { key: "ctrl-s", label: "サイドバー開閉", command: "layout.toggle", args: { id: "sidebar" } },
  { key: "s", label: "設定", command: "app.settings" },
  { key: "q", label: "最小化（プログラムは継続）", command: "window.minimize" },
  { key: "h", label: "上下分割", command: "pane.split", args: { direction: "down" } },
  { key: "v", label: "左右分割", command: "pane.split", args: { direction: "right" } },
  { key: "g", label: "2×2 の4分割", command: "grid" },
  ...["left", "down", "up", "right"].map((direction) => ({
    key: direction, label: `ペイン移動: ${direction}`, command: "pane.go", args: { direction },
  })),
  { key: "ctrl-p", label: "ペインを閉じる", command: "pane.close" },
  { key: "t", label: "タブ作成", command: "tab.new" },
  { key: "ctrl-t", label: "タブを閉じる", command: "tab.close" },
  { key: "p", label: "前のタブ", command: "tab.prev" },
  { key: "n", label: "次のタブ", command: "tab.next" },
  ...Array.from({ length: 9 }, (_, i) => ({
    key: String(i + 1), label: `タブ ${i + 1}`, command: "tab.select", args: { index: i + 1 },
  })),
  { key: "T", label: "タブ名変更", command: "tab.rename" },
  { key: "w", label: "ワークスペース作成", command: "space.new" },
  { key: "f", label: "次のワークスペース", command: "space.next" },
  { key: "b", label: "前のワークスペース", command: "space.prev" },
  { key: "ctrl-w", label: "ワークスペースを閉じる", command: "space.close" },
  { key: "W", label: "ワークスペース名変更", command: "space.rename" },
  { key: "G", label: "新規 worktree", command: "worktree" },
  { key: "k", label: "前のエージェント", command: "agent.prev" },
  { key: "j", label: "次のエージェント", command: "agent.next" },
];

const UNSUPPORTED = new Map([
  ["z", "直前のペインへの移動"],
  ["r", "キーボードでのペインリサイズ（境界をドラッグして変更できます）"],
  ["P", "ペイン名の変更"],
  ["R", "設定の手動リロード（デスクトップ版は設定変更を自動反映します）"],
]);

/** @param {import("gpui-kit").KeyEvent} event */
function keyOf(event) {
  const m = event.modifiers;
  if (m.alt || m.platform) return null;
  if (m.control) return m.shift ? null : `ctrl-${event.key}`;
  return event.key_char ?? (m.shift && event.key.length === 1 ? event.key.toUpperCase() : event.key);
}

/** @param {unknown} error */
function report(error) {
  notify({ title: "Herdr shortcuts", body: String(error), level: "error" });
}

export default class DotfilesPrefix extends View {
  busy = false;
  all = false;
  /** @type {import("gpui-kit").FocusHandle | undefined} */
  handle;
  /** @type {string | null} */
  terminal = null;

  /** @param {unknown} _props @param {import("gpui-kit").AsyncContext} cx */
  init(_props, cx) {
    this.terminal = focused()?.terminal ?? null;
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (this.busy) continue;
        if (command === "send-prefix") await this.sendPrefix();
        else if (command === "grid") await this.grid(cx);
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  async sendPrefix() {
    this.busy = true;
    try {
      if (this.terminal) {
        const result = await hc(["keys", this.terminal, "ctrl+b"]);
        if (result.code !== 0) throw new Error(result.stderr || "Ctrl+B の送信に失敗しました。");
      }
    } catch (error) { report(error); }
    this.dismiss();
  }

  /** @param {import("gpui-kit").AsyncContext} cx */
  async grid(cx) {
    this.busy = true;
    cx.notify();
    try {
      const target = focused();
      if (!target?.pane) throw new Error("分割するペインを選択してください。");
      const original = target.pane;
      const tab = target.tab;
      /** @param {string} pane @param {"down" | "right"} direction */
      const split = async (pane, direction) => {
        const before = new Set(panes().filter((p) => p.tab === tab).map((p) => p.pane));
        run("pane.split", { pane, direction });
        const deadline = Date.now() + 10000;
        while (Date.now() < deadline) {
          const added = panes().filter((p) => p.tab === tab && !before.has(p.pane));
          if (added.length > 1) throw new Error("分割中に別のペインが追加されました。残りの分割を中止します。");
          if (added.length === 1) return added[0].pane;
          await cx.sleep(50);
        }
        throw new Error("ペイン分割が完了しませんでした。作成済みのペインは残しています。");
      };
      const bottom = await split(original, "down");
      await split(original, "right");
      await split(bottom, "right");
      run("pane.focus", { pane: original });
    } catch (error) { report(error); }
    this.dismiss();
  }

  /** @param {import("gpui-kit").KeyEvent} event @param {import("gpui-kit").Context} cx */
  key(event, cx) {
    cx.stop_propagation();
    if (this.busy) return;
    const key = keyOf(event);
    if (key === "escape") return this.dismiss();
    if (key === "ctrl-b") { cx.spawn(async () => this.sendPrefix()); return; }
    if (key === "?") { this.all = !this.all; cx.notify(); return; }
    if (key && UNSUPPORTED.has(key)) {
      notify({ title: "デスクトップ版では未対応", body: UNSUPPORTED.get(key) ?? "" });
      return this.dismiss();
    }
    const binding = BINDINGS.find((b) => b.key === key);
    if (!binding) return this.dismiss();
    if (binding.command === "grid") { cx.spawn(async (cx) => this.grid(cx)); return; }
    const space = focused()?.space;
    this.dismiss();
    if (binding.command === "worktree") {
      openOverlay({ mod: "worktree", props: { space, action: "new" }, kind: "dialog", width: 600 });
    } else {
      run(binding.command, binding.args ?? {});
    }
  }

  render() {
    const t = theme();
    const rows = this.all ? BINDINGS : BINDINGS.filter((b) => !/^\d$/.test(b.key) && !["left", "down", "up", "right"].includes(b.key));
    const root = v_flex().id("dotfiles-prefix");
    if (this.handle) root.track_focus(this.handle);
    return root.on_key_down((event, cx) => this.key(event, cx))
      .p(14).gap(8).bg(t.popover).text_color(t.foreground).text_size(12)
      .child(h_flex().justify_between()
        .child(div().font_semibold().child(this.busy ? "実行中…" : "Ctrl+B · ショートカット"))
        .child(div().text_color(t.muted).child("Esc キャンセル · ^B キー送信")))
      .child(v_flex().h(320).min_h(0).overflow_y_scrollbar().children(rows.map((b) =>
        h_flex().h(22).flex_none().items_center().gap(12)
          .child(div().w(68).text_color(t.accent).child(b.key))
          .child(div().flex_1().child(b.label)))))
      .child(div().text_color(t.muted).child("1–9 タブ切替 · 矢印 ペイン移動 · ? 一覧切替"));
  }
}

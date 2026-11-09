# Terminal
brew "herdr"
brew "fresh-editor"
brew "sheldon"
brew "zoxide"
brew "eza"
brew "bat"
# Markdown ビューア（formula 名は leaf-markdown-viewer、コマンド名は leaf）
brew "leaf-markdown-viewer"
brew "ripgrep"
brew "fd"
brew "starship"
brew "gitui"
brew "git-delta"
brew "ghq"
brew "fzf"
# GitHub CLI（git の認証ヘルパー、gbr エイリアス、メニューバーの Copilot 使用量で使用）
brew "gh"
# JSON 処理（メニューバーのプラグインと make packages で使用）
brew "jq"

# JavaScript runtime (npx / claude-mem installer)
brew "node"
brew "uv"

# AI Coding Agent (macOS cask のみ提供)
if OS.mac?
  cask "claude-code"
  cask "codex"
  # Meta の Muse（ターミナルで動くコーディングエージェント、コマンド名は muse）
  cask "muse-code"
  cask "t3-code"
end

# macOS only
if OS.mac?
  tap "asmvik/formulae"
  cask "ghostty"
  cask "visual-studio-code"
  cask "cursor"

  # AI desktop apps
  cask "chatgpt"
  cask "grok-bot"
  cask "google-gemini"
  cask "claude"
  # 音声入力（Speech-to-text）
  cask "aqua-voice"

  # Work apps
  cask "slack"
  cask "notion"

  # Markdown エディタ（MacDown は配布終了のため後継の MacDown 3000）
  cask "macdown-3000"

  # Mac App Store（mas でのインストールには App Store へのサインインが必要）
  brew "mas"
  mas "Kindle", id: 302584613

  # LaTeX（TeX Live full、GUI アプリなし）と SyncTeX 対応 PDF ビューア
  cask "mactex-no-gui"
  cask "skim"

  # メニューバーにスクリプト出力を表示 (Claude Code / Codex の残クレジット)
  cask "swiftbar"

  brew "asmvik/formulae/yabai", trusted: true
  cask "karabiner-elements"

  # Fonts
  cask "font-hackgen"
  cask "font-hackgen-nerd"
end

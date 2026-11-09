# ==============================================================================
# dotfiles Makefile
# ==============================================================================
#
# 使用方法:
#   make init  - Homebrew とパッケージをインストール
#   make link  - シンボリックリンクを作成
#   make all   - init と link を実行
#
# ==============================================================================

SHELL := /bin/bash
DOT_DIRECTORY := $(CURDIR)
SRC_DIRECTORY := $(DOT_DIRECTORY)/src
BACKUP_DIRECTORY := $(HOME)/.backup/dotfiles
OS := $(shell uname -s)

# Rosetta の uname は x86_64 を返すため、ハードウェア側の ARM 対応を調べる。
ifeq ($(OS),Darwin)
ifeq ($(shell /usr/sbin/sysctl -n hw.optional.arm64 2>/dev/null),1)
BREW_PREFIX := /opt/homebrew
SHELL := /usr/bin/arch -arm64 /bin/bash
else
BREW_PREFIX := /usr/local
endif
else
BREW_PREFIX := /home/linuxbrew/.linuxbrew
endif
export PATH := $(BREW_PREFIX)/bin:$(BREW_PREFIX)/sbin:$(PATH)

.PHONY: all init link codex-skills codex-config claude-settings swiftbar brew packages herdr-app plugins macos-setup claude-mcp claude-mem vscode-extensions skim-setup help

# デフォルトターゲット
all: init
	+@$(MAKE) link
	@echo ""
	@echo "=========================================="
	@echo "セットアップが完了しました！"
	@echo "=========================================="

# ------------------------------------------------------------------------------
# init: Homebrew とパッケージのインストール
# ------------------------------------------------------------------------------
init: brew packages herdr-app plugins claude-mcp claude-mem vscode-extensions skim-setup macos-setup karabiner-config
	@echo ""
	@echo "=========================================="
	@echo "init が完了しました！"
	@echo "=========================================="

# Homebrew のインストール
brew:
	@echo ""
	@echo "[init] Homebrew のインストール"
	@echo "------------------------------------------"
	@set -eu; \
	if [ ! -x "$(BREW_PREFIX)/bin/brew" ]; then \
		echo "$(OS) / $$(uname -m): $(BREW_PREFIX) に Homebrew をインストールします（既存の別環境は保持します）。"; \
		installer=$$(mktemp); \
		trap 'rm -f "$$installer"' EXIT HUP INT TERM; \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$$installer"; \
		/bin/bash "$$installer"; \
	else \
		echo "Homebrew を使用します: $(BREW_PREFIX)/bin/brew ($$(uname -m))"; \
	fi; \
	if [ ! -x "$(BREW_PREFIX)/bin/brew" ]; then \
		echo "Homebrew の導入に失敗しました: $(BREW_PREFIX)/bin/brew がありません。" >&2; \
		exit 1; \
	fi

# パッケージのインストール
# Homebrew 外で導入済みのアプリ（手動導入や MDM 配布）を cask で取り込むと sudo が必要になるため、
# /Applications に同名アプリがある未管理の cask はスキップして既存アプリをそのまま使う
packages: brew
	@echo ""
	@echo "[init] Brewfile からパッケージをインストール"
	@echo "------------------------------------------"
	@set -eu; \
	brew="$(BREW_PREFIX)/bin/brew"; \
	skip=""; \
	if [ "$(OS)" = Darwin ] && command -v jq >/dev/null 2>&1; then \
		casks=$$("$$brew" bundle list --cask --file="$(DOT_DIRECTORY)/Brewfile"); \
		if [ -n "$$casks" ]; then \
			skip=$$("$$brew" info --cask --json=v2 $$casks \
				| jq -r '.casks[] | select(.installed == null) | .token as $$t | .artifacts[] | .app? // empty | .[] | (if type == "object" then .target else . end) | strings | "\($$t) \(.)"' \
				| while read -r token app; do \
					if [ -e "/Applications/$$app" ]; then echo "$$token"; fi; \
				done | sort -u | tr '\n' ' '); \
		fi; \
	fi; \
	if [ -n "$$skip" ]; then \
		echo "Homebrew 外で導入済みのためスキップします: $$skip"; \
	fi; \
	HOMEBREW_BUNDLE_CASK_SKIP="$$skip" "$$brew" bundle --file="$(DOT_DIRECTORY)/Brewfile"

# Herdr デスクトップ版（Homebrew の herdr はターミナル版）
herdr-app: packages
	@echo ""
	@echo "[init] Herdr デスクトップ版のインストール"
	@set -eu; \
	if [ "$(OS)" != Darwin ] && [ "$(OS)" != Linux ]; then \
		echo "対応する OS ではないためスキップします。"; \
	elif command -v herdr-app >/dev/null 2>&1 || \
	     [ -x "$(HOME)/Applications/Herdr.app/Contents/MacOS/Herdr" ] || \
	     [ -x "/Applications/Herdr.app/Contents/MacOS/Herdr" ] || \
	     [ -x "$(HOME)/.local/bin/herdr-app" ]; then \
		echo "Herdr デスクトップ版は導入済みです。スキップします。"; \
	else \
		installer=$$(mktemp); \
		trap 'rm -f "$$installer"' EXIT HUP INT TERM; \
		curl -fsSL https://releases.herdr.dev/app/install.sh -o "$$installer"; \
		/bin/sh "$$installer"; \
	fi

# Sheldon プラグインのインストール
plugins: packages
	@echo ""
	@echo "[init] Sheldon プラグインのインストール"
	@echo "------------------------------------------"
	@mkdir -p "$(HOME)/.config/sheldon"
	@ln -snfv "$(SRC_DIRECTORY)/.config/sheldon/plugins.toml" "$(HOME)/.config/sheldon/plugins.toml"
	sheldon lock --update

# Claude Code MCP サーバーの設定
claude-mcp: packages
	@echo ""
	@echo "[init] Claude Code MCP サーバーの設定"
	@echo "------------------------------------------"
	@if command -v claude &> /dev/null; then \
		echo "MCP サーバーを設定中..."; \
		claude mcp add -s user context7 -- npx -y @upstash/context7-mcp 2>/dev/null || true; \
		claude mcp add -s user Playwright -- npx @playwright/mcp@latest 2>/dev/null || true; \
		claude mcp add -s user serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context=claude-code --project-from-cwd 2>/dev/null || true; \
		claude mcp add -s user github -- npx -y @modelcontextprotocol/server-github 2>/dev/null || true; \
		echo "MCP サーバーの設定が完了しました。"; \
		echo ""; \
		echo "NOTE: GitHub MCP を使用するには GITHUB_TOKEN 環境変数が必要です。"; \
		echo "  1. ~/.zshrc.local.example を ~/.zshrc.local にコピー"; \
		echo "  2. GITHUB_TOKEN を設定（https://github.com/settings/tokens で作成）"; \
	else \
		echo "Claude Code がインストールされていません。スキップします。"; \
	fi

# claude-mem を Claude Code / Codex の両方へインストール
claude-mem: packages
	@echo ""
	@echo "[init] claude-mem のインストール"
	@echo "------------------------------------------"
	@if command -v npx &> /dev/null; then \
		npx --yes claude-mem@latest install --ide claude-code --provider claude --runtime worker --no-auto-start && \
		npx --yes claude-mem@latest install --ide codex-cli --provider claude --runtime worker --no-auto-start && \
		npx --yes claude-mem@latest start; \
	else \
		echo "npx が見つかりません。Node.js のインストールを確認してください。"; \
		exit 1; \
	fi

# VSCode 拡張機能のインストール
# PATH 上の code が別エディタを指す場合があるため、アプリ同梱の CLI を優先する
VSCODE_CLI := $(shell p="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; [ -x "$$p" ] && echo "$$p" || echo code)
vscode-extensions: packages
	@echo ""
	@echo "[init] VSCode 拡張機能のインストール"
	@echo "------------------------------------------"
	@if command -v "$(VSCODE_CLI)" &> /dev/null; then \
		EXTENSION_FILE="$(SRC_DIRECTORY)/.config/Code/extensions.txt"; \
		if [ -f "$$EXTENSION_FILE" ]; then \
			INSTALLED=$$("$(VSCODE_CLI)" --list-extensions); \
			WANTED=$$(grep -v '^\s*$$' "$$EXTENSION_FILE" | grep -v '^\s*#'); \
			echo "不要な拡張機能を削除中..."; \
			for ext in $$INSTALLED; do \
				if ! echo "$$WANTED" | grep -qFxi "$$ext"; then \
					echo "  アンインストール: $$ext"; \
					"$(VSCODE_CLI)" --uninstall-extension "$$ext" 2>/dev/null || true; \
				fi; \
			done; \
			echo ""; \
			echo "必要な拡張機能をインストール中..."; \
			for ext in $$WANTED; do \
				if echo "$$INSTALLED" | grep -qFxi "$$ext"; then \
					echo "  既存: $$ext"; \
				else \
					echo "  インストール: $$ext"; \
					"$(VSCODE_CLI)" --install-extension "$$ext" 2>/dev/null || true; \
				fi; \
			done; \
			echo "VSCode 拡張機能の同期が完了しました。"; \
		else \
			echo "extensions.txt が見つかりません。スキップします。"; \
		fi; \
	else \
		echo "VSCode がインストールされていません。スキップします。"; \
	fi

# Skim の SyncTeX 逆方向検索（PDF → Fresh）と自動再読み込みを設定
skim-setup: packages
	@echo ""
	@echo "[init] Skim の設定"
	@echo "------------------------------------------"
ifeq ($(OS),Darwin)
	@defaults write -app Skim SKTeXEditorPreset -string ""
	@defaults write -app Skim SKTeXEditorCommand -string "$(HOME)/.local/bin/fresh-synctex"
	@defaults write -app Skim SKTeXEditorArguments -string '"%file" %line'
	@defaults write -app Skim SKAutoCheckFileUpdate -bool true
	@defaults write -app Skim SKAutoReloadFileUpdate -bool true
	@echo "Skim: 逆方向検索を fresh-synctex に設定し、PDF の自動再読み込みを有効化しました"
else
	@echo "macOS ではないためスキップします。"
endif

# macOS 固有の設定
macos-setup: packages
	@echo ""
	@echo "[init] macOS 固有の設定"
	@echo "------------------------------------------"
ifeq ($(OS),Darwin)
	@echo "yabai サービスを開始中..."
	@yabai --start-service || { echo "yabai の起動に失敗しました。アクセシビリティ権限と上のエラーを確認してください。" >&2; exit 1; }
	@echo ""
	@echo "NOTE: yabai にはアクセシビリティ権限が必要です。"
	@echo "  1. システム設定 > プライバシーとセキュリティ > アクセシビリティ を開く"
	@echo "  2. $(BREW_PREFIX)/bin/yabai を追加して有効化"
	@echo "  3. 実行: yabai --restart-service"
else
	@echo "macOS ではないためスキップします。"
endif

# ------------------------------------------------------------------------------
# codex-skills: Claude Code と同じスキルを Codex に共有
# ------------------------------------------------------------------------------
codex-skills:
	@echo ""
	@echo "[link] Claude Code のスキルを Codex に共有"
	@echo "------------------------------------------"
	@if [ -d "$(SRC_DIRECTORY)/.claude/skills" ]; then \
		mkdir -p "$(HOME)/.codex/skills"; \
		for d in "$(SRC_DIRECTORY)/.claude/skills"/*/; do \
			if [ -d "$$d" ]; then \
				ln -snfv "$$d" "$(HOME)/.codex/skills/$$(basename "$$d")"; \
			fi; \
		done; \
	else \
		echo "Claude Code のスキルが見つかりません。スキップします。"; \
	fi

# ------------------------------------------------------------------------------
# codex-config: Codex の共通設定を ~/.codex/config.toml にマージ
# ~/.codex/config.toml には Codex アプリが書く端末固有の状態が混ざるため
# シンボリックリンクにはせず、src/.codex/config.toml のキーだけを上書きする
# ------------------------------------------------------------------------------
codex-config:
	@echo ""
	@echo "[link] Codex の共通設定をマージ"
	@echo "------------------------------------------"
	@if ! command -v uv &> /dev/null; then \
		echo "uv が見つからないため Codex の設定をマージできません。uv をインストールしてから make codex-config を実行してください。" >&2; \
		exit 1; \
	fi
	@uv run --quiet --no-project --with tomlkit python "$(SRC_DIRECTORY)/.codex/scripts/merge-config.py" \
		"$(SRC_DIRECTORY)/.codex/config.toml" "$(HOME)/.codex/config.toml"

# ------------------------------------------------------------------------------
# claude-settings: Claude Code の共通設定を ~/.claude/settings.json にマージ
# iTerm2 連携など各 PC のアプリが書き込む設定をリポジトリに混ぜないよう、
# シンボリックリンクにはせず src/.claude/settings.json の内容だけを反映する
# 前回反映した内容を ~/.claude/.dotfiles-settings-base.json に残し、リポジトリから消した設定は PC からも消す
claude-settings:
	@echo ""
	@echo "[link] Claude Code の共通設定をマージ"
	@echo "------------------------------------------"
	@set -eu; \
	target="$(HOME)/.claude/settings.json"; \
	mkdir -p "$(HOME)/.claude"; \
	if [ -L "$$target" ]; then \
		echo "シンボリックリンクを通常ファイルに置き換えます: $$target"; \
		cp "$$target" "$$target.tmp"; \
		mv -f "$$target.tmp" "$$target"; \
	fi; \
	if ! command -v uv >/dev/null 2>&1; then \
		echo "uv が見つからないため Claude Code の設定をマージできません。uv をインストールしてから make claude-settings を実行してください。" >&2; \
		exit 1; \
	fi; \
	uv run --quiet --no-project python "$(SRC_DIRECTORY)/.claude/merge-settings.py" \
		"$(SRC_DIRECTORY)/.claude/settings.json" "$$target" "$(HOME)/.claude/.dotfiles-settings-base.json"

# swiftbar: メニューバーに Claude Code / Codex の月間残クレジットを表示
# プラグインディレクトリを指定し、ログイン時に SwiftBar を起動する LaunchAgent を登録する
# LaunchAgent の plist は symlink だと launchd に読まれないことがあるためコピーする
# ------------------------------------------------------------------------------
SWIFTBAR_AGENT := local.dotfiles.swiftbar
swiftbar:
	@echo ""
	@echo "[link] SwiftBar プラグインの設定"
	@echo "------------------------------------------"
ifeq ($(OS),Darwin)
	@mkdir -p "$(HOME)/.config/swiftbar"
	@chmod +x "$(SRC_DIRECTORY)/.config/swiftbar/plugins"/*
	@ln -snfv "$(SRC_DIRECTORY)/.config/swiftbar/plugins" "$(HOME)/.config/swiftbar/plugins"
	@defaults write com.ameba.SwiftBar PluginDirectory -string "$(HOME)/.config/swiftbar/plugins"
	@mkdir -p "$(HOME)/Library/LaunchAgents"
	@install -m 644 "$(SRC_DIRECTORY)/Library/LaunchAgents/$(SWIFTBAR_AGENT).plist" "$(HOME)/Library/LaunchAgents/$(SWIFTBAR_AGENT).plist"
	@if [ -d /Applications/SwiftBar.app ]; then \
		launchctl bootout "gui/$$(id -u)/$(SWIFTBAR_AGENT)" 2>/dev/null || true; \
		launchctl bootstrap "gui/$$(id -u)" "$(HOME)/Library/LaunchAgents/$(SWIFTBAR_AGENT).plist"; \
		echo "SwiftBar をログイン時に起動するよう登録しました"; \
	else \
		echo "SwiftBar がインストールされていません。make packages の後に make swiftbar を実行してください。"; \
	fi
else
	@echo "macOS ではないためスキップします。"
endif

# ------------------------------------------------------------------------------
# link: シンボリックリンクの作成
# ------------------------------------------------------------------------------
.PHONY: t3-keybindings
t3-keybindings:
	@mkdir -p "$(HOME)/.t3/userdata"
	@if [ -f "$(HOME)/.t3/userdata/keybindings.json" ] && [ ! -L "$(HOME)/.t3/userdata/keybindings.json" ]; then \
		cp -p "$(HOME)/.t3/userdata/keybindings.json" "$(HOME)/.t3/userdata/keybindings.json.backup-$$(date +%Y%m%d%H%M%S)" || exit 1; \
	fi
	@ln -snfv "$(SRC_DIRECTORY)/.t3/userdata/keybindings.json" "$(HOME)/.t3/userdata/keybindings.json"

# Karabiner はファイル単体の symlink では変更を検知しないため、通常ファイルとして配置する
.PHONY: karabiner-config
karabiner-config:
ifeq ($(OS),Darwin)
	@set -eu; \
	mkdir -p "$(HOME)/.config/karabiner"; \
	if ! cmp -s "$(SRC_DIRECTORY)/.config/karabiner/karabiner.json" "$(HOME)/.config/karabiner/karabiner.json"; then \
		if [ -e "$(HOME)/.config/karabiner/karabiner.json" ] || [ -L "$(HOME)/.config/karabiner/karabiner.json" ]; then \
			mv "$(HOME)/.config/karabiner/karabiner.json" "$(HOME)/.config/karabiner/karabiner.json.backup-$$(date +%Y%m%d%H%M%S)"; \
		fi; \
		cp "$(SRC_DIRECTORY)/.config/karabiner/karabiner.json" "$(HOME)/.config/karabiner/karabiner.json"; \
	fi; \
	if [ -d "/Applications/Karabiner-Elements.app" ] && ! pgrep -q -x Karabiner-Core-Service; then \
		echo "Karabiner-Elements を起動します（ドライバの許可が必要です）。"; \
		open -g -a "Karabiner-Elements"; \
		echo "NOTE: Caps Lock → Hyper を有効にするには以下の許可が必要です。"; \
		echo "  1. システム設定 > 一般 > ログイン項目と機能拡張 > ドライバ機能拡張 で .Karabiner-VirtualHIDDevice-Manager を有効化"; \
		echo "  2. システム設定 > プライバシーとセキュリティ > 入力監視 で karabiner_grabber / Karabiner-Core-Service を有効化"; \
	fi
else
	@echo "macOS ではないためスキップします。"
endif

link: codex-skills codex-config claude-settings swiftbar t3-keybindings karabiner-config
	@echo ""
	@echo "[link] シンボリックリンクの作成"
	@echo "------------------------------------------"
	@mkdir -p "$(BACKUP_DIRECTORY)"
	@# ホームディレクトリ直下のドットファイル
	@echo "ホームディレクトリのドットファイルをリンク中..."
	@cd "$(SRC_DIRECTORY)" && \
	for f in .??*; do \
		if [ "$$f" = ".git" ] || [ "$$f" = ".config" ] || [ "$$f" = ".claude" ] || [ "$$f" = ".codex" ] || [ "$$f" = ".local" ] || [ "$$f" = ".t3" ]; then \
			continue; \
		fi; \
		if [ -e "$(HOME)/$$f" ] && [ ! -L "$(HOME)/$$f" ]; then \
			echo "  バックアップ: $$f -> $(BACKUP_DIRECTORY)/"; \
			mv "$(HOME)/$$f" "$(BACKUP_DIRECTORY)/"; \
		fi; \
		ln -snfv "$(SRC_DIRECTORY)/$$f" "$(HOME)/$$f"; \
	done
	@rmdir -p "$(BACKUP_DIRECTORY)" 2>/dev/null || true
	@# .config 配下（共通）
	@echo ""
	@echo ".config 配下の設定ファイルをリンク中（共通）..."
	@mkdir -p "$(HOME)/.config/sheldon"
	@ln -snfv "$(SRC_DIRECTORY)/.config/sheldon/plugins.toml" "$(HOME)/.config/sheldon/plugins.toml"
	@mkdir -p "$(HOME)/.config/starship"
	@ln -snfv "$(SRC_DIRECTORY)/.config/starship/starship.toml" "$(HOME)/.config/starship/starship.toml"
	@mkdir -p "$(HOME)/.config/herdr"
	@ln -snfv "$(SRC_DIRECTORY)/.config/herdr/config.toml" "$(HOME)/.config/herdr/config.toml"
	@mkdir -p "$(HOME)/.config/herdr-app/mods"
	@if [ -f "$(HOME)/.config/herdr-app/keys.json" ] && [ ! -L "$(HOME)/.config/herdr-app/keys.json" ]; then \
		cp -p "$(HOME)/.config/herdr-app/keys.json" "$(HOME)/.config/herdr-app/keys.json.backup-$$(date +%Y%m%d%H%M%S)"; \
	fi
	@ln -snfv "$(SRC_DIRECTORY)/.config/herdr-app/keys.json" "$(HOME)/.config/herdr-app/keys.json"
	@ln -snfv "$(SRC_DIRECTORY)/.config/herdr-app/mods/dotfiles-prefix" "$(HOME)/.config/herdr-app/mods/dotfiles-prefix"
	@mkdir -p "$(HOME)/.config/fresh"
	@ln -snfv "$(SRC_DIRECTORY)/.config/fresh/config.json" "$(HOME)/.config/fresh/config.json"
	@ln -snfv "$(SRC_DIRECTORY)/.config/fresh/init.ts" "$(HOME)/.config/fresh/init.ts"
	@mkdir -p "$(HOME)/.config/leaf"
	@ln -snfv "$(SRC_DIRECTORY)/.config/leaf/config.toml" "$(HOME)/.config/leaf/config.toml"
	@# .config 配下（macOS専用）
ifeq ($(OS),Darwin)
	@echo ""
	@echo ".config 配下の設定ファイルをリンク中（macOS専用）..."
	@mkdir -p "$(HOME)/.config/ghostty"
	@ln -snfv "$(SRC_DIRECTORY)/.config/ghostty/config" "$(HOME)/.config/ghostty/config"
	@# skhd はセキュア入力が有効な間は起動できないため廃止し、キー割り当ては Karabiner-Elements に移した。
	@# 旧環境で両方が反応しないよう、skhd のサービスと dotfiles のリンクを片付ける
	@if command -v skhd >/dev/null 2>&1; then \
		skhd --stop-service 2>/dev/null || true; \
		skhd --uninstall-service 2>/dev/null || true; \
	fi
	@for f in "$(HOME)/.skhdrc" "$(HOME)/.config/skhd/skhdrc"; do \
		if [ -L "$$f" ] && [ "$$(readlink "$$f")" = "$(SRC_DIRECTORY)/.config/skhd/skhdrc" ]; then rm -v "$$f"; fi; \
	done
	@mkdir -p "$(HOME)/.config/yabai"
	@ln -snfv "$(SRC_DIRECTORY)/.config/yabai/yabairc" "$(HOME)/.config/yabai/yabairc"
	@# VSCode settings.json
	@echo ""
	@echo "VSCode の設定ファイルをリンク中..."
	@mkdir -p "$(HOME)/Library/Application Support/Code/User"
	@ln -snfv "$(SRC_DIRECTORY)/.config/Code/User/settings.json" "$(HOME)/Library/Application Support/Code/User/settings.json"
	@# yabai をリロード（設定を即時反映）
	@echo ""
	@echo "yabai の設定をリロード中..."
	@yabai --restart-service 2>/dev/null || true
endif
	@# .local/bin 配下のスクリプト
	@if [ -d "$(SRC_DIRECTORY)/.local/bin" ]; then \
		echo ""; \
		echo ".local/bin 配下のスクリプトをリンク中..."; \
		mkdir -p "$(HOME)/.local/bin"; \
		cd "$(SRC_DIRECTORY)/.local/bin" && \
		for f in *; do \
			if [ -f "$$f" ]; then \
				chmod +x "$(SRC_DIRECTORY)/.local/bin/$$f"; \
				ln -snfv "$(SRC_DIRECTORY)/.local/bin/$$f" "$(HOME)/.local/bin/$$f"; \
			fi; \
		done; \
	fi
ifeq ($(OS),Darwin)
	@mkdir -p "$(HOME)/.local/lib"
	@ln -snfv "$(SRC_DIRECTORY)/.local/lib/app-toggle.swift" "$(HOME)/.local/lib/app-toggle.swift"
	@"$(HOME)/.local/bin/app-toggle" --build
endif
	@# ホームディレクトリ配下（個別ファイル）
	@echo ""
	@echo "ホームディレクトリ配下の設定ファイルをリンク中..."
	@mkdir -p "$(HOME)/.claude"
	@ln -snfv "$(SRC_DIRECTORY)/.claude/CLAUDE.md" "$(HOME)/.claude/CLAUDE.md"
	@mkdir -p "$(HOME)/.codex"
	@ln -snfv "$(SRC_DIRECTORY)/.codex/AGENTS.md" "$(HOME)/.codex/AGENTS.md"
	@# .claude/commands 配下
	@if [ -d "$(SRC_DIRECTORY)/.claude/commands" ]; then \
		echo ""; \
		echo ".claude/commands 配下のコマンド設定をリンク中..."; \
		mkdir -p "$(HOME)/.claude/commands"; \
		cd "$(SRC_DIRECTORY)/.claude/commands" && \
		for f in *.md; do \
			if [ -f "$$f" ]; then \
				ln -snfv "$(SRC_DIRECTORY)/.claude/commands/$$f" "$(HOME)/.claude/commands/$$f"; \
			fi; \
		done; \
	fi
	@# .claude/scripts 配下
	@if [ -d "$(SRC_DIRECTORY)/.claude/scripts" ]; then \
		echo ""; \
		echo ".claude/scripts 配下のスクリプトをリンク中..."; \
		mkdir -p "$(HOME)/.claude/scripts"; \
		cd "$(SRC_DIRECTORY)/.claude/scripts" && \
		for f in *.sh; do \
			if [ -f "$$f" ]; then \
				chmod +x "$(SRC_DIRECTORY)/.claude/scripts/$$f"; \
				ln -snfv "$(SRC_DIRECTORY)/.claude/scripts/$$f" "$(HOME)/.claude/scripts/$$f"; \
			fi; \
		done; \
	fi
	@# .claude/skills 配下（各スキルディレクトリを symlink）
	@if [ -d "$(SRC_DIRECTORY)/.claude/skills" ]; then \
		echo ""; \
		echo ".claude/skills 配下のスキルをリンク中..."; \
		mkdir -p "$(HOME)/.claude/skills"; \
		for d in "$(SRC_DIRECTORY)/.claude/skills"/*/; do \
			if [ -d "$$d" ]; then \
				ln -snfv "$$d" "$(HOME)/.claude/skills/$$(basename "$$d")"; \
			fi; \
		done; \
	fi
	@echo ""
	@echo "=========================================="
	@echo "link が完了しました！"
	@echo "=========================================="

# ------------------------------------------------------------------------------
# help: ヘルプの表示
# ------------------------------------------------------------------------------
help:
	@echo "dotfiles Makefile"
	@echo ""
	@echo "使用方法:"
	@echo "  make all               - init と link を実行（フルセットアップ）"
	@echo "  make init              - Homebrew とパッケージをインストール"
	@echo "  make herdr-app         - Herdr デスクトップ版をインストール"
	@echo "  make link              - シンボリックリンクを作成"
	@echo "  make codex-skills      - Claude Code のスキルを Codex に共有"
	@echo "  make codex-config      - Codex の共通設定を ~/.codex/config.toml にマージ"
	@echo "  make claude-settings   - Claude Code の共通設定を ~/.claude/settings.json にマージ"
	@echo "  make swiftbar          - メニューバーに AI 使用量を表示 (SwiftBar)"
	@echo "  make claude-mcp             - Claude Code MCP サーバーを設定"
	@echo "  make claude-mem             - claude-mem を Claude Code / Codex に導入"
	@echo "  make vscode-extensions      - VSCode 拡張機能をインストール"
	@echo "  make help                   - このヘルプを表示"

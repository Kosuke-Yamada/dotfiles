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

.PHONY: all init link codex-skills brew packages plugins macos-setup claude-mcp claude-mem vscode-extensions skim-setup help

# デフォルトターゲット
all: init link
	@echo ""
	@echo "=========================================="
	@echo "セットアップが完了しました！"
	@echo "=========================================="

# ------------------------------------------------------------------------------
# init: Homebrew とパッケージのインストール
# ------------------------------------------------------------------------------
init: brew packages plugins claude-mcp claude-mem vscode-extensions skim-setup macos-setup
	@echo ""
	@echo "=========================================="
	@echo "init が完了しました！"
	@echo "=========================================="

# Homebrew のインストール
brew:
	@echo ""
	@echo "[init] Homebrew のインストール"
	@echo "------------------------------------------"
	@if ! command -v brew &> /dev/null; then \
		echo "Homebrew が見つかりません。インストールを開始します..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		if [ "$(OS)" = "Linux" ]; then \
			eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
		fi; \
	else \
		echo "Homebrew は既にインストールされています。スキップします。"; \
	fi

# パッケージのインストール
packages: brew
	@echo ""
	@echo "[init] Brewfile からパッケージをインストール"
	@echo "------------------------------------------"
	brew bundle --file="$(DOT_DIRECTORY)/Brewfile"

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
vscode-extensions:
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
skim-setup:
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
macos-setup:
	@echo ""
	@echo "[init] macOS 固有の設定"
	@echo "------------------------------------------"
ifeq ($(OS),Darwin)
	@echo "skhd サービスを開始中..."
	@skhd --start-service 2>/dev/null || true
	@echo "yabai サービスを開始中..."
	@yabai --start-service 2>/dev/null || true
	@echo ""
	@echo "NOTE: skhd と yabai にはアクセシビリティ権限が必要です。"
	@echo "  1. システム設定 > プライバシーとセキュリティ > アクセシビリティ を開く"
	@echo "  2. /opt/homebrew/bin/skhd と /opt/homebrew/bin/yabai を追加して有効化"
	@echo "  3. 実行: skhd --restart-service && yabai --restart-service"
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
# link: シンボリックリンクの作成
# ------------------------------------------------------------------------------
link: codex-skills
	@echo ""
	@echo "[link] シンボリックリンクの作成"
	@echo "------------------------------------------"
	@mkdir -p "$(BACKUP_DIRECTORY)"
	@# ホームディレクトリ直下のドットファイル
	@echo "ホームディレクトリのドットファイルをリンク中..."
	@cd "$(SRC_DIRECTORY)" && \
	for f in .??*; do \
		if [ "$$f" = ".git" ] || [ "$$f" = ".config" ] || [ "$$f" = ".claude" ] || [ "$$f" = ".local" ]; then \
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
	@mkdir -p "$(HOME)/.config/skhd"
	@ln -snfv "$(SRC_DIRECTORY)/.config/skhd/skhdrc" "$(HOME)/.config/skhd/skhdrc"
	@ln -snfv "$(SRC_DIRECTORY)/.config/skhd/skhdrc" "$(HOME)/.skhdrc"
	@mkdir -p "$(HOME)/.config/yabai"
	@ln -snfv "$(SRC_DIRECTORY)/.config/yabai/yabairc" "$(HOME)/.config/yabai/yabairc"
	@# VSCode settings.json
	@echo ""
	@echo "VSCode の設定ファイルをリンク中..."
	@mkdir -p "$(HOME)/Library/Application Support/Code/User"
	@ln -snfv "$(SRC_DIRECTORY)/.config/Code/User/settings.json" "$(HOME)/Library/Application Support/Code/User/settings.json"
	@# skhd と yabai をリロード（設定を即時反映）
	@echo ""
	@echo "skhd と yabai の設定をリロード中..."
	@skhd --reload 2>/dev/null || true
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
	@# ホームディレクトリ配下（個別ファイル）
	@echo ""
	@echo "ホームディレクトリ配下の設定ファイルをリンク中..."
	@mkdir -p "$(HOME)/.claude"
	@ln -snfv "$(SRC_DIRECTORY)/.claude/CLAUDE.md" "$(HOME)/.claude/CLAUDE.md"
	@ln -snfv "$(SRC_DIRECTORY)/.claude/settings.json" "$(HOME)/.claude/settings.json"
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
	@echo "  make link              - シンボリックリンクを作成"
	@echo "  make codex-skills      - Claude Code のスキルを Codex に共有"
	@echo "  make claude-mcp             - Claude Code MCP サーバーを設定"
	@echo "  make claude-mem             - claude-mem を Claude Code / Codex に導入"
	@echo "  make vscode-extensions      - VSCode 拡張機能をインストール"
	@echo "  make help                   - このヘルプを表示"

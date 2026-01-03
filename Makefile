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
DOT_DIRECTORY := $(HOME)/dotfiles
SRC_DIRECTORY := $(DOT_DIRECTORY)/src
BACKUP_DIRECTORY := $(HOME)/.backup/dotfiles
OS := $(shell uname -s)

.PHONY: all init link brew packages plugins macos-setup claude-mcp cursor-extensions help

# デフォルトターゲット
all: init link
	@echo ""
	@echo "=========================================="
	@echo "セットアップが完了しました！"
	@echo "=========================================="

# ------------------------------------------------------------------------------
# init: Homebrew とパッケージのインストール
# ------------------------------------------------------------------------------
init: brew packages plugins claude-mcp cursor-extensions macos-setup
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

# Cursor 拡張機能のインストール
cursor-extensions:
	@echo ""
	@echo "[init] Cursor 拡張機能のインストール"
	@echo "------------------------------------------"
	@if command -v cursor &> /dev/null; then \
		EXTENSION_FILE="$(SRC_DIRECTORY)/.config/cursor/extensions.txt"; \
		if [ -f "$$EXTENSION_FILE" ]; then \
			INSTALLED=$$(cursor --list-extensions); \
			WANTED=$$(grep -v '^\s*$$' "$$EXTENSION_FILE" | grep -v '^\s*#'); \
			echo "不要な拡張機能を削除中..."; \
			for ext in $$INSTALLED; do \
				if ! echo "$$WANTED" | grep -qFxi "$$ext"; then \
					echo "  アンインストール: $$ext"; \
					cursor --uninstall-extension "$$ext" 2>/dev/null || true; \
				fi; \
			done; \
			echo ""; \
			echo "必要な拡張機能をインストール中..."; \
			for ext in $$WANTED; do \
				if echo "$$INSTALLED" | grep -qFxi "$$ext"; then \
					echo "  既存: $$ext"; \
				else \
					echo "  インストール: $$ext"; \
					cursor --install-extension "$$ext" 2>/dev/null || true; \
				fi; \
			done; \
			echo "Cursor 拡張機能の同期が完了しました。"; \
		else \
			echo "extensions.txt が見つかりません。スキップします。"; \
		fi; \
	else \
		echo "Cursor がインストールされていません。スキップします。"; \
		echo "Cursor をインストール後、'cursor' コマンドを PATH に追加してください。"; \
	fi

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
# link: シンボリックリンクの作成
# ------------------------------------------------------------------------------
link:
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
	@mkdir -p "$(HOME)/.config/zellij"
	@ln -snfv "$(SRC_DIRECTORY)/.config/zellij/config.kdl" "$(HOME)/.config/zellij/config.kdl"
	@mkdir -p "$(HOME)/.config/sheldon"
	@ln -snfv "$(SRC_DIRECTORY)/.config/sheldon/plugins.toml" "$(HOME)/.config/sheldon/plugins.toml"
	@mkdir -p "$(HOME)/.config/starship"
	@ln -snfv "$(SRC_DIRECTORY)/.config/starship/starship.toml" "$(HOME)/.config/starship/starship.toml"
	@# .config 配下（macOS専用）
ifeq ($(OS),Darwin)
	@echo ""
	@echo ".config 配下の設定ファイルをリンク中（macOS専用）..."
	@mkdir -p "$(HOME)/.config/ghostty"
	@ln -snfv "$(SRC_DIRECTORY)/.config/ghostty/config" "$(HOME)/.config/ghostty/config"
	@mkdir -p "$(HOME)/.config/skhd"
	@ln -snfv "$(SRC_DIRECTORY)/.config/skhd/skhdrc" "$(HOME)/.config/skhd/skhdrc"
	@mkdir -p "$(HOME)/.config/yabai"
	@ln -snfv "$(SRC_DIRECTORY)/.config/yabai/yabairc" "$(HOME)/.config/yabai/yabairc"
endif
	@# .local/bin 配下のスクリプト
	@echo ""
	@echo ".local/bin 配下のスクリプトをリンク中..."
	@mkdir -p "$(HOME)/.local/bin"
	@cd "$(SRC_DIRECTORY)/.local/bin" && \
	for f in *; do \
		if [ -f "$$f" ]; then \
			chmod +x "$(SRC_DIRECTORY)/.local/bin/$$f"; \
			ln -snfv "$(SRC_DIRECTORY)/.local/bin/$$f" "$(HOME)/.local/bin/$$f"; \
		fi; \
	done
	@# ホームディレクトリ配下（個別ファイル）
	@echo ""
	@echo "ホームディレクトリ配下の設定ファイルをリンク中..."
	@mkdir -p "$(HOME)/.claude"
	@ln -snfv "$(SRC_DIRECTORY)/.claude/CLAUDE.md" "$(HOME)/.claude/CLAUDE.md"
	@ln -snfv "$(SRC_DIRECTORY)/.claude/settings.json" "$(HOME)/.claude/settings.json"
	@# .claude/agents 配下
	@echo ""
	@echo ".claude/agents 配下のエージェント設定をリンク中..."
	@mkdir -p "$(HOME)/.claude/agents"
	@cd "$(SRC_DIRECTORY)/.claude/agents" && \
	for f in *.md; do \
		if [ -f "$$f" ]; then \
			ln -snfv "$(SRC_DIRECTORY)/.claude/agents/$$f" "$(HOME)/.claude/agents/$$f"; \
		fi; \
	done
	@# .claude/commands 配下
	@echo ""
	@echo ".claude/commands 配下のコマンド設定をリンク中..."
	@mkdir -p "$(HOME)/.claude/commands"
	@cd "$(SRC_DIRECTORY)/.claude/commands" && \
	for f in *.md; do \
		if [ -f "$$f" ]; then \
			ln -snfv "$(SRC_DIRECTORY)/.claude/commands/$$f" "$(HOME)/.claude/commands/$$f"; \
		fi; \
	done
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
	@echo "  make claude-mcp        - Claude Code MCP サーバーを設定"
	@echo "  make cursor-extensions - Cursor 拡張機能をインストール"
	@echo "  make help              - このヘルプを表示"

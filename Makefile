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

.PHONY: all init link brew packages plugins macos-setup claude-mcp help

# デフォルトターゲット
all: init link
	@echo ""
	@echo "=========================================="
	@echo "セットアップが完了しました！"
	@echo "=========================================="

# ------------------------------------------------------------------------------
# init: Homebrew とパッケージのインストール
# ------------------------------------------------------------------------------
init: brew packages plugins claude-mcp macos-setup
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
		echo "MCP サーバーの設定が完了しました。"; \
	else \
		echo "Claude Code がインストールされていません。スキップします。"; \
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
		if [ "$$f" = ".git" ] || [ "$$f" = ".config" ] || [ "$$f" = ".claude" ]; then \
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
	@# ホームディレクトリ配下（個別ファイル）
	@echo ""
	@echo "ホームディレクトリ配下の設定ファイルをリンク中..."
	@mkdir -p "$(HOME)/.claude"
	@ln -snfv "$(SRC_DIRECTORY)/.claude/CLAUDE.md" "$(HOME)/.claude/CLAUDE.md"
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
	@echo "  make all        - init と link を実行（フルセットアップ）"
	@echo "  make init       - Homebrew とパッケージをインストール"
	@echo "  make link       - シンボリックリンクを作成"
	@echo "  make claude-mcp - Claude Code MCP サーバーを設定"
	@echo "  make help       - このヘルプを表示"

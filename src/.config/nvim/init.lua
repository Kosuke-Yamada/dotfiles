-- =============================================================================
-- Neovim 設定ファイル
-- =============================================================================

-- 基本設定
vim.opt.number = true           -- 行番号を表示
vim.opt.relativenumber = true   -- 相対行番号
vim.opt.cursorline = true       -- カーソル行をハイライト
vim.opt.expandtab = true        -- タブをスペースに展開
vim.opt.tabstop = 2             -- タブ幅
vim.opt.shiftwidth = 2          -- インデント幅
vim.opt.smartindent = true      -- スマートインデント
vim.opt.wrap = false            -- 行の折り返しを無効
vim.opt.ignorecase = true       -- 検索時に大文字小文字を無視
vim.opt.smartcase = true        -- 大文字が含まれる場合は区別
vim.opt.hlsearch = true         -- 検索結果をハイライト
vim.opt.incsearch = true        -- インクリメンタルサーチ
vim.opt.termguicolors = true    -- True Color を有効
vim.opt.scrolloff = 8           -- スクロール時の余白
vim.opt.signcolumn = "yes"      -- サイン列を常に表示
vim.opt.updatetime = 250        -- 更新間隔を短縮
vim.opt.timeoutlen = 300        -- キーマップのタイムアウト
vim.opt.splitbelow = true       -- 水平分割は下に
vim.opt.splitright = true       -- 垂直分割は右に
vim.opt.clipboard = "unnamedplus" -- システムクリップボードを使用
vim.opt.mouse = "a"             -- マウスを有効化
vim.opt.encoding = "utf-8"      -- エンコーディング
vim.opt.fileencoding = "utf-8"  -- ファイルエンコーディング

-- リーダーキーの設定
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =============================================================================
-- キーマップ
-- =============================================================================

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 保存・終了
keymap("n", "<leader>w", ":w ", { noremap = true, silent = false, desc = "名前をつけて保存" })
keymap("n", "<leader>q", ":q<CR>", { noremap = true, silent = true, desc = "終了" })
keymap("n", "<leader>Q", ":q!<CR>", { noremap = true, silent = true, desc = "強制終了" })
keymap("n", "<leader>x", ":x<CR>", { noremap = true, silent = true, desc = "保存して終了" })

-- ウィンドウ操作
keymap("n", "<C-h>", "<C-w>h", { noremap = true, silent = true, desc = "左のウィンドウへ" })
keymap("n", "<C-j>", "<C-w>j", { noremap = true, silent = true, desc = "下のウィンドウへ" })
keymap("n", "<C-k>", "<C-w>k", { noremap = true, silent = true, desc = "上のウィンドウへ" })
keymap("n", "<C-l>", "<C-w>l", { noremap = true, silent = true, desc = "右のウィンドウへ" })

-- バッファ操作
keymap("n", "<leader>bn", ":bnext<CR>", { noremap = true, silent = true, desc = "次のバッファ" })
keymap("n", "<leader>bp", ":bprevious<CR>", { noremap = true, silent = true, desc = "前のバッファ" })
keymap("n", "<leader>bd", ":bdelete<CR>", { noremap = true, silent = true, desc = "バッファを閉じる" })

-- 検索ハイライトを解除
keymap("n", "<Esc>", ":nohlsearch<CR>", opts)

-- ビジュアルモードでのインデント調整（選択を維持）
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- 行の移動
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- =============================================================================
-- ステータスライン（コマンドヒント表示）
-- =============================================================================

-- グローバルステータスラインを使用（画面最下部に常に表示）
vim.opt.laststatus = 3

-- コマンドラインの高さ（1行）
vim.opt.cmdheight = 1

-- ヒント1行目（winbar用）
function _G.winbar_hints()
  local mode = vim.fn.mode()

  if mode == "n" then
    return " [NORMAL] i:挿入 │ v:選択 │ V:行選択 │ /:検索 │ ::コマンド │ u:取消 │ <C-r>:やり直し"
  elseif mode == "i" then
    return " [INSERT] <Esc>:ノーマル │ <C-w>:単語削除 │ <C-u>:行頭まで削除 │ <C-o>:一時ノーマル"
  elseif mode == "v" or mode == "V" or mode == "\22" then
    return " [VISUAL] <Esc>:ノーマル │ y:コピー │ d:削除 │ c:変更 │ >/<:インデント │ J/K:行移動"
  elseif mode == "c" then
    return " [COMMAND] <Esc>:キャンセル │ <Tab>:補完 │ <C-p>/<C-n>:履歴"
  else
    return ""
  end
end

-- ヒント2行目（statusline用）
function _G.statusline_hints()
  local mode = vim.fn.mode()

  if mode == "n" then
    return "dd:行削除 │ yy:コピー │ p:貼付 │ w:単語移動 │ <Space>w:保存 │ <Space>q:終了 │ <Space>Q:強制終了"
  elseif mode == "i" then
    return "<C-n>:補完 │ <C-p>:補完(逆) │ <C-t>:インデント+ │ <C-d>:インデント-"
  elseif mode == "v" or mode == "V" or mode == "\22" then
    return "gq:整形 │ ~:大小変換 │ u/U:小文字/大文字 │ o:選択反転 │ I/A:矩形挿入"
  elseif mode == "c" then
    return ":w:保存 │ :q:終了 │ :wq:保存終了 │ :q!:強制終了 │ :%s/old/new/g:置換"
  else
    return ""
  end
end

-- タブライン（画面最上部）にヒント1行目を表示
vim.opt.showtabline = 2
vim.opt.tabline = "%{%v:lua.winbar_hints()%}"

-- winbar（タブラインの下）にヒント2行目を表示
vim.opt.winbar = "%{%v:lua.statusline_hints()%}"

-- ステータスライン（ファイル情報のみ）
vim.opt.statusline = table.concat({
  " %f",                           -- ファイル名
  "%m",                            -- 修正フラグ
  "%r",                            -- 読み取り専用フラグ
  "%=",                            -- 右寄せ
  " %l:%c ",                       -- 行:列
  " %{&fileencoding?&fileencoding:&encoding}", -- エンコーディング
  " [%{&fileformat}] ",            -- ファイルフォーマット
})

-- =============================================================================
-- ヒント行の色を統一
-- =============================================================================

-- tablineとwinbarを同じ色に設定
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    local hint_bg = "#3c3836"
    local hint_fg = "#ebdbb2"
    vim.api.nvim_set_hl(0, "TabLine", { fg = hint_fg, bg = hint_bg })
    vim.api.nvim_set_hl(0, "TabLineFill", { fg = hint_fg, bg = hint_bg })
    vim.api.nvim_set_hl(0, "TabLineSel", { fg = hint_fg, bg = hint_bg })
    vim.api.nvim_set_hl(0, "WinBar", { fg = hint_fg, bg = hint_bg })
    vim.api.nvim_set_hl(0, "WinBarNC", { fg = hint_fg, bg = hint_bg })
  end,
})

-- 起動時にも適用
local hint_bg = "#3c3836"
local hint_fg = "#ebdbb2"
vim.api.nvim_set_hl(0, "TabLine", { fg = hint_fg, bg = hint_bg })
vim.api.nvim_set_hl(0, "TabLineFill", { fg = hint_fg, bg = hint_bg })
vim.api.nvim_set_hl(0, "TabLineSel", { fg = hint_fg, bg = hint_bg })
vim.api.nvim_set_hl(0, "WinBar", { fg = hint_fg, bg = hint_bg })
vim.api.nvim_set_hl(0, "WinBarNC", { fg = hint_fg, bg = hint_bg })

-- モード変更時にステータスラインとwinbarを更新
vim.api.nvim_create_autocmd({ "ModeChanged" }, {
  pattern = "*",
  callback = function()
    vim.cmd("redrawstatus")
    vim.cmd("redrawtabline")
  end,
})

-- =============================================================================
-- その他の便利な設定
-- =============================================================================

-- ファイルタイプごとの設定を有効化
vim.cmd("filetype plugin indent on")

-- シンタックスハイライトを有効化
vim.cmd("syntax enable")

-- 不可視文字の表示
vim.opt.list = true
vim.opt.listchars = {
  tab = "→ ",
  trail = "·",
  extends = "»",
  precedes = "«",
}

-- ファイル保存時に末尾の空白を削除
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- ターミナルモードでEscでノーマルモードに戻る
keymap("t", "<Esc>", "<C-\\><C-n>", opts)

-- カーソル位置を記憶
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

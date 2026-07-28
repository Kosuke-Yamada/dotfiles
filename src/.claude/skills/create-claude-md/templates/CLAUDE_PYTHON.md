# CLAUDE_PYTHON_TEMPLATE.md

Pythonプロジェクト向けのClaude Code指示テンプレート。
新規プロジェクト作成時に `CLAUDE.md` へコピーして使用すること。

---

## 🚨 CRITICAL INSTRUCTIONS (最優先事項)

### Golden Rule

> **「依存関係は事前管理、実行は uv run」**

依存関係の追加（`uv add`）はスクリプト実行とは**分離**して事前に行うこと。
すべての依存関係は `pyproject.toml` で管理し、実行時には `uv run` のみを使用せよ。

```bash
# ✅ 正しいフロー
# 1. 事前に依存関係を追加（開発時のみ）
uv add pandas polars

# 2. 実行時は uv run のみ
uv run python src/train.py
```

```bash
# ❌ 避けるべきパターン
uv add pandas && uv run python src/train.py  # 実行時にパッケージ追加しない
```

### Execution

Pythonスクリプトの実行は、必ず以下の形式で行うこと：

```bash
uv run python [script_path]
```

> ⚠️ 直接 `python` コマンドを使用しない

### No Notebook Edits

ロジックの変更やバグ修正のために `.ipynb` ファイルを直接編集してはならない。

- ✅ `src/` 内のPythonモジュールを修正
- ✅ Notebookはそれをインポートして再実行するのみ
- ❌ Notebook内でロジックを実装

### Reproducibility First

すべての学習コードは**決定論的（Deterministic）**でなければならない。

- 乱数シード（Python, NumPy, Torch）を固定
- CUDAの決定論的モードを有効化

### Data Safety

> 10MBを超えるデータファイルを直接コンテキストに読み込んではならない

`head()` や schema 確認用スクリプトを用いて構造のみを把握せよ。

---

## 🏗️ Architecture & Structure (ディレクトリ構造)

```
project-root/
├── src/           # プロダクションコード
├── notebooks/     # 実験・EDA・プロトタイプ
├── tests/         # テストコード
├── configs/       # 設定ファイル (YAML)
├── script/        # シェルスクリプト
└── data/          # データ (.gitignore対象)
```

### 各ディレクトリの責務

| ディレクトリ | 責務 | ルール |
|-------------|------|--------|
| `src/` | プロダクションコードの唯一の保管場所 | 厳密な型ヒント + GoogleスタイルDocstrings必須 |
| `notebooks/` | 実験、EDA、プロトタイプ用 | 「使い捨て」- 永続的なロジックを含めない |
| `tests/` | `src/` に対応するテストコード | `pytest` を使用 |
| `configs/` | 実験設定ファイル | **YAML形式 (.yaml)** 必須。コード内ハードコード禁止 |
| `script/` | シェルスクリプト (.sh) | 複雑な `uv run` コマンドチェーンをラップ |
| `data/` | データファイル | `.gitignore` 必須。AIは直接読み込み禁止 |

---

## 🛠️ Technology Stack & Standards (技術スタック)

### Package Manager: `uv` + `pyproject.toml`

すべての依存関係は `pyproject.toml` で一元管理する。

| 操作 | コマンド | タイミング |
|------|---------|-----------|
| パッケージ追加 | `uv add <package>` | 開発時（事前） |
| 開発用パッケージ追加 | `uv add --dev <package>` | 開発時（事前） |
| パッケージ削除 | `uv remove <package>` | 開発時 |
| 依存関係同期 | `uv sync` | clone直後 / CI |
| スクリプト実行 | `uv run python <script>` | 実行時 |

> ⚠️ `pip` コマンドは直接使用しない
> 依存関係追加後は `pyproject.toml` と `uv.lock` の更新を確認すること
> 実行時に `uv add` を行わないこと（依存関係は事前に追加済みであること）

### DataFrames: Polars (推奨)

- パフォーマンスとメモリ効率のため、**Pandas より Polars を優先**
- 可能な限り `pl.LazyFrame` を使用し、遅延評価を活用

### ML Framework: PyTorch

- 推論時には `torch.compile` を活用して最適化

### Linting / Formatting: `ruff`

コミット前に必ず `ruff` を適用すること（lint と format の両方を担う）：

```bash
# Lint + 自動修正
uv run ruff check . --fix

# フォーマット
uv run ruff format .
```

> ⚠️ `black`, `isort` は使用しない（ruff に統一）
> Python 3.10+ の最新型ヒント (`X | Y`, `list[int]`) を使用すること

### Logging

- ❌ 標準の `print()` は禁止
- ✅ `structlog` 等の構造化ロガーを使用
- ❌ 外部の実験管理ツール (MLflow/W&B) は使用しない

---

## 🧪 Testing Strategy (品質保証)

| テスト種別 | ツール | 目的 |
|-----------|--------|------|
| Unit Tests | `pytest` | ロジックの正当性を検証 |
| Property-Based Tests | `hypothesis` | データ変換のエッジケースを網羅的にテスト |
| Schema Validation | `pandera` | データパイプラインの入出力を実行時検証 |

### テスト実行コマンド

```bash
uv run pytest tests/ -v --cov=src
```

---

## 🤖 Common Commands (頻出コマンド集)

```bash
# セットアップ
uv sync

# Lint & Format
uv run ruff check . --fix && uv run ruff format .

# テスト実行
uv run pytest tests/

# 学習実行 (例)
uv run python src/train.py --config configs/experiment_v1.yaml

# データ確認
uv run python script/inspect_data.py --path data/raw/train.csv
```

---

## 🔒 Security & Safety (セキュリティ)

### Secrets

- ❌ APIキーをコードにハードコードしてはならない
- ✅ `python-dotenv` を使用し、`.env` ファイルから読み込む

### Model Safety

- ❌ 信頼できないソースからのシリアライズファイル読み込みは禁止
- ✅ `safetensors` 形式を優先

---

## 💡 運用上のヒント

### タスク依頼の例

#### データ前処理パイプライン作成

```
「CLAUDE.md の指示に従い、src/ にデータ前処理のパイプラインを作成してください。
使用するライブラリはPolarsで、設定は configs/preprocess.yaml に切り出してください。」
```

#### シェルスクリプト作成

```
「今の実験コマンドが長くなったので、script/run_experiment_v2.sh という
シェルスクリプトにまとめて、uv run で実行できるようにしてください。」
```

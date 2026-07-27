# CLAUDE_STREAMLIT.md

Streamlit アプリケーション開発のためのガイドライン

---

## 🛠 Commands (よく使うコマンド)

| コマンド | 説明 |
|----------|------|
| `streamlit run streamlit_app.py` | アプリ起動 |
| `ruff check . --fix` | リント & 自動修正 |
| `ruff format .` | フォーマット |
| `pytest tests/ -v` | テスト (全体) |
| `pytest tests/e2e -v` | テスト (E2E) |
| `mypy .` | 型チェック |
| `uv sync` | 依存関係インストール |
| `rm -rf .pytest_cache .ruff_cache .mypy_cache __pycache__` | キャッシュ削除 |

---

## 🏗 Architecture & File Structure

```
project/
├── streamlit_app.py      # Entry Point (最小限の構成にする)
├── src/
│   ├── components/       # 再利用可能なUI部品 (純粋関数)
│   ├── utils/            # 純粋なPythonロジック (※streamlitをimportしない)
│   ├── models/           # Pydanticモデル (データ検証・スキーマ定義)
│   └── pages/            # マルチページアプリ用サブページ
├── tests/
│   ├── unit/             # src/utils, src/models 用の単体テスト
│   └── e2e/              # AppTest を使用した統合テスト
└── pyproject.toml
```

### ディレクトリ設計ルール

| ディレクトリ | 役割 | 注意事項 |
|--------------|------|----------|
| `components/` | 再利用可能なUI部品 | 状態を持たず、引数を受け取って描画する純粋関数として定義 |
| `utils/` | データ処理、APIクライアント | **`streamlit` をインポートしてはいけない** |
| `models/` | Pydanticモデル | データ検証、スキーマ定義用 |
| `pages/` | サブページ | マルチページアプリ用 |

---

## 🧠 Streamlit Coding Standards

### 1. 実行モデルと状態管理 (State Management)

#### リランの意識

> ユーザーの操作（クリックや入力）ごとに、スクリプト全体が **先頭から再実行** されることを常に意識すること。

#### セッション状態 (`st.session_state`)

- 変数の永続化には **必ず** `st.session_state` を使用する
- **初期化パターン**: 以下の「存在確認→初期化」パターンを厳守

```python
if 'key' not in st.session_state:
    st.session_state.key = default_value
```

> ⚠️ グローバル変数やクラス属性での状態管理は **禁止**（リラン時にリセットされるため）

---

### 2. キャッシュ戦略 (Caching)

| デコレータ | 用途 | 例 |
|------------|------|-----|
| `@st.cache_data` | シリアライズ可能なオブジェクト | DataFrameの処理、APIレスポンス |
| `@st.cache_resource` | シリアライズ不可なリソース | DB接続、MLモデル |

```python
@st.cache_data(ttl=3600)  # TTL設定を忘れずに
def fetch_data(url: str) -> pd.DataFrame:
    return pd.read_csv(url)

@st.cache_resource
def get_db_connection():
    return create_connection()
```

> 💡 データが古くなる可能性がある場合は、必ず `ttl` パラメータを設定すること

---

### 3. UI/UX & ウィジェット

#### ユニークキー

ループや条件分岐内で生成するウィジェットには、**必ず一意な `key=` 引数を付与**:

```python
for i, item in enumerate(items):
    st.text_input(f"Item {i}", key=f"input_{i}")
```

#### フォーム

バッチ入力が必要な場合は `st.form` を使用し、過剰なリランを防ぐ:

```python
with st.form("my_form"):
    name = st.text_input("Name")
    submitted = st.form_submit_button("Submit")
    if submitted:
        process(name)
```

#### フィードバック

| 用途 | ウィジェット |
|------|-------------|
| 重い処理中 | `st.spinner` |
| 完了通知 | `st.toast` |

#### レイアウト

- 生のHTML/CSS注入は **避ける**
- `st.columns`, `st.container`, `st.expander` を活用

---

### 4. Python実装ルール

| ルール | 詳細 |
|--------|------|
| Lint/Format | Ruffの設定に従う。コード生成後は必ずリントを実行 |
| 型ヒント | **すべての関数に型ヒントを記述**（Pydanticモデル推奨） |
| Secrets | `st.secrets` 経由でアクセス。**ハードコーディング禁止** |

```python
# Good
api_key = st.secrets["API_KEY"]

# Bad
api_key = "sk-xxx..."  # 絶対にNG
```

---

## 🧪 Testing Guidelines

### AppTest を使用したテスト

UIテストには `streamlit.testing.v1.AppTest` を使用する。

> SeleniumやPlaywrightではなく、**Streamlitネイティブのヘッドレステスト**を優先

#### 実装例

```python
from streamlit.testing.v1 import AppTest

def test_app_interaction():
    at = AppTest.from_file("streamlit_app.py")
    at.run()
    at.text_input(key="user_input").input("Claude").run()
    assert at.markdown.value == "Hello, Claude!"
```

---

## 📦 Tech Stack

| 項目 | バージョン/ツール |
|------|------------------|
| Python | 3.11+ |
| Framework | Streamlit 1.35+ |
| Linting/Formatting | Ruff |
| Testing | Pytest + AppTest |
| Package Manager | uv |

---

## 📄 推奨設定ファイル

### `pyproject.toml`

```toml
[project]
name = "streamlit-ai-app"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "streamlit>=1.35.0",
    "pydantic>=2.0.0",
]

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
# E: pycodestyle, F: Pyflakes, I: isort, B: Bugbear (バグ検知)
select = ["E", "F", "I", "B"]

[tool.ruff.format]
quote-style = "double"

[tool.pytest.ini_options]
addopts = "-ra -q"
testpaths = ["tests"]
```

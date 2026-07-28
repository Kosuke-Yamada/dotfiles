# CLAUDE_REACT_FASTAPI.md

React + FastAPI フルスタック開発のためのガイドライン

---

## 🚨 CRITICAL RULES (絶対遵守事項)

> このプロジェクトでは以下のルールを **厳守** すること。

### パッケージ管理

| 対象 | 使用ツール | 禁止ツール |
|------|-----------|-----------|
| Backend | `uv` | pip, poetry |
| Frontend | `npm` | yarn, pnpm |

```bash
# Backend
uv add <package>      # パッケージ追加
uv run <command>      # コマンド実行

# Frontend
npm install <package>
npm run <script>
```

### 厳格な型安全性

| 言語 | ルール |
|------|--------|
| Python | Pydantic V2構文 (`model_config`) を使用。型ヒント (`list[str]` 等) 必須 |
| TypeScript | `any` 型の使用 **禁止**。必ず Interface または Type を定義 |

### コード品質

- ❌ プレースホルダーコード（`pass` や `// TODO` で終わる実装）を残さない
- ❌ エラーハンドリングを省略しない（例外を握りつぶさない）

---

## 📍 PROJECT CONTEXT (プロジェクト文脈)

### Architecture

| 項目 | 内容 |
|------|------|
| Type | Full-stack Web Application (Monorepo) |
| Backend | FastAPI (Python 3.12+), SQLAlchemy (Async), Pydantic v2 |
| Frontend | React 19, TypeScript, Vite, TailwindCSS 4, Shadcn/UI |
| Database | PostgreSQL (Prod), SQLite (Dev) |
| API | REST API. Frontend proxies `/api` requests to backend via Vite |

### Directory Structure

```
project/
├── backend/
│   └── app/
│       ├── api/          # Endpoints (Routers)
│       ├── schemas/      # Pydantic models ⭐ Source of Truth for API Contract
│       └── services/     # Business Logic
│
└── frontend/
    └── src/
        ├── features/     # Domain-specific modules (Components, Hooks, API calls)
        └── lib/
            └── api.ts    # Central Axios instance
```

> ⭐ **Source of Truth**: API コントラクト（仕様）の正解は `backend/app/schemas` にある

---

## 🛠️ DEVELOPMENT COMMANDS (開発コマンド)

### Backend (`/backend` or Root via uv)

| コマンド | 説明 |
|----------|------|
| `uv run fastapi dev backend/app/main.py` | 開発サーバー起動 |
| `uv run ruff check . --fix` | リント & 自動修正 |
| `uv run ruff format .` | フォーマット |
| `uv run pytest` | テスト実行 |
| `uv run mypy .` | 型チェック |
| `uv run alembic revision --autogenerate -m "msg"` | マイグレーション作成 |
| `uv run alembic upgrade head` | マイグレーション適用 |

**エンドポイント:**
- Dev Server: http://127.0.0.1:8000
- API Docs: http://127.0.0.1:8000/docs

### Frontend (`/frontend`)

| コマンド | 説明 | ツール |
|----------|------|--------|
| `npm run dev` | 開発サーバー起動 | Vite |
| `npm run test` | テスト実行 | Vitest |
| `npm run lint` | リント | ESLint |
| `npm run format` | フォーマット | Prettier |
| `npm run typecheck` | 型チェック | tsc |

**エンドポイント:**
- Dev Server: http://localhost:5173

---

## 🧩 CODING STANDARDS (コーディング規約)

### Python / FastAPI

#### Router-Service Pattern

```
api/ (Router) → services/ (Logic) → schemas/ (Validation)
```

> ルートハンドラ (`api/`) にはロジックを書かない。`services/` 層に委譲し、`schemas/` で入出力を検証する。

#### Async/Await

> ⚠️ 全てのDB操作と外部API呼び出しは **async** でなければならない

```python
# ✅ Good
async def get_users(db: AsyncSession) -> list[User]:
    result = await db.execute(select(User))
    return result.scalars().all()

# ❌ Bad (同期関数によるブロッキング)
def get_users(db: Session) -> list[User]:
    return db.query(User).all()
```

#### Pydantic V2

```python
# ❌ V1 (使用禁止)
class UserSchema(BaseModel):
    class Config:
        orm_mode = True

# ✅ V2
class UserSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
```

#### Dependency Injection

```python
# ✅ Good - Depends() を使用
async def get_users(
    db: AsyncSession = Depends(get_db),
    service: UserService = Depends()
) -> list[UserSchema]:
    return await service.get_all(db)

# ❌ Bad - グローバル変数
db = get_global_db()  # 避ける
```

---

### React / TypeScript

#### コンポーネント定義

```typescript
// ✅ Functional Components
const Component = () => {
  return <div>...</div>
}

// ❌ Class Components (使用しない)
class Component extends React.Component { ... }
```

#### データ取得

```typescript
// ✅ Good - TanStack Query
const { data, isLoading } = useQuery({
  queryKey: ['users'],
  queryFn: fetchUsers,
})

// ❌ Bad - useEffect (Race conditionの温床)
useEffect(() => {
  fetchUsers().then(setData)
}, [])
```

#### スタイリング

```typescript
// Tailwind Utility Classes を使用
// 複雑な条件分岐には cn() ユーティリティ
import { cn } from '@/lib/utils'

<button className={cn(
  "px-4 py-2 rounded",
  isActive && "bg-blue-500",
  isDisabled && "opacity-50"
)}>
```

#### インポート

```typescript
// ✅ 絶対パス
import { Button } from '@/components/ui/button'

// ❌ 相対パス (深いネストで可読性低下)
import { Button } from '../../../components/ui/button'
```

#### テスト

- **ツール**: Vitest + React Testing Library
- **方針**: ユーザーの振る舞いをテストし、実装詳細には依存しない

```typescript
// ✅ Good - ユーザー視点でテスト
expect(screen.getByRole('button', { name: 'Submit' })).toBeEnabled()

// ❌ Bad - 実装詳細に依存
expect(component.state.isSubmitting).toBe(false)
```

---

## 🧠 MEMORY & ETIQUETTE (記憶と作法)

### API変更時の同期

> ⚠️ Backend の Pydantic モデルを変更した場合は、**必ず** Frontend の TypeScript 型定義も同期して更新すること

```
backend/app/schemas/user.py  ←→  frontend/src/features/user/types.ts
```

### Git

- コミットメッセージは **Conventional Commits** に従う

```bash
feat: add user login API
fix: resolve race condition in data fetching
refactor: extract common validation logic
```

### 環境変数

- 機密情報は `.env` にのみ記述し、コードにはハードコードしない

```python
# ✅ Good
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    secret_key: str

# または
import os
api_key = os.getenv("API_KEY")

# ❌ Bad
api_key = "sk-xxx..."  # 絶対にNG
```

---

## 📚 実践的ワークフロー

### 1. 初期セットアップ (オンボーディング)

新しいセッション開始時に以下を確認:

```
「CLAUDE.md の PROJECT CONTEXT と CRITICAL RULES を読み込み、
このプロジェクトのアーキテクチャと使用すべきパッケージマネージャーについて要約してください。」
```

### 2. 機能追加時のフロー

```
「Todo機能を追加したい。

1. まず backend/app/schemas にPydanticモデルを定義し、
2. backend/app/api と backend/app/services にエンドポイントとロジックを実装し、
3. 最後に frontend/src/features/todo にReactコンポーネントを作成してください。

CODING STANDARDS に従い、型定義の同期と useQuery の使用を徹底してください。」
```

### 3. エラー修正とデバッグ

```
「テストが失敗している。エラーログは以下の通り。
CLAUDE.md に記載されたバックエンドのテストコマンドを実行し、
問題を特定・修正してください。」
```

---

## 📦 Tech Stack Summary

| Layer | Technologies |
|-------|--------------|
| Backend | Python 3.12+, FastAPI, SQLAlchemy (Async), Pydantic v2, Alembic |
| Frontend | React 19, TypeScript, Vite, TailwindCSS 4, Shadcn/UI, TanStack Query |
| Database | PostgreSQL (Prod), SQLite (Dev) |
| Testing | pytest (Backend), Vitest + RTL (Frontend) |
| Linting | Ruff (Backend), ESLint + Prettier (Frontend) |
| Package Manager | uv (Backend), npm (Frontend) |

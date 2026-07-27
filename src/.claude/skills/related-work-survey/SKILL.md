---
name: related-work-survey
description: >
  指定された研究テーマに関する関連研究を主要国際会議およびarXivからサーベイし、
  カテゴリ分類付きのMarkdownサーベイ文書を自動生成するスキル。
  /related-work-survey で呼び出す。
  「関連研究を調べて」「サーベイを作って」「先行研究をまとめて」
  「related workを書いて」「論文サーベイ」「研究動向を調査して」
  「Xに関する論文を探して」「最新の研究を調べて」「引用すべき論文は？」
  といった発言があった場合にこのスキルを使用すること。
  ユーザーが明示的に「サーベイ」「会議」「arXiv」と言及しなくても、
  研究論文の調査・収集・整理を求めている場合は積極的にこのスキルを使用せよ。
---

# 関連研究サーベイ自動生成

指定された研究テーマに関する関連論文をカンファレンス予稿集・arXiv・Google Scholar から検索・収集し、カテゴリ分類と詳細な要約を含むMarkdownサーベイ文書を自動生成する。

## 基本姿勢

- 出力テキストは全て**日本語**で記述する（論文タイトルは原文の英語のまま）
- カテゴリ名、カテゴリ説明、サマリーテーブルの各セル、詳細フィールド（一言要約、概要、動機、知見、貢献）は全て**日本語**で記述すること
- 各論文の詳細フィールドは**全自動生成**する
- abstract が取得できなかった論文はタイトルとvenueから推測し、「※abstract未取得のため推測」と注記する
- 不確実な情報には必ず注記を付ける
- 出力フォーマットは `assets/output_template.md` に従う

## 前提条件

### 依存パッケージ

`scripts/search_papers.py` は `requests` パッケージに依存する。初回実行時に自動インストールされる。

## 実行ステップ

### ステップ1: 研究テーマと検索条件の確認

ユーザーから研究テーマを受け取り、AskUserQuestion を使って以下を確認する:

1. **英語の検索クエリ**（複数可）: ユーザーが日本語で指定した場合は英訳候補を3つ程度提示して選択してもらう
2. **対象年範囲**: デフォルトは過去5年（例: 2021-2026）
3. **対象会議/分野**: デフォルトは全トップ会議 + arXiv。分野の絞り込み（NLP, ML, AI, IR, HCI, CV, MM, DB）も可能
4. **出力ファイルパス**: デフォルトは `./survey_{テーマの英語略称}_{YYYYMMDD}.md`
5. **追加の検索クエリ**: テーマの別表現や関連キーワードがあれば追加

トップ会議リスト（CORE2023ランキング準拠、参考情報としてユーザーに提示）:

| 分野 | A* | A | B (AI系) |
|------|-----|---|----------|
| NLP | ACL, EMNLP | NAACL, EACL | COLING, CoNLL, Findings* |
| ML | NeurIPS, ICML, ICLR, COLT | ECML-PKDD, AISTATS | |
| AI | AAAI, IJCAI, AAMAS | UAI, ECAI | |
| IR/DM | SIGIR, KDD, ICDM, WWW | WSDM, CIKM, SDM, ECIR, RecSys | PAKDD |
| HCI | CHI | | |
| CV | CVPR, ICCV, ECCV | WACV | ACCV |
| MM | ACMMM | ICME | ICMR |
| DB | SIGMOD, VLDB, ICDE, PODS | | |

*Findings はACL/EMNLP併設のためCOREランクなし

### ステップ2: 3フェーズ論文収集

**収集優先順位:** カンファレンス予稿集 → arXiv → Google Scholar

---

**フェーズ1 — カンファレンス予稿集サイトでの検索（最優先）:**

対象分野に応じて、以下の予稿集サイトを WebSearch または WebFetch で検索する。各サイトで上位10〜20件を収集し、タイトル・著者・年・venue・URLを記録する。

| 分野 | サイト | WebSearch クエリ例 |
|------|--------|-------------------|
| NLP | ACL Anthology | `site:aclanthology.org "{query}" {year_range}` |
| NLP | ACL Anthology (直接) | WebFetch: `https://aclanthology.org/search/?q={query}` |
| ML | PMLR (ICML/AISTATS/COLT 等) | `site:proceedings.mlr.press "{query}"` |
| ML | NeurIPS Proceedings | `site:papers.nips.cc OR site:proceedings.neurips.cc "{query}"` |
| ML | OpenReview (ICLR/UAI/ECAI 等) | `site:openreview.net "{query}" ICLR` |
| AI | AAAI | `site:ojs.aaai.org "{query}"` |
| AI | IJCAI | `site:ijcai.org/proceedings "{query}"` |
| AI | AAMAS | `site:ifaamas.org "{query}" OR site:dl.acm.org "{query}" AAMAS` |
| IR/DM | ACM DL (SIGIR/KDD/WWW/CIKM/WSDM/RecSys 等) | `site:dl.acm.org "{query}"` |
| IR/DM | IEEE (ICDM) | `site:ieeexplore.ieee.org "{query}" ICDM` |
| HCI | ACM DL (CHI) | `site:dl.acm.org "{query}" CHI` |
| CV | CVPR/ICCV/ECCV | `site:openaccess.thecvf.com "{query}"` |
| CV | WACV/ACCV | `site:openaccess.thecvf.com "{query}" WACV` |
| MM | ACM DL (ACMMM/ICMR) | `site:dl.acm.org "{query}" "ACM Multimedia"` |
| MM | IEEE (ICME) | `site:ieeexplore.ieee.org "{query}" ICME` |
| DB | ACM DL (SIGMOD/PODS) | `site:dl.acm.org "{query}" SIGMOD` |
| DB | VLDB/ICDE | `site:vldb.org "{query}" OR site:ieeexplore.ieee.org "{query}" ICDE` |

**NLP 分野の場合は必ず ACL Anthology を優先して検索すること。**

各フェーズ1論文には `venue_tier = "conference"` を付与する。

---

**フェーズ2 — arXiv 検索:**

`scripts/search_papers.py` を使って arXiv から論文を収集する。arXiv API は無料・認証不要。

```bash
python3 scripts/search_papers.py "{検索クエリ}" --year {年範囲} --limit 50
```

分野を絞る場合:

```bash
# 分野ショートハンドで指定 (NLP / ML / AI / CV / HCI / DB)
python3 scripts/search_papers.py "{検索クエリ}" --year {年範囲} --limit 50 --field NLP

# arXiv カテゴリを直接指定
python3 scripts/search_papers.py "{検索クエリ}" --year {年範囲} --limit 50 --categories cs.CL,cs.LG
```

**注意:** arXiv API は引用数を提供しない。優先度スコアは新しさ（recency）のみに基づく。

---

**フェーズ3 — Google Scholar / 広範囲検索:**

WebSearch で Google Scholar や一般的な学術検索を実施し、フェーズ1・2で見つからなかった重要論文を補完する:

- `"{query}" research paper {year_range} site:scholar.google.com`
- `"{query}" ACL EMNLP NeurIPS ICML {year_range}`
- `"{query}" arxiv {year_range}`

---

**全フェーズの結果を統合:**

- タイトルの類似性・DOI・arXiv IDに基づいて重複を除去する
- venue tier でソート: `conference` (フェーズ1) → `arxiv` (フェーズ2) → `other` (フェーズ3)
- 同一 tier 内は年度の新しい順（arXiv は recency スコアの降順）

**複数クエリがある場合:**
- 各クエリをフェーズ1〜3で順次または並列で実行する
- タイトル・DOI・arXiv IDに基づいて全クエリ結果の重複を除去する

**結果件数の調整:**
- 少なすぎる場合（< 10件）: クエリの言い換え、年範囲の拡大を提案
- 多すぎる場合（> 200件）: 年範囲の絞り込み、会議の絞り込みを提案

収集結果の件数を venue tier 別（conference / arxiv / other）でユーザーに報告する。

### ステップ3: WebFetch による詳細情報の補完

以下の情報を WebFetch ツールで補完する:

1. **abstract 未取得の論文**:
   - ACL Anthology 論文: `https://aclanthology.org/{ACL_id}` から abstract を取得
   - arXiv 論文: `https://arxiv.org/abs/{arXiv_id}` から abstract を取得
   - その他: 論文の公式ページまたは著者配布PDFページから取得

2. **コードリポジトリのURL**: Papers With Code (`https://paperswithcode.com`) や GitHub 検索で取得

3. **引用数（参考値）**: Google Scholar 検索結果ページから被引用数を取得（上位20件のみ）

**注意**: WebFetch は1論文あたりのコストが高いため、以下のルールで対象を絞る:
- abstract 未取得の論文は全て対象
- コードリポジトリ検索は重要度上位20件に限定
- 全論文の一括処理は避け、Agent ツールで並列化することを検討する

### ステップ4: カテゴリ分類

収集した全論文のタイトルと abstract を分析し、5-8個のカテゴリに自動分類する。

**分類の手順:**

1. 全論文のタイトルと abstract を一覧化する
2. テーマとの関連性を考慮し、研究アプローチ・対象タスク・手法の類似性に基づいて5-8個のカテゴリを決定する
3. 各カテゴリに**日本語**の名前と説明（2-3文）を付与する
4. 各論文を最も適切な1つのカテゴリに割り当てる
5. カテゴリ内での論文は: conference論文を先頭に（年度の降順）、続いてarXiv論文（recencyスコアの降順）

**分類結果の提示:**

分類結果を以下の形式でユーザーに提示し、調整希望があれば対応する:

```
カテゴリ分類の結果:

1. {カテゴリ名} ({N}件): {説明}
   - [conf] {論文タイトル1} ({year}, {venue})
   - [conf] {論文タイトル2} ({year}, {venue})
   - [arXiv] {論文タイトル3} ({year})
   ...

2. {カテゴリ名} ({N}件): {説明}
   ...
```

ユーザーから以下のフィードバックを受け付ける:
- カテゴリの追加・統合・分割・名称変更
- 論文の別カテゴリへの移動
- 不要な論文の除外

### ステップ5: 論文ごとの詳細フィールド生成

カテゴリ分類が確定したら、各論文について以下のフィールドを**日本語**で自動生成する:

| フィールド | 生成方法 | 長さの目安 |
|-----------|---------|-----------|
| **一言要約** | abstract から核心を抽出 | 30-50文字（日本語） |
| **概要** | abstract を日本語で要約 | 3-5文 |
| **動機** | abstract の背景・課題部分から抽出 | 2-3文 |
| **知見** | abstract の結果・実験部分から抽出 | 箇条書き3-5項目 |
| **貢献** | abstract の提案・新規性部分から抽出 | 箇条書き2-4項目 |

**サマリーテーブルの各列（全て日本語で記述）:**

| 列名 | 内容 | 長さの目安 |
|------|------|-----------|
| 論文タイトル | 略称または短縮タイトル（太字） | 20文字以内 |
| 年度 (Conference) | 年 (会議略称) | 例: 2024 (ACL) |
| タスクの種類 | 論文の主タスク | 15文字以内 |
| 評価タスク | 評価に使われたタスク | 15文字以内 |
| 使用データセット | 主要なデータセット名 | 20文字以内 |
| 入出力 | 入力→出力の形式 | 20文字以内 |
| 評価のポイント | この研究の主な評価ポイント | 20文字以内 |

**abstract が存在しない論文の対処:**
- タイトル、venue から推測して生成する
- 全フィールドに「※abstract未取得のため推測」と注記する

### ステップ6: Markdown文書の生成

`assets/output_template.md` の構造に従い、完成した Markdown をローカルファイルに出力する。

**出力時の注意:**
- ファイルエンコーディングは UTF-8
- `<details>` タグは GitHub Wiki/Markdown で正常にレンダリングされる形式にする
- 目次のアンカーリンクはカテゴリ番号+名前を使用（日本語アンカー対応）
- コードリポジトリが存在しない論文は `[Code]` リンクを省略する
- arXiv の論文は `[Paper](https://arxiv.org/abs/{arXiv_id})` 形式のリンクを使用する
- ACL Anthology の論文は `[Paper](https://aclanthology.org/{ACL_id})` 形式のリンクを使用する
- 各論文に venue tier タグを付ける: 例 `[ACL 2024]`, `[arXiv 2024]`
- **全ての説明文、要約、分類結果は日本語で記述すること**

出力後、ファイルパスをユーザーに報告する。

## 重要な注意点

- 論文の abstract のみから生成するため、論文本文の詳細な実験結果等は含まれない。ユーザーにこの制約を初回で伝える
- arXiv API は引用数を提供しない。引用数が必要な場合は Google Scholar で個別に確認するよう案内する
- 生成された要約の正確性は abstract の品質に依存する。重要な論文については元の論文を確認するよう推奨する
- WebFetch で取得できない論文（ペイウォール等）がある場合は、取得可能な情報のみで生成し、注記を付ける
- フェーズ1のカンファレンスサイト検索は検索エンジンの精度に依存するため、関連性の低い結果が含まれる場合がある

---
name: seo-aieo-skills
description: "SEO + AIEO（AI Engine Optimization）統合スキル。footage-nursing.jp の集客コラム（訪問看護・経営支援・デイサービス）を対象に、Google検索最適化とAI引用最適化を両立した記事ライティング。記事生成、AIEO最適化、記事改善、品質チェック、リライト、ガイドライン集約など記事に関するあらゆる作業で使用する。「記事を書いて」「AIEO最適化」「AI引用を増やしたい」「記事を改善して」「要修正の記事を直して」「品質チェックして」「ガイドラインを更新して」といった指示でトリガーすること。"
---

# SEO + AIEO 統合ライティングスキル

footage-nursing.jp の集客コラム記事を、**SEO（Google検索上位）+ AIEO（AI引用獲得）**の両軸で生成・改善するスキル。改善のたびにフィードバックログを蓄積し、ガイドラインを進化させることで、記事品質が継続的に向上する仕組み。

## SEO vs AIEO の基本理解

| | SEO | AIEO |
|---|---|---|
| 対象 | Googleクローラー | ChatGPT/Perplexity/Gemini/ClaudeのRAGパイプライン |
| 重要指標 | キーワード密度・被リンク・ドメインパワー | 信頼シグナル・構造化データ・回答性・データ具体性 |
| 引用単位 | ページ単位（リンク表示） | 文単位（テキスト引用） |
| 最重要箇所 | タイトル・H1・meta | **導入文の最初100語**（LLM引用の44.2%がここから） |

**両立の原則**: SEO対策はそのまま維持しつつ、AIEOの追加要件を重ねる。SEOを犠牲にしてAIEOを優先することはしない。

## 最初に必ずやること

**どのタスクでも、作業開始前に `references/` 配下のガイドラインを全て読み込む。**

```
references/tone-and-voice.md       # トーン・文体
references/evidence-standards.md   # エビデンス基準
references/seo-patterns.md         # SEO構成・文字数基準
references/aieo-patterns.md        # AIEO（AI引用最適化）パターン ★NEW
references/footage-specific.md     # Footage固有ルール
references/common-mistakes.md      # NGパターン集
references/FEEDBACK_LOOP.md        # フィードバックループ定義
```

ガイドラインを読まずに記事を書くと、過去の改善知見が活かされない。これがこのスキルの核心。

## タスク別フロー

### A. 新規記事生成

ユーザーから「記事を書いて」「○○についてのコラムを作って」等の指示があった場合。

1. **ガイドライン読み込み**（上記6ファイル）
2. **カテゴリ特定**: 訪問看護集客 / 経営支援集客 / デイサービス集客
3. **テーマ重複チェック（必須）**:
   - **正のデータソース**: `~/dev/footage-aix/data/article_state.json`（スキルローカルの `data/article_state.json` ではない）
   - **Git KBの既存記事も必ず確認**: `~/dev/footage-aix/article-skills/knowledge-base/` 配下の全 `.md` ファイル名・タイトルを走査する
   - 該当カテゴリの `generated_themes`（生成済み）、`rejected_themes`（却下済み）、`existing_titles_keywords`（既存記事キーワード）を確認
   - **以下に該当するテーマは提案禁止**:
     - `rejected_themes` に含まれるテーマ、またはその類似テーマ
     - `generated_themes` に含まれるテーマ（既に生成済み）
     - `existing_titles_keywords` のキーワードと内容が大きく重複するテーマ
     - **Git KB内に同一・類似テーマの .md ファイルが既に存在するもの**
   - Notion記事マスター（DB ID: `5688443c-5376-4399-bbb2-c29779c67ec9`）の全記事タイトルも確認し、既存記事との類似性をチェック
   - テーマ承認後、`generated_themes` に追加。却下された場合は `rejected_themes` に追加
   - **デイサービスカテゴリの場合**: PD関連記事は上限10本に到達済み。新規テーマは運動障害・介護予防・フレイル等の非PD領域から選定すること
4. **構成決定**: `seo-patterns.md` + `aieo-patterns.md` のテンプレートに従う
5. **執筆（SEO + AIEO統合）**:
   - `tone-and-voice.md` のカテゴリ別トーンを適用
   - `evidence-standards.md` に基づきエビデンスを含める
   - `footage-specific.md` から差別化ポイントを1-2点盛り込む
   - **AIEO必須要素:**
     - 導入文の最初100語に「直接回答 + 具体数値 + 権威ある出典」
     - H2の50%以上を質問形式（Q: なぜ〜？）
     - 記事全体で具体的データ5つ以上
     - Footage独自データ最低1つ
     - 曖昧表現ゼロ（「多くの」「高い」→具体数値に置換）
   - **文字数: 4,000〜5,000文字**（本文のみ、タイトル・CTA除く）
6. **セルフチェック（SEO + AIEO）**:
   - `common-mistakes.md` の全NGパターンに照合
   - `seo-patterns.md` のSEOチェックリストを実行
   - `aieo-patterns.md` のAIEOチェックリストを実行
   - 文字数が範囲内か確認
6. **出力**: Markdown形式で記事を出力
7. **Notion登録後の検証（必須）**: Notionにページ作成・プロパティ更新した後、必ず `curl GET` で読み返して全プロパティが埋まっていることを確認。「★ プロパティ更新の検証+フォールバック」セクション参照。

### B. 既存記事の改善（要修正対応）

ユーザーから「要修正の記事を直して」「Notionのコメントに基づいて改善して」等の指示があった場合。

1. **ガイドライン読み込み**
2. **対象記事の取得**:
   - `article_reference.json` でNotion Page IDを確認
   - `notion-fetch` (include_discussions: true) で本文とコメント位置を取得
   - `notion-get-comments` (include_all_blocks: true) でコメント詳細を取得
3. **改善**: 以下の優先順位で修正
   1. ユーザーコメントの修正指示（最優先）
   2. `common-mistakes.md` のNGパターン照合
   3. `tone-and-voice.md` のトーン適合
   4. `evidence-standards.md` のエビデンス基準
   5. `seo-patterns.md` の構成・文字数チェック
   6. `footage-specific.md` の独自性確認
4. **Notion反映**:
   - `notion-update-page`: command=replace_content, new_str=改善後Markdown
   - `notion-update-page`: command=update_properties, properties={"ステータス": "レビュー中"}
5. **改善ログ生成** ★ここが最重要★:
   - `FEEDBACK_LOOP.md` のテンプレートに従い改善ログを生成
   - 保存先: `improvement-log/YYYY-MM-DD_記事index_短縮タイトル.md`
   - 何をなぜどう直したかを記録し、パターンを抽出する

### C. 品質チェック（レビュー支援）

ユーザーから「この記事をチェックして」「品質確認して」等の指示があった場合。

1. **ガイドライン読み込み**
2. **対象記事の取得**
3. **チェック項目**:
   - 文字数（4,000〜5,000文字の範囲内か）
   - `common-mistakes.md` の8つのNGパターン
   - `seo-patterns.md` のSEOチェックリスト
   - `tone-and-voice.md` のNG表現
   - `evidence-standards.md` のDON'T表現
   - `footage-specific.md` の独自性（Footageの取り組みが1箇所以上あるか）
4. **レポート出力**: 問題点と改善提案をリスト化

### D. ガイドライン集約

改善ログが10件以上たまった場合、または「ガイドラインを更新して」と指示された場合。

1. `improvement-log/` 内の全ログを読み込む
2. 修正カテゴリ別に集計（tone / evidence / seo / structure / footage / other）
3. 3回以上出現したパターンを該当ガイドラインファイルに追記
4. `common-mistakes.md` の「改善ログからの追加分」セクションを更新
5. 集約結果をユーザーに報告

## Notion データベース情報

- **DB URL**: https://www.notion.so/5688443c53764399bbb2c29779c67ec9
- **データソースID**: `collection://61554e58-651c-4e7a-833d-38c5f0f3d897`
- **ステータス**: `原文保管済` / `WP反映済` / `レビュー中` / `要修正` / `公開準備完了`
- **事業体**: `訪問看護集客` / `経営支援集客` / `デイサービス集客`

## 記事カテゴリ（動的取得）

以下は起動時にNotionから最新件数を取得する:

!`ls ~/dev/footage-aix/article-skills/knowledge-base/訪問看護集客/*.md 2>/dev/null | wc -l | xargs printf "訪問看護集客: %d件 / " && ls ~/dev/footage-aix/article-skills/knowledge-base/経営支援集客/*.md 2>/dev/null | wc -l | xargs printf "経営支援集客: %d件 / " && ls ~/dev/footage-aix/article-skills/knowledge-base/デイサービス集客/*.md 2>/dev/null | wc -l | xargs printf "デイサービス集客: %d件\n" 2>/dev/null || echo "(Git KB未検出。フォールバック: 訪看55/経営28/デイ17)"`

| カテゴリ | 事業体 | Post Type | 上限 | ターゲット |
|---|---|---|---|---|
| houmon | 訪問看護集客 | column | 100 | 患者・家族・ケアマネ |
| keiei | 経営支援集客 | rec_column | 100 | 開業者・経営者 |
| dayservice | デイサービス集客 | column | 30 | 運動障害・介護予防対象者・家族 |

### デイサービス記事のサブカテゴリ構成（上限30本）

| サブカテゴリ | 上限 | 現状 | 備考 |
|---|---|---|---|
| パーキンソン病関連 | **10本** | 10本（上限到達） | PD特化記事はこれ以上追加しない |
| 運動障害・介護予防・その他 | **20本** | 7本 | 非PD記事で残り13本を埋める |

**重要**: Re-moveはパーキンソン病および運動障害特化型デイサービス。PD記事は上限到達のため、今後は運動障害全般（脳卒中後遺症、関節疾患、フレイル、サルコペニア等）や介護予防の記事で展開する。

### 週次生成ペース

| カテゴリ | 本数/週 |
|---|---|
| 訪問看護集客 | 3本 |
| 経営支援集客 | 3本 |
| デイサービス集客 | 2本 |
| **合計** | **8本/週** |

## ★ Notion ステータス自動更新プロトコル（必須）

**Notionが正（Single Source of Truth）。記事に関するあらゆる操作の後、必ずNotionステータスを更新すること。**

### ステータス遷移ルール

```
新規生成 → 「レビュー中」
改善完了 → 「レビュー中」
品質チェックNG → 「要修正」
品質チェックOK → 「公開準備完了」
WPに投稿/反映 → 「WP反映済」
記事削除 → 「削除」
```

### 各タスク完了時の必須アクション

| タスク | 完了時のNotion更新 |
|--------|-------------------|
| A. 新規記事生成 | `notion-update-page` → ステータス=「レビュー中」、ファイル名・keywords・公開日を設定 |
| B. 記事改善 | `notion-update-page` → ステータス=「レビュー中」 |
| C. 品質チェック | PASS→「公開準備完了」/ FAIL→「要修正」 |
| WP投稿完了 | `notion-update-page` → ステータス=「WP反映済」、WP Post ID・WP URL・WP公開ステータス・WP最終更新日を設定 |
| KB保存 | `notion-update-page` → ファイル名を設定（Git KBのファイル名と一致させる） |

### 更新コマンド例

```
notion-update-page:
  page_id: "{記事のNotion Page ID}"
  command: "update_properties"
  properties:
    ステータス: "レビュー中"
    ファイル名: "20260313_記事ファイル名.md"
    WP Post ID: "3054"
    WP URL: "https://footage-nursing.jp/column/3054/"
    WP公開ステータス: "publish"
    date:WP最終更新日:start: "2026-03-13"
```

### ★ プロパティ更新の検証+フォールバック（必須）

**既知の問題**: Notion MCP の `notion-update-page` `update_properties` はプロパティ書き込みが無言で失敗することがある（CLAUDE.md参照）。このため、以下の手順を **必ず** 守ること。

#### 手順

1. **更新**: まず Notion REST API を直接呼ぶ（`curl -X PATCH https://api.notion.com/v1/pages/{id}`）。MCP経由の `notion-update-page` は使わない。
2. **検証**: 更新直後に `curl GET https://api.notion.com/v1/pages/{id}` でプロパティを読み返し、書き込んだ値が反映されていることを確認する。
3. **失敗時リトライ**: 検証NGの場合、同じ curl PATCH を再実行し、再度検証する。2回失敗したらユーザーに報告して手動対応を依頼する。

#### 更新すべき全プロパティチェックリスト（記事生成時）

新規記事をNotionに登録する際、以下の **全項目** を1回のPATCHリクエストで設定すること。1つでも空欄があれば完了とみなさない。

- [ ] `ステータス` — レビュー中
- [ ] `事業体` — 訪問看護集客 / 経営支援集客 / デイサービス集客（「集客」付き）
- [ ] `Post Type` — column / rec_column
- [ ] `公開日` — 予約投稿日
- [ ] `ファイル名` — 記事の短縮名
- [ ] `meta_description` — 120〜160文字
- [ ] `keywords` — カンマ区切り10個程度

#### Notion APIトークン取得方法

```bash
NOTION_TOKEN=$(~/.claude/skills/apikey-manager/bin/apikey.sh get "eYGWqRJ8ZWf3TrFlxWk72d9g9Mr8Bj" notion default 2>/dev/null)
```

#### 更新コマンド例（curl版）

```bash
curl -s -X PATCH "https://api.notion.com/v1/pages/{PAGE_ID}" \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "properties": {
      "ステータス": {"select": {"name": "レビュー中"}},
      "事業体": {"select": {"name": "デイサービス集客"}},
      "Post Type": {"select": {"name": "column"}},
      "公開日": {"date": {"start": "2026-04-01"}},
      "ファイル名": {"rich_text": [{"text": {"content": "記事ファイル名"}}]},
      "meta_description": {"rich_text": [{"text": {"content": "..."}}]},
      "keywords": {"rich_text": [{"text": {"content": "kw1, kw2, ..."}}]}
    }
  }'
```

### ★ 記事修正・リライト後のNotion/WP/Git全文一致プロトコル（必須）

記事のリライトや内容修正を行った場合、以下の3箇所が**同一の全文**であることを保証すること。

```
Notion（正）= WP（公開版）= Git KB（ナレッジベース）
```

#### 手順

1. **Notion更新**: リライト版の全文をNotionの元記事ページに反映する
   - 元記事のブロックを削除→リライト版のブロックをコピー
   - または：リライト版ページをpromotion（元記事をアーカイブ→リライト版のプロパティを引き継ぎ）
2. **WP更新**: Notionの全文をHTML変換してWPの既存記事を更新（CDPまたは手動）
3. **Notion プロパティ更新**: `WP最終更新日` を更新日に設定
4. **Git KB同期**: `~/dev/footage-aix/scripts/notion_to_md.py` を実行してGit KBをNotionと一致させる
5. **検証**: Notion/WP/Gitの文字数が概ね一致していることを確認

#### リライト時の注意

- リライト版は別ページとして「レビュー中」で作成し、承認後に元ページに差し替える
- 元ページのWP Post ID/URL/公開日は保持する（URLが変わるとSEO的に不利）
- タイトル変更は慎重に（既存インデックスへの影響あり）
- リライト元ページはアーカイブで残す（ロールバック用）

### ★ WP投稿タイプルール（厳守）

記事の事業体によってWPの投稿タイプ（カスタム投稿タイプ）が異なる。**間違えると別のコラムページに混入する。**

| 事業体 | WP Post Type | WP URL形式 | 備考 |
|---|---|---|---|
| 訪問看護集客 | `column` | /column/{id}/ | 訪問看護コラム |
| デイサービス集客 | `column` | /column/{id}/ | 訪問看護コラムと同じ |
| 経営支援集客 | `rec_column` | /opening/column/{id}/ | 経営支援コラム（/opening/配下） |

**新規投稿・投稿タイプ変更時の確認事項:**
- 投稿作成時に `post_type` が事業体に合っているか必ず確認
- `post-new.php?post_type=column` → 訪問看護/デイサービス
- `post-new.php?post_type=rec_column` → 経営支援
- 間違えた場合: 旧投稿を削除 → 正しいpost_typeで新規作成 → Notion WP Post ID更新

### ⚠️ WP REST API 制約（2026-04-08 FSEレビュー反映）

- WPカスタム投稿タイプ `column` / `rec_column` は `show_in_rest` が未設定のため、**REST APIでの記事取得・投稿・更新は一切不可**
- `/wp-json/wp/v2/columns` → 404、`/wp-json/wp/v2/rec_columns` → 404
- **FSE対応不可確定（2026-04）**: FSE（フリースタイルエンターテイメント）はAIエージェントによる自動投稿運用の責任を負えないと回答。`show_in_rest` 有効化はFSE側では行わない
- **WP反映は手動（管理画面から直接編集）またはブラウザ操作（gstack/browse）で実施**
- リライト成果物はNotion + Git KBに保存し、WP反映は別途手動 or ブラウザ操作で行う

### ⚠️ FSE SEO対策レビュー結果（2026-04）

FSE（株式会社フリースタイルエンターテイメント）から以下の回答あり:

| 項目 | FSE判断 | 対応方針 |
|---|---|---|
| meta description | **テーマ側で設定済み**（対応不要） | — |
| OGPタグ | **テーマ側で設定済み**（対応不要） | — |
| canonicalタグ | FSEが**順次実装** | 自己参照canonicalで重複クローリング抑制 |
| 構造化データ | FSEが**随時実装**（パンくず・FAQ一部・求人は済み） | 残: FAQ(TOP/経営支援)、組織情報、記事(article) |
| サイトマップ | FSEが**修正＋動的プラグイン導入** | 1,000URL中597件(60%)が不正URL |
| mu-plugin (aix-seo-suite.php) | **却下** — 誤情報多数（架空住所・存在しないFAQ） | FSEが手動で施策実行 |
| mu-plugin (aix-redirects.php) | **却下** — 元ページ内容不明で闇雲なリダイレクト非推奨 | テーマ一致の7件のみ再提案検討 |
| REST API公開 | **FSE対応不可** | AIブラウザ操作（claude cowork等）での自動実装を推奨 |

### 禁止事項

- ステータスを更新せずに記事内容だけ変更して終了すること
- Git KBにファイルを追加してNotionのファイル名欄を空のままにすること
- WPに投稿したのにNotion側のWP Post ID/URLを更新しないこと
- **Notion MCP の `notion-update-page` `update_properties` をプロパティ更新に使うこと（curl直叩きを使え）**
- **プロパティ更新後に読み返し検証をせずに完了とすること**
- **WP記事を更新してNotionの本文を同期しないこと（Notion=WP=Git全文一致が必須）**
- **訪問看護/デイサービス記事を `rec_column` で投稿すること（`column` が正）**
- **経営支援記事を `column` で投稿すること（`rec_column` が正）**
- **導入文の最初100語に具体数値と出典がない記事を公開すること**（AIEO）
- **曖昧表現（「多くの」「高い」「一般的に」）を含む記事を公開すること**（AIEO）
- **架空のURLをCTAや内部リンクに使用すること**

## E. AIEO最適化（既存記事への適用）

ユーザーから「AIEO最適化して」「AI引用を増やしたい」等の指示があった場合。

1. **ガイドライン読み込み**（特に `aieo-patterns.md`）
2. **対象記事をNotionからfetch**（Git KBではなくNotionが正）
3. **3つの改善を部分編集（update_content）で適用**:
   - **導入文リストラクチャ**: 結論2文を「この記事でわかること」の前に追加（直接回答+数値+出典）
   - **見出しの質問形式化**: H2の50%以上をQ形式に変換
   - **曖昧表現→具体数値**: 全ての「多くの」「高い」「一般的に」を数値+出典に置換
4. **本文を上書きしない**: 部分的な差し替え（old_str→new_str）のみ。replace_contentは使わない

## G. コンテンツギャップ分析（GA4ベース）

ユーザーから「コンテンツギャップを分析して」「足りない記事を洗い出して」等の指示があった場合。GA4 MCPが利用可能な場合に実行。

1. **GA4データ取得**: 過去90日間のオーガニック流入をランディングページ別に取得
2. **Notion記事DBとの突合**: GA4の高PVページとNotionの集客記事マスターを照合し、以下を特定:
   - **DB外高PV記事**: GA4で流入があるがNotionで管理されていない既存記事 → DB取り込み候補
   - **低PV管理記事**: Notion管理下だがGA4流入が少ない記事 → リライト候補
   - **未対応テーマ**: 検索需要があるがまだ記事がないテーマ → 新規記事候補
3. **テーマ別ギャップ特定**:
   - GA4の検索エンジン別流入（Google/Yahoo/Bing）とAIソース別流入を分析
   - AI流入が多いテーマ領域を特定し、AIEO最適化の優先対象を決定
4. **出力**: ギャップ一覧 + 推奨アクション（DB取込/リライト/新規生成）をレポート

### 2026-04-08時点の既知ギャップ（GA4 90日分析結果）

| テーマ | 現状 | 推奨アクション |
|--------|------|---------------|
| 訪問看護 費用・料金 | 削除（保留）1件のみ | 復活・リライトして再公開（高検索ボリュームKW） |
| 介護保険制度全般 | /column/3045/ のみ | 制度解説シリーズ追加（申請方法、対象者等） |
| 訪問看護 名古屋（地域KW） | エリアページはあるがコラム少 | 「名古屋で訪問看護を探すなら」等の地域特化コラム |
| フレイル予防 | 予約投稿済み（/column/3117予定） | 公開待ち |
| DB外404記事（16件, 2,375users/90日） | 大半が削除済み404。Googleインデックス残存 | テーマ一致7件は301リダイレクトをFSEに再提案。テーマ不一致9件はGoogle除外待ち |
| /column/3063/（服薬管理, 31users） | HTTP 200だがNotion管理外 | Notion DB取込 |
| AI流入（chatgpt.com: 30users/90日） | 微量だが検出開始 | AIEO最適化記事からの流入を個別LP追跡 |

## F. スキル自己改善

このスキル自体も改善プロセスの中で進化させる。改善ログの集約（タスクD）を実行する際に、以下も合わせて実行する。

### トリガー
- ガイドライン集約（タスクD）の実行時に自動で併せて実施
- ユーザーから「スキルを改善して」「ワークフローを見直して」等の指示があった場合

### 手順

1. **improvement-log の傾向分析**: 改善ログのパターンを読み、現在のSKILL.mdの指示で防げたはずの問題がないか確認
2. **ガイドライン参照のギャップ検出**: 改善時にガイドラインのどのファイルが役立ち、どこが不足していたかを特定
3. **SKILL.md 更新候補の洗い出し**:
   - タスクフローに不足するステップはないか
   - 優先順位の調整が必要か
   - 新しいチェック項目を追加すべきか
4. **references/ 配下のガイドライン更新**: タスクDで集約した内容を反映
5. **SKILL.md への反映**: 上記を踏まえてSKILL.mdを更新
6. **変更サマリーをユーザーに報告**: 何をなぜ変えたかを簡潔に説明し、承認を得る

### 自己改善のルール

- SKILL.mdの構造（タスクA-E）は維持する。中身のブラッシュアップのみ
- references/ のガイドラインは追記を基本とし、既存ルールの削除はユーザー承認が必要
- 変更は必ずユーザーに報告して承認を得てから確定する
- improvement-log は削除しない（蓄積こそが価値）

## WordPress接続情報

- **サイト**: https://footage-nursing.jp
- **WP管理画面**: https://footage-nursing.jp/app/login_73906/
- **ユーザー名**: footage_user
- **パスワード**: `.env` の `WP_APP_PASSWORD` または `/apikey-manager` で取得
- **注意**: カスタム投稿タイプ `column` / `rec_column` はshow_in_rest: falseのため、REST API不可（FSE対応不可確定 2026-04）。ブラウザ操作で反映。
- **WPブラウザ操作手順**: `~/.claude/skills/seo-aieo-skills/references/wordpress-operations.md` を参照。Cookie先行インポート、1操作1確認、wait 3000 が鉄則。

## Gotchas

- **Notion MCP `update_properties` が無言で失敗する**: curl直叩き+読み返し検証が必須。MCP経由のプロパティ更新は使わない
- **予約投稿のkeywords/meta_description空欄**: future記事の37/39件が空欄のまま公開される問題が発生済み。生成時に必ず全プロパティ設定
- **訪問看護/デイサービスの投稿タイプ混同**: 訪看・デイは`column`、経営支援は`rec_column`。間違えると別セクションに混入する
- **DB外の高PV記事は大半が404**: /column/2020/（758users/90日）等のTOP記事が削除済み＆NotionDB管理外。テーマ一致の旧記事7件は301リダイレクト候補（FSE再提案要）、テーマ不一致の9件はGoogle除外待ち
- **WP REST API非対応（確定）**: column/rec_columnはshow_in_rest未設定。FSEが対応不可と回答（2026-04）。WP反映はブラウザ操作のみ

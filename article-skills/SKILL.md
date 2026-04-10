---
name: footage-article-writer
description: 株式会社Footageの公式サイト記事を生成するスキル。訪問看護・デイサービス・採用・経営支援の4テーマに対応し、222記事のナレッジベースと16件のガイドラインを活用して一貫性のあるSEO+AIEO記事を作成する。
version: 1.0.0
author: Footage
---

# Footage 記事ライティングスキル

## 概要
株式会社Footage（footage-nursing.jp）のWordPressサイト向けSEO記事を生成するスキルです。
222記事のナレッジベースと16件の診療ガイドライン（Tier1エビデンス）に基づき、過去記事のトーン・構成・専門性を維持した新規記事を作成します。

## 対応テーマ（4種）

| テーマ | 投稿タイプ | 記事数 | ナレッジベースパス |
|--------|-----------|--------|-------------------|
| 訪問看護集客 | column | 55 | `knowledge-base/訪問看護集客/` |
| デイサービス集客 | column | 17 | `knowledge-base/デイサービス集客/` |
| 採用マーケ | column | 11 | `knowledge-base/採用マーケ/` |
| 経営支援集客 | rec_column | 28 | `knowledge-base/経営支援集客/` |

## 記事生成フロー

### STEP 1: テーマ特定
ユーザーの指示からテーマを特定する。明示されていない場合はキーワードから推定し確認する。

### STEP 2: ナレッジベース参照
該当テーマの `knowledge-base/{テーマ}/` 配下のファイルを読み込み、以下を把握する：
- 過去記事のトピック一覧（重複回避）
- 文体・構成パターン
- 頻出キーワード・専門用語の使い方
- Footage独自の訴求ポイント

加えて `knowledge-base/guidelines/` 配下のガイドラインから、関連するTier1エビデンス（診療ガイドライン・系統的レビュー）を参照し、記事の医学的根拠を担保する。

### STEP 3: 設定ファイル読み込み
`~/.claude/skills/seo-aieo-skills/references/` 配下の設定を参照する（正本）：
- `tone-and-voice.md` → トーン&マナー・カテゴリ別ボイス
- `footage-specific.md` → 会社概要・差別化・テーマ設計ルール（3軸構造）・学術フレーム一覧・CTA
- `seo-patterns.md` → SEO構成パターン + GA4実測に基づく内部リンク設計
- `aieo-patterns.md` → AIEO（AI引用最適化）パターン + AI流入実測データ
- `evidence-standards.md` → エビデンス引用基準
- `common-mistakes.md` → よくあるミスと対策
- `FEEDBACK_LOOP.md` → 改善ログ・ガイドライン集約プロセス

補助（プロジェクト固有の数値目標）：
- `config/goals.md` → テーマ別KPI・週次目標・公開カレンダー

### STEP 4: 構成案作成
- SEOキーワードを軸にH2/H3の構成案を作成
- 過去記事との差別化ポイントを明確化
- 内部リンク候補を選定

### STEP 5: 本文執筆
- config/のルールに従い記事本文を執筆
- ナレッジベースのトーンを維持
- Footage独自要素を自然に組み込む

### STEP 6: レビュー・出力
- SEOチェック（キーワード配置、見出し構成）
- 文字数チェック（テーマ別目安）
- CTA配置の確認
- マークダウン形式で出力

### STEP 7: 品質ゲート（必須）
STEP 6の出力に対して、seo-aieo-skillsの品質基準で自己チェックを実行する。**記事を渡す前にこのチェックを通すこと。**

チェック項目（`~/.claude/skills/seo-aieo-skills/references/` から）:
1. `common-mistakes.md` のNGパターンに該当しないか
2. `aieo-patterns.md` の質問型見出し比率（50%以上）を満たすか
3. `evidence-standards.md` のエビデンスTier基準を満たすか
4. `footage-specific.md` のFOOTAGE独自データが適切に組み込まれているか

不合格項目があればSTEP 5に戻って修正する。全項目パスで出力確定。

## ナレッジベースのファイル形式
```markdown
---
title: "記事タイトル"
date: "YYYY-MM-DD"
url: "https://footage-nursing.jp/column/{ID}/"
theme: "テーマ名"
post_type: "column" または "rec_column"
status: "公開済み" または "非公開"
---

# 記事タイトル

概要テキスト

## セクション
- ポイント

## キーワード・トピック
- キーワードリスト
```

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `/article:generate` | 新規記事を生成する |
| `/article:outline` | 構成案のみを作成する |
| `/article:analyze` | 既存記事を分析する |
| `/article:list` | ナレッジベースの記事一覧を表示する |
| `/article:improve` | 既存記事の改善提案を行う |
| `/article:keywords` | テーマのキーワード調査を行う |

## Notion管理ルール（必須）

集客記事マスターDB（`5688443c-5376-4399-bbb2-c29779c67ec9`）をSSoTとする。

### ステータス遷移

```
レビュー待ち → レビュー中 → 公開準備完了 → WP反映済
                 ↓
              要修正 → レビュー中（修正後）
```

### 記事生成時の必須アクション

1. **テーマ承認後**: Notionに即時登録。ステータス=「レビュー待ち」、WP公開ステータス=「未アップロード」
2. **本文生成後**: Notion本文を更新。ステータス→「レビュー中」
3. **CEO査読後**: ステータス→「公開準備完了」
4. **WPアップロード後**: 以下を**全て**埋めること
   - `WP Post ID`: WPの投稿ID（数字）
   - `WP URL`: `https://footage-nursing.jp/{post_type}/{id}/`
   - `WP公開ステータス`: `publish` or `future（予約）`
   - `WP最終更新日`: アップロード日
   - `ステータス`: 「WP反映済」
5. **空欄禁止**: WP Post ID・WP URL・公開日・事業体・Post Type は必ず埋める

### 重複チェック

テーマ提案時に必ずNotion DBを検索し、タイトルの類似度チェックを行う。
既存記事と主題が重複する場合は提案から除外する。

## KB整合性ルール（Git汚染防止）

### 原則: Notion SSoT → manifest.json → Git KB

```
Notion集客記事マスターDB (134件)
  ↓ ファイル名プロパティ
manifest.json (knowledge-base/manifest.json)
  ↓ 検証ゲート
Git KB active files (knowledge-base/{テーマ}/*.md)
```

### ファイル命名規約

1. **1記事1ファイル**: Notionの`ファイル名`プロパティの値がGit KBのファイル名。長タイトル版の別ファイルは作らない
2. **新規記事生成時**: `YYYYMMDD_短縮キーワード.md` 形式でファイル名を決め、Notionの`ファイル名`プロパティに即時登録
3. **manifest.json更新**: 新規記事をKBに追加したら `manifest.json` にもエントリを追加する

### 検証コマンド

```bash
# KBの整合性チェック（manifest.json vs 実ファイル）
python3 article-skills/tools/kb_lint.py
```

- `kb_lint.py` は manifest.json に載っていないファイルを検出し、警告を出す
- Notion MCPが使えるセッションでは、Notion DBと直接照合も可能

### Gotchas

- **Notion view queryは100件上限**: 全件取得にはsearch APIの併用が必要。manifest.jsonを中間キャッシュとして使う
- **ファイル名未設定のNotionエントリ**: 記事登録時に必ず`ファイル名`を埋めること。空欄はkb_lintで検出される
- **`_archive/`ディレクトリ**: Notionに未登録の旧記事を退避する場所。削除ではなく退避で履歴を保持
- **`&` vs `＆`**: Notionの全角半角の揺れに注意。Git側のファイル名を正とする

## 使用上の注意
- 医療情報を含む記事は「医師に相談してください」等の注意書きを必ず含める
- 薬機法・医療広告ガイドラインに抵触する表現を避ける
- 過去記事と重複するトピックの場合は差別化ポイントを明示する
- 非公開記事（status: "非公開"）は参考情報として扱い、URLを公開記事としてリンクしない

## Related Skills

| スキル | 関係 | 使い所 |
|--------|------|--------|
| `/seo-aieo-skills` | 品質ルール参照元 | 記事生成後の品質チェック・AIEO最適化に使う |
| `/yt-pipeline` | 後続 | YouTube動画から記事を生成する場合はこちらが起点 |

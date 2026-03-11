---
name: seo-lmo-writing
description: "SEO/LMO最適化された記事の生成・改善・品質チェックを行うスキル。footage-nursing.jp の集客コラム（訪問看護・経営支援・デイサービス）を対象に、品質ガイドラインと改善フィードバックループを統合した記事ライティング。記事生成、記事改善、記事レビュー、コラム執筆、SEO記事、LMOコンテンツ、Notion記事更新、要修正記事の対応、品質チェック、ガイドライン集約など、記事に関するあらゆる作業で使用する。「記事を書いて」「記事を改善して」「要修正の記事を直して」「品質チェックして」「ガイドラインを更新して」といった指示すべてでトリガーすること。"
---

# SEO/LMO ライティングスキル

footage-nursing.jp の集客コラム記事を、品質ガイドラインに基づいて生成・改善するスキル。改善のたびにフィードバックログを蓄積し、ガイドラインを進化させることで、記事品質が継続的に向上する仕組み。

## 最初に必ずやること

**どのタスクでも、作業開始前に `references/` 配下のガイドラインを全て読み込む。**

```
references/tone-and-voice.md       # トーン・文体
references/evidence-standards.md   # エビデンス基準
references/seo-patterns.md         # SEO構成・文字数基準
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
3. **構成決定**: `seo-patterns.md` のカテゴリ別テンプレートに従う
4. **執筆**:
   - `tone-and-voice.md` のカテゴリ別トーンを適用
   - `evidence-standards.md` に基づきエビデンスを含める
   - `footage-specific.md` から関連する差別化ポイントを1-2点盛り込む
   - **文字数: 4,000〜5,000文字**（本文のみ、タイトル・CTA除く）
5. **セルフチェック**:
   - `common-mistakes.md` の全NGパターンに照合
   - `seo-patterns.md` のSEOチェックリストを実行
   - 文字数が範囲内か確認
6. **出力**: Markdown形式で記事を出力

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
- **ステータス**: `原文保管済` / `WP反映済` / `レビュー中` / `要修正`
- **事業体**: `訪問看護集客` / `経営支援集客` / `デイサービス集客`
- **記事メタ情報**: `article_reference.json`（80件のpage_id, post_id等）

## 記事カテゴリ

| カテゴリ | 事業体 | 件数 | Post Type | ターゲット |
|---|---|---|---|---|
| houmon | 訪問看護集客 | 40 | column | 患者・家族・ケアマネ |
| keiei | 経営支援集客 | 30 | column | 開業者・経営者 |
| dayservice | デイサービス集客 | 10 | rec_column | パーキンソン病患者・家族 |

## E. スキル自己改善

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
- **パスワード**: @bw9nB8qi&sIaehlEKoBwO7Y
- **注意**: カスタム投稿タイプ `column` はshow_in_rest: falseのため、REST API不可。ブラウザ操作で反映。

# フィードバックループ プロセス定義

> Claude Codeがこのファイルを読み込むことで、記事改善時に自動的にフィードバックループが回る。

## ディレクトリ構成

```
quality-guidelines/
  tone-and-voice.md       # トーン・文体ルール
  evidence-standards.md   # エビデンス・引用基準
  seo-patterns.md         # SEO構成パターン
  footage-specific.md     # Footage固有ルール
  common-mistakes.md      # よくあるNG集（自動追記あり）
  FEEDBACK_LOOP.md        # このファイル（プロセス定義）
improvement-log/
  YYYY-MM-DD_記事index_短縮タイトル.md   # 個別改善ログ
```

## プロセス1: 記事改善（毎回実行）

### 入力
- Notionの「要修正」記事 + コメント（修正指示）

### 手順

```
1. quality-guidelines/ 配下の全 .md を読み込む
2. 対象記事のNotion本文とコメントを取得
3. ガイドラインを参照しながら記事を改善:
   a. コメントの修正指示を最優先で対応
   b. ガイドラインのチェック項目に照合して追加修正
   c. common-mistakes.md のパターンに該当する箇所を修正
4. 改善後の記事をNotionに反映
5. ステータスを「レビュー中」に変更
6. 【重要】改善ログを生成（プロセス2へ）
```

## プロセス2: 改善ログ生成（改善の直後に毎回実行）

改善を1件行うごとに、以下のテンプレートで改善ログを生成する。

### テンプレート

```markdown
# 改善ログ: [記事タイトル]

- **日付**: YYYY-MM-DD
- **記事index**: [番号]
- **カテゴリ**: [houmon / keiei / dayservice]
- **トリガー**: [ユーザーコメント / セルフチェック / ガイドライン照合]

## 修正内容

| # | 修正箇所 | 元の内容（要約） | 修正後（要約） | カテゴリ |
|---|---|---|---|---|
| 1 | [セクション名] | [元] | [修正後] | tone / evidence / seo / structure / footage / other |
| 2 | ... | ... | ... | ... |

## 抽出パターン

この改善から得られた汎用的な教訓:

- **パターン名**: [例: 経営系記事の箇条書き過多]
- **ルール化**: [例: 箇条書きの各項目に最低2文の説明段落を追加する]
- **該当ガイドライン**: [例: common-mistakes.md #1]
- **新規ルール追加の必要性**: [yes/no — yesの場合、プロセス3で反映]
```

### 保存先
`improvement-log/YYYY-MM-DD_記事index_短縮タイトル.md`

例: `improvement-log/2026-03-02_40_経営現場対立.md`

## プロセス3: ガイドライン集約（10件ごとに実行）

improvement-log/ 内のファイル数が前回集約時から10件以上増えたら実行。

### 手順

```
1. improvement-log/ の全ログを読み込む
2. 修正カテゴリ別に集計:
   - tone: ○件
   - evidence: ○件
   - seo: ○件
   - structure: ○件
   - footage: ○件
   - other: ○件
3. 頻出パターン（3回以上）を特定
4. 該当するガイドラインファイルに新ルールを追記:
   - tone → tone-and-voice.md
   - evidence → evidence-standards.md
   - seo → seo-patterns.md
   - structure → common-mistakes.md
   - footage → footage-specific.md
5. common-mistakes.md の「改善ログからの追加分」セクションを更新
6. 集約結果のサマリーをユーザーに報告
```

## プロセス4: 記事生成時の品質チェック（新規記事生成時に実行）

### 事前チェック（生成前）
```
1. quality-guidelines/ 配下の全 .md を読み込む
2. 対象カテゴリのテンプレート（seo-patterns.md）に従って構成を決定
3. tone-and-voice.md のカテゴリ別トーンを適用
4. footage-specific.md の差別化ポイントから関連項目を選定
```

### 事後チェック（生成後）
```
1. common-mistakes.md の全NGパターンに照合
2. evidence-standards.md のDON'T表現がないか確認
3. seo-patterns.md のチェックリストを実行
4. 問題があれば自動修正して最終版を出力
```

## 運用ルール

- ガイドラインの手動編集もOK。Claude Codeは既存内容を尊重し、追記のみ行う
- 改善ログは削除しない（蓄積が価値）
- ガイドラインの変更履歴はGitで管理

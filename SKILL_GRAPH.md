# Skill Graph — スキル間関係マップ

> スキル発火時にこのファイルを参照し、関連スキルの存在をユーザーに提示すること。
> 強制チェインではなく「次に使える候補」として扱う。

## 凡例

| 記号 | 意味 | 説明 |
|------|------|------|
| `→` | chains-to | この順序で使うと効果的 |
| `⇐` | requires | 事前に実行が必要 |
| `≈` | alternative | 同じ目的の別手段 |
| `←` | references | ナレッジやルールを参照 |

---

## 1. ワークフロー・パイプライン

### 企画 → 実装 → 出荷

```
office-hours (壁打ち)
  → plan-ceo-review (スコープ判断)
  → plan-design-review (デザイン判断)
  → plan-eng-review (設計判断)
  → plan-devex-review (DX判断)

autoplan ≈ [plan-ceo-review → plan-design-review → plan-eng-review → plan-devex-review]
  ※ autoplan は4つのレビューを自動連続実行する代替手段
```

### 出荷フロー

```
review (PRレビュー)
  → ship (PR作成・push)
  → land-and-deploy (マージ・デプロイ)
    ⇐ setup-deploy (初回のみ: デプロイ設定)
  → canary (本番監視)
  → document-release (ドキュメント更新)
```

### デザインフロー

```
design-consultation (デザインシステム構築)
  → design-shotgun (複数バリアント生成)
  → design-html (本番品質HTML出力)
  → design-review (ビジュアルQA・修正)

plan-design-review ≈ design-consultation  ※plan-modeならplan-design-review、ゼロからならdesign-consultation
design-review ≈ plan-design-review        ※実装後のライブQAならdesign-review、計画段階ならplan-design-review
```

### QAフロー

```
qa (テスト+修正)
  → design-review (ビジュアル面の仕上げ)

qa-only ≈ qa  ※レポートのみ・修正なし
```

### パフォーマンス

```
benchmark (ベースライン計測・PR前後比較)
canary (デプロイ後の異常検知)
  ※両方とも browse を内部で使用
```

---

## 2. ドメイン別グループ

### 記事コンテンツ

```
article-skills (記事生成)
  ← seo-aieo-skills/references/ (品質ルール・SEO/AIEOパターン)
seo-aieo-skills (品質評価・改善)
  ← article-skills/knowledge-base/ (記事ナレッジ)
yt-pipeline (YouTube→記事パイプライン)
  ← seo-aieo-skills/references/ (品質ルール)
```

関係: article-skills と seo-aieo-skills は相互参照。yt-pipeline は seo-aieo-skills のルールに従う。

### 採用コンテンツ

```
recruit-brand (採用ブランドKB: EVP・FactSheet)
  → recruit-ad (採用広告 Meta/Google)
  → recruit-sns-instagram (Instagram運用)

recruit-ad ⇐ recruit-brand   ※KB参照必須
recruit-sns-instagram ⇐ recruit-brand  ※KB参照必須
```

### 医療・事業分析

```
market-research (二次医療圏分析)
vn-compliance (訪問看護コンプライアンス)
strategy-review (施策の多角的検討: 11エージェント)
```

独立スキル。相互依存なし。ただし market-research の結果を strategy-review に渡すと効果的。

### 設計・IA

```
ia-framework (情報設計Blueprint)
  → dashboard-design (ダッシュボード設計原則)
  → penpot-uiux-design (Penpot MCP でUI実装)
```

### GAS/インフラ

```
gas-auto-deploy (FOOTAGE HANDLE GAS デプロイ)
apikey-manager (APIキー暗号化管理)
```

独立スキル。

---

## 3. 安全・制御

```
careful (破壊コマンド警告)
freeze (ディレクトリ制限) ↔ unfreeze (制限解除)
guard = careful + freeze  ※両方を一括有効化

investigate ⇐ freeze  ※デバッグ中の誤編集防止hookが組み込み済み
```

---

## 4. ユーティリティ

```
browse          基盤ブラウザ。qa, qa-only, design-review, benchmark, canary が内部利用
codex           独立した第三者レビュー (OpenAI Codex)。review の補完に使える
health          コード品質スコア。ship 前の確認に有用
checkpoint      作業状態の保存・復元
learn           プロジェクト学習の蓄積・検索
retro           週次振り返り
slides          スライド生成（独立）
autoresearch    自律的な反復研究（独立）
office-hours    壁打ち。plan-*-review の前段として有効（benefits-from）
workflow-orchestration  エージェント行動ルール（メタスキル）
```

---

## 5. よくある組み合わせパターン

| シナリオ | 推奨スキルチェイン |
|----------|-------------------|
| 新機能の企画から実装 | office-hours → autoplan → 実装 → review → ship |
| デザイン刷新 | design-consultation → design-shotgun → design-html → design-review |
| バグ修正 | investigate → 修正 → qa → ship |
| 記事公開 | article-skills → seo-aieo-skills (品質チェック) |
| 採用コンテンツ作成 | recruit-brand → recruit-sns-instagram or recruit-ad |
| 本番デプロイ | ship → land-and-deploy → canary |
| セキュリティ監査 | cso → review |
| パフォーマンス改善 | benchmark → 改善 → benchmark (before/after) |
| 安全モードで作業 | guard (= careful + freeze) |
| GAS更新 | gas-auto-deploy |

---
name: recruit-ad
description: "FOOTAGE採用広告（Meta Ads / Google Ads）の運用管理スキル。採用広告のパフォーマンス分析、変更提案、予算最適化、週次/月次レポート生成、監査を4段階承認フレームワーク（L0〜L3）に基づいて行う。訪問看護・デイサービスの看護師・PT/OT・介護士採用が対象。「採用広告」「広告分析」「広告レポート」「広告提案」「CPA」「広告予算」「Meta Ads」「Google Ads」「広告パフォーマンス」「広告最適化」「採用CPA」「広告運用」といった指示でトリガーすること。recruit-brandスキルと併用して使う。"
---

# FOOTAGE 採用広告運用スキル

FOOTAGEグループの採用広告（Meta Ads / Google Ads）を自律管理するスキル。看護師・PT/OT・介護士の採用広告について、パフォーマンス分析・変更提案・実行・監査を行う。

## 最初に必ずやること

**どのタスクでも、作業開始前に以下を読み込む。**

1. **SKILL定義（全体構造）:**
```
/Users/yusuke/footage-aix/src/recruit/recruit-ad-skills/SKILL.md
```

2. **タスクに応じた設定ファイル（後述のルーティングテーブル参照）:**
```
/Users/yusuke/footage-aix/src/recruit/recruit-ad-skills/config/
├── approval-rules.md   # 承認レベル判定（L0〜L3）
├── kpi-targets.md      # KPI目標値・閾値
├── operation-rules.md  # 予算制約・運用ルール
└── platforms.md        # Meta/Google Ads API仕様
```

3. **ブランドKB（広告クリエイティブ作成時）:**
```
/Users/yusuke/footage-aix/knowledge-base/recruit/brand/recruit-brand-kb-v031.md
```

4. **分析リファレンス（分析・レポート・提案・監査タスク時）:**
```
references/
├── hypothesis-driven-analysis.md  # 仮説駆動分析プロトコル（4ステップ）
├── learned-corrections.md         # 過去の分析失敗・インシデント集
├── cross-data-sources.md          # クロスデータソース分析ルール
└── FEEDBACK_LOOP.md               # フィードバックループ定義
```

## 設定ファイル参照ルーティング

| タスク | 必須参照（config/） | 必須参照（references/） | 推奨参照 |
|---|---|---|---|
| **パフォーマンス分析** | kpi-targets.md | hypothesis-driven-analysis.md, learned-corrections.md, cross-data-sources.md, FEEDBACK_LOOP.md | operation-rules.md |
| **変更提案の生成** | approval-rules.md, kpi-targets.md | learned-corrections.md | operation-rules.md, platforms.md |
| **予算変更** | approval-rules.md, operation-rules.md | — | kpi-targets.md |
| **新キャンペーン作成** | platforms.md, approval-rules.md | — | kpi-targets.md, ブランドKB |
| **広告クリエイティブ作成** | — | — | ブランドKB §1 EVP, §11 ファクトシート, §4 ブランドボイス, §6 アンチパターン |
| **週次/月次レポート** | kpi-targets.md | cross-data-sources.md, learned-corrections.md | operation-rules.md |
| **監査** | approval-rules.md, operation-rules.md | learned-corrections.md | platforms.md |

## タスク別フロー

### A. パフォーマンス分析（/recruit:ad:analyze）

> 仮説駆動型分析。references/ の全ファイルに従い、「なぜ」に答える。

1. **設定・リファレンス読み込み**: kpi-targets.md + references/ 全ファイル
2. **分析前チェック**: FEEDBACK_LOOP.md プロセス4 のチェックリストを実行
3. **Supabaseナレッジ参照**: `ad_analysis_knowledge` から直近4回分を読み込み
4. **データ取得**: Notion広報運用DB or GAS経由でMeta/Google Adsデータ
5. **事実確認**（hypothesis-driven-analysis.md Step 1）:
   - 主要KPIの現在値・前週比・目標比・前年同期比を整理
   - 数字を見る。解釈はしない
   - learned-corrections.md #1（CV定義の混同）を照合 — プラットフォームCPAと採用CPAを分離
6. **仮説の発散**（Step 2）:
   - KPI変動に対して最低3つの仮説を列挙
   - 4カテゴリ: 広告運用 / 外部環境 / 技術的要因 / サイト側要因
7. **クロスデータソース検証**（Step 3 + cross-data-sources.md）:
   - 検証マトリックスに従い、GA4・GSC・季節カレンダーを確認
   - learned-corrections.md の既知パターンに該当しないか照合
   - **全仮説を体系的に検証する（最初に合致した仮説で止まらない）**
8. **反復**（Step 4）:
   - 検証中に新事実が発見されれば新仮説を生成して繰り返す
9. **結論・アクション**:
   - 閾値超過（130%）でアラート
   - hypothesis-driven-analysis.md の出力テンプレートに従い結果を構造化
   - 分析結果をNotionに記録 + Slack通知
10. **分析ログ生成**: FEEDBACK_LOOP.md プロセス2 に従いログを出力

### B. 変更提案（/recruit:ad:propose）

1. **設定読み込み**: approval-rules.md, kpi-targets.md
2. **提案生成**: データに基づく改善案
3. **承認レベル自動判定**:
   - 影響額算出: `|提案値 - 現在値| × 残存日数`
   - L0（<¥10,000/日）: 自動実行+事後報告
   - L1（<¥100,000）: 担当者承認
   - L2（<¥1,000,000）: 二重チェック
   - L3（≥¥1,000,000）: 役員判断
4. **Slack承認依頼（L1以上）or 自動実行（L0）**

### C. 週次/月次レポート（/recruit:ad:report）

1. **設定読み込み**: kpi-targets.md + cross-data-sources.md + learned-corrections.md
2. **データ集計**: 期間別パフォーマンスサマリー
3. **クロスデータ補足**: GA4からサイト流入トレンド、GSCから検索クエリ動向を取得し、広告パフォーマンスの文脈を補強
4. **KPI達成度**: 目標値との乖離分析（learned-corrections.md #1 CV定義混同チェック必須）
5. **レポート出力**: Notion + Slack通知

### D. 予算最適化（/recruit:ad:optimize）

1. **設定読み込み**: operation-rules.md, kpi-targets.md, approval-rules.md
2. **予算制約チェック**:
   - 日予算上限: ¥30,000/キャンペーン
   - 月間上限: 訪問看護 ¥240,000 / デイサービス ¥90,000
   - 増額上限: 現在値の200%まで
3. **媒体ミックス最適化提案**（L2承認）

### E. 監査（/recruit:ad:audit）

1. **設定読み込み**: approval-rules.md, operation-rules.md
2. **チェック項目**:
   - 承認レベルと実行の整合性
   - 禁止時間帯（23:00〜06:00）の操作有無
   - 学習期間保護（新規7日/入札戦略14日）の遵守
   - 緊急停止条件の適用状況

## 承認フレームワーク早見表

| レベル | 条件 | AI権限 | 承認者 |
|---|---|---|---|
| **L0** | 影響額 < ¥10,000/日 | 実行+事後報告 | — |
| **L1** | 影響額 < ¥100,000 | ドラフト | 安藤 |
| **L2** | 影響額 < ¥1,000,000 | ドラフト+リスク分析 | 安藤（二重チェック） |
| **L3** | 影響額 ≥ ¥1,000,000 | 分析のみ | 大串CEO |

## 緊急停止条件（L0即時停止）

以下に該当したら承認不要で即時停止:
1. CPA が目標の **300%超過**
2. 日予算消化が **3時間以内に90%到達**
3. CTR が **0.1%未満**
4. API接続エラーが **3回連続**

## 関連システム

| システム | 参照先 |
|---|---|
| Notion広報運用DB | `f7ce5da2-155a-45d4-bebe-33efc1b6cfd8` |
| GAS AdAnalyst | `src/recruit/gas/AdAnalyst.gs` |
| GAS AdOperator | `src/recruit/gas/AdOperator.gs` |
| Scripts | `src/recruit/scripts/ad-data-fetch.py`, `performance-report.py` |
| D21設計書 | Notion `3113cbc3-90eb-810b-8165-d797b4e0c122` |

## 絶対に守ること

1. **承認レベルを絶対にスキップしない** — 影響額に基づくL0〜L3判定は厳守
2. **変更禁止時間帯（23:00〜06:00）に操作しない**
3. **学習期間中の広告を変更しない** — 新規7日間、入札戦略14日間
4. **月間予算上限を超えない** — 訪問看護¥240,000 / デイサービス¥90,000
5. **FC案件は対象外** — オーナー出資のため広告変更提案の対象にしない
6. **広告クリエイティブはブランドKB準拠** — §4ブランドボイス、§6アンチパターンを必ず照合

## Related Skills

| スキル | 関係 | 使い所 |
|--------|------|--------|
| `/recruit-brand` | 前提（必須） | 広告コピー作成前にKBを読み込む。EVP・ファクトシートが根拠 |
| `/recruit-sns-instagram` | 併用 | SNSオーガニック施策。広告と並行して使うケースあり |

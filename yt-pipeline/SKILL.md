---
name: yt-pipeline
description: "YouTubeパイプライン（YT/YP）の運用管理スキル。動画検出→記事生成→承認→公開の全フロー管理、否認時の修正指示対応、フィードバックループによる品質改善を担当する。「YTパイプライン」「YouTube記事」「シークレットコラム」「YT否認」「YP実行」「YT状態確認」「パイプライン調査」といった指示でトリガーすること。"
---

# YouTube パイプライン運用スキル

YouTube新着動画 → 字幕取得 → コラム記事生成 → Slack承認 → LINE配信 + YouTubeコメント投稿の全フローを管理するスキル。否認フィードバックを品質ガイドラインに還元し、記事品質を継続的に向上させる。

## アーキテクチャ

```
YT（毎週月曜 18:05）    YP（2時間おき + watcher 10秒間隔）
  YouTube RSS監視          承認/否認検出
  → 字幕取得              → 承認 → LINE + YTコメント公開
  → ノウハウ判定           → 否認 → 修正指示検出 → 再生成
  → 記事生成              → improvement-log記録
  → Notion下書き作成       → 品質ガイドライン集約
  → Slack DM承認リクエスト
```

## 最初に必ずやること

作業開始前に以下を読み込む:

```
references/quality-rules.md        # YTパイプライン固有の品質ルール
references/improvement-log/        # 否認フィードバック蓄積ディレクトリ
```

## 記事品質基準（seo-aieo-skills 正本参照）

YTパイプラインで生成する記事も、seo-aieo-skills の品質基準に準拠する。**記事生成・修正時**に以下のreferencesを参照し、基準を満たすこと:

```
~/.claude/skills/seo-aieo-skills/references/tone-and-voice.md      # カテゴリ別トーン＆ボイス
~/.claude/skills/seo-aieo-skills/references/evidence-standards.md  # エビデンス基準（Tier 1-3）
~/.claude/skills/seo-aieo-skills/references/seo-patterns.md        # SEO最適化パターン
~/.claude/skills/seo-aieo-skills/references/aieo-patterns.md       # AIEO最適化（質問型見出し・具体数値等）
~/.claude/skills/seo-aieo-skills/references/footage-specific.md    # FOOTAGE独自データ・差別化要件
~/.claude/skills/seo-aieo-skills/references/common-mistakes.md     # NGパターン集
```

### YTパイプライン固有の適用ルール

- **字幕忠実性が最優先**: 動画の字幕内容を逸脱しない範囲で、上記品質基準を適用する
- **文字数**: 字幕の情報量に依存するため、seo-aieo-skillsの4,000-5,000字目標は努力目標とする。ただし1,500字未満は不可
- **FOOTAGE独自データ**: 字幕内にFOOTAGEの事例・数値があれば必ず活用する。なければ無理に追加しない
- **AIEO最適化**: 見出しの50%以上を質問形式にする。導入文で動画の核心を端的に回答する
- **エビデンス**: 字幕内の主張に公的データ・ガイドラインの裏付けがあれば付記する。捏造しない
- **トーン**: `tone-and-voice.md` のカテゴリ別ガイドに従う（訪問看護→共感寄り、経営→実務寄り）

## コード配置

| ファイル | 役割 |
|---------|------|
| `src/youtube_pipeline/yt_pipeline.py` | YT: 動画検出→記事生成→承認リクエスト |
| `src/youtube_pipeline/yt_publish.py` | YP: 承認検出→公開 / 否認→修正→再承認 |
| `src/youtube_pipeline/article_generator.py` | 記事生成プロンプト・API呼び出し |
| `src/youtube_pipeline/approval.py` | Slack承認フロー・Notion連携 |
| `src/youtube_pipeline/config.py` | 環境変数・定数定義 |
| `~/.bridge/yt_pipeline_state.json` | パイプライン状態ファイル（ライブ） |

## 状態管理

stateファイル: `~/.bridge/yt_pipeline_state.json`

| ステータス | 意味 | 次のアクション |
|-----------|------|--------------|
| `pending` | 承認待ち | watcherが10秒間隔で承認/否認を検出 |
| `published` | 公開済み | 完了 |
| `rejected_awaiting_feedback` | 否認、修正指示待ち | Slackスレッドに修正指示が来たら再生成 |
| `revision_failed` | 修正再生成に失敗 | feedbackが来ていれば再試行可能 |
| `failed_line` | LINE配信のみ失敗 | 次回YP実行でLINE再送 |

## Slack承認フロー

- 承認リクエスト送信先: 大串DM (`D0AK6704KGD`) + 山口DM (`D0AJ08Q8V1R`)
- 否認検出: `#aix-daily` (`C0AGMGQ5GNR`) の監査ログから `❌ *YTコラム却下*` マーカーを探索
- 修正指示取得: 山口DM (`D0AJ08Q8V1R`) のスレッドから Bot以外の返信を収集
- **重要**: stateの `channel` フィールドに承認リクエスト投稿先チャネルIDが保存される。これがないとfeedback取得に失敗する

## フィードバックループ

### 否認時の自動記録

否認feedbackが検出されると、`yt_publish.py` の `_log_rejection_feedback()` が以下に自動記録:

```
~/.claude/skills/yt-pipeline/references/improvement-log/YYYY-MM-DD_YT_{video_id}.md
```

### ガイドライン集約（3件ごとに実行）

improvement-log/ 内のファイル数が前回集約時から **3件以上** 増えたら、このスキル実行時に集約を行う。

#### 集約手順

```
1. improvement-log/ の全ログを読み込む
2. 修正カテゴリ別に集計
3. 頻出パターン（2回以上）を特定
4. references/quality-rules.md に新ルールを追記
5. 該当する場合、seo-aieo-skills の common-mistakes.md にも反映（記事生成にも波及させるため）
6. 集約結果をユーザーに報告
```

### 品質チェック（記事生成時に自動適用）

`article_generator.py` のプロンプトに以下が組み込み済み:
- Markdown記法の本文残存禁止
- 箇条書きだけの記事禁止
- 出力はMarkdown形式だが、読者の目に触れるテキストにMarkdown記号を残さない

加えて、「記事品質基準」セクションの seo-aieo-skills references を記事生成・修正時に参照し、以下を検証する:
- トーン＆ボイスがカテゴリに適合しているか
- エビデンスが根拠なく断言していないか
- AIEO最適化（質問型見出し比率、導入文の直接回答）が適用されているか
- NGパターン（common-mistakes.md）に該当していないか

`references/quality-rules.md` のルールが追加されるたびに、プロンプトへの反映を検討する。

## 運用タスク

### パイプライン状態確認
```bash
python3 -c "
import json
with open('$HOME/.bridge/yt_pipeline_state.json') as f:
    state = json.load(f)
for entry in state.get('pending_approvals', []):
    print(f'{entry[\"video_id\"]}: {entry.get(\"status\",\"?\")} ch={entry.get(\"channel\",\"N/A\")}')
"
```

### 手動YP実行（cron環境変数と同等）
crontabの `YP-youtube-publish` エントリと同じ環境変数で実行。

### watcher状態確認
```bash
launchctl list | grep footage.yt
tail -20 ~/.bridge/logs/yt_watcher_stdout.log
```

## Gotchas

1. **Botに `im:history` scopeが必要** — DMスレッドの修正指示を読むため。2026-04-07に追加済み
2. **stateの `channel` が空だとfeedback取得失敗** — `_resolve_approval_channel()` でフォールバックするが、正しいチャネルがstateに保存されていることが前提
3. **`revision_failed` は永久停止ではない** — feedbackが来ていれば次回実行で再試行する（2026-04-07修正済み）
4. **feedbackフィルタはBot以外の全ユーザー** — `APPROVAL_USER_ID` 以外からの修正指示も検出する（2026-04-07修正済み）
5. **Markdown記法残存** — AI生成テキストにMarkdown記号が残るとAI作成と判断される。プロンプトで禁止済みだが、変換工程でも検証すべき
6. **WP反映はブラウザ操作** — REST APIはcolumn/rec_columnで使用不可。gstack/browseでの操作手順は `~/.claude/skills/seo-aieo-skills/references/wordpress-operations.md` を参照

## Related Skills

| スキル | 関係 | 使い所 |
|--------|------|--------|
| `/seo-aieo-skills` | 品質ルール参照元 | 記事生成時の品質基準。references/配下のルールに従う |
| `/article-skills` | ナレッジ参照元 | 過去記事のトーン・構成の一貫性を保つために参照 |

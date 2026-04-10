# Footage 記事生成システム（article-skills）

株式会社Footage公式サイト（footage-nursing.jp）のSEO記事を生成するClaude Code Skillsプロジェクト。

## 概要

AIに「書いて」と投げるだけではオリジナリティのある記事は生まれない。
**「ルール」と「ナレッジ」を構造化してAIに渡し、継続的に育てる**仕組み。

- 91記事＋16件の診療ガイドライン（Tier1エビデンス）から過去記事のトーン・構成・専門性を学習
- 4テーマ × 設定ファイルで一貫したブランドボイスを維持
- 6つのSkillsコマンドで記事制作ワークフローを効率化

## ディレクトリ構成

```
article-skills/
├── SKILL.md                   ← メインスキル定義
├── config/                    ← 設定ファイル群
│   ├── target.md              ← ターゲット像（4テーマ分）
│   ├── tone.md                ← トーン＆マナー
│   ├── writing-rules.md       ← ライティングルール
│   └── goals.md               ← 記事のゴール設定
├── knowledge-base/            ← ナレッジベース（91記事 + 16ガイドライン）
│   ├── 訪問看護集客/           ← 41記事（column）
│   ├── デイサービス集客/       ← 10記事（column）
│   ├── 経営支援集客/           ← 30記事（rec_column）
│   ├── 採用マーケ/             ← 10記事（column）
│   └── guidelines/             ← 16件（Tier1エビデンス・診療ガイドライン）
├── .claude/commands/          ← Skillsコマンド（6種）
│   ├── generate.md            ← 新規記事生成
│   ├── outline.md             ← 構成案作成
│   ├── analyze.md             ← 既存記事分析
│   ├── list.md                ← 記事一覧表示
│   ├── improve.md             ← 記事改善提案
│   └── keywords.md            ← キーワード調査
└── tools/                     ← ツール群
    └── wp-publish.py          ← WordPress入稿スクリプト
```

## 4テーマ

| テーマ | 投稿タイプ | 記事数 | ターゲット |
|--------|-----------|--------|-----------|
| 訪問看護集客 | column | 41 | 患者本人・家族・ケアマネ |
| デイサービス集客 | column | 10 | リハビリ利用検討者・家族 |
| 経営支援集客 | rec_column | 30 | 訪問看護開設検討者・経営者 |
| 採用マーケ | column | 10 | 転職検討中の看護師 |

## セットアップ

### 1. Claude Code Skillsとして使用

```bash
# プロジェクトディレクトリとして開く
claude --project ./article-skills

# コマンド実行
/article:generate 訪問看護集客 在宅リハビリ
/article:list
```

### 2. WordPress入稿（オプション）

```bash
# 依存パッケージ
pip install requests python-frontmatter markdown

# 環境変数設定
export WP_URL="https://footage-nursing.jp"
export WP_USERNAME="your_username"
export WP_APP_PASSWORD="xxxx xxxx xxxx xxxx xxxx xxxx"

# 接続テスト
python tools/wp-publish.py --test

# 記事を下書き保存
python tools/wp-publish.py path/to/article.md

# 記事を下書き保存 + ナレッジベースにも追加
python tools/wp-publish.py path/to/article.md --save-kb
```

## ワークフロー

```
キーワード入力
    ↓
/article:outline（構成案作成）
    ↓ ← config/ + knowledge-base/ を読み込み
ユーザー承認
    ↓
/article:generate（記事執筆）
    ↓ ← knowledge-base/ から口調・事例を再現
/article:analyze（品質チェック）
    ↓
WordPress入稿（手動 or wp-publish.py）
    ↓
knowledge-base更新 → 次の記事がより良くなる
```

## ライセンス

株式会社Footage 社内利用

# Claude Code Skills — FOOTAGE AIX

Claude Code のカスタムスキル集。FOOTAGE AIXプロジェクトで使用するSkillを管理。

## スキル一覧

### このリポ管理（Mac共通）

| スキル | 概要 |
|---|---|
| `gas-auto-deploy` | FOOTAGE HANDLE GASへの自動注入・デプロイ |
| `seo-lmo-writing` | SEO/LMO最適化記事生成・改善・品質チェック |
| `workflow-orchestration` | タスク計画・サブエージェント委譲・自己改善ループ |
| `project-visualizer` | タスク進捗・タイムライン・依存関係の可視化 |
| `penpot-uiux-design` | PenpotによるプロUI/UXデザイン作成 |

### footage-aix リポ連携（シンボリックリンク）

| スキル | 概要 | ソース |
|---|---|---|
| `article-skills` | SEO記事生成 6コマンド（generate/outline/analyze/improve/keywords/list）+ KB 100記事超 | `footage-aix/article-skills/` |

> footage-aix リポの `*-skills/` ディレクトリは `setup.sh` 実行時に自動でシンボリックリンクされます。

## 新しいMacへのセットアップ

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/oyuta-svg/claude-skills/main/setup.sh)
```

または手動：

```bash
# 1. クローン
git clone git@github.com:oyuta-svg/claude-skills.git ~/.claude/skills

# 2. 自動pull設定（LaunchAgent）
cp ~/.claude/skills/com.footage.claude-skills-sync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.footage.claude-skills-sync.plist
```

## スキルの更新・追加

```bash
cd ~/.claude/skills
git add .
git commit -m "feat: <skill-name> - <変更内容>"
git push
```

他のMacへの反映はLaunchAgentが自動的に行います（1時間ごと）。

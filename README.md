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

| `article-skills` | SEO記事生成 6コマンド（generate/outline/analyze/improve/keywords/list）+ KB 100記事超 | 本リポに統合済み |

## 新しいMacへのセットアップ

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/footage-inc/claude-skills/main/setup.sh)
```

または手動：

```bash
# 読み取り専用（他メンバー向け）
git clone https://github.com/footage-inc/claude-skills.git ~/.claude/skills

# push権限あり（管理者向け・SSH必要）
git clone git@github.com:footage-inc/claude-skills.git ~/.claude/skills

# サブモジュール初期化
git -C ~/.claude/skills submodule update --init --recursive

# 自動pull設定（LaunchAgent）
sed "s|__HOME__|${HOME}|g" ~/.claude/skills/com.footage.claude-skills-sync.plist > ~/Library/LaunchAgents/com.footage.claude-skills-sync.plist
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

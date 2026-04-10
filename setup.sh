#!/bin/bash
# Claude Skills セットアップスクリプト
# 新しいMacで1コマンド実行するだけでスキルを同期

set -e

# SSH書き込み用 / HTTPS読み取り専用
REPO_SSH="git@github.com:footage-inc/claude-skills.git"
REPO_HTTPS="https://github.com/footage-inc/claude-skills.git"

# SSHキーがあればSSH（push可能）、なければHTTPS（読み取り専用）
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  REPO="$REPO_SSH"
  echo "SSH認証OK → SSH URL（push可能）"
else
  REPO="$REPO_HTTPS"
  echo "SSH認証なし → HTTPS URL（読み取り専用）"
fi
TARGET="$HOME/.claude/skills"
PLIST_NAME="com.footage.claude-skills-sync"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

echo "=== Claude Skills セットアップ ==="

# ~/.claude ディレクトリ確認
mkdir -p "$HOME/.claude"

# すでにスキルが存在する場合
if [ -d "$TARGET/.git" ]; then
  echo "既存のgitリポジトリを検出。git pullで更新します..."
  git -C "$TARGET" pull
else
  if [ -d "$TARGET" ]; then
    echo "既存のskillsディレクトリをバックアップ..."
    mv "$TARGET" "${TARGET}_backup_$(date +%Y%m%d%H%M%S)"
  fi
  echo "リポジトリをクローン中..."
  git clone "$REPO" "$TARGET"
fi

# サブモジュール初期化（gstack等）
echo "サブモジュールを初期化中..."
git -C "$TARGET" submodule update --init --recursive

echo "スキルのクローン完了: $TARGET"

# LaunchAgent（自動同期）のインストール — リポのテンプレートから生成
sed "s|__HOME__|${HOME}|g" "$TARGET/com.footage.claude-skills-sync.plist" > "$PLIST_PATH"

mkdir -p "$HOME/.claude/logs"
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

# footage-aix リポの *-skills/ をシンボリックリンク
FOOTAGE_AIX_REPO="$HOME/dev/footage-aix"
if [ -d "$FOOTAGE_AIX_REPO" ]; then
  echo ""
  echo "=== footage-aix Skills リンク ==="
  for skills_dir in "$FOOTAGE_AIX_REPO"/*-skills; do
    if [ -d "$skills_dir" ]; then
      skill_name=$(basename "$skills_dir")
      link_path="$TARGET/$skill_name"
      if [ -L "$link_path" ]; then
        echo "  既存リンク: $skill_name → $(readlink "$link_path")"
      elif [ -d "$link_path" ]; then
        echo "  スキップ（実ディレクトリが存在）: $skill_name"
      else
        ln -s "$skills_dir" "$link_path"
        echo "  リンク作成: $skill_name → $skills_dir"
      fi
    fi
  done
else
  echo ""
  echo "[INFO] footage-aix リポが $FOOTAGE_AIX_REPO に見つかりません。"
  echo "  footage-aix のスキルを連携するには:"
  echo "  git clone git@github.com:oyuta-svg/footage-aix.git $FOOTAGE_AIX_REPO"
  echo "  bash $TARGET/setup.sh  # 再実行でリンクされます"
fi

# Claude Code plugin としてスキルを登録
PLUGIN_DIR="$HOME/.claude/plugins/marketplaces/claude-plugins-official/plugins/footage-aix-skills"
echo ""
echo "=== Claude Code Plugin 登録 ==="
mkdir -p "$PLUGIN_DIR/.claude-plugin" "$PLUGIN_DIR/skills"

cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" << 'PJSON'
{
  "name": "footage-aix-skills",
  "description": "FOOTAGE AIXプロジェクトのカスタムスキル集。SEO記事生成、GASデプロイ、ワークフロー管理等。",
  "author": {
    "name": "FOOTAGE",
    "email": "o.yuta@footage-nursing.jp"
  }
}
PJSON

# 各スキルディレクトリの SKILL.md を plugin/skills/ にシンボリックリンク
for skill_dir in "$TARGET"/*/; do
  skill_name=$(basename "$skill_dir")
  # .git や隠しディレクトリはスキップ
  [[ "$skill_name" == .* ]] && continue
  if [ -f "$skill_dir/SKILL.md" ]; then
    link_path="$PLUGIN_DIR/skills/$skill_name"
    if [ ! -L "$link_path" ] && [ ! -d "$link_path" ]; then
      ln -s "$skill_dir" "$link_path"
      echo "  Plugin登録: $skill_name"
    else
      echo "  既存: $skill_name"
    fi
  fi
done

echo ""
echo "=== セットアップ完了 ==="
echo "スキル: $TARGET"
echo "自動同期: 1時間ごと (LaunchAgent: $PLIST_NAME)"
echo ""
echo "手動同期: git -C ~/.claude/skills pull"

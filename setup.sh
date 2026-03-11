#!/bin/bash
# Claude Skills セットアップスクリプト
# 新しいMacで1コマンド実行するだけでスキルを同期

set -e

REPO="git@github.com:oyuta-svg/claude-skills.git"
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

echo "スキルのクローン完了: $TARGET"

# LaunchAgent（自動同期）のインストール
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${PLIST_NAME}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/git</string>
    <string>-C</string>
    <string>${TARGET}</string>
    <string>pull</string>
    <string>--ff-only</string>
  </array>
  <key>StartInterval</key>
  <integer>3600</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${HOME}/.claude/logs/skills-sync.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/.claude/logs/skills-sync-error.log</string>
</dict>
</plist>
EOF

mkdir -p "$HOME/.claude/logs"
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo "=== セットアップ完了 ==="
echo "スキル: $TARGET"
echo "自動同期: 1時間ごと (LaunchAgent: $PLIST_NAME)"
echo ""
echo "手動同期: git -C ~/.claude/skills pull"

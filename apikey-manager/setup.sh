#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# APIキーマネージャー セットアップスクリプト
#
# clone後に実行:
#   bash .claude/skills/apikey-manager/setup.sh
#
# 実行内容:
#   1. 依存ツール (openssl, jq) の確認
#   2. スキルを ~/.claude/skills/apikey-manager にシンボリックリンク
#   3. チーム共有ストア (.apikeys/store.enc) の存在確認
#   4. マスターパスワードの動作テスト
# ============================================================

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SKILL_SRC="$PROJECT_ROOT/.claude/skills/apikey-manager"
SKILL_DST="$HOME/.claude/skills/apikey-manager"
PROJECT_STORE="$PROJECT_ROOT/.apikeys"

echo "=== APIキーマネージャー セットアップ ==="
echo "プロジェクト: $PROJECT_ROOT"

# 1. 依存チェック
echo -e "\n[1/4] 依存ツール確認..."
for cmd in openssl jq; do
  if command -v "$cmd" &>/dev/null; then
    echo "  ✓ $cmd: $(command -v "$cmd")"
  else
    echo "  ✗ $cmd: 未インストール"
    echo "    brew install $cmd"
    exit 1
  fi
done

# 2. シンボリックリンク
echo -e "\n[2/4] スキルのシンボリックリンク..."
mkdir -p "$HOME/.claude/skills"
if [[ -L "$SKILL_DST" ]]; then
  echo "  既存リンク: $(readlink "$SKILL_DST")"
  if [[ "$(readlink "$SKILL_DST")" != "$SKILL_SRC" ]]; then
    rm "$SKILL_DST"
    ln -s "$SKILL_SRC" "$SKILL_DST"
    echo "  → 更新: $SKILL_DST → $SKILL_SRC"
  else
    echo "  → 変更なし"
  fi
elif [[ -d "$SKILL_DST" ]]; then
  echo "  既存ディレクトリを発見。バックアップ後にリンク作成..."
  mv "$SKILL_DST" "$SKILL_DST.bak.$(date +%Y%m%d%H%M%S)"
  ln -s "$SKILL_SRC" "$SKILL_DST"
  echo "  → リンク作成: $SKILL_DST → $SKILL_SRC"
else
  ln -s "$SKILL_SRC" "$SKILL_DST"
  echo "  → リンク作成: $SKILL_DST → $SKILL_SRC"
fi

# 3. チーム共有ストア確認
echo -e "\n[3/4] チーム共有ストア確認..."
if [[ -f "$PROJECT_STORE/store.enc" ]]; then
  echo "  ✓ $PROJECT_STORE/store.enc が存在"
else
  echo "  ✗ チーム共有ストアが見つかりません"
  echo "  チームリーダーに .apikeys/store.enc を確認してください"
  exit 1
fi

# 4. パスワードテスト
echo -e "\n[4/4] チーム共有ストア接続テスト..."
if [[ -n "${APIKEY_TEAM_PW:-${APIKEY_MASTER_PW:-}}" ]]; then
  PW="${APIKEY_TEAM_PW:-$APIKEY_MASTER_PW}"
  if "$SKILL_SRC/bin/apikey.sh" --store "$PROJECT_STORE" list "$PW" &>/dev/null; then
    echo "  ✓ ストア復号OK"
    echo ""
    echo "  登録済みキー:"
    "$SKILL_SRC/bin/apikey.sh" --store "$PROJECT_STORE" list "$PW" | while read -r line; do
      echo "    $line"
    done
  else
    echo "  ✗ パスワードが一致しません"
    echo "  APIKEY_MASTER_PW または APIKEY_TEAM_PW を確認してください"
    exit 1
  fi
else
  echo "  ⚠ APIKEY_MASTER_PW が未設定。スキップ。"
  echo "  使用前に export APIKEY_MASTER_PW=<password> を設定してください"
fi

echo -e "\n=== セットアップ完了 ==="
echo ""
echo "使い方:"
echo "  export APIKEY_MASTER_PW=<チーム共有パスワード>"
echo "  # Claude Code で /apikey list"
echo "  # Claude Code で /apikey inject"
echo ""

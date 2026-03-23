---
name: apikey
description: "APIキーの暗号化CRUD管理。追加・一覧・取得・更新・削除・.env注入をサポート。"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# APIキー管理スキル

暗号化ファイル (`~/.claude/apikeys/store.enc`) でAPIキーをCRUD管理し、プロジェクトの`.env`に注入できるスキル。

## 定数

- **ヘルパースクリプト**: `~/.claude/skills/apikey-manager/bin/apikey.sh`
- **暗号化ストア**: `~/.claude/apikeys/store.enc`
- **暗号方式**: openssl aes-256-cbc -pbkdf2

## 初期セットアップ

スキル呼び出し時、まず以下を確認:

1. プロジェクトストア（`<git-root>/.apikeys/store.enc`）の有無を検出
2. 環境変数 `APIKEY_MASTER_PW`（パーソナル）と `APIKEY_TEAM_PW`（チーム共有）を確認
3. 必要なパスワードが未設定なら `AskUserQuestion` で入力してもらう
4. ストアが存在しなければ初期化

```bash
# プロジェクトストアの自動検出
_GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_PROJECT_STORE=""
if [[ -n "$_GIT_ROOT" && -f "$_GIT_ROOT/.apikeys/store.enc" ]]; then
  _PROJECT_STORE="$_GIT_ROOT/.apikeys"
  echo "PROJECT_STORE: $_PROJECT_STORE"
fi

# パスワードチェック
if [[ -n "$_PROJECT_STORE" && -z "${APIKEY_TEAM_PW:-}" ]]; then
  echo "NEED_TEAM_PASSWORD"
fi
if [[ -z "${APIKEY_MASTER_PW:-}" ]]; then
  echo "NEED_PERSONAL_PASSWORD"
fi

# パーソナルストア初期化
if [[ ! -f ~/.claude/apikeys/store.enc ]]; then
  ~/.claude/skills/apikey-manager/bin/apikey.sh init "$APIKEY_MASTER_PW"
fi
```

### ストア参照の優先順位

全てのコマンド（list, get, add, inject等）で以下の順にキーを探す:
1. **プロジェクトストア** (`--store $PROJECT_STORE`) — チーム共有キー
2. **パーソナルストア** (`~/.claude/apikeys`) — 個人キー

プロジェクトストアがある場合、`--store $_PROJECT_STORE` オプションを自動付与する。

## コマンド別ワークフロー

引数の解析: `/apikey <subcommand> [args...]`

### `/apikey add`

1. `AskUserQuestion` で以下を対話入力:
   - サービス名 (例: `openai`, `anthropic`, `stripe`)
   - 環境名 (例: `dev`, `prod`, `default`) — デフォルト: `default`
   - APIキーの値
   - ENV変数名 (例: `OPENAI_API_KEY`) — デフォルト: `<SERVICE>_API_KEY` (大文字)
2. 現在のストアを復号:
   ```bash
   CURRENT=$(~/.claude/skills/apikey-manager/bin/apikey.sh decrypt "$APIKEY_MASTER_PW")
   ```
3. jqで新しいキーを追加:
   ```bash
   UPDATED=$(echo "$CURRENT" | jq \
     --arg svc "$SERVICE" \
     --arg env "$ENV" \
     --arg val "$VALUE" \
     --arg evar "$ENV_VAR" \
     --arg date "$(date +%Y-%m-%d)" \
     '.keys[$svc][$env] = {"value": $val, "env_var": $evar, "added": $date}')
   ```
4. 暗号化して保存:
   ```bash
   echo "$UPDATED" | ~/.claude/skills/apikey-manager/bin/apikey.sh encrypt "$APIKEY_MASTER_PW"
   ```
5. 追加完了メッセージを表示（値はマスク表示）

### `/apikey list`

1. ヘルパーでマスク済み一覧を表示:
   ```bash
   ~/.claude/skills/apikey-manager/bin/apikey.sh list "$APIKEY_MASTER_PW"
   ```
2. テーブル形式で整形して出力:
   ```
   Service         Env        ENV Variable              Value                Added
   ───────────────────────────────────────────────────────────────────────────────
   openai          dev        OPENAI_API_KEY            ****xxxx             2026-03-20
   anthropic       default    ANTHROPIC_API_KEY         ****xxxx             2026-03-20
   ```

### `/apikey get <service> [env]`

1. 引数からサービス名と環境名を取得（環境名デフォルト: `default`）
2. キーを復号取得:
   ```bash
   ~/.claude/skills/apikey-manager/bin/apikey.sh get "$APIKEY_MASTER_PW" "$SERVICE" "$ENV"
   ```
3. 値を表示（⚠️ 平文表示される旨を警告）

### `/apikey update <service> [env]`

1. 引数からサービス名と環境名を取得
2. `AskUserQuestion` で新しいキー値を入力
3. 復号 → jqで値を更新 → 暗号化保存:
   ```bash
   CURRENT=$(~/.claude/skills/apikey-manager/bin/apikey.sh decrypt "$APIKEY_MASTER_PW")
   UPDATED=$(echo "$CURRENT" | jq \
     --arg svc "$SERVICE" \
     --arg env "$ENV" \
     --arg val "$NEW_VALUE" \
     '.keys[$svc][$env].value = $val')
   echo "$UPDATED" | ~/.claude/skills/apikey-manager/bin/apikey.sh encrypt "$APIKEY_MASTER_PW"
   ```

### `/apikey delete <service> [env]`

1. 引数からサービス名と環境名を取得
2. `AskUserQuestion` で削除確認
3. 復号 → jqで削除 → 暗号化保存:
   ```bash
   CURRENT=$(~/.claude/skills/apikey-manager/bin/apikey.sh decrypt "$APIKEY_MASTER_PW")
   UPDATED=$(echo "$CURRENT" | jq \
     --arg svc "$SERVICE" \
     --arg env "$ENV" \
     'del(.keys[$svc][$env]) | if (.keys[$svc] | length) == 0 then del(.keys[$svc]) else . end')
   echo "$UPDATED" | ~/.claude/skills/apikey-manager/bin/apikey.sh encrypt "$APIKEY_MASTER_PW"
   ```

### `/apikey inject [dir] [env]`

1. ディレクトリ: 引数指定 or カレントディレクトリ
2. 環境名: 引数指定 or プロジェクト設定から取得 or `default`
3. プロジェクト設定からサービス一覧を取得。未設定なら全キーを対象。
4. 復号して対象キーを抽出:
   ```bash
   CURRENT=$(~/.claude/skills/apikey-manager/bin/apikey.sh decrypt "$APIKEY_MASTER_PW")
   ```
5. `.env` ファイルを生成:
   ```bash
   # 既存の.envがあればバックアップ
   if [[ -f "$DIR/.env" ]]; then
     cp "$DIR/.env" "$DIR/.env.backup.$(date +%Y%m%d%H%M%S)"
   fi
   ```
6. jqで ENV_VAR=VALUE 形式に変換して書き出し:
   ```bash
   echo "$CURRENT" | jq -r --arg env "$ENV" '
     .keys | to_entries[] |
     .value[$env] // empty |
     "\(.env_var)=\(.value)"
   ' > "$DIR/.env"
   ```
7. 生成された`.env`の内容をマスク表示で確認
8. `.gitignore` に `.env` が含まれているか確認。なければ警告。

### `/apikey project <dir>`

1. `AskUserQuestion` で以下を入力:
   - 環境名 (dev/prod/staging等)
   - 紐付けるサービス名のリスト
2. 復号 → projects に設定を追加 → 暗号化保存:
   ```bash
   CURRENT=$(~/.claude/skills/apikey-manager/bin/apikey.sh decrypt "$APIKEY_MASTER_PW")
   UPDATED=$(echo "$CURRENT" | jq \
     --arg dir "$DIR" \
     --arg env "$ENV" \
     --argjson svcs '["openai","anthropic"]' \
     '.projects[$dir] = {"environment": $env, "services": $svcs}')
   echo "$UPDATED" | ~/.claude/skills/apikey-manager/bin/apikey.sh encrypt "$APIKEY_MASTER_PW"
   ```

### `/apikey export [env]`

1. 環境名: 引数指定 or `default`
2. 復号して全キーをENV形式で標準出力:
   ```bash
   ~/.claude/skills/apikey-manager/bin/apikey.sh decrypt "$APIKEY_MASTER_PW" | jq -r --arg env "$1" '
     .keys | to_entries[] |
     .value[$env] // empty |
     "export \(.env_var)=\"\(.value)\""
   '
   ```

## セキュリティ注意事項

- **平文JSONをディスクに書き出さない**: 全操作はパイプ経由で行う。一時ファイルを作らない。
- **マスターパスワードは環境変数のみ**: `APIKEY_MASTER_PW` はセッション終了で消える。永続化しない。
- **`/apikey get` の出力は平文**: 端末に表示される点をユーザーに警告する。
- **`.env` は `.gitignore` に含める**: inject時に `.gitignore` をチェックし、未記載なら追加を提案する。
- **store.enc はgit管理可能**: バイナリファイルだが `.gitattributes` で管理推奨。

## 自動キー解決（Auto-Resolve）

**このスキルの核心機能。** 会話中にAPIキーが必要になった場面で、Claudeが自動的にストアを参照し注入する。

### トリガー条件

以下のいずれかを検出したら自動的にこのフローを実行する：

- `.env` に `*_API_KEY` や `*_SECRET` 等が必要だが値が空・未設定
- `npm install`, `pip install` 等でAPI系パッケージをインストールした直後
- コード中に `process.env.OPENAI_API_KEY` 等の参照があるが未設定
- コマンド実行時に「API key not found」「unauthorized」「authentication failed」等のエラー
- ユーザーが「APIキーが必要」「キーを設定して」等と言った

### 自動解決フロー

```
1. サービス名を特定（パッケージ名・エラー文・ENV変数名から推測）
   例: openai パッケージ → サービス名 "openai"
   例: ANTHROPIC_API_KEY → サービス名 "anthropic"
   例: STRIPE_SECRET_KEY → サービス名 "stripe"

2. ストアに該当キーがあるか確認
   → ~/.claude/skills/apikey-manager/bin/apikey.sh get "$APIKEY_MASTER_PW" "$SERVICE" "$ENV"

3a. キーが見つかった場合:
   → 「ストアから $SERVICE のAPIキーを取得しました。.envに注入します。」と通知
   → プロジェクトの .env に自動書き込み（既存値は上書きしない）
   → 作業を続行

3b. キーが見つからない場合:
   → AskUserQuestion で「$SERVICE のAPIキーを入力してください」と聞く
   → 入力されたキーをストアに保存（サービス名・ENV変数名は自動推測）
   → .env に注入
   → 作業を続行

3c. ストアが未初期化（store.enc がない）場合:
   → AskUserQuestion でマスターパスワードを聞く
   → ストア初期化 → 3b へ
```

### サービス名の自動推測マッピング

| パッケージ / エラー文 | サービス名 | デフォルトENV変数 |
|----------------------|-----------|-----------------|
| `openai` | openai | `OPENAI_API_KEY` |
| `anthropic`, `@anthropic-ai/sdk` | anthropic | `ANTHROPIC_API_KEY` |
| `stripe` | stripe | `STRIPE_SECRET_KEY` |
| `@google/generative-ai` | google-ai | `GOOGLE_API_KEY` |
| `@supabase/supabase-js` | supabase | `SUPABASE_KEY` |
| `firebase`, `firebase-admin` | firebase | `FIREBASE_API_KEY` |
| `resend` | resend | `RESEND_API_KEY` |
| `@sendgrid/mail` | sendgrid | `SENDGRID_API_KEY` |
| `twilio` | twilio | `TWILIO_AUTH_TOKEN` |
| `aws-sdk`, `@aws-sdk/*` | aws | `AWS_SECRET_ACCESS_KEY` |

#### OAuthクレデンシャル

APIキーだけでなく、OAuthクライアント情報（Client ID / Client Secret）も管理対象。

| トリガー | サービス名 | デフォルトENV変数 |
|---------|-----------|-----------------|
| Google OAuth, Supabase Auth Google | google-oauth-client-id | `GOOGLE_OAUTH_CLIENT_ID` |
| 同上（シークレット） | google-oauth-client-secret | `GOOGLE_OAUTH_CLIENT_SECRET` |
| YouTube OAuth | youtube-oauth-client-id | `YOUTUBE_CLIENT_ID` |
| 同上（シークレット） | youtube-oauth-client-secret | `YOUTUBE_CLIENT_SECRET` |
| GitHub OAuth | github-oauth-client-id | `GITHUB_CLIENT_ID` |
| 同上（シークレット） | github-oauth-client-secret | `GITHUB_CLIENT_SECRET` |
| LINE Login | line-channel-id | `LINE_CHANNEL_ID` |
| 同上（シークレット） | line-channel-secret | `LINE_CHANNEL_SECRET` |

OAuthクレデンシャルの検出パターン:
- `*_CLIENT_ID` / `*_CLIENT_SECRET` → OAuthクレデンシャルとして扱う
- Supabase Auth プロバイダー設定時に自動検出
- `signInWithOAuth`, `auth.signIn` 等のコードパターン

#### 汎用推測ルール

上記に該当しない場合は、ENV変数名から `_API_KEY` / `_SECRET_KEY` / `_TOKEN` / `_CLIENT_ID` / `_CLIENT_SECRET` を除いた部分をサービス名として推測する。

### .env 注入ルール

- 既存の `.env` にすでに値がセットされているキーは上書きしない
- `.env` がなければ新規作成
- 書き込み後、`.gitignore` に `.env` がなければ追加を提案
- 注入したキーはマスク表示でユーザーに報告（例: `OPENAI_API_KEY=sk-...xxxx を設定しました`）

## チーム共有（Git連携）

### 構成

```
my-project/
├── .apikeys/
│   └── store.enc          ← チーム共有の暗号化ストア（git管理）
├── .claude/
│   └── skills/
│       └── apikey-manager/  ← スキル本体（git管理 or symlink）
│           ├── SKILL.md
│           ├── setup.sh
│           └── bin/
│               └── apikey.sh
├── .gitattributes
├── .gitignore
└── .env                   ← 平文（git管理しない）
```

### プロジェクトへのスキル導入

1. スキルをプロジェクトにコピー or サブモジュールとして追加:
   ```bash
   cp -r ~/.claude/skills/apikey-manager .claude/skills/apikey-manager
   # or
   git submodule add <repo-url> .claude/skills/apikey-manager
   ```

2. `.gitattributes` に追加:
   ```
   *.enc binary
   ```

3. `.gitignore` に追加:
   ```
   .env
   .env.local
   .env.*.local
   *.backup.*
   ```

4. チーム共有ストアを初期化:
   ```bash
   apikey.sh --store .apikeys init "<team-master-password>"
   ```

5. git commit & push

### チームメンバーのセットアップ

clone後:
```bash
bash .claude/skills/apikey-manager/setup.sh
```

これだけで:
- スキルが `~/.claude/skills/apikey-manager` にシンボリックリンクされる
- 依存ツール（openssl, jq）が確認される
- チーム共有ストアが検出される

### ストアの優先順位

キー検索時、以下の順に探す:

1. **プロジェクトストア** (`<project-root>/.apikeys/store.enc`) — チーム共有キー
2. **パーソナルストア** (`~/.claude/apikeys/store.enc`) — 個人キー

```
キー検索フロー:
  プロジェクトストアにあるか? → YES → 使用
                               → NO  → パーソナルストアにあるか? → YES → 使用
                                                                  → NO  → ユーザーに聞く → 保存先を選択
```

### `/apikey add` でのストア選択

チーム共有ストアが存在する場合、add時に保存先を聞く:
- **チーム共有** (`--store <project>/.apikeys`) — 全メンバーが使えるキー
- **パーソナル** — 自分だけが使うキー

### マスターパスワード管理

- **チーム共有ストア用**: `APIKEY_TEAM_PW` 環境変数（チームで共有するパスワード）
- **パーソナルストア用**: `APIKEY_MASTER_PW` 環境変数（個人パスワード）
- セッション開始時、必要に応じて両方を聞く（使うストアに応じて）

## 自動コミット（プロジェクトストア変更時）

**プロジェクトストア (`<git-root>/.apikeys/store.enc`) を変更する操作の後、自動的にgitコミットする。**

### 対象操作

以下のコマンドでプロジェクトストアに書き込みが発生した場合:
- `/apikey add`（チーム共有を選択した場合）
- `/apikey update`
- `/apikey delete`
- `/apikey merge`
- `init`（プロジェクトストア初期化時）
- 自動解決フローでストアに新規保存した場合

### 自動コミットフロー

ストアへの書き込み完了後、以下を実行:

```bash
_GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -n "$_GIT_ROOT" && -f "$_GIT_ROOT/.apikeys/store.enc" ]]; then
  cd "$_GIT_ROOT"
  if git diff --name-only .apikeys/store.enc 2>/dev/null | grep -q store.enc; then
    git add .apikeys/store.enc
    git commit -m "[Claude] chore: update encrypted API key store"
    git pull --rebase 2>/dev/null || true
    git push 2>/dev/null && echo "AUTO_PUSHED: .apikeys/store.enc" || echo "PUSH_FAILED: manual push required"
    echo "AUTO_COMMITTED: .apikeys/store.enc"
  fi
fi
```

### ルール

- **コミットメッセージ**: `[Claude] chore: update encrypted API key store`（固定）
- **コミット後に自動push**: `pull --rebase` → `push` を実行。チームメンバーが即座に最新キーを取得可能
- **push失敗時**: 警告を表示して続行（コミットは成功しているのでユーザーが後でpush可能）
- **パーソナルストアは対象外**: `~/.claude/apikeys/store.enc` はgit管理外なのでコミットしない
- **コミット失敗時**: 警告を表示して続行（ストア更新自体は成功しているため）

## エラーハンドリング

- パスワード間違い → 復号失敗メッセージ、再入力を促す
- サービス/環境が見つからない → 一覧を表示して選択を促す
- jqがインストールされていない → インストール手順を案内
- store.encが壊れている → バックアップから復元を案内

# WordPress REST API セットアップ手順

footage-nursing.jp への記事自動入稿のためのセットアップガイドです。

## 前提条件
- WordPress管理画面へのアクセス権限（管理者 or 編集者）
- WordPress 5.6以上（Application Password対応）

## STEP 1: Application Passwordの発行

1. WordPress管理画面にログイン
2. **ユーザー** > **プロフィール** に移動
3. ページ下部の「**アプリケーションパスワード**」セクションを見つける
4. 「新しいアプリケーションパスワード名」に `article-skills` と入力
5. 「**新しいアプリケーションパスワードを追加**」をクリック
6. 表示されたパスワード（例: `ABCD 1234 EFGH 5678 IJKL 9012`）を**コピーして安全な場所に保管**

> このパスワードは一度しか表示されません。紛失した場合は再発行が必要です。

## STEP 2: 環境変数の設定

ターミナルで以下を設定（.bashrc や .zshrc に追加推奨）:

```bash
export WP_URL="https://footage-nursing.jp"
export WP_USERNAME="あなたのWordPressユーザー名"
export WP_APP_PASSWORD="ABCD 1234 EFGH 5678 IJKL 9012"
```

セキュリティのため、`.env` ファイルに保存してもOK:

```bash
# .env（.gitignore に追加済み）
WP_URL=https://footage-nursing.jp
WP_USERNAME=your_username
WP_APP_PASSWORD=ABCD 1234 EFGH 5678 IJKL 9012
```

## STEP 3: Pythonパッケージのインストール

```bash
pip install requests python-frontmatter markdown
```

## STEP 4: 接続テスト

```bash
python tools/wp-publish.py --test
```

成功すると以下のように表示されます:

```
==================================================
WordPress REST API 接続テスト
==================================================
URL: https://footage-nursing.jp

✅ サイト接続OK: Footage
✅ 認証OK: your_username (your_slug)

✅ 投稿タイプ 'column' (column): アクセス可能
✅ 投稿タイプ 'rec_column' (rec_column): アクセス可能
```

## STEP 5: テスト入稿

```bash
# ドライラン（実際には保存しない）
python tools/wp-publish.py test-output/20260223_褥瘡予防在宅ケア訪問看護.md --dry-run

# 下書き保存
python tools/wp-publish.py test-output/20260223_褥瘡予防在宅ケア訪問看護.md
```

## トラブルシューティング

### 「Application Password」セクションが表示されない
- WordPressが5.6未満の場合はアップデートが必要
- SSL（https）が有効になっていない場合は表示されないことがある
- プラグインが無効にしている場合がある

### HTTP 401 Unauthorized
- ユーザー名またはApplication Passwordが間違っている
- Application Passwordにスペースが含まれていることを確認（そのまま設定）

### HTTP 403 Forbidden
- ユーザーの権限が不足（「編集者」以上が必要）
- REST APIがプラグイン等で制限されている可能性

### カスタム投稿タイプにアクセスできない
- `column` や `rec_column` のREST API公開設定を確認
- `functions.php` で `'show_in_rest' => true` が設定されていること:

```php
// functions.php での設定例
register_post_type('column', array(
    'show_in_rest' => true,
    'rest_base' => 'column',
    // ... 他の設定
));
```

## セキュリティ注意事項
- Application Passwordは通常のパスワードと同等の権限を持ちます
- `.env` ファイルは `.gitignore` に追加し、GitHubにプッシュしないこと
- 不要になったApplication Passwordは速やかに削除
- 本番環境では、入稿専用の権限制限付きユーザーを作成することを推奨

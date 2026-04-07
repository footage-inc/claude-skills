# WordPress 操作リファレンス — footage-nursing.jp

> gstack/browse で WordPress 管理画面を操作する際の手順書。
> このファイルは `$B` (browse コマンド) 前提で書かれている。

---

## 1. 前提条件

| 項目 | 値 |
|------|-----|
| サイト | `https://footage-nursing.jp` |
| WP管理画面 | `https://footage-nursing.jp/app/wp-admin/` |
| ログインURL | `https://footage-nursing.jp/app/login_73906/` |
| ユーザー名 | `footage_user` |
| エディタ | Classic Editor（Gutenbergではない） |
| SiteGuard | 導入済み。`/wp-admin/` → 403。必ず `/app/login_73906/` を使う |
| REST API | カスタム投稿タイプは使用不可（nginx が Authorization ヘッダーを転送しない） |

---

## 2. ログインフロー

### 2-1. Cookie インポート方式（推奨）

ブラウザ（Comet / Chrome / Arc）で事前にWP管理画面にログインしておく。

```
$B cookie-import-browser comet --domain footage-nursing.jp
$B goto https://footage-nursing.jp/app/wp-admin/
$B snapshot
```

**確認ポイント:**
- snapshot に「ダッシュボード」が表示 → ログイン成功
- ログイン画面が表示 → Cookie 期限切れ。ブラウザで再ログイン後、再インポート

### 2-2. 直接ログイン方式

Cookie インポートが使えない場合:

```
$B goto https://footage-nursing.jp/app/login_73906/
$B snapshot
$B fill @user-login-input footage_user
$B fill @user-pass-input [パスワード]
$B click @wp-submit-button
$B wait 3000
$B snapshot
```

**注意:** パスワードは `.env` または Secret Manager から取得。会話に直書きしない。

### 2-3. ログイン状態の判定

```
$B url
```

- URL に `login` / `wp-login` を含む → 未ログイン
- URL が `/app/wp-admin/` を含む → ログイン済み

---

## 3. 投稿タイプとURL

| 投稿タイプ | スラッグ | 新規作成URL |
|-----------|---------|------------|
| コラム（訪問看護/デイ） | `column` | `/app/wp-admin/post-new.php?post_type=column` |
| 経営支援コラム | `rec_column` | `/app/wp-admin/post-new.php?post_type=rec_column` |
| ブログ | `blog` | `/app/wp-admin/post-new.php?post_type=blog` |
| お知らせ | `news` | `/app/wp-admin/post-new.php?post_type=news` |
| 通常投稿 | `post` | `/app/wp-admin/post-new.php` |

---

## 4. 新規記事作成（Classic Editor）

### 4-1. 投稿画面を開く

```
$B goto https://footage-nursing.jp/app/wp-admin/post-new.php?post_type=column
$B wait 3000
$B snapshot
```

**3秒待つ理由:** Classic Editor の JS 初期化に時間がかかる。snapshot で `#title` が見えることを確認してから次へ。

### 4-2. タイトル入力

```
$B fill #title 記事タイトル
```

### 4-3. 本文入力（HTML モード）

Classic Editor はビジュアル/テキスト(HTML)の2タブ。HTML を直接入力する場合:

```
$B click #content-html
$B wait 500
$B fill #content <p>本文HTML</p>
```

**注意:**
- `#content-html` が見つからない場合、すでにテキストタブが選択されている
- `fill` で入力する前に `snapshot` で `#content` textarea が存在するか確認
- 長い HTML は `js` コマンドで直接セット:

```
$B js document.getElementById('content').value = '<p>長い本文...</p>'
```

### 4-4. カテゴリ選択

```
$B snapshot
```

サイドバーのカテゴリチェックボックスを確認し、@ref で click:

```
$B click @category-checkbox-ref
```

### 4-5. 下書き保存

```
$B click #save-post
$B wait 3000
$B snapshot
```

**確認:** snapshot に「下書きを保存しました」メッセージ、または URL に `post=<ID>` が含まれる。

### 4-6. 予約投稿（日時指定）

```
# 日時編集を開く
$B click .edit-timestamp
$B wait 1000
$B snapshot

# 日時を設定
$B select #mm <月の値>        # 例: 04
$B fill #jj <日>             # 例: 15
$B fill #aa <年>             # 例: 2026
$B fill #hh <時>             # 例: 08
$B fill #mn <分>             # 例: 00

# 日時確定
$B click .save-timestamp
$B wait 1000

# 予約投稿を実行
$B click #publish
$B wait 5000
$B snapshot
```

**月の select 値:** `01`=1月, `02`=2月, ..., `12`=12月

### 4-7. 投稿ID取得

```
$B js document.getElementById('post_ID').value
```

---

## 5. 既存記事の編集

### 5-1. 記事一覧から開く

```
$B goto https://footage-nursing.jp/app/wp-admin/edit.php?post_type=column
$B wait 2000
$B snapshot
```

### 5-2. Post ID で直接開く

```
$B goto https://footage-nursing.jp/app/wp-admin/post.php?post=<POST_ID>&action=edit
$B wait 3000
$B snapshot
```

### 5-3. 更新保存

```
$B click #publish
$B wait 5000
$B snapshot
```

**注意:** 編集画面では「公開」ボタンが「更新」になっている。セレクタは同じ `#publish`。

---

## 6. メタフィールド操作

### 6-1. meta_description

カスタムフィールドが表示されていない場合:
```
$B snapshot
```

「表示オプション」でカスタムフィールドを有効化:
```
$B click #screen-options-link-wrap
$B wait 500
$B snapshot
# 「カスタムフィールド」チェックボックスを探して click
```

カスタムフィールドのキー/値を入力:
```
# 既存のカスタムフィールド欄を snapshot で確認
$B snapshot
# キーに "meta_description"、値に説明文を入力
```

---

## 7. エラー回復

### 7-1. ログインセッション切れ

**症状:** 操作中に突然ログイン画面にリダイレクトされる

```
$B url
# login が含まれていたら:
$B cookie-import-browser comet --domain footage-nursing.jp
$B goto https://footage-nursing.jp/app/wp-admin/
$B wait 3000
$B snapshot
```

### 7-2. nonce エラー

**症状:** 保存時に「セキュリティチェックに失敗しました」等のエラー

```
# ページをリロードして nonce を再取得
$B reload
$B wait 3000
$B snapshot
# 再度操作を実行
```

### 7-3. 403 Forbidden

**症状:** `/wp-admin/` に直接アクセスした

```
# SiteGuard により 403。正しい URL を使う:
$B goto https://footage-nursing.jp/app/login_73906/
```

### 7-4. 要素が見つからない

**症状:** `#title` や `#content` が snapshot に表示されない

```
# ページ読み込み待ち不足。追加で待つ:
$B wait 3000
$B snapshot

# まだない場合は JS で確認:
$B js document.readyState
$B js document.getElementById('title') !== null
```

### 7-5. handoff（手動介入）

自動操作が困難な場面（CAPTCHA、2FA等）:

```
$B handoff ログインが必要です。ブラウザで操作してください。
# ユーザーが操作完了後:
$B resume
$B snapshot
```

---

## 8. 操作のベストプラクティス

1. **毎回 snapshot で確認してから操作する。** 見えていない要素を操作しない
2. **`wait` は最低 2000ms。** WP管理画面の JS 初期化は遅い。特に `post-new.php` は 3000ms 必要
3. **HTML 入力は `js` コマンドで。** `fill` は短いテキスト向き。長い HTML は `js` で `value` を直接セット
4. **操作完了後は必ず url + snapshot で結果確認。** 保存成功/失敗を目視確認
5. **Cookie は事前にインポート。** 操作中のログイン処理は不安定になりやすい
6. **1操作1確認。** 複数操作をまとめず、fill → snapshot → click → snapshot のリズムで進める

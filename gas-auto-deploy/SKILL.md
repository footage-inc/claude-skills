---
name: gas-auto-deploy
description: >
  FOOTAGE HANDLEのGAS（Google Apps Script）プロジェクトにコードを自動注入・保存・デプロイするスキル。
  dashboard.html（約81KB）やコード.gsの変更をMonaco Editor APIとbase64チャンク分割注入で反映する。
  仕様変更でコード修正が発生した場合にその場で使うこと（別タスクにしない）。
  以下のような場面で必ずトリガーすること:
  「GASに反映して」「GASを更新して」「デプロイして」「HTMLを注入して」「FOOTAGE HANDLEを更新」
  「コードをGASに入れて」「dashboard.htmlを反映」「コード.gsを更新」「FOOTAGE HANDLE デプロイ」
  FOOTAGE HANDLEのコード変更・仕様変更が完了した直後にも自動的にトリガーすべき。
---

# GAS Auto Deploy — FOOTAGE HANDLE

FOOTAGE HANDLEのdashboard.htmlまたはコード.gsに変更があった場合、GASエディタに自動で注入・保存・デプロイする手順。

## 前提情報

| 項目 | 値 |
|------|-----|
| Google アカウント | o.yuta@footage-nursing.jp（URLは `/u/0/` を使用） |
| GAS プロジェクトURL | `https://script.google.com/u/0/home/projects/1XWcPBvLC9C3QvP4I0SyJVHKkIb83M2Lm9ChnYEuTl_dB9iw-UVPCeIdR/edit` |
| Monaco Editor モデル | コード.gs（約16KB）と dashboard.html（約81KB）の2ファイル。長さで判別（50KB超がdashboard.html） |
| Notion設計書 | `https://www.notion.so/3173cbc390eb8159a22fd9c7fc083a09` |
| Notionフルソース | `https://www.notion.so/31f3cbc390eb81f7b9d1f4d9b5de1125` |

## 運用ルール

仕様変更でコード修正が発生したら、**その場でGASに反映する**。別タスクやスケジュールにはしない。所要時間は注入〜デプロイ完了まで約3〜5分。

## 実行手順

### Step 1: 更新するコードを取得

ユーザーに確認すること:

- 更新対象ファイル: dashboard.html / コード.gs / 両方
- コードの入手方法: ローカルファイル / 会話で直接渡す / Notionから取得
- デプロイも行うか（保存のみ or 新バージョンデプロイ）

### Step 2: GASエディタを開く

1. ブラウザタブのコンテキストを取得（tabs_context_mcp）
2. GASプロジェクトURLに移動: `https://script.google.com/u/0/home/projects/1XWcPBvLC9C3QvP4I0SyJVHKkIb83M2Lm9ChnYEuTl_dB9iw-UVPCeIdR/edit`
3. 4秒待機してエディタのロードを確認
4. screenshotで表示を確認

アカウントが `/u/0/`（o.yuta@footage-nursing.jp）であることを必ず確認する。`/u/1/` は別アカウントなので間違えない。

### Step 3: 対象ファイルに切り替え

Monaco Editor APIでモデルを特定する。モデル番号はセッションごとに変わるため、ファイルサイズで判別する。

```javascript
const models = monaco.editor.getModels();
const editor = monaco.editor.getEditors()[0];
// dashboard.htmlは81KB以上（50KB超で判定）
const target = models.find(m => m.getValue().length > 50000);
// コード.gsの場合は50KB未満のモデルを使う
// const target = models.find(m => m.getValue().length < 50000 && m.getValue().length > 1000);
editor.setModel(target);
```

### Step 4: base64チャンク分割注入

81KBのHTMLは1回のJS実行では注入できないため、base64エンコード → 8000文字ずつチャンク分割 → 個別注入 → 結合デコードの手順を取る。この方式は検証済み（perfectMatch確認）。

**4a. ローカルでbase64エンコード + チャンク分割（Bash）**

```bash
python3 -c "
import base64, json
with open('path/to/dashboard.html', 'r') as f:
    html = f.read()
b64 = base64.b64encode(html.encode('utf-8')).decode('ascii')
CHUNK_SIZE = 8000
chunks = [b64[i:i+CHUNK_SIZE] for i in range(0, len(b64), CHUNK_SIZE)]
for i, chunk in enumerate(chunks):
    with open(f'/tmp/chunk_{i}.txt', 'w') as f:
        f.write(chunk)
print(json.dumps({'total': len(chunks), 'b64len': len(b64)}))
"
```

**4b. チャンク初期化（JavaScript 呼び出し #1）**

```javascript
window._htmlChunks = [];
```

**4c. 各チャンクを順番に注入（JavaScript 呼び出し #2〜#N）**

各チャンクファイルの内容を読み取り、個別のJS実行で push する。1つずつ別々の呼び出しで行うこと。

```javascript
window._htmlChunks.push('CHUNK_DATA_HERE');
'Chunk pushed. Total: ' + window._htmlChunks.length;
```

**4d. デコード & setValue（JavaScript 最終呼び出し）**

```javascript
const fullBase64 = window._htmlChunks.join('');
const decoded = new TextDecoder().decode(
  Uint8Array.from(atob(fullBase64), c => c.charCodeAt(0))
);
const models = monaco.editor.getModels();
const editor = monaco.editor.getEditors()[0];
const target = models.find(m => m.getValue().length > 50000);
editor.setModel(target);
target.setValue(decoded);
JSON.stringify({injectedLen: decoded.length, success: true});
```

### Step 5: 保存（Ctrl+S）

ブラウザ自動化で `ctrl+s` を送信。2秒待機後、screenshotで保存完了を確認。

### Step 6: デプロイ（ユーザーが希望した場合）

1. 「デプロイ」ドロップダウン▼をクリック
2. 「デプロイを管理」を選択
3. 鉛筆アイコン（編集）をクリック
4. 「新バージョン」を選択
5. 「デプロイ」ボタンをクリック

### Step 7: 検証

ページリロード後、`getValue().length` で注入前後の文字数一致を確認する。

```javascript
const models = monaco.editor.getModels();
const target = models.find(m => m.getValue().length > 50000);
JSON.stringify({length: target.getValue().length});
```

### Step 8: Notion設計書を更新

変更内容に応じて、Notion設計書（`3173cbc390eb8159a22fd9c7fc083a09`）の更新履歴に追記する。

## 注意事項

- 必ず `/u/0/` アカウントでアクセスすること（`/u/1/` は別アカウント）
- モデル番号（inmemory://model/N）はセッションごとに変わるため、常に長さで判別する
- チャンク注入は1つずつ個別のJS呼び出しで実行すること（まとめて送ると文字数制限に引っかかる）
- 検証済み: base64チャンク分割→結合→デコードの往復テスト完全一致確認 (2026-03-10)

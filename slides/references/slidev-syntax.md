# Slidev マークダウン記法リファレンス

## 基本構造

```markdown
---
theme: default
title: プレゼンタイトル
info: 説明文
drawings:
  persist: false
transition: slide-left
---

# スライド1タイトル

内容

---

# スライド2タイトル

内容
```

- `---` でスライドを区切る
- 最初の `---...---` ブロックはYAMLフロントマター（グローバル設定）
- 各スライドの先頭に `---` + YAML でスライド個別設定可能

## スライド個別設定（frontmatter）

```markdown
---
layout: center
class: text-center
transition: fade
---
```

### 主要レイアウト

| layout | 用途 |
|---|---|
| `default` | 通常スライド |
| `cover` | タイトルスライド |
| `center` | 中央寄せ |
| `two-cols` | 2カラム |
| `image-right` | 右に画像 |
| `image-left` | 左に画像 |
| `section` | セクション区切り |
| `fact` | 数字・事実の強調 |
| `quote` | 引用 |
| `end` | 最終スライド |

## 2カラムレイアウト

```markdown
---
layout: two-cols
---

# 左カラム

左側の内容

::right::

# 右カラム

右側の内容
```

## コードブロック

````markdown
```python {2|3-4|all}
def hello():
    print("line 2 をハイライト")
    print("次に line 3-4")
    print("最後に全体")
```
````

- `{2}` → 2行目をハイライト
- `{2|3-4|all}` → クリックで段階的にハイライト
- `{monaco}` → Monaco Editor（編集可能）

## クリックアニメーション

```markdown
<v-click>

この要素はクリックで表示

</v-click>

<v-clicks>

- 項目1（クリック1で表示）
- 項目2（クリック2で表示）
- 項目3（クリック3で表示）

</v-clicks>
```

## Mermaid 図

````markdown
```mermaid
graph LR
  A[入力] --> B[処理]
  B --> C[出力]
```
````

## スピーカーノート

```markdown
---

# スライドタイトル

内容

<!--
ここにスピーカーノートを書く。
プレゼンターモードでのみ表示される。
発表時のポイントや補足情報を記載。
-->
```

## アイコン（UnoCSS Icons）

```markdown
<mdi-account /> ユーザー
<mdi-chart-bar /> チャート
<mdi-rocket /> ロケット
<carbon-warning /> 警告
```

## LaTeX 数式

```markdown
インライン: $E = mc^2$

ブロック:
$$
\sum_{i=1}^{n} x_i = x_1 + x_2 + \cdots + x_n
$$
```

## グローバルスタイル

```markdown
<style>
h1 {
  color: #192864;
}
.slidev-layout {
  font-family: 'Noto Sans JP', sans-serif;
}
</style>
```

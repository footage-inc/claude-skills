#!/usr/bin/env python3
"""
WordPress REST API 入稿スクリプト
Footage公式サイト（footage-nursing.jp）への記事下書き保存用

使い方:
  python wp-publish.py <マークダウンファイルパス>

環境変数:
  WP_URL       - WordPressサイトURL（例: https://footage-nursing.jp）
  WP_USERNAME  - WordPressユーザー名
  WP_APP_PASSWORD - Application Password（スペース含むそのまま）

セットアップ:
  1. WordPress管理画面 > ユーザー > プロフィール > Application Password
  2. 新しいアプリケーションパスワード名を入力して「追加」
  3. 生成されたパスワードを WP_APP_PASSWORD に設定
  4. pip install requests python-frontmatter markdown --break-system-packages
"""

import os
import shutil
import sys
import json
import argparse
from datetime import datetime, timedelta
import requests
import frontmatter
import markdown
from pathlib import Path

# ============================================================
# 設定
# ============================================================

WP_URL = os.environ.get("WP_URL", "https://footage-nursing.jp")
WP_USERNAME = os.environ.get("WP_USERNAME", "")
WP_APP_PASSWORD = os.environ.get("WP_APP_PASSWORD", "")

# 投稿ステータス定数
STATUS_DRAFT = "draft"
STATUS_PUBLISH = "publish"
STATUS_FUTURE = "future"

# 予約投稿の公開時刻（JST）
SCHEDULE_HOUR = 8
SCHEDULE_MINUTE = 0

# テーマ → 予約投稿の曜日マッピング（0=月曜, 4=金曜）
THEME_SCHEDULE = {
    "訪問看護集客": [0, 3],      # 月曜・木曜
    "経営支援集客": [1, 4],      # 火曜・金曜
    "デイサービス集客": [2],     # 水曜
}

# テーマ → カスタム投稿タイプのマッピング
THEME_TO_POST_TYPE = {
    "訪問看護集客": "column",
    "デイサービス集客": "column",
    "採用マーケ": "column",
    "経営支援集客": "rec_column",
}

# カスタム投稿タイプ → REST APIエンドポイント
# WordPressのREST APIではカスタム投稿タイプの複数形がエンドポイントになる
# 実際のエンドポイントはWordPressの設定に依存するため、必要に応じて変更
POST_TYPE_ENDPOINTS = {
    "column": "column",          # /wp-json/wp/v2/column
    "rec_column": "rec_column",  # /wp-json/wp/v2/rec_column
}


# ============================================================
# 予約投稿スケジュール
# ============================================================

def get_next_scheduled_dates(theme: str, count: int = 1) -> list[datetime]:
    """テーマに応じた翌週の予約投稿日時を返す。

    Args:
        theme: テーマ名（例: "訪問看護集客"）
        count: 必要な日付の数

    Returns:
        翌週の予約投稿日時リスト（JST）
    """
    weekdays = THEME_SCHEDULE.get(theme)
    if not weekdays:
        raise ValueError(f"テーマ '{theme}' の予約投稿スケジュールが未定義です")

    today = datetime.now()
    # 翌週の月曜日を起点にする
    days_until_next_monday = (7 - today.weekday()) % 7
    if days_until_next_monday == 0:
        days_until_next_monday = 7  # 今日が月曜でも翌週
    next_monday = today + timedelta(days=days_until_next_monday)

    dates = []
    for wd in sorted(weekdays):
        dt = next_monday + timedelta(days=wd)
        dt = dt.replace(hour=SCHEDULE_HOUR, minute=SCHEDULE_MINUTE, second=0, microsecond=0)
        dates.append(dt)

    return dates[:count]


# ============================================================
# メイン処理
# ============================================================

def load_article(filepath: str) -> dict:
    """マークダウンファイルを読み込み、フロントマターと本文を分離"""
    post = frontmatter.load(filepath)

    # フロントマター情報
    meta = {
        "title": post.get("title", "無題"),
        "date": post.get("date", ""),
        "theme": post.get("theme", ""),
        "post_type": post.get("post_type", "column"),
        "status": post.get("status", "公開済み"),
    }

    # マークダウン → HTML変換
    html_content = markdown.markdown(
        post.content,
        extensions=["tables", "fenced_code", "nl2br", "toc"]
    )

    return {
        "meta": meta,
        "content_md": post.content,
        "content_html": html_content,
    }


def publish_to_wordpress(
    article: dict,
    status: str = STATUS_DRAFT,
    scheduled_date: datetime | None = None,
) -> dict:
    """WordPress REST APIで記事を保存（下書き・公開・予約投稿）"""

    if not WP_USERNAME or not WP_APP_PASSWORD:
        raise ValueError(
            "環境変数 WP_USERNAME と WP_APP_PASSWORD を設定してください。\n"
            "詳しくは: WordPress管理画面 > ユーザー > プロフィール > Application Password"
        )

    meta = article["meta"]
    post_type = meta.get("post_type", "column")
    endpoint = POST_TYPE_ENDPOINTS.get(post_type, post_type)

    api_url = f"{WP_URL}/wp-json/wp/v2/{endpoint}"

    # リクエストボディ
    payload = {
        "title": meta["title"],
        "content": article["content_html"],
        "status": status,
    }

    # 予約投稿の場合: status=future + date指定
    if status == STATUS_FUTURE and scheduled_date:
        payload["date"] = scheduled_date.strftime("%Y-%m-%dT%H:%M:%S")
    elif meta.get("date"):
        payload["date"] = meta["date"] + "T00:00:00"

    # API呼び出し
    response = requests.post(
        api_url,
        json=payload,
        auth=(WP_USERNAME, WP_APP_PASSWORD),
        headers={"Content-Type": "application/json"},
        timeout=30,
    )

    if response.status_code in (200, 201):
        result = response.json()
        return {
            "success": True,
            "id": result.get("id"),
            "link": result.get("link"),
            "edit_link": f"{WP_URL}/wp-admin/post.php?post={result.get('id')}&action=edit",
            "status": result.get("status"),
            "scheduled_date": scheduled_date.strftime("%Y-%m-%d %H:%M") if scheduled_date else None,
        }
    else:
        return {
            "success": False,
            "status_code": response.status_code,
            "error": response.text[:500],
        }


def save_to_knowledge_base(filepath: str, article: dict, kb_dir: str = None):
    """記事をナレッジベースに保存（knowledge-base/テーマ名/ にコピー）"""
    if not kb_dir:
        # article-skills/knowledge-base/{テーマ}/ を推定
        script_dir = Path(__file__).parent.parent
        theme = article["meta"].get("theme", "")
        if not theme:
            print("⚠ テーマが未設定のためナレッジベースへの保存をスキップ")
            return
        kb_dir = script_dir / "knowledge-base" / theme

    kb_path = Path(kb_dir)
    kb_path.mkdir(parents=True, exist_ok=True)

    # ファイル名はそのまま使用
    dest = kb_path / Path(filepath).name

    shutil.copy2(filepath, dest)
    print(f"✅ ナレッジベースに保存: {dest}")


def _get_json(url: str, auth=None, timeout: int = 10) -> tuple[int, dict | None]:
    """GETリクエストを実行し、(status_code, json_body | None) を返す"""
    try:
        response = requests.get(url, auth=auth, timeout=timeout)
        try:
            body = response.json()
        except Exception:
            body = None
        return response.status_code, body
    except Exception as e:
        return -1, {"_error": str(e)}


def check_api_connection() -> bool:
    """WordPress REST APIへの接続確認"""
    status_code, body = _get_json(f"{WP_URL}/wp-json/")
    if status_code == 200 and body:
        print(f"✅ サイト接続OK: {body.get('name', 'Unknown')}")
        return True
    elif status_code == -1:
        print(f"❌ 接続失敗: {body.get('_error', '')}")
        return False
    else:
        print(f"❌ サイト接続エラー: HTTP {status_code}")
        return False


def check_auth() -> bool:
    """認証情報の確認"""
    if not WP_USERNAME or not WP_APP_PASSWORD:
        print("❌ 認証情報が未設定です")
        print("  export WP_USERNAME='your_username'")
        print("  export WP_APP_PASSWORD='xxxx xxxx xxxx xxxx xxxx xxxx'")
        return False

    status_code, body = _get_json(
        f"{WP_URL}/wp-json/wp/v2/users/me",
        auth=(WP_USERNAME, WP_APP_PASSWORD),
    )
    if status_code == 200 and body:
        print(f"✅ 認証OK: {body.get('name', 'Unknown')} ({body.get('slug', '')})")
        return True
    elif status_code == -1:
        print(f"❌ 認証確認失敗: {body.get('_error', '')}")
        return False
    else:
        print(f"❌ 認証エラー: HTTP {status_code}")
        return False


def run_connection_test() -> None:
    """API接続と認証情報の確認をまとめて実行"""
    print("=== WordPress 接続テスト ===")
    api_ok = check_api_connection()
    auth_ok = check_auth()
    if api_ok and auth_ok:
        print("\n✅ すべてのチェックが通過しました")
    else:
        print("\n❌ チェックに失敗した項目があります")
        sys.exit(1)


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description="Footage WordPress 入稿スクリプト",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用例:
  # 接続テスト
  python wp-publish.py --test

  # 記事を下書き保存
  python wp-publish.py article.md

  # 記事を下書き保存 + ナレッジベースにも追加
  python wp-publish.py article.md --save-kb

  # 記事を公開（注意: 即公開されます）
  python wp-publish.py article.md --publish

  # 記事を翌週の指定曜日に予約投稿（テーマから自動判定）
  python wp-publish.py article.md --schedule

  # 記事を指定日時に予約投稿
  python wp-publish.py article.md --schedule --schedule-date "2026-03-16T08:00:00"
        """
    )

    parser.add_argument("file", nargs="?", help="入稿するマークダウンファイルのパス")
    parser.add_argument("--test", action="store_true", help="API接続テストのみ実行")
    parser.add_argument("--publish", action="store_true", help="下書きではなく公開する")
    parser.add_argument("--schedule", action="store_true", help="翌週の指定曜日に予約投稿する")
    parser.add_argument("--schedule-date", type=str, help="予約投稿日時を直接指定（例: 2026-03-16T08:00:00）")
    parser.add_argument("--schedule-slot", type=int, default=1, choices=[1, 2], help="投稿枠の番号（1=最初の曜日, 2=2番目の曜日）")
    parser.add_argument("--save-kb", action="store_true", help="ナレッジベースにも保存")
    parser.add_argument("--dry-run", action="store_true", help="実行せずに内容を確認")

    args = parser.parse_args()

    # 接続テスト
    if args.test:
        run_test()
        return

    # ファイル指定必須
    if not args.file:
        parser.print_help()
        sys.exit(1)

    filepath = args.file
    if not os.path.exists(filepath):
        print(f"❌ ファイルが見つかりません: {filepath}")
        sys.exit(1)

    # 記事読み込み
    print(f"📄 読み込み: {filepath}")
    article = load_article(filepath)
    meta = article["meta"]

    print(f"  タイトル: {meta['title']}")
    print(f"  テーマ: {meta['theme']}")
    print(f"  投稿タイプ: {meta['post_type']}")
    print(f"  日付: {meta['date']}")
    print(f"  本文長: {len(article['content_html'])} 文字 (HTML)")
    print()

    # ドライラン
    if args.dry_run:
        print("🔍 ドライラン: 入稿は実行しません")
        print("-" * 40)
        print(article["content_html"][:500] + "...")
        return

    # 投稿モード判定
    scheduled_date = None
    if args.schedule or args.schedule_date:
        status = STATUS_FUTURE
        status_label = "予約投稿"

        if args.schedule_date:
            # 直接日時指定
            scheduled_date = datetime.fromisoformat(args.schedule_date)
        else:
            # テーマから自動算出
            theme = meta.get("theme", "")
            if not theme:
                print("❌ テーマが未設定のため予約投稿日を自動判定できません")
                print("  フロントマターに theme を設定するか --schedule-date で直接指定してください")
                sys.exit(1)
            dates = get_next_scheduled_dates(theme, count=2)
            slot_index = min(args.schedule_slot - 1, len(dates) - 1)
            scheduled_date = dates[slot_index]

        print(f"📅 予約投稿日時: {scheduled_date.strftime('%Y-%m-%d (%a) %H:%M')} JST")
    elif args.publish:
        status = STATUS_PUBLISH
        status_label = "公開"
    else:
        status = STATUS_DRAFT
        status_label = "下書き"

    print(f"📤 WordPress に{status_label}保存中...")

    result = publish_to_wordpress(article, status=status, scheduled_date=scheduled_date)

    if result["success"]:
        print(f"✅ {status_label}保存完了!")
        print(f"  記事ID: {result['id']}")
        print(f"  URL: {result['link']}")
        print(f"  編集: {result['edit_link']}")
        if result.get("scheduled_date"):
            print(f"  予約日時: {result['scheduled_date']}")
    else:
        print(f"❌ 入稿エラー: HTTP {result['status_code']}")
        print(f"  {result['error']}")
        sys.exit(1)

    # ナレッジベース保存
    if args.save_kb:
        print()
        save_to_knowledge_base(filepath, article)

    print()
    print("完了!")


if __name__ == "__main__":
    main()

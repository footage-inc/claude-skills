#!/usr/bin/env python3
"""KB整合性チェッカー: manifest.json vs 実ファイル の差分を検出する。

Usage:
    python3 article-skills/tools/kb_lint.py          # チェックのみ
    python3 article-skills/tools/kb_lint.py --fix     # 孤立ファイルを_archiveに移動
"""

import json
import os
import shutil
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
KB_BASE = os.path.join(SCRIPT_DIR, "..", "knowledge-base")
MANIFEST = os.path.join(KB_BASE, "manifest.json")
ARCHIVE = os.path.join(KB_BASE, "_archive")
SKIP_DIRS = {"guidelines", "_archive"}


def load_manifest():
    with open(MANIFEST) as f:
        data = json.load(f)
    return set(data.get("articles", {}).keys())


def scan_active_files():
    """KB active領域の全.mdファイルを返す {filename: full_path}"""
    files = {}
    for dirpath, dirnames, filenames in os.walk(KB_BASE):
        # Skip excluded dirs
        rel = os.path.relpath(dirpath, KB_BASE)
        if any(skip in rel.split(os.sep) for skip in SKIP_DIRS):
            continue
        for f in filenames:
            if f.endswith(".md"):
                files[f] = os.path.join(dirpath, f)
    return files


def main():
    fix_mode = "--fix" in sys.argv

    if not os.path.exists(MANIFEST):
        print("ERROR: manifest.json が見つかりません")
        print(f"  期待パス: {MANIFEST}")
        sys.exit(1)

    manifest_files = load_manifest()
    active_files = scan_active_files()

    # 1. manifest にあるが Git にない（欠損）
    missing = manifest_files - set(active_files.keys())
    # 2. Git にあるが manifest にない（孤立 = archive候補）
    orphans = set(active_files.keys()) - manifest_files

    # Report
    print(f"manifest.json: {len(manifest_files)} 件")
    print(f"KB active:     {len(active_files)} 件")
    print()

    ok = True

    if missing:
        ok = False
        print(f"⚠ Git欠損 ({len(missing)}件) — manifestにあるがKBにないファイル:")
        for f in sorted(missing):
            print(f"  - {f}")
        print()

    if orphans:
        ok = False
        print(f"⚠ 孤立ファイル ({len(orphans)}件) — KBにあるがmanifestにないファイル:")
        for f in sorted(orphans):
            print(f"  - {f}")

        if fix_mode:
            print(f"\n--fix: 孤立ファイルを _archive/ に移動します...")
            os.makedirs(ARCHIVE, exist_ok=True)
            for f in sorted(orphans):
                src = active_files[f]
                rel_dir = os.path.relpath(os.path.dirname(src), KB_BASE)
                dst_dir = os.path.join(ARCHIVE, rel_dir)
                os.makedirs(dst_dir, exist_ok=True)
                shutil.move(src, os.path.join(dst_dir, f))
                print(f"  移動: {f} → _archive/{rel_dir}/")
        print()

    if ok:
        print("✓ KB整合性OK — manifest.json と Git KB が一致しています")

    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()

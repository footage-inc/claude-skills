<?php
/**
 * REST API 有効化スニペット
 *
 * 【設置方法】以下のいずれかの方法で設置してください：
 *   方法A: wp-content/mu-plugins/ ディレクトリにこのファイルをアップロード（推奨）
 *   方法B: テーマの functions.php に以下のコードを追記
 *
 * 【機能】
 *   1. カスタム投稿タイプ column / rec_column を REST API で公開
 *   2. Basic認証（Application Password）を有効化
 */

// ============================================================
// 1. カスタム投稿タイプを REST API に公開
// ============================================================
add_filter('register_post_type_args', function ($args, $post_type) {
    $rest_enabled_types = [
        'column'     => 'column',      // コラム
        'rec_column' => 'rec_column',   // 経営支援コラム
    ];

    if (isset($rest_enabled_types[$post_type])) {
        $args['show_in_rest'] = true;
        $args['rest_base']    = $rest_enabled_types[$post_type];
    }

    return $args;
}, 10, 2);

// ============================================================
// 2. Basic認証の Authorization ヘッダーを通す（Apache環境用）
//    ※ Nginx環境では nginx.conf 側で設定が必要
// ============================================================
add_action('init', function () {
    // Apache が Authorization ヘッダーを除去する問題への対処
    if (!isset($_SERVER['PHP_AUTH_USER']) && isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $auth = $_SERVER['HTTP_AUTHORIZATION'];
        if (stripos($auth, 'Basic ') === 0) {
            $decoded = base64_decode(substr($auth, 6));
            if ($decoded) {
                list($user, $pass) = explode(':', $decoded, 2);
                $_SERVER['PHP_AUTH_USER'] = $user;
                $_SERVER['PHP_AUTH_PW']   = $pass;
            }
        }
    }

    // REDIRECT_HTTP_AUTHORIZATION 経由のフォールバック
    if (!isset($_SERVER['PHP_AUTH_USER']) && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $auth = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        if (stripos($auth, 'Basic ') === 0) {
            $decoded = base64_decode(substr($auth, 6));
            if ($decoded) {
                list($user, $pass) = explode(':', $decoded, 2);
                $_SERVER['PHP_AUTH_USER'] = $user;
                $_SERVER['PHP_AUTH_PW']   = $pass;
            }
        }
    }
});

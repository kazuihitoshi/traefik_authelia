# Traefik + Authelia 2FA Docker Stack

Traefikをリバースプロキシとして使い、任意のDockerコンテナに対してホスト名単位の強力な認証(二要素認証対応)を追加するためのテンプレートです。

## 🌟 特徴
* **簡単セットアップ**: 秘密鍵（JWT_SECRET等）を初回起動時に自動生成
* **二要素認証 (2FA)**: AutheliaによるTOTP認証を標準サポート
* **SSL対応**: TraefikによるLet's Encrypt自動更新
* **柔軟な認証**: `users_database.yml` によるファイルベースのユーザー管理

## セットアップ方法

- .envへドメインなどの設定を行ってください

  .envは、env.templateをコピーして作成してください。

  ```
  AUTHELIA_ISSUER=Authelia
  ACME_EMAIL=xxxxx@xxxx.com
  TIMEZONE=Asia/Tokyo
  DOMAIN=xxxxx.com
  AUTH_DOMAIN=auth.$DOMAIN
  DASHBOARD_DOMAIN=dashboard.$DOMAIN
  ```
- authelia/configuration.ymlへメールサーバの設定を行ってください。

  authelia/configuration.ymlは、authelia/configuration.template.ymlをコピーして作成してください。

  以下はgoogleのメールサーバを使用する場合の設定です。

  ```
  notifier:
    smtp:
      address: 'submission://smtp.gmail.com:587'
      timeout: 5s
      username: "xxxxxxxxxxxxxxxxxxxxx@gmail.com"  # google mail address
      password: "xxxxxxxxxxxxxxxxxxxxxxx"  # 発行した16桁のアプリパスワード（スペースは詰めてもOK)
      sender: ""
      identifier: "localhost"
  ```

## autheliaユーザ登録方法

autheliaへのユーザ登録は、以下ファイルに対してユーザ情報を追加してください。

authelia/users_database.yml

authelia/users_database.ymlは authelia/users_database.template.ymlをコピーして作成してください。

パスワードのハッシュは次のコマンドにて生成できます。生成後に users_database.ymlのパスワード部分に転記してください。

docker compose exec -T authelia authelia crypto hash generate argon2 --password "hogehoge" | awk '{print $NF}'

## 関連資料

https://doc.traefik.io/traefik/

https://www.authelia.com/configuration/second-factor/duo/



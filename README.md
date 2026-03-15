# Docker 認証コンテナ

## 内容

traefikとautheliaにてホスト名単位の認証付きコンテナを構築できるものです。

autheliaは二要素認証もサポートされていますので、Dockerコンテナ単位に認証させたい方には役に立つものと考えます。

## セットアップ方法

.env に各種事項を設定してください

.envは、env.templateをコピーして作成してください。

```
AUTHELIA_ISSUER=Authelia
ACME_EMAIL=xxxxx@xxxx.com
TIMEZONE=Asia/Tokyo
DOMAIN=xxxxx.com
AUTH_DOMAIN=auth.$DOMAIN
DASHBOARD_DOMAIN=dashboard.$DOMAIN
```

## autheliaユーザ登録方法

autheliaへのユーザ登録は、以下ファイルに対してユーザ情報を追加してください。

authelia/users_database.yml

パスワードのハッシュは次のコマンドにて生成できます。生成後に users_database.ymlのパスワード部分に転記してください。

docker compose exec -T authelia authelia crypto hash generate argon2 --password "hogehoge" | awk '{print $NF}'

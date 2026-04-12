# Traefik + Authelia 2FA Docker Stack

Traefikをリバースプロキシとして使い、任意のDockerコンテナに対してホスト名単位の強力な認証(二要素認証対応)を追加するためのテンプレートです。

## 🌟 特徴
* **簡単セットアップ**: 秘密鍵（JWT_SECRET等）を初回起動時に自動生成
* **二要素認証 (2FA)**: AutheliaによるTOTP認証を標準サポート
* **SSL対応**: TraefikによるLet's Encrypt自動更新
* **柔軟な認証**: `users_database.yml` によるファイルベースのユーザー管理
* **Cloudflare経由での接続**: Cloudflareのトンネル経由でのコンテナ接続

## セットアップ方法 従来型ポート開放による公開

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
## cloudflare経由で接続する方法

- docker-compose.override_cloudflare_tunnel.ymlの有効化
  docker-compose.override_cloudflare_tunnel.ymlにcloudflareトンネルベースでの接続設定を行っています。
  
  次のコマンドでdocker-compose.override.yml へコピーして利用されるようにしてください。

  ```bash
  cp -p docker-compose.override_cloudflare_tunnel.yml docker-compose.override.yml
  ```
- cloudflareにログインし、Domain registrations にて使用するドメイン名を設定する

![Domain registrations](img/image.png)

- Zero Trust ⇒ Networks ⇒ Connectorsをクリック 

![Zero Trust](img/image-1.png)

![Connectors](img/image-2.png)

- Create a tunnel ⇒ Select Cloudflared 任意のトンネル名を入力して Save tunnel

![create tunnel](img/image-3.png)

- Docker を選択 ⇒ docker ... のコマンド右のコピーアイコンをクリック

![docker command](img/image-6.png)

コマンドは次のようになっています。--token の隣 ey～最後までがトークンです。

```
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx9
```

トークンの値を、.envのCLOUDFLAR_TUNNEL_TOKENに指定してください。

```
CLOUDFLAR_TUNNEL_TOKEN=eyJhIjoiNzA1ZmNmMTJjODMyMmExNmY3YWU2MGY4MzRlYWIyZDAiLCeyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx9
```

- Next ⇒ サブドメイン * ドメイン選択 HTTP traefik:80 を入力 Complete setup

![Hostname Domain](img/image-4.png)

![Type URL](img/image-5.png)

- docker compose でコンテナ起動

```bash
docker compose up -d
```

- ssh接続を追加する方法
  - Zero Trust -> Networks -> Connectors -> 以前作成したtunnelを選択 -> Published application routers タブをクリック

  - **Subdomain:** `ssh` **Domain:** `ドメインを選択` **Path:** `初期値のまま` **Sevice Type:** `SSH` **URL:** `host.docker.internal:22` を入力して Save

  - Published application routesの表示順について、ssh.ドメイン名の行を *.ドメイン名より上の行に移動してください。これをやらないと、接続エラーが出ます。

  - Zero Trust -> Access controls -> Applications -> Add an application -> Self-hosted -> **Application name** `SSH-open` **Session Duration** `24 hours` Add Public hostname **Input method:** `Default` **Subdomain:** `ssh` **Domain:** `ドメインを選択` **Path:** `初期値のまま` Access policies create new policy をクリック

  - policyの設定がブラウザの新しいタブで表示される。 **Policy name:** `Allow-me` **Action:** Allow **Session duration:** `15 miniutes` **Add rules>Selector:** `Emails` `認証コードが送られてくるメールアドレスを記入` Save

  - 以前のタブに移動して、**select existing policies** `Allow-me` Save Application

- sshクライアント側の設定
  sshクライアント側に、cloudflaredのインストールが必要です。(トンネル通信用) 

  以下より、任意のモジュールをダウンロードしてインストールしてください。
  https://github.com/cloudflare/cloudflared/releases

  .ssh\config
  ```
  Host ssh.ドメイン名
    HostName ssh.ドメイン名
    IdentityFile "秘密鍵"
    User ユーザ名
    ProxyCommand "C:\Program Files (x86)\cloudflared\cloudflared.exe" access ssh --hostname %h
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

## 別フォルダのコンテナを参加させる場合

- 別コンテナで使用可能なネットワークの作成

  ```bash
  docker network create traefik-public
  ```
- 使用ネットワークの変更

　次のファイルを作成し、使用ネットワークを外部化します。

  docker-compose.override.yml
  ```yml
  networks:
    traefik-public:
      external: true
  ```
- dokcerコンテナの再作成

  ```bash
  docker compose down && docker compose up -d
  ```
## 秘密鍵の作り方
  以下の方法で、生成される secretkey が秘密鍵  secretkey.pub が公開鍵です。
  ```bash
  ssh-keygen -t ed25519 -f secretkey
  ```
  秘密鍵の再生用パスフレーズを聞かれます。安全性確保のために、入力をお勧めします。
  ```
  Generating public/private ed25519 key pair.
  Enter passphrase (empty for no passphrase):
  ```
  ログイン先のサーバ側に、公開鍵をコピーし、次の設定を行ってください。

  ログインユーザ(rootではない)でログインして設定してください。

  ```bash
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  cat secretkey.pub >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  ```
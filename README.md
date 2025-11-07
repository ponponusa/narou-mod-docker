# narou-mod-docker

このリポジトリは、[narou-mod](https://github.com/narou-mod/narou-mod) を Docker コンテナ上で動作させるための`Dockerfile` および関連ファイルを提供しています。

> ponponusa が運用している家庭用NAS（Synology DS415+)では、compose が利用できないので、単一の `Dockerfile` を使ってイメージをビルドし、コンテナを起動する方法を採用しています。

## 動作要件

- `narou-mod` のバージョン `2.0.3-646d9ad` 以上
- Docker がインストールされている環境
  - Windows 11 (PowerShell) + WSL2 が動作する環境
  - ~~Linux (Ubuntu 20.04 以上推奨)~~ 対応予定
  - ~~macOS (Ventura 13.0 以上推奨)~~ 対応予定

## Docker内のソフトウェア構成

- [Ruby:3.4.7-slim-bookworm](https://hub.docker.com/_/ruby)
- [Azlu Zulu JDK 21](https://www.azul.com/downloads/?package=jdk#zulu)
- [narou-mod](https://github.com/ponponusa/narou-mod)
- [改造版AozoraEpub3](https://github.com/kyukyunyorituryo/AozoraEpub3)
- [kindlegen](https://archive.org/details/kindlegen2.9)


## Windows 11 上での利用手順

Windows 11 の PowerShell 上でこの `Dockerfile` を使ってイメージをビルドし、コンテナを起動する手順は、以下のようになります。

**前提条件:**

  * [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) がインストールされており、WSL 2 バックエンドで実行されていること（※ホストがWindowsの場合）
  * このリポジトリのファイル一式がPC上のどこか（例: `C:\docker\narou-mod-docker`）に保存されていること
  * ホスト側で、小説データを保存・共有するためのフォルダ（例: `C:\my-novels`, `/home/narou/novel`）を準備していること

-----

## ＞ `run.ps1` スクリプトを使ってビルド・起動する場合

### ステップ1: PowerShell で Dockerfile の場所に移動

まず、PowerShell を起動し、`Dockerfile` を保存したフォルダに `cd` コマンドで移動します。

```powershell
# 例: C:\docker\narou フォルダに Dockerfile がある場合
cd C:\docker\narou
```

### ステップ2: 設定を行う（optional setting）

`Dockerfile` のビルド時に使用する環境変数を `.env` ファイルで設定します。

必要に応じて、`.env` ファイルの内容を編集してください。

```env
# 例: .env ファイルの内容
HOST_NOVEL_PATH="C:\my-novels"
HOST_P1=33000
HOST_P2=33001
```

### ステップ3: `run.ps1` スクリプトを実行してビルド・起動

```powershell
# 例: run.ps1 スクリプトを実行
.\run.ps1
```

-----

## ＞ 自分で`docker build` と `docker run` を実行する場合

### ステップ1: PowerShell で Dockerfile の場所に移動

まず、PowerShell を起動し、`Dockerfile` を保存したフォルダに `cd` コマンドで移動します。

```powershell
# 例: C:\docker\narou フォルダに Dockerfile がある場合
cd C:\docker\narou
```

### ステップ2: イメージのビルド (docker build)

次に、`docker build` コマンドを実行してイメージを作成します。

ビルドが完了すると、`narou-mod-app` という名前のローカルイメージが作成されます。

### ステップ3: コンテナの起動 (docker run)

最後に、`docker run` コマンドでビルドしたイメージをコンテナとして起動します。

**重要なポイント:**

1.  **ポート (`-p`):** `.env` で定義した `HOST_P1 (33000)` と `HOST_P2 (33001)` をホストPCにマッピングします
2.  **ボリューム (`-v`):** ステップ2で指定したホスト側のパス（`C:\my-novels`）を、コンテナ内の `/app/novel` に接続（バインド）します
3.  **環境変数 (`-e`):** ビルド時に引数で環境変数を渡した場合は、実行時にも環境変数として渡す必要があります

<!-- end list -->

```powershell
# PowerShell で改行する場合は、行末に ` (バッククォート) を入力する

docker run -d --name narou-mod-app `
  -p 33000:33000 `
  -p 33001:33001 `
  -v "C:\my-novels:/app/novel" `
  -e HOST_NOVEL_PATH="C:\my-novels" `
  narou-mod-app
```

**コマンドの解説:**

  * `docker run`: コンテナを起動
  * `-d`: バックグラウンドで実行（デタッチモード）
  * `--name narou-mod-app`: コンテナに `narou-mod-app` などの分かりやすい名前を付ける
  * `-p 33000:33000`: ホスト（Windows）の 33000番ポートを、コンテナの `P1` (33000番) に接続
  * `-p 33001:33001`: ホスト（Windows）の 33001番ポートを、コンテナの `P2` (33001番) に接続
  * `-v "C:\my-novels:/app/novel"`: ホストの `C:\my-novels` フォルダを、コンテナの `/app/novel` フォルダにマッピング
  * `-e HOST_NOVEL_PATH="C:\my-novels"`: コンテナ内の `HOST_NOVEL_PATH` 環境変数に、ホストのパスを設定
  * `narou-mod-app`: 起動するイメージの名前

-----

### 起動の確認

コンテナが起動したら、`docker ps` コマンドで実行状態を確認できます。

```powershell
docker ps
```

`STATUS` が `Up ...` となっていれば成功です。
ブラウザで `http://localhost:33000` （既定のポートの場合）にアクセスすると、`narou-mod` のWebサーバーが表示されるはずです。

### （参考）コンテナを停止・削除する場合

```powershell
# 停止 (名前指定)
docker stop narou-mod-app

# 削除 (名前指定)
docker rm narou-mod-app
```

## License

- 本ソフトウェアを利用（入手、インストール、実行等）した時点で、[利用規約・免責事項](https://github.com/ponponusa/narou-mod-docker/blob/develop/TERMS_AND_DISCLAIMER.md)に同意したものとみなします。ご利用の前に必ず内容をご確認ください。
- This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

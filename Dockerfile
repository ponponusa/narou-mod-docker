#------------------------------------------------------------------------------------#
#
# builder
# - i386版のkindlegenを使うため、bookwormベースのイメージを使用
#
#------------------------------------------------------------------------------------#
FROM ruby:3.4.7-bookworm AS builder

# Set environment variables for non-interactive commands.
# This prevents certain prompts from interrupting the build.
ENV DEBIAN_FRONTEND=noninteractive

# ビルド用環境変数の設定
ARG NAROU_MOD_VERSION="latest"
ARG NAROU_MOD_GEM_LOCAL_FILE="dummy"
ARG AOZORAEPUB3_VERSION="latest"
ARG AOZORAEPUB3_ZIP_LOCAL_FILE="dummy"
ARG KINDLEGEN_URL="https://archive.org/download/kindlegen2.9/"
ARG KINDLEGEN_FILE="kindlegen_linux_2.6_i386_v2_9.tar.gz"
ARG KINDLEGEN_TAR_LOCAL_FILE="dummy"

ENV NAROU_MOD_VERSION=$NAROU_MOD_VERSION
ENV NAROU_MOD_GEM_LOCAL_FILE=$NAROU_MOD_GEM_LOCAL_FILE
ENV AOZORAEPUB3_VERSION=$AOZORAEPUB3_VERSION
ENV AOZORAEPUB3_ZIP_LOCAL_FILE=$AOZORAEPUB3_ZIP_LOCAL_FILE
ENV KINDLEGEN_URL=$KINDLEGEN_URL
ENV KINDLEGEN_FILE=$KINDLEGEN_FILE
ENV KINDLEGEN_TAR_LOCAL_FILE=$KINDLEGEN_TAR_LOCAL_FILE

# ビルドに必要なパッケージ (Cコンパイラ, ダウンロードツール)
# build-base: gem の C拡張コンパイル (nio4r など) に必要
RUN set -eux; \
    # パッケージリストを更新
    apt-get update; \
    # extrepo をインストールして zulu-openjdk リポジトリを有効化
    apt-get install -y extrepo; \
    extrepo enable zulu-openjdk; \
    # パッケージリストを更新
    apt-get update; \
    # ビルドに必要なツールをインストール
    # - build-essential: gemコンパイル用, ca-certificates: curl/https用
    # - OpenJDK 21 を zulu からインストール（JRE確保用）
    apt-get install -y --no-install-recommends \
            build-essential \
            curl \
            unzip \
            ca-certificates \
            zulu21-jre; \
    # キャッシュをクリーンアップ
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# narou-mod のインストール
# - gem のインストール先をコンテナ内の /usr/local/bundle に統一する
# - インストールスクリプトをコピーして実行
ENV BUNDLE_PATH="/usr/local/bundle"
ENV PATH=$BUNDLE_PATH/bin:$PATH
COPY $NAROU_MOD_GEM_LOCAL_FILE /tmp/narou-mod.gem
COPY build/scripts/install_narou_mod.sh /tmp/install_narou_mod.sh
RUN chmod +x /tmp/install_narou_mod.sh
RUN /tmp/install_narou_mod.sh

# AozoraEpub3 のインストール
# - インストールスクリプトをコピーして実行
COPY $AOZORAEPUB3_ZIP_LOCAL_FILE /tmp/AozoraEpub3.zip
COPY build/scripts/install_aozora_epub3.sh /tmp/install_aozora_epub3.sh
RUN chmod +x /tmp/install_aozora_epub3.sh
RUN /tmp/install_aozora_epub3.sh

# kindlegen のインストール
# - インストールスクリプトをコピーして実行
COPY $KINDLEGEN_TAR_LOCAL_FILE /tmp/${KINDLEGEN_FILE}
COPY build/scripts/install_kindlegen.sh /tmp/install_kindlegen.sh
RUN chmod +x /tmp/install_kindlegen.sh 
RUN /tmp/install_kindlegen.sh

#------------------------------------------------------------------------------------#
#
# stage-1
# - 最終的に実行されるイメージ。ビルダーから成果物をコピーする
#
#------------------------------------------------------------------------------------#
FROM ruby:3.4.7-slim-bookworm

# 実行時に必要なパッケージのインストール
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        tzdata; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# narou-mod をコピー
ENV BUNDLE_PATH="/usr/local/bundle"
ENV PATH=$BUNDLE_PATH/bin:$PATH
COPY --from=builder $BUNDLE_PATH $BUNDLE_PATH

# AozoraEpub3 をコピー
COPY --from=builder /opt/AozoraEpub3 /opt/AozoraEpub3

# JRE の実体ファイル をコピー
# - Debian の Zulu JRE パスは /usr/lib/jvm/zulu21-ca-amd64
COPY --from=builder /usr/lib/jvm/zulu21-ca-amd64 /usr/lib/jvm/zulu21-ca-amd64
ENV JAVA_HOME=/usr/lib/jvm/zulu21-ca-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# libjpeg をコピー
COPY --from=builder /lib/x86_64-linux-gnu/libjpeg* /lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libjpeg* /usr/lib/x86_64-linux-gnu/

# 環境変数
ENV TZ=Asia/Tokyo
ENV HOME=/home/narou
ENV HOST_NOVEL_PATH=""
ENV P1=33000
ENV P2=33001
ENV UID=1000
ENV GID=1000

# narou ユーザーの作成
RUN groupmod -g $GID -o narou || groupadd -g $GID narou
RUN useradd -u $UID -o -m -g $GID -d $HOME narou

# 必要なパーミッションを付与
RUN chown -R narou:narou $HOME && \
    chown -R narou:narou /opt/AozoraEpub3

# 起動スクリプトのコピー
COPY cmd/narou-mod-start.sh $HOME/narou-mod-start.sh
RUN chmod +x $HOME/narou-mod-start.sh && \
    chown narou:narou $HOME/narou-mod-start.sh && \
    # Windows の改行コード (CRLF) を Linux (LF) に変換 (念のため)
    sed -i 's/\r$//' $HOME/narou-mod-start.sh

# ユーザー切り替え
USER narou
WORKDIR $HOME
VOLUME $HOME/novel

# ポートの公開
EXPOSE $P1
EXPOSE $P2

# コンテナの起動
CMD ["./narou-mod-start.sh"]
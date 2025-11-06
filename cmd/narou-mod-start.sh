#!/bin/sh

#
# コンテナ内で narou-mod を起動するスクリプト
#
# Copyright (c) 2025 ponponusa
#

set -e


echo "Starting narou-mod initialization..."
mkdir -p novel
cd novel
narou-mod version
narou-mod init --output-mode silent -p /opt/AozoraEpub3 -l 1.8

# server-ws-add-accepted-domains の現在の設定を取得
current_domains=$(narou-mod setting server-ws-add-accepted-domains)
echo "Current accepted domains: $current_domains"

# localhost が含まれていない場合、追加する
if ! echo "$current_domains" | grep -q "localhost"; then
    if [ -n "$current_domains" ]; then
        new_domains="${current_domains},localhost"
    else
        new_domains="localhost"
    fi
    echo "Adding localhost to accepted domains: $new_domains"
    narou-mod setting server-ws-add-accepted-domains="$new_domains"
else
    echo "localhost is already in accepted domains"
fi

echo "Starting main web server on port $P1..."
# 最後のコマンドのみ exec にする
exec narou-mod web -np $P1
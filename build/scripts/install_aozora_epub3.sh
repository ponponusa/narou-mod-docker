#!/bin/sh

set -eux;

if [ -n "$AOZORAEPUB3_ZIP_LOCAL_FILE" ] && [ -f "$AOZORAEPUB3_ZIP_LOCAL_FILE" ] && [ -s "$AOZORAEPUB3_ZIP_LOCAL_FILE" ]; then
    echo "Copying AozoraEpub3 zip from local file: $AOZORAEPUB3_ZIP_LOCAL_FILE";
elif [ "$AOZORAEPUB3_VERSION" = "latest" ]; then
    echo "Downloading AozoraEpub3 latest release...";
    ZIP_URL=$(curl -s https://api.github.com/repos/kyukyunyorituryo/AozoraEpub3/releases/latest | \
                grep "browser_download_url" | \
                grep "AozoraEpub3" | \
                grep "\.zip\"$" | \
                sed -E 's/.*"browser_download_url": "(.*)".*/\1/' | \
                head -n 1);
    if [ -z "$ZIP_URL" ]; then
        echo "Error: Could not find AozoraEpub3 .zip download URL." >&2;
        exit 1;
    fi;
    echo "Downloading AozoraEpub3 from: $ZIP_URL";
    curl -L -o AozoraEpub3.zip "$ZIP_URL";
else
    echo "Downloading AozoraEpub3 version $AOZORAEPUB3_VERSION...";
    ZIP_URL=$(curl -s https://api.github.com/repos/kyukyunyorituryo/AozoraEpub3/releases/tags/$AOZORAEPUB3_VERSION | \
                grep "browser_download_url" | \
                grep "AozoraEpub3" | \
                grep "\.zip\"$" | \
                sed -E 's/.*"browser_download_url": "(.*)".*/\1/' | \
                head -n 1);
    if [ -z "$ZIP_URL" ]; then
        echo "Error: Could not find AozoraEpub3 .zip download URL for version $AOZORAEPUB3_VERSION." >&2;
        exit 1;
    fi;
    echo "Downloading AozoraEpub3 from: $ZIP_URL";
    curl -L -o AozoraEpub3.zip "$ZIP_URL";
fi;
# 展開先を /opt/AozoraEpub3 に指定
mkdir -p /opt/AozoraEpub3;
unzip AozoraEpub3.zip -d /opt/AozoraEpub3;
rm AozoraEpub3.zip

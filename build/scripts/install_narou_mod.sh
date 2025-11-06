#!/bin/sh

set -eux;

if [ -n "$NAROU_MOD_GEM_LOCAL_FILE" ] && [ -f "$NAROU_MOD_GEM_LOCAL_FILE" ] && [ -s "$NAROU_MOD_GEM_LOCAL_FILE" ]; then
    echo "Copying narou-mod gem from local file: $NAROU_MOD_GEM_LOCAL_FILE";
elif [ "$NAROU_MOD_VERSION" = "latest" ]; then
    echo "Downloading narou-mod latest release (generic)...";
    GEM_URL=$(curl -s https://api.github.com/repos/ponponusa/narou-mod/releases/latest | \
                grep "browser_download_url" | \
                grep "\.gem\"$" | \
                grep -v "mingw" | \
                sed -E 's/.*"browser_download_url": "(.*)".*/\1/' | \
                head -n 1);
    if [ -z "$GEM_URL" ]; then
        echo "Error: Could not find generic narou-mod latest .gem download URL." >&2;
        exit 1;
    fi;
    echo "Downloading narou-mod gem from: $GEM_URL";
    curl -L -o narou-mod.gem "$GEM_URL";
else
    echo "Downloading narou-mod version $NAROU_MOD_VERSION (generic)...";
    GEM_URL=$(curl -s https://api.github.com/repos/ponponusa/narou-mod/releases/tags/$NAROU_MOD_VERSION | \
                grep "browser_download_url" | \
                grep "\.gem\"$" | \
                grep -v "mingw" | \
                sed -E 's/.*"browser_download_url": "(.*)".*/\1/' | \
                head -n 1);
    if [ -z "$GEM_URL" ]; then
        echo "Error: Could not find generic narou-mod .gem download URL for version $NAROU_MOD_VERSION." >&2;
        exit 1;
    fi;
    echo "Downloading narou-mod gem from: $GEM_URL";
    curl -L -o narou-mod.gem "$GEM_URL";
fi;
# gem を $BUNDLE_PATH にインストール
gem install --no-document narou-mod.gem --install-dir $BUNDLE_PATH;
rm narou-mod.gem;

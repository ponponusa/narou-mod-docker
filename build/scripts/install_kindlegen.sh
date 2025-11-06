#!/bin/sh

set -eux;

if [ -n "$KINDLEGEN_TAR_LOCAL_FILE" ] && [ -f "$KINDLEGEN_TAR_LOCAL_FILE" ] && [ -s "$KINDLEGEN_TAR_LOCAL_FILE" ]; then
    echo "Copying kindlegen tar from local file: $KINDLEGEN_TAR_LOCAL_FILE";
else
    echo "Downloading kindlegen from: ${KINDLEGEN_URL}${KINDLEGEN_FILE}";
    curl -L -o "${KINDLEGEN_FILE}" "${KINDLEGEN_URL}${KINDLEGEN_FILE}";
fi;
tar -xzf ${KINDLEGEN_FILE} && \
mv kindlegen /opt/AozoraEpub3;
rm ${KINDLEGEN_FILE};

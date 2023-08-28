#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

now=$(date -u +%Y/%m/%d)

ARCHIVER_PATH="/home/moh/cronjob-ytlive-generic.sh"
DIR_ARCHIVE="/home/moh/youtube.com"
DIR_LOGS="/home/moh/log/$now"

mkdir -p "$DIR_LOGS"

# Ririsya Music
nohup \
    "$ARCHIVER_PATH" \
        "UC1ucgoC_sGww_Euu5iMqpQw" \
        "$DIR_ARCHIVE" \
     | awk '{ print strftime("%FT%T%z: "), $0; fflush(); }'  \
     >> "$DIR_LOGS"/cronjob.UC1ucgoC_sGww_Euu5iMqpQw.log 2>&1 &

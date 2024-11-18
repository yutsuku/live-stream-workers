#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

CHANNEL_ID=${1}
ARCHIVE_DIRECTORY=${2}

# define binaries
ytdlp="/usr/local/bin/yt-dlp"
python="python3"
ffmpeg="ffmpeg"

# boring stuff
SCRIPTNAME=`basename $0`
PIDFILE=${SCRIPTNAME}.${CHANNEL_ID}.pid

# do not allow script with same pid to run more than a day
MAX_UPTIME_GRACEFUL=86400
MAX_UPTIME_FORCE=90000

if [ -f ${PIDFILE} ]; then
    #verify if the process is actually still running under this pid
    OLDPID=`cat ${PIDFILE}`

    if [ -n "$(ps -p $OLDPID -o pid=)" ]; then
      if [ $MAX_UPTIME_GRACEFUL -gt 0 ]; then
        uptime_script=$(stat --format='%Y' /proc/$OLDPID)
        uptime_now=$(date +%s)
        uptime_difference=$(( ($uptime_now - $uptime_script) ))

        if [ $uptime_difference -gt $MAX_UPTIME_FORCE ]; then
          kill -9 $OLDPID
        fi

        if [ $uptime_difference -gt $MAX_UPTIME_GRACEFUL ]; then
          kill $OLDPID
        fi
      fi

      exit 255
    fi
fi

# grab pid of this process and update the pid file with it
echo $$ > ${PIDFILE}
# boring stuff end

cd "$ARCHIVE_DIRECTORY"

echo '========================================================================='
date
date --iso-8601=seconds
echo 'yt-dlp version:'
$ytdlp --version
echo 'ffmpeg version:'
$ffmpeg -version
echo "running as: " $(id)
echo "pwd: " $(pwd)
echo "stat: " $(stat .)
echo '========================================================================='
echo

first_char="$(printf '%c' "$CHANNEL_ID")"
if [ "$first_char" = @ ]; then
  STREAM_URL="https://www.youtube.com/$CHANNEL_ID/live"
else
  STREAM_URL="https://www.youtube.com/channel/$CHANNEL_ID/live"
fi

# https://github.com/yt-dlp/yt-dlp/issues/3081#issuecomment-1075852658
#output_template='archive/%(channel_id)s/video/%(upload_date>%Y)s/%(upload_date>%m)s/%(upload_date>%d)s/%(id)s/live/%(fulltitle)s-%(id)s.%(ext)s'

$python -u /opt/youtube/youtube-stream-status/check.py \
--wait \
--timeout-max-sleep 300 \
--timeout 1800 \
"$STREAM_URL" && \
now=$(date -u +%Y/%m/%d) && \
output_template="archive/%(channel_id)s/video/$now/%(id)s/live/%(fulltitle)s-%(id)s.%(ext)s" && \
$ytdlp --ignore-config \
--no-progress \
--write-description \
--write-info-json \
--write-thumbnail \
--live-from-start \
--downloader-args ffmpeg:'-hide_banner -loglevel error' \
--output $output_template \
$STREAM_URL

# boring stuff
if [ -f ${PIDFILE} ]; then
    rm ${PIDFILE}
fi
# boring stuff end

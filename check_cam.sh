#!/bin/bash



TARGET_IP=$1
USERNAME=$2
PASSWORD=$3
PORT="554"

check_and_install_dependencies() {
    for tool in "$@"; do
        if ! command -v "$tool" &> /dev/null; then
            sudo apt update
            sudo apt install -y "$tool"
        fi
    done
}


main() {

  if [ -z "$PASSWORD" ]; then
      AUTH_STRING=""
  else
      AUTH_STRING="${USERNAME}:${PASSWORD}@"
  fi

  echo "--- start scanning RTSP, IP: $TARGET_IP ---"

  PATHS=(
      "user=$USERNAME&password=$PASSWORD&channel=1&stream=0.sdp?"
      "user=$USERNAME&password=$PASSWORD&channel=2&stream=0.sdp?"
      "user=$USERNAME&password=$PASSWORD&channel=1&stream=1.sdp?"

      "live/ch0"
      "live/ch1"
      "11"
      "12"
      "live/main"
      "live/sub"
      "h264/ch1/main/av_stream"
      "onvif1"
      "onvif2"

      "snl/live/1/1"
  )

  for PATH_SUFFIX in "${PATHS[@]}"; do
      FULL_URL="rtsp://${AUTH_STRING}${TARGET_IP}:${PORT}/${PATH_SUFFIX}"

      echo -ne "checking: $PATH_SUFFIX ... "

      timeout 4 ffprobe -v quiet -show_streams -i "$FULL_URL" > /dev/null 2>&1

      RESULT=$?

      if [ $RESULT -eq 0 ]; then
          echo -e "\033[0;32m success \033[0m"
          echo "working link: $FULL_URL"
          echo "---------------------------------------------------"
      else
          echo -e "\033[0;31m error \033[0m"
      fi
  done
}


check_and_install_dependencies ffmpeg
main



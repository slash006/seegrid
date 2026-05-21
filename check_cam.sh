#!/bin/bash

PORT="554"
VERBOSE=false
TARGET_IP=""
USERNAME=""
PASSWORD=""

show_help() {
    echo "Usage: $0 --device-ip <IP> --user <USER> --pass <PASS> [OPTIONS]"
    echo ""
    echo "Required parameters:"
    echo "  --device-ip, -d    Target device IP address"
    echo "  --user, -u         Username for authentication"
    echo "  --pass, -p         Password for authentication"
    echo ""
    echo "Optional parameters:"
    echo "  --verbose, -v      Enable debug mode (set -ex)"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --device-ip 192.168.1.10 --user admin --pass admin123"
}

parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -d|--device-ip) TARGET_IP="$2"; shift ;;
            -u|--user) USERNAME="$2"; shift ;;
            -p|--pass) PASSWORD="$2"; shift ;;
            -v|--verbose) VERBOSE=true ;;
            -h|--help) show_help; exit 0 ;;
            *) show_help; exit 1 ;;
        esac
        shift
    done
}

validate_params() {
    if [[ -z "$TARGET_IP" || -z "$USERNAME" || -z "$PASSWORD" ]]; then
        show_help
        exit 1
    fi
}

check_dependencies() {
    local tools=("ffmpeg")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            sudo apt update && sudo apt install -y "$tool"
        fi
    done
}

scan_rtsp() {
    local auth_string="${USERNAME}:${PASSWORD}@"

    echo "--- Start scanning RTSP, IP: $TARGET_IP ---"

    local paths=(
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

    for path_suffix in "${paths[@]}"; do
        local full_url="rtsp://${auth_string}${TARGET_IP}:${PORT}/${path_suffix}"

        echo -ne "Checking: $path_suffix ... "

        if timeout 4 ffprobe -v quiet -show_streams -i "$full_url" > /dev/null 2>&1; then
            echo -e "\033[0;32m SUCCESS \033[0m"
            echo "Working link: $full_url"
            echo "---------------------------------------------------"
        else
            echo -e "\033[0;31m error \033[0m"
        fi
    done
}

parse_arguments "$@"

if [ "$VERBOSE" = true ]; then
    set -ex
fi

validate_params
check_dependencies
scan_rtsp
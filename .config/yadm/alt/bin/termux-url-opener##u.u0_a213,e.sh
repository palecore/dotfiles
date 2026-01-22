#!/bin/sh
# shellcheck shell=sh
set -eu
. ~/.profile

# get_song SONG_URL - download a given song using yt-dlp
song_url="${1:?SONG_URL null or empty}"
shift
curr_year="$(date +%Y)"
music_dir="$HOME/storage/music/pub/prv/$curr_year"
mkdir -p "$music_dir"
python3 -m get_song --directory "$music_dir" "$song_url" &

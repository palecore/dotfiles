#!/bin/sh
# shellcheck shell=sh
set -eu
. ~/.profile

song_url="${1:?SONG_URL null or empty}"

# get_song SONG_URL - download a given song using yt-dlp
#
# NOTE: logic is written to a temporary script which is then run in the
# background with termux-job-scheduler
tmp_script_path="$(mktemp)"
cat > "$tmp_script_path" << 'SH'
#!/bin/sh
# shellcheck shell=sh
set -eu
. ~/.profile

trap 'rm "$0"' EXIT # the temp script should remove itself afterwards

read -r song_url << 'EOF'
SH

printf %s\\n "$song_url" >> "$tmp_script_path"

cat >> "$tmp_script_path" << 'SH'
EOF
curr_year="$(date +%Y)"
music_dir="$HOME/storage/music/pub/prv/$curr_year"
mkdir -p "$music_dir"
python3 -m get_song --directory "$music_dir" "$song_url"
SH

chmod +x "$tmp_script_path"

termux-job-scheduler --script "$tmp_script_path"

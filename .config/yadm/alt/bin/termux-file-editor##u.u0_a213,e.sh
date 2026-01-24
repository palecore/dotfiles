#!/bin/sh
# shellcheck shell=sh
set -eu
. ~/.profile

# Accept the shared file path as argument
file_path="${1:?FILE_PATH null or empty}"

# Extract year from file basename (expects prefix like 20250101_...)
file_base="$(basename "$file_path")"
year="$(printf '%s' "$file_base" | cut -c1-4)"
# Fallback to current year if file's year is not a valid number:
case "$year" in
	'' | *[!0-9]*) year="$(date +%Y)" ;;
esac

music_dir="$HOME/storage/music/pub/prv/$year"
mkdir -p "$music_dir"

# Prepare a temporary script for termux-job-scheduler
# The script will run get_song and delete the input file after processing

# Create temp script
script_path="$(mktemp)"
cat > "$script_path" << 'SH'
#!/bin/sh
set -eu
. ~/.profile
trap 'rm "$0"' EXIT # Remove self after execution

read -r file_path << 'EOF'
SH

# Pass the file path into the script
printf %s\\n "$file_path" >> "$script_path"

cat >> "$script_path" << 'SH'
EOF
music_dir="$HOME/storage/music/pub/prv/$year"
python3 -m get_song --populate-empty-album --directory "$music_dir" "$file_path"
rm -f "$file_path"
SH

chmod +x "$script_path"

termux-job-scheduler --script "$script_path"

#!/bin/bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 input_dir output_dir [--max_depth N]"
    exit 1
fi

input_dir=$(realpath -e "$1")
output_dir=$(realpath -m "$2")
shift 2

max_depth=""
if [[ $# -ge 2 && "$1" == "--max_depth" ]]; then
    max_depth="$2"
    shift 2
fi

mkdir -p "$output_dir"

declare -A name_counts

process_file() {
    local src="$1"
    local rel="${src#$input_dir/}"
    local name=$(basename "$rel")
    local path=$(dirname "$rel")

    IFS='/' read -ra parts <<< "$path"
    local depth=${#parts[@]}

    if [[ -n "$max_depth" ]]; then
        max_path_depth=$((max_depth - 1))
        if (( depth > max_path_depth )); then
            parts=("${parts[@]:depth - max_path_depth}")
        fi
    fi

    local dest_path="${parts[*]}"
    dest_path="${dest_path// /\/}"
    local dest_dir="$output_dir"
    [[ -n "$dest_path" && "$dest_path" != "." ]] && dest_dir="$output_dir/$dest_path"

    mkdir -p "$dest_dir"

    local key="$name"
    local count=${name_counts["$key"]:-0}

    if [[ "$name" =~ ^(.+)\.([^.]+)$ ]]; then
        local n="${BASH_REMATCH[1]}"
        local ext="${BASH_REMATCH[2]}"
    else
        local n="$name"
        local ext=""
    fi

    local new_name
    if (( count == 0 )); then
        new_name="$name"
    else
        new_name="${n}${count}${ext:+.$ext}"
    fi

    name_counts["$key"]=$((count + 1))
    cp -p "$src" "$dest_dir/$new_name"
}

mapfile -d '' files < <(find "$input_dir" -type f -print0)

for f in "${files[@]}"; do
    process_file "$f"
done

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
    local src_file="$1"
    local rel_path="${src_file#$input_dir/}"
    local base_name
    base_name=$(basename -- "$src_file")

    # Глобальный счётчик по имени файла
    local global_key="$base_name"
    local count=${name_counts["$global_key"]:-0}

    if [[ "$base_name" =~ ^(.+)\.([^.]+)$ ]]; then
        local name=${BASH_REMATCH[1]}
        local ext=${BASH_REMATCH[2]}
    else
        local name=$base_name
        local ext=""
    fi

    local new_name
    if (( count == 0 )); then
        new_name="$base_name"
    else
        if [[ -n "$ext" ]]; then
            new_name="${name}${count}.${ext}"
        else
            new_name="${name}${count}"
        fi
    fi

    name_counts["$global_key"]=$((count + 1))

    if [[ -n "$max_depth" ]]; then
        IFS='/' read -ra parts <<< "$rel_path"
        local depth=${#parts[@]}

        if (( depth > max_depth )); then
            truncated_path="${parts[*]:depth - max_depth:max_depth}"
            truncated_path="${truncated_path// /\/}"
            dest_dir="$output_dir/${truncated_path%/*}"
        else
            dest_dir="$output_dir/${rel_path%/*}"
        fi
    else
        dest_dir="$output_dir"
    fi

    mkdir -p "$dest_dir"
    cp -p "$src_file" "$dest_dir/$new_name"
}

mapfile -d '' files < <(find "$input_dir" -type f -print0)

for file in "${files[@]}"; do
    process_file "$file"
done
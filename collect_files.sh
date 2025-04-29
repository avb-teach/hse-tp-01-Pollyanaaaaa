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
if [[ "$1" == "--max_depth" ]]; then
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
    local count=${name_counts["$base_name"]:-0}

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
            new_name="${name}_${count}.${ext}"
        else
            new_name="${base_name}_${count}"
        fi
    fi

    name_counts["$base_name"]=$((count + 1))

    if [[ -n "$max_depth" ]]; then
        IFS='/' read -ra parts <<< "$rel_path"
        if (( ${#parts[@]} > max_depth )); then
            return
        fi
        truncated_path="${parts[*]:0:${#parts[@]}-1}"
        truncated_path="${truncated_path// /\/}"
        dest_dir="$output_dir/$truncated_path"
    else
        dest_dir="$output_dir"
    fi

    mkdir -p "$dest_dir"
    cp -p "$src_file" "$dest_dir/$new_name"
}

if [[ -n "$max_depth" ]]; then
    mapfile -d '' files < <(find "$input_dir" -mindepth 1 -maxdepth "$max_depth" -type f -print0)
    for file in "${files[@]}"; do
        process_file "$file"
    done
else
    mapfile -d '' files < <(find "$input_dir" -type f -print0)
    for file in "${files[@]}"; do
        process_file "$file"
    done
fi

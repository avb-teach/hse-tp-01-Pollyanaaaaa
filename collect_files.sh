#!/bin/bash
set -euo pipefail

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
    IFS='/' read -ra parts <<< "$rel_path"
    local depth=${#parts[@]}
    local base_name="${parts[-1]}"
    local dest_path_parts=()

    if [[ -n "$max_depth" && "$depth" -gt "$max_depth" ]]; then
        dest_path_parts=("${parts[@]:0:max_depth-1}")
        dest_path_parts+=("${parts[@]:max_depth-1:depth - max_depth}")
    else
        dest_path_parts=("${parts[@]:0:depth - 1}")
    fi

    local dest_dir="$output_dir"
    for part in "${dest_path_parts[@]}"; do
        dest_dir="$dest_dir/$part"
    done

    mkdir -p "$dest_dir"

    local count=${name_counts["$base_name"]:-0}
    local name="${base_name%.*}"
    local ext="${base_name##*.}"
    local new_name="$base_name"

    if (( count > 0 )); then
        if [[ "$base_name" == *.* ]]; then
            new_name="${name}${count}.${ext}"
        else
            new_name="${base_name}${count}"
        fi
    fi

    name_counts["$base_name"]=$((count + 1))

    cp -p "$src_file" "$dest_dir/$new_name"
}

export -f process_file
export input_dir
export output_dir
export max_depth
export -A name_counts

find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
    process_file "$file"
done

#!/bin/bash

input_dir=$(realpath "$1")
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

    local file_name=$(basename "$rel_path")
    local count=${name_counts["$file_name"]:-0}

    if [[ "$file_name" =~ ^(.+)\.([^.]+)$ ]]; then
        local name="${BASH_REMATCH[1]}"
        local ext="${BASH_REMATCH[2]}"
        local new_name="$name"
        [[ $count -gt 0 ]] && new_name+="_$count"
        new_name+=".$ext"
    else
        local new_name="$file_name"
        [[ $count -gt 0 ]] && new_name+="_$count"
    fi

    name_counts["$file_name"]=$((count + 1))
    cp -p "$src_file" "$dest_dir/$new_name"
}

mapfile -d '' files < <(find "$input_dir" -type f -print0)

for file in "${files[@]}"; do
    process_file "$file"
done

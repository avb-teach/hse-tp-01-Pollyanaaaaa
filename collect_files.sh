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

    local dest_dir="$output_dir"
    local file_name=$(basename "$rel_path")

    if [[ -n "$max_depth" ]]; then
        depth=$(tr -cd '/' <<< "$rel_path" | wc -c)
        ((depth++))
        if (( depth > max_depth )); then
            return
        fi
        IFS='/' read -ra parts <<< "$rel_path"
        truncated_path=""
        for ((i=0; i<depth-1; i++)); do
            truncated_path+="${parts[i]}/"
        done
        dest_dir="$output_dir/$truncated_path"
        mkdir -p "$dest_dir"
    fi

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

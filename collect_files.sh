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
    local base_name=$(basename -- "$src_file")
    local count=${name_counts["$base_name"]:-0}

    if [[ "$base_name" =~ ^(.+)\.([^.]+)$ ]]; then
        local name=${BASH_REMATCH[1]}
        local ext=${BASH_REMATCH[2]}
        local new_name="$name"
        [[ $count -gt 0 ]] && new_name+="_$count"
        new_name+=".$ext"
    else
        local new_name="$base_name"
        [[ $count -gt 0 ]] && new_name+="_$count"
    fi

    name_counts["$base_name"]=$((count + 1))
    cp -p "$src_file" "$output_dir/$new_name"
}

mapfile -d '' files < <(find "$input_dir" -type f -print0)

for file in "${files[@]}"; do
    if [[ -n "$max_depth" ]]; then
        rel_path=${file#$input_dir/}
        depth=$(tr -cd '/' <<< "$rel_path" | wc -c)
        ((depth++))
        if (( depth > max_depth )); then
            continue
        fi
    fi
    process_file "$file"
done

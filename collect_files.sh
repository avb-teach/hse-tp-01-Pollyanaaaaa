#!/bin/bash
set -euo pipefail

input_dir=$(realpath -e "$1")
output_dir=$(realpath -m "$2")
shift 2

max_depth=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            max_depth="$2"
            shift 2
            ;;
        *)
            exit 1
            ;;
    esac
done

mkdir -p "$output_dir"

declare -A name_counts

process_file() {
    local src_file=$1
    local base_name=$(basename -- "$src_file")
    local count=${name_counts["$base_name"]:-0}
    
    if [[ "$base_name" =~ ^(.+)\.([^.]+)$ ]]; then
        local name=${BASH_REMATCH[1]}
        local ext=${BASH_REMATCH[2]}
    else
        local name=$base_name
        local ext=""
    fi

    if (( count == 0 )); then
        local new_name="$base_name"
    else
        if [[ -n "$ext" ]]; then
            local new_name="${name}_${count}.${ext}"
        else
            local new_name="${base_name}_${count}"
        fi
    fi

    name_counts["$base_name"]=$((count + 1))
    cp -p -- "$src_file" "$output_dir/$new_name"
}

export -f process_file
export output_dir
declare -x name_counts

move_files() {
    local current_dir=$1
    local current_depth=$2

    for file in "$current_dir"/*; do
        if [[ -d "$file" ]]; then
            local dir_name=$(basename -- "$file")
            if (( current_depth <= max_depth )); then
                mkdir -p "$output_dir/$dir_name"
            fi
            move_files "$file" $((current_depth + 1))
        elif [[ -f "$file" ]]; then
            if (( current_depth <= max_depth )); then
                process_file "$file"
            else
                local relative_path="${file#$input_dir/}"
                local depth=$(tr -cd '/' <<< "$relative_path" | wc -c)
                ((depth++))
                local parent_dir=$(dirname -- "$relative_path")
                cp -p -- "$file" "$output_dir/$parent_dir/$(basename "$file")"
            fi
        fi
    done
}

move_files "$input_dir" 1

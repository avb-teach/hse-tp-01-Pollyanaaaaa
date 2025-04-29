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
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            if [[ $# -lt 2 ]]; then
                echo "Error: --max_depth requires a value"
                exit 1
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: --max_depth must be an integer"
                exit 1
            fi
            max_depth="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown parameter: $1"
            exit 1
            ;;
    esac
done

mkdir -p "$output_dir"

if [[ -n "$max_depth" ]]; then
    mapfile -d '' files < <(find "$input_dir" -mindepth 1 -maxdepth "$max_depth" -type f -print0)
    for file in "${files[@]}"; do
        rel_path="${file#$input_dir/}"
        dest="$output_dir/$rel_path"
        mkdir -p "$(dirname "$dest")"
        cp -p "$file" "$dest"
    done
else
    declare -A name_counts

    process_file() {
        local src_file=$1
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
        cp -p -- "$src_file" "$output_dir/$new_name"
    }

    export -f process_file
    export output_dir
    find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
        process_file "$file"
    done
fi

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

if [[ "$output_dir" == "$input_dir"* ]]; then
    echo "Error: output directory cannot be inside input directory"
    exit 1
fi

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

find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
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

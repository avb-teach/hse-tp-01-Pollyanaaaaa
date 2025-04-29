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
    find "$input_dir" -mindepth 1 -maxdepth "$max_depth" -type f -print0 | while IFS= read -r -d '' file; do
        rel_path="${file#$input_dir/}"
        dest_path="$output_dir/$rel_path"
        mkdir -p "$(dirname "$dest_path")"
        cp -p "$file" "$dest_path"
    done
else
    declare -A name_counts

    find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
        base_name=$(basename "$file")
        count=${name_counts["$base_name"]:-0}

        if [[ "$base_name" =~ ^(.+)\.([^.]+)$ ]]; then
            name="${BASH_REMATCH[1]}"
            ext="${BASH_REMATCH[2]}"
        else
            name="$base_name"
            ext=""
        fi

        if (( count == 0 )); then
            new_name="$base_name"
        else
            if [[ -n "$ext" ]]; then
                new_name="${name}_${count}.${ext}"
            else
                new_name="${name}_${count}"
            fi
        fi

        name_counts["$base_name"]=$((count + 1))
        cp -p "$file" "$output_dir/$new_name"
    done
fi

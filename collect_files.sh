#!/bin/bash
set -euo pipefail

show_help() {
    echo "Использование: $0 входная_директория выходная_директория [--max_depth ЧИСЛО]"
    echo "Пример: $0 /home/user/source /home/user/destination --max_depth 3"
    exit 1
}

if [[ $# -lt 2 ]]; then
    show_help
fi

input_dir=$(realpath -e "$1")
output_dir=$(realpath -m "$2")
shift 2

max_depth=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            if [[ $# -lt 2 ]]; then
                echo "Ошибка: после --max_depth нужно указать число" >&2
                show_help
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Ошибка: значение --max_depth должно быть положительным целым числом" >&2
                exit 1
            fi
            max_depth="$2"
            shift 2
            ;;
        *)
            echo "Ошибка: неизвестный параметр '$1'" >&2
            show_help
            ;;
    esac
done

if [[ "$output_dir" == "$input_dir"* ]]; then
    echo "Ошибка: выходная директория не должна находиться внутри входной" >&2
    exit 1
fi

mkdir -p "$output_dir"
declare -A name_counts

process_file() {
    local src="$1"
    local base=$(basename -- "$src")
    local count=${name_counts["$base"]:-0}

    if [[ "$base" =~ ^(.+)\.([^.]+)$ ]]; then
        name="${BASH_REMATCH[1]}"
        ext="${BASH_REMATCH[2]}"
    else
        name="$base"
        ext=""
    fi

    if (( count == 0 )); then
        newname="$base"
    else
        if [[ -n "$ext" ]]; then
            newname="${name}_${count}.${ext}"
        else
            newname="${base}_${count}"
        fi
    fi

    name_counts["$base"]=$((count + 1))
    cp -p -- "$src" "$output_dir/$newname"
}

while IFS= read -r -d '' file; do
    if [[ -n "$max_depth" ]]; then
        rel=${file#$input_dir/}
        depth=$(tr -cd '/' <<< "$rel" | wc -c)
        ((depth++))
        if (( depth > max_depth )); then
            continue
        fi
    fi
    process_file "$file"
done < <(find "$input_dir" -type f -print0)

#!/bin/bash
set -e

if [ "$#" -lt 2 ]; then
  echo "Нужно указать как минимум две папки: откуда копировать и куда. Попробуйте так:"
  echo "  $0 /путь/к/входной /путь/к/выходной [--max_depth N]"
  exit 1
fi

input_dir="$1"
output_dir="$2"
shift 2

max_depth=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --max_depth)
      max_depth="$2"
      if ! [[ "$max_depth" =~ ^[0-9]+$ ]]; then
        echo "Значение после --max_depth должно быть целым числом. Например: --max_depth 3"
        exit 1
      fi
      shift 2
      ;;
    *)
      echo "Неизвестный параметр: $1. Поддерживается только --max_depth"
      exit 1
      ;;
  esac
done

if [ ! -d "$input_dir" ]; then
  echo "Папки '$input_dir' не существует. Проверьте путь и попробуйте снова."
  exit 1
fi

mkdir -p "$output_dir"
declare -A name_counts

safe_name() {
  local filename="$1"
  local base="${filename%.*}"
  local ext="${filename##*.}"
  local key="$filename"
  local count=${name_counts["$key"]}

  if [ -z "$count" ]; then
    name_counts["$key"]=1
    echo "$filename"
  else
    name_counts["$key"]=$((count + 1))
    if [ "$filename" = "$ext" ]; then
      echo "${filename}${name_counts["$key"]}"
    else
      echo "${base}${name_counts["$key"]}.$ext"
    fi
  fi
}

find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
  if [ -n "$max_depth" ]; then
    rel_path=$(realpath --relative-to="$input_dir" "$file")
    IFS='/' read -ra parts <<< "$rel_path"
    if [ "${#parts[@]}" -gt "$max_depth" ]; then
      continue
    fi
  fi

  dst_name=$(safe_name "$(basename "$file")")
  cp -p "$file" "$output_dir/$dst_name"
done

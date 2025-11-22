#!/usr/bin/env bash

cashe() {
  cache_dir="$HOME/scripts/services/work/hash"
  mkdir -p "$cache_dir"

  hash_files=(
    "$cache_dir/disabled_hash"
    "$cache_dir/up_hash"
    "$cache_dir/down_hash"
  )

  dirs=("$disabled_dir" "$up_dir" "$down_dir")

  current_disabled=$(printf "%s\n" "${disabled_services[@]}" | sort)
  current_up=$(printf "%s\n" "${up_services[@]}" | sort)
  current_down=$(printf "%s\n" "${down_services[@]}" | sort)

  current_dirs=("current_disabled" "current_up" "current_down")

  for i in "${!dirs[@]}"; do
    dir="${dirs[$i]}"
    hash_file="${hash_files[$i]}"
    current_var="${current_dirs[$i]}"
    value="${!current_var}"

    [ ! -f "$hash_file" ] && touch "$hash_file"

    old_services=$(find "$dir" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort)

    old_hash=$(<"$hash_file")

    new_hash=$(printf "%s\n" "$value" | grep -v '^$' | sort | sha256sum | awk '{print $1}')

    if [[ "$new_hash" != "$old_hash" ]]; then
      added=$(comm -13 <(echo "$old_services") <(echo "$value"))
      removed=$(comm -23 <(echo "$old_services") <(echo "$value"))

      if [ -n "$added" ]; then
        while IFS= read -r d; do
          [[ -n "$d" ]] && mkdir -p "${dirs[$i]}/$d"
        done <<<"$added"
      fi

      if [ -n "$removed" ]; then
        while IFS= read -r d; do
          target="${dirs[$i]}/$d"
          [[ -n "$d" && -d "$target" ]] && rm -rf "$target"
        done <<<"$removed"
      fi

      echo "$new_hash" >"$hash_file"
    fi
  done
}

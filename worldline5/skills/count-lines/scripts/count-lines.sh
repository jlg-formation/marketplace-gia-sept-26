#!/usr/bin/env bash
# Compatible bash 3.2 (macOS) et outils BSD/GNU.
set -euo pipefail
export LC_ALL=C

root="${1:-.}"
cd "$root"

exclude_dirs=(.git node_modules dist build out bin obj .vs .vscode .idea __pycache__ .venv venv coverage .next target)
[ $# -gt 1 ] && exclude_dirs=("${@:2}")

is_binary() {
  local f="$1" bom
  shopt -s nocasematch
  case "$f" in
    *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.ico|*.webp|*.tiff|*.psd|\
    *.mp3|*.wav|*.ogg|*.flac|*.mp4|*.avi|*.mov|*.mkv|*.webm|\
    *.ttf|*.otf|*.woff|*.woff2|*.eot|\
    *.zip|*.gz|*.tar|*.7z|*.rar|*.jar|*.war|\
    *.exe|*.dll|*.so|*.dylib|*.bin|*.obj|*.o|*.a|*.lib|*.class|*.pyc|*.wasm|\
    *.pdf|*.doc|*.docx|*.xls|*.xlsx|*.ppt|*.pptx|*.db|*.sqlite)
      shopt -u nocasematch; return 0 ;;
  esac
  shopt -u nocasematch
  [ -s "$f" ] || return 1
  # UTF-16 contient des octets nuls mais reste du texte
  bom=$(head -c 2 "$f" | od -An -tx1 | tr -d ' \n')
  case "$bom" in fffe|feff) return 1 ;; esac
  [ $(( $(head -c 8000 "$f" | tr -dc '\000' | wc -c) )) -gt 0 ]
}

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  use_git=1
  echo "Mode : git ls-files (.gitignore respecte)"
else
  use_git=0
  echo "Mode : parcours du dossier (dossiers exclus : ${exclude_dirs[*]})"
fi

list_files() {
  if [ "$use_git" -eq 1 ]; then
    git ls-files -z --cached --others --exclude-standard
  else
    local args=( \( -type d \( ) d
    for d in "${exclude_dirs[@]}"; do args+=( -name "$d" -o ); done
    unset 'args[${#args[@]}-1]'
    args+=( \) -prune \) -o -type f -print0 )
    find . "${args[@]}"
  fi
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

analysed=0; skipped=0; total=0; width=7
while IFS= read -r -d '' f; do
  f="${f#./}"
  [ -f "$f" ] || continue
  if is_binary "$f"; then skipped=$((skipped + 1)); continue; fi
  # awk compte aussi une derniere ligne sans retour a la ligne
  n=$(awk 'END { print NR }' "$f")
  printf '%s\t%s\n' "$n" "$f" >> "$tmp"
  analysed=$((analysed + 1))
  total=$((total + n))
  [ ${#f} -gt "$width" ] && width=${#f}
done < <(list_files)

echo
printf "%-${width}s  %6s\n" "Fichier" "Lignes"
printf "%-${width}s  %6s\n" "-------" "------"
sort -t "$(printf '\t')" -k1,1nr "$tmp" | while IFS=$'\t' read -r n f; do
  printf "%-${width}s  %6s\n" "$f" "$n"
done
echo
echo "Fichiers texte analyses : $analysed"
echo "Fichiers binaires ignores : $skipped"
echo "Total lignes : $total"

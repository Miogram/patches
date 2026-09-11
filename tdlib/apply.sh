#!/usr/bin/env bash

set -euo pipefail

PATCH_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
SERIES_FILE=$PATCH_DIR/series
UPSTREAM_DIR=${1:?Usage: apply.sh /path/to/upstream/td}

if [ ! -d "$UPSTREAM_DIR/.git" ] && ! git -C "$UPSTREAM_DIR" rev-parse --git-dir >/dev/null 2>&1 ; then
  echo "Error: upstream checkout not found at $UPSTREAM_DIR" >&2
  exit 1
fi
if ! git -C "$UPSTREAM_DIR" diff --quiet || ! git -C "$UPSTREAM_DIR" diff --cached --quiet ; then
  echo 'Error: upstream checkout must be clean before applying patches.' >&2
  exit 1
fi

entries=()
while IFS= read -r entry || [ -n "$entry" ] ; do
  case "$entry" in
    ''|'#'*) continue ;;
  esac
  if [[ ! "$entry" =~ ^[0-9]{4}-[A-Za-z0-9._-]+\.patch$ ]] ; then
    echo "Error: invalid patch entry: $entry" >&2
    exit 1
  fi
  entries+=("$entry")
done < "$SERIES_FILE"

shopt -s nullglob
patch_files=("$PATCH_DIR"/*.patch)
if [ ${#entries[@]} -eq 0 ] || [ ${#entries[@]} -ne ${#patch_files[@]} ] ; then
  echo 'Error: tdlib/series must list every patch exactly once.' >&2
  exit 1
fi

for index in "${!entries[@]}" ; do
  patch_name=${entries[$index]}
  patch_path=$PATCH_DIR/$patch_name
  if [ "$(basename -- "${patch_files[$index]}")" != "$patch_name" ] ; then
    echo 'Error: tdlib/series must be ordered and match tdlib/*.patch.' >&2
    exit 1
  fi

  echo "Applying $patch_name"
  git -C "$UPSTREAM_DIR" apply --check --index --whitespace=error-all "$patch_path"
  git -C "$UPSTREAM_DIR" apply --index --whitespace=error-all "$patch_path"
done

git -C "$UPSTREAM_DIR" diff --cached --check
git -C "$UPSTREAM_DIR" diff --cached --stat

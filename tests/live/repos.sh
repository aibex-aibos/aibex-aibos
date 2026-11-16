#!/bin/bash
# repos.sh: package repos for the live tests (V0.7, memos 11, 30: F289, FL33); sourced by tests/live/*.sh
# repos <dir-or-empty> <package>...: prints the folder with the package repos. Without a folder the
# packages come as clones of AIBOS_LIVE_HUB (default https://github.com/aibex-aibos) into a cache under
# TMPDIR, refreshed with git fetch --tags on every run; nothing under ~/git is needed.

   repos() {
      local DIR="$1" HUB="${AIBOS_LIVE_HUB:-https://github.com/aibex-aibos}" P; shift
      if [ -n "$DIR" ]; then echo "$DIR"; return 0; fi
      DIR="${TMPDIR:-/tmp}"; DIR="${DIR%/}/aibos-live-repos"; mkdir -p "$DIR" || return 1
      for P in "$@"; do
         if [ -d "$DIR/$P/.git" ]; then
            git -C "$DIR/$P" fetch -q --tags origin >/dev/null 2>&1 || { echo "*** cannot fetch $HUB/$P" >&2; return 1; }
         else
            git clone -q "$HUB/$P" "$DIR/$P" >/dev/null 2>&1 || { echo "*** cannot clone $HUB/$P" >&2; return 1; }
         fi
      done
      echo "$DIR"
   }

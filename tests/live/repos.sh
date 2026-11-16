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

# tagver <repo>: the highest tag of a package repo without v, a candidate below its release
# (v0.2.0-rc1 < v0.2.0); the live tests take their versions from here, not fixed (V0.7, memo 32: FL37)

   tagver() {
      git -C "$1" -c versionsort.suffix=-rc tag -l 'v[0-9]*' --sort=-v:refname | head -1 | sed 's/^v//'
   }

# release <clone>...: a candidate as its release, only in the clone of the sandbox hub (S5): a commit with
# version: <x.y.z> and the tag v<x.y.z>; a fetch without == takes no candidate (spec 06, Versionen und
# Bereiche). Nothing happens if the highest tag is a release already

   release() {
      local C V R
      for C in "$@"; do
         V="$(tagver "$C")"; case "$V" in *-rc*) ;; *) continue;; esac
         R="${V%-rc*}"
         sed -i.bak "s/^version: .*$/version: $R/" "$C/manifest.yaml" && rm "$C/manifest.yaml.bak" || return 1
         git -C "$C" -c user.name=live -c user.email=live@test commit -q -am "$(basename "$C") $R (test release of $V)" &&
            git -C "$C" tag "v$R" || return 1
      done
   }

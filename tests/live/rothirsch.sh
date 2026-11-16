#!/bin/bash
# rothirsch.sh: live test of the distribution Rothirsch in a sandbox (V0.5, step 13; V0.6, step 11; v0.6.1,
# step 5; V0.7, memo 32: versions from the manifest of the distribution and the tags of the repos, FL37): the candidate of distribution-rothirsch with the kernel of VERSION from a sandbox clone of this
# repo with the local tag (F59); local hub aibex-local of the package repos, real PyPI

   exec </dev/null                                  # nothing waits for input (V0.7, memo 26: H55)

   if [ "$*" == "-?" ] || [ "$*" == "--help" ]; then
      echo '   usage: tests/live/rothirsch.sh [<repos>]  # install distribution-rothirsch from a local hub of the'
      echo '                                           # tagged package repos in <repos> (default: clones of AIBOS_LIVE_HUB)'
      echo '          tests/live/rothirsch.sh --version  # print version'
      echo '   not part of tests/run: needs network access to PyPI, takes about two minutes;'
      echo '   the test versions distribution-rothirsch <candidate>-rc8 (if the release wants another kernel),'
      echo '   <candidate>-rc9 and worker-yt-dlp <x.y>.9 exist only in the'
      echo '   clones of the sandbox hub, never in the package repos (S5)'
      echo '   see also: tests/live/workers.sh, aibos --install distribution-<name>'
      exit 1
   fi

#===============================================================================
# print version: tests/live/rothirsch.sh --version
#===============================================================================

   if [ "$*" == "--version" ]; then
      echo "0.4.1"; exit 0
   fi

#===============================================================================
# run the live test: tests/live/rothirsch.sh [<repos>]
#===============================================================================

   if [ "$2" == "" ]; then
      . "$(dirname "$0")/repos.sh"; REPOS="$(repos "$1" distribution-rothirsch skill-video-analyse assistant-anja skill-5-8-zusammenfassung skill-memo skill-cleanup worker-yt-dlp worker-deno)" || exit 1   # F289, FL33
      REPO="$(cd "$(dirname "$0")/../.." && pwd)"
      T="${TMPDIR:-/tmp}"; SB="$(cd "$(mktemp -d "${T%/}/aibos-live.XXXXXX")" && pwd -P)" || exit 1
      PASS=0; FAIL=0
      check() {                                     # check <name> <condition...>
         local N="$1"; shift
         if "$@"; then PASS=$((PASS+1)); printf '\033[32mok\033[0m   %s\n' "$N"
         else FAIL=$((FAIL+1)); printf '\033[31mFAIL\033[0m %s\n' "$N"; fi
      }
      has() { case "$1" in *"$2"*) return 0;; esac; return 1; }
      line() { printf '%s\n' "$1" | grep -n -m1 -F "$2" | cut -d: -f1; }
      G() { git -c user.name=live -c user.email=live@test "$@"; }

      K="$(cat "$REPO/VERSION")"; S="$SB/kernel"    # sandbox clone with the working tree and the local tag (F59)
      DV="$(sed -n 's/^version: //p' "$REPOS/distribution-rothirsch/manifest.yaml")"   # the candidate of the distribution
      DT="${DV%-rc*}-rc9"                           # its test version for the upgrade, only in the sandbox hub
      G clone -q "$REPO" "$S" || exit 1
      (cd "$REPO" && git -c core.quotePath=false ls-files -co --exclude-standard) | while IFS= read -r F; do
         mkdir -p "$S/$(dirname "$F")"; cp -p "$REPO/$F" "$S/$F"
      done
      printf '%s\n' "$K" > "$S/VERSION"; sed -i.bak "s/^version: .*$/version: $K/" "$S/manifest.yaml" && rm "$S/manifest.yaml.bak"
      G -C "$S" tag -d "v$K" >/dev/null 2>&1        # a tag of the repo moves onto the working tree, in the clone only
      G -C "$S" add -A && { G -C "$S" diff --cached --quiet || G -C "$S" commit -q -m "v$K"; } && G -C "$S" tag "v$K" || exit 1

      H="$SB/aibex-local"; mkdir -p "$H/aibos-index"   # local hub of the tagged package repos (S4)
      printf 'schema: 1\npackages:\n' > "$H/aibos-index/index.yaml"
      for P in distribution-rothirsch skill-video-analyse assistant-anja skill-5-8-zusammenfassung skill-memo skill-cleanup \
               worker-yt-dlp worker-deno; do
         G clone -q "$REPOS/$P" "$H/$P" || exit 1
         printf '  - name: %s\n    type: %s\n    description: %s\n' "$P" "${P%%-*}" "$P" >> "$H/aibos-index/index.yaml"
      done
      G -C "$H/aibos-index" init -q && G -C "$H/aibos-index" add -A && G -C "$H/aibos-index" commit -q -m index
      D0="$H/distribution-rothirsch"; KV="$(sed -n 's/^kernel: *"==\(.*\)"/\1/p' "$D0/manifest.yaml")"
      PIN() { sed -n "s/^  $1: *\"==\(.*\)\"/\1/p" "$D0/manifest.yaml"; }   # versions of the distribution (FL37)
      VV="$(PIN skill-video-analyse)"; AV="$(PIN assistant-anja)"
      ZV="$(tagver "$H/skill-5-8-zusammenfassung")"; MV="$(tagver "$H/skill-memo")"   # by the resolver: the highest
      CV="$(tagver "$H/skill-cleanup")"                                              # dependency of Anja since 0.4.0
      YV="$(tagver "$H/worker-yt-dlp")"; NV="$(tagver "$H/worker-deno")"               # version, candidate or release
      YT="$(echo "${YV%-rc*}" | sed 's/\.[0-9]*$/.9/')"   # test version of worker-yt-dlp in the range of the skill
      if [ "$KV" != "$K" ]; then                    # the release wants another kernel (v0.6.2: 1.1.0 stays, F92):
         DV="${DV%-rc*}-rc8"                        # test version with the candidate, only in the sandbox hub (S5)
         sed -i.bak -e "s/^version: .*$/version: $DV/" -e "s/^kernel: .*$/kernel: \"==$K\"/" "$D0/manifest.yaml" && rm "$D0/manifest.yaml.bak"
         G -C "$D0" commit -q -am "distribution-rothirsch $DV (test version with kernel $K)" && G -C "$D0" tag "v$DV" || exit 1
      fi
      mkdir -p "$SB/home/bin" "$SB/opt" "$SB/fake" "$SB/stup"
      printf '#!/bin/bash\n[ "$*" == "--version" ] && { echo "9.9"; exit 0; }\n[ "$*" == "--profile" ] && { echo "# profile" > "$BIN/profile.sh"; exit 0; }\nexit 1\n' > "$SB/stup/stup"
      export HOME="$SB/home" AIBOS_PREFIX="$SB/opt" AIBOS_CLAUDE_DIR="$SB/home/.claude"
      export AIBOS_SUDO="$SB/fake/no-sudo" AIBOS_PIP=true AIBOS_STUP_URL="file://$SB/stup/stup"
      export AIBOS_HUBS="aibex-local=file://$H"
      PYDIR=""                                      # never the real ~/bin in PATH: aibos --install would
      for P in $(type -ap python3) /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
         [ -x "$P" ] && "$P" -c "import yaml, venv, ensurepip" 2>/dev/null && { PYDIR="$(dirname "$P")"; break; }
      done                                          # update the user's stup there (V0.5, memo 61)
      [ -n "$PYDIR" ] || { echo "*** needs a python3 with PyYAML, venv and ensurepip" >&2; exit 1; }
      export PATH="$HOME/bin:$PYDIR:/usr/bin:/bin:/usr/sbin:/sbin"
      V="$SB/§Probe-Rothirsch"; mkdir -p "$V"
      I() { (cd "$V" && "$S/bin/aibos" --install "$@" 2>&1); }      # the candidate installs itself from its clone
      WK="$HOME/.aibos/workers"; BIN="$HOME/.aibos/bin"   # no /opt/aibos/workers.yaml: workers per user (V0.6, F27)

      OUT="$(I distribution-rothirsch==$DV --plan)"
      check "plan: install distribution-rothirsch $DV (kernel $K)" has "$OUT" "=> install distribution-rothirsch $DV into $V (kernel $K)"
      check "plan: kernel from the sandbox clone" has "$OUT" "install AIBOS v$K from $S"
      check "plan: setup worker-deno" has "$OUT" "setup      worker-deno $NV -> $WK/worker-deno/v$NV"
      check "plan: setup worker-yt-dlp" has "$OUT" "setup      worker-yt-dlp $YV -> $WK/worker-yt-dlp/v$YV"
      check "plan: worker-deno before worker-yt-dlp" [ "$(line "$OUT" "setup      worker-deno")" -lt "$(line "$OUT" "setup      worker-yt-dlp")" ]
      check "plan: machine part before the vault part" [ "$(line "$OUT" "machine part")" -lt "$(line "$OUT" "vault part")" ]
      check "plan: binding of the vault root" has "$OUT" "create $V/.aibos/config.yaml with aibos: $K"
      for P in "skill-video-analyse $VV" "assistant-anja $AV" "skill-5-8-zusammenfassung $ZV" "skill-memo $MV" "skill-cleanup $CV"; do
         check "plan: new $P" has "$OUT" "new        $P"
      done

      OUT="$(I distribution-rothirsch==$DV --yes)"; RC=$?
      [ "$RC" == "0" ] || printf '%s\n' "$OUT"
      check "install: exit 0" [ "$RC" == "0" ]
      check "vault bound to $K" has "$(cat "$V/.aibos/config.yaml")" "aibos: $K"
      check "packages: the distribution" has "$(cat "$V/.aibos/config.yaml")" "distribution-rothirsch: \"==$DV\""
      check "kernel $K under ~/.aibos/versions" [ -x "$HOME/.aibos/versions/v$K/bin/aibos" ]
      check "skill video-analyse registered by the installation (K2)" [ -f "$V/.claude/skills/video-analyse/SKILL.md" ]
      check "the forwarder runs $K in the vault" [ "$(cd "$V" && "$BIN/aibos" --version 2>&1)" == "$K" ]
      check "yt-dlp over its forwarder in the vault" [ "$(cd "$V" && "$BIN/yt-dlp" --version 2>&1)" == "2026.10.21" ]
      check "yt-dlp finds deno" has "$(cd "$V" && "$BIN/yt-dlp" -v 2>&1)" "JS runtimes: deno-2.9.8"

      W1="$H/worker-yt-dlp"                         # test versions only in the clones (S5), released after 1.0.0
      sed -i.bak "s/^version: .*$/version: $YT/" "$W1/manifest.yaml" && rm "$W1/manifest.yaml.bak"
      G -C "$W1" commit -q -am "worker-yt-dlp $YT (test version)" && G -C "$W1" tag "v$YT"
      D1="$H/distribution-rothirsch"
      sed -i.bak -e "s/^version: $DV\$/version: $DT/" "$D1/manifest.yaml" && rm "$D1/manifest.yaml.bak"
      printf '  worker-yt-dlp: "==%s"\n' "$YT" >> "$D1/manifest.yaml"
      G -C "$D1" commit -q -am "distribution-rothirsch $DT (test version)" && G -C "$D1" tag v$DT

      OUT="$(echo y | I distribution-rothirsch==$DT)"; RC=$?
      [ "$RC" == "0" ] || printf '%s\n' "$OUT"
      check "upgrade: $DV -> $DT" has "$OUT" "=> upgrade distribution-rothirsch $DV -> $DT into $V"
      check "upgrade: setup worker-yt-dlp $YT" has "$OUT" "setup      worker-yt-dlp $YT -> $WK/worker-yt-dlp/v$YT"
      check "upgrade: old version removed" has "$OUT" "remove     worker-yt-dlp $YV -> $WK/worker-yt-dlp/v$YV (removed: no known project uses it)"
      check "upgrade: forwarder takes $YT" has "$(cd "$V" && "$BIN/yt-dlp" ---which)" "package=worker-yt-dlp version=$YT"
      check "upgrade: $YV gone" [ ! -e "$WK/worker-yt-dlp/v$YV" ]

      echo "=> $PASS passed, $FAIL failed (sandbox $SB)"
      [ "$FAIL" == "0" ] || exit 1
      chmod -R u+w "$SB"; rm -rf "$SB"
      exit 0
   fi

#===============================================================================
# cannot deal with anything else ...
#===============================================================================

   "$0" -?
   exit 1

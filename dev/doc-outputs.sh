#!/bin/bash
# doc-outputs.sh: outputs of the commands in README and tutorials, from a sandbox with a local hub of
# the tagged package repos (the state after publishing; V0.5, step 14); paths shown as ~/…

   if [ "$*" == "-?" ] || [ "$*" == "--help" ]; then
      echo '   usage: dev/doc-outputs.sh [<repos>]    # print the outputs, section by section (### <label>)'
      echo '          dev/doc-outputs.sh --version    # print version'
      echo '   <repos>: the package repos (default ~/git/AIbex); tutorial 05 sets up the workhorses from'
      echo '   PyPI, tutorial 04 clones from GitHub (network); nothing outside the sandbox is changed'
      echo '   see also: doc/tutorials, tests/live/rothirsch.sh'
      exit 1
   fi

#===============================================================================
# print version: dev/doc-outputs.sh --version
#===============================================================================

   if [ "$*" == "--version" ]; then
      echo "0.2.0"; exit 0
   fi

#===============================================================================
# run: dev/doc-outputs.sh [<repos>]
#===============================================================================

   if [ "$2" == "" ]; then
      REPOS="${1:-$HOME/git/AIbex}"
      REPO="$(cd "$(dirname "$0")/.." && pwd)"
      T="${TMPDIR:-/tmp}"; SB="$(cd "$(mktemp -d "${T%/}/aibos-doc.XXXXXX")" && pwd -P)" || exit 1
      G() { git -c user.name=du -c user.email=du@example.org "$@"; }

      S="$SB/kernel"                                # the kernel as v0.6.0 (sandbox clone with the tag)
      (cd "$REPO" && git -c core.quotePath=false ls-files -co --exclude-standard) | while IFS= read -r F; do
         mkdir -p "$S/$(dirname "$F")"; cp -p "$REPO/$F" "$S/$F"
      done
      G -C "$S" init -q && G -C "$S" add -A && G -C "$S" commit -q -m v0.6.0 && G -C "$S" tag v0.6.0 || exit 1

      mkdir -p "$SB/hubs/aibex-aibos/aibos-index" "$SB/hubs/aibex-hub"   # aibex-hub has no index
      printf 'schema: 1\npackages:\n' > "$SB/hubs/aibex-aibos/aibos-index/index.yaml"
      for D in "$REPOS"/*/; do                      # hubs from the origin of each package repo
         P="$(basename "$D")"
         [ -f "$D/manifest.yaml" ] && [ "$P" != "aibex-aibos" ] || continue
         case "$(git -C "$D" remote get-url origin 2>/dev/null)" in *aibex-hub/*) H=aibex-hub ;; *) H=aibex-aibos ;; esac
         case "$P" in assistent-*) continue ;; esac  # the index of v0.5 names assistant-*
         G clone -q "$D" "$SB/hubs/$H/$P" || exit 1
         DESC="$(sed -n 's/^description: *//p' "$D/manifest.yaml" | sed 's/^"//; s/"$//')"
         [ "$H" == "aibex-aibos" ] && printf '  - name: %s\n    type: %s\n    description: "%s"\n' "$P" \
            "$(sed -n 's/^type: *//p' "$D/manifest.yaml")" "$DESC" >> "$SB/hubs/$H/aibos-index/index.yaml"
      done
      G -C "$SB/hubs/aibex-aibos/aibos-index" init -q && G -C "$SB/hubs/aibex-aibos/aibos-index" add -A &&
         G -C "$SB/hubs/aibex-aibos/aibos-index" commit -q -m index

      mkdir -p "$SB/home/bin" "$SB/home/.aibos" "$SB/home/tmp"
      export HOME="$SB/home" AIBOS_PREFIX="$SB/opt" AIBOS_CLAUDE_DIR="$SB/home/.claude"
      export AIBOS_GITHUB="file://$SB/hubs"                # the hubs are the GitHub organizations
      printf 'v0.6.0: %s\n' "$S" > "$HOME/.aibos/installations.yaml"
      mkdir -p "$HOME/.aibos/bin"                    # forwarder of v0.6; aibos in the PATH only for typing
      cp "$S/templates/forwarder" "$HOME/.aibos/bin/aibos"; chmod +x "$HOME/.aibos/bin/aibos"
      ln -s "$HOME/.aibos/bin/aibos" "$HOME/bin/aibos"
      PYDIR=""                                      # never the real ~/bin in PATH: aibos --install would
      for P in $(type -ap python3) /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
         [ -x "$P" ] && "$P" -c "import yaml, venv, ensurepip" 2>/dev/null && { PYDIR="$(dirname "$P")"; break; }
      done                                          # update the user's stup there (V0.5, memo 61)
      [ -n "$PYDIR" ] || { echo "*** needs a python3 with PyYAML, venv and ensurepip" >&2; exit 1; }
      export PATH="$HOME/bin:$PYDIR:/usr/bin:/bin:/usr/sbin:/sbin"
      mkdir -p "$AIBOS_PREFIX"

      show() {                                      # show <label> <dir> <command...>
         local L="$1" D="$2"; shift 2
         echo "### $L"
         (cd "$D" && "$@" 2>&1) | sed -e "s|$SB/home|~|g" -e "s|file://$SB/hubs|https://github.com|g" \
            -e "s|$SB/hubs|https://github.com|g" -e "s|$SB/opt|/opt/aibos|g" -e "s|$S|~/.aibos/versions/v0.6.0|g" \
            -e "s|0\.6\.0-dev|0.6.0|g" -e "s|0\.6\.1-dev|0.6.1|g"
         echo
      }
      V="$HOME/tmp/§Demo"; mkdir -p "$V"

      # tutorial 01
      show "01 activate" "$V" aibos --activate v0.6.0 "$V" --yes
      mkdir -p "$V/@/@Rule"; printf '# Stil\nAntworte kurz und auf Deutsch.\n' > "$V/@/@Rule/stil.md"
      for P in G-Garten S-Sternwarte; do mkdir -p "$V/$P"; (cd "$V" && aibos --init "$V/$P" --yes >/dev/null 2>&1); done
      show "01 library assistant" "$V" aibos --library assistant
      show "01 fetch gaertner plan" "$V" aibos --fetch assistant-gaertner --to "$V" --plan
      show "01 fetch gaertner" "$V" aibos --fetch assistant-gaertner --to "$V" --yes
      show "01 config" "$V" cat .aibos/config.yaml
      show "01 context garten" "$V/G-Garten" aibos --context --list
      show "01 fetch astronom" "$V" aibos --fetch assistant-astronom --to "$V/S-Sternwarte" --yes

      # tutorial 02 (the projects of tutorial 01 committed)
      for P in "$V" "$V/G-Garten" "$V/S-Sternwarte"; do G -C "$P" add -A >/dev/null; G -C "$P" commit -qm "Tutorial 01" >/dev/null; done
      mkdir -p "$V/G-Garten/beet"
      show "02 init beet plan" "$V" aibos --init "$V/G-Garten/beet" --plan
      show "02 init beet" "$V" aibos --init "$V/G-Garten/beet" --name GB-Beet --yes
      G -C "$V" add -A >/dev/null; G -C "$V" commit -qm "GB-Beet" >/dev/null
      rm "$V/S-Sternwarte/.gitignore"
      printf '# Notiz\n' > "$V/G-Garten/@/notiz.md"
      show "02 integrity" "$V" aibos --integrity "$V"
      G -C "$V/G-Garten" add -A >/dev/null; G -C "$V/G-Garten" commit -qm notiz >/dev/null
      (cd "$V" && aibos --init "$V/S-Sternwarte" --yes >/dev/null 2>&1)

      # tutorial 03
      show "03 hubs" "$V" aibos --hubs
      show "03 library rechner" "$V" aibos --library rechner
      show "03 library app" "$V" aibos --library app-taschenrechner
      show "03 fetch app plan" "$V" aibos --fetch app-taschenrechner --plan
      show "03 fetch app" "$V" aibos --fetch app-taschenrechner --yes
      show "03 config" "$V" cat .aibos/config.yaml
      show "03 lock" "$V" sed -n '/app-taschenrechner:/,/required_by\|requested/p' .aibos/lock.yaml
      show "03 gui apps" "$V" aibos --gui --apps
      show "03 hubs add" "$V" aibos --hubs add aibex-hub --vault --yes
      show "03 hubs 2" "$V" aibos --hubs
      show "03 library scorpio search" "$V" aibos --library scorpio
      show "03 library scorpio" "$V" aibos --library aibex-hub/knowledge-scorpio
      (cd "$V" && aibos --fetch knowledge-orion --yes >/dev/null 2>&1)
      show "03 fetch scorpio" "$V" aibos --fetch aibex-hub/knowledge-scorpio --yes
      show "03 config 2" "$V" cat .aibos/config.yaml
      show "03 fetch 0.3.2 plan" "$V" aibos --fetch app-taschenrechner==0.3.2 --plan
      show "03 deploy" "$V" aibos --deploy

      # tutorial 05: Rothirsch 1.1.0 with the kernel 0.6.1, as after publishing (v0.6.1, step 5): the tag
      # v0.6.1 in the sandbox clone, the release 1.1.0 from the candidate in the clone of the sandbox hub
      if [ -n "$AIBOS_DOC_05" ]; then
      G -C "$S" tag v0.6.1 || exit 1
      D="$SB/hubs/aibex-aibos/distribution-rothirsch"
      sed -i.bak -e 's/^version: 1.1.0-rc[0-9]*$/version: 1.1.0/' -e 's/^kernel: "==0.6.1-rc[0-9]*"$/kernel: "==0.6.1"/' "$D/manifest.yaml" &&
         rm "$D/manifest.yaml.bak" && G -C "$D" commit -q -am "distribution-rothirsch 1.1.0" && G -C "$D" tag v1.1.0 || exit 1
      (cd "$HOME/tmp" && aibos --install v0.6.1 --yes >/dev/null 2>&1) || exit 1    # prerequisite of the tutorial
      V="$HOME/tmp/§Rothirsch"; mkdir -p "$V/P-Projekt"
      show "05 install rothirsch plan" "$V" aibos --install distribution-rothirsch "$V" --plan
      show "05 install rothirsch" "$V" aibos --install distribution-rothirsch "$V" --yes
      show "05 worker" "$V" aibos --worker
      (cd "$V" && aibos --init "$V/P-Projekt" --yes >/dev/null 2>&1)
      show "05 which" "$V/P-Projekt" "$HOME/.aibos/bin/yt-dlp" ---which
      show "05 version" "$V/P-Projekt" "$HOME/.aibos/bin/yt-dlp" --version
      show "05 outside" "$HOME" "$HOME/.aibos/bin/yt-dlp" --version
      show "05 workers.yaml" "$V" cat "$HOME/.aibos/workers.yaml"
      show "05 config" "$V" cat .aibos/config.yaml
      show "05 advise" "$V/P-Projekt" bash -c "chmod -R u+w '$HOME/.aibos/workers/worker-yt-dlp' && mv '$HOME/.aibos/workers/worker-yt-dlp' '$SB/gone' && aibos --context --advise </dev/null | grep AIBOS-WORKERS"
      show "05 reconcile plan" "$V" aibos --fetch --plan
      show "05 reconcile" "$V" aibos --fetch --yes
      show "05 remove plan" "$V" aibos --fetch --remove distribution-rothirsch --plan
      fi

      # v0.6: outside an AIBOS workspace (README, tutorial 01)
      show "06 outside skill" "$HOME/tmp" aibos --skill aibos-status
      show "06 outside id" "$HOME/tmp" aibos --context --id
      show "06 wrappers" "$HOME/tmp/§Demo" ls .claude/skills

      # tutorial 04 (network: GitHub)
      V="$HOME/tmp/§Demo"; W="$V/W-Werkstatt"; mkdir -p "$W"
      show "04 init" "$W" aibos --init --yes
      mkdir -p "$W/.aibos"; cat > "$W/.aibos/workspace.yaml" <<'EOF'
schema: 1
remotes:
  aibex: https://github.com/aibex-aibos
projects:
  - name: app-taschenrechner
    remote: aibex
    revision: v0.4.0
    path: app-taschenrechner
  - name: skill-memo
    remote: aibex
    revision: main
    path: skill-memo
  - name: knowledge-orion
    remote: aibex
    revision: main
    path: wissen/knowledge-orion
    groups: [wissen]
EOF
      show "04 update plan" "$W" aibos --workspace update --plan
      show "04 update" "$W" aibos --workspace update --yes
      show "04 log" "$W" git log -3 --format=%s
      show "04 status" "$W" aibos --workspace status
      show "04 integrity" "$W" aibos --integrity

      chmod -R u+w "$SB"; rm -rf "$SB"
      exit 0
   fi

#===============================================================================
# cannot deal with anything else ...
#===============================================================================

   "$0" -?
   exit 1

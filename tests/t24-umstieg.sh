# t24-umstieg.sh: v0.7, the transition from AIbex AIOS to AIbex AIBOS until 0.8 (spec 01, Vorabversionen;
# spec 04, Umstieg auf v0.7; spec 06, Hubs; V0.7, memos 13, 19: steps 3, 5, 6)

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# setup: a python3 with PyYAML, vault §Neu bound to 0.7.0
#===============================================================================

   PYDIR=""
   for P in $(type -ap python3) /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
      [ -x "$P" ] && "$P" -c "import yaml" 2>/dev/null && { PYDIR="$(dirname "$P")"; break; }
   done
   [ -n "$PYDIR" ] && ok || fail "t24 needs a python3 with PyYAML (pip install pyyaml)"
   export PATH="$PYDIR:/usr/bin:/bin:/usr/sbin:/sbin"
   unset AIBOS_HUBS AIOS_HUBS AIOS_GITHUB
   mk() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" > "$1"; }
   at() { (cd "$1" && shift && "$@" 2>&1); }
   A() { local d="$1"; shift; at "$d" "$SRC/bin/aibos" "$@"; }
   PY() { local d="$1"; shift; at "$d" env PYTHONPATH="$SRC/lib" python3 -c "$*"; }
   G() { git -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
   N="$SANDBOX/work/§Neu"; mk "$N/.aibos/config.yaml" $'aibos: 0.7.0\n'; mkdir -p "$N/@"

#===============================================================================
# step 3: environment AIOS_<x> as fallback with a note (F268)
#===============================================================================

   OUT="$(at "$N" env -u AIBOS_HUBS AIOS_HUBS="eins=file:///x/eins" PYTHONPATH="$SRC/lib" python3 -c "
from aibos import hub
print(' '.join(h.name + '(' + h.origin + ')' for h in hub.hub_list()))
print(' '.join(h.name for h in hub.hub_list()))")"
   assert_contains "$OUT" "eins(AIBOS_HUBS)" "AIOS_HUBS is read when AIBOS_HUBS is missing"
   assert_eq "$(grep -c 'note: AIOS_HUBS is read as AIBOS_HUBS until AIBOS 0.8' <<< "$OUT")" "1" "one note per name and call"
   OUT="$(at "$N" env AIBOS_HUBS="zwei=file:///x/zwei" AIOS_HUBS="eins=file:///x/eins" PYTHONPATH="$SRC/lib" python3 -c "
from aibos import hub
print(' '.join(h.name for h in hub.hub_list()))")"
   assert_eq "$OUT" "zwei" "AIBOS_HUBS wins over AIOS_HUBS, no note"
   assert_eq "$(PY "$N" "from aibos import legacy; print(sorted(legacy.package_env(AIBOS_DATA='d', PATH='p').items()))")" \
      "[('AIBOS_DATA', 'd'), ('AIOS_DATA', 'd'), ('PATH', 'p')]" "variables for packages under both names (FL4)"

#===============================================================================
# step 3: hub aibex-aios is aibex-aibos (F264); addresses on GitHub (F281)
#===============================================================================

   mk "$N/.aibos/config.yaml" $'aibos: 0.7.0\nhubs:\n  - aibex-aios\n'
   assert_eq "$(PY "$N" "from aibos import hub; print(' '.join(h.name + '=' + h.url for h in hub.hub_list()))")" \
      "aibex-aibos=https://github.com/aibex-aibos" "hubs: aibex-aios is read as aibex-aibos"
   mk "$N/.aibos/config.yaml" $'aibos: 0.7.0\n'
   assert_eq "$(PY "$N" "from aibos import fetch; print(fetch.parse_spec('aibex-aios/skill-memo~=6.1')[:2])")" \
      "('aibex-aibos', 'skill-memo')" "full name with aibex-aios"
   assert_eq "$(PY "$N" "from aibos import fetch; print(fetch.request(dict(range='*', hub='aibex-aios')).hub)")" \
      "aibex-aibos" "hub of a packages: entry"
   assert_eq "$(PY "$N" "from aibos import legacy
for u in ('https://github.com/aibex-aios/skill-memo', 'git@github.com:aibex-aios/x.git', 'https://github.com/aibex-aios-x/y', 'https://gitlab.com/aibex-aios/z'):
    print(legacy.url(u))")" $'https://github.com/aibex-aibos/skill-memo\ngit@github.com:aibex-aibos/x.git\nhttps://github.com/aibex-aios-x/y\nhttps://gitlab.com/aibex-aios/z' \
      "addresses: only the organisation aibex-aios on GitHub"

#===============================================================================
# step 3: requires.aios is read, the range applies (F283, FL10)
#===============================================================================

   H="$SANDBOX/hub-alt"
   mkpkg() {                                       # mkpkg <name> <version> <requires line>
      local R="$H/$1"; mkdir -p "$R/knowledge"
      [ -d "$R/.git" ] || G -C "$R" init -q
      printf 'name: %s\nversion: %s\ntype: knowledge\ndescription: Probe\nrequires:\n  %s\n' "$1" "$2" "$3" > "$R/manifest.yaml"
      printf '# %s\n' "$2" > "$R/knowledge/k.md"
      G -C "$R" add -A; G -C "$R" commit -q -m "v$2"; G -C "$R" tag "v$2"
   }
   mkpkg knowledge-alt 1.0.0 'aios: ">=0.6,<0.7"'
   mkpkg knowledge-beide 1.0.0 'aios: ">=0.6,<0.7"'
   mkpkg knowledge-beide 1.1.0 'aibos: ">=0.7,<0.8"'
   export AIBOS_HUBS="aibex-aibos=file://$H"
   assert_eq "$(PY "$N" "from aibos import package; m = package.load(__import__('pathlib').Path('$H/knowledge-alt')); print(m.requires_key, m.requires)")" \
      "aios >=0.6,<0.7" "manifest with requires.aios"
   mk "$SANDBOX/kein/manifest.yaml" $'name: knowledge-kein\nversion: 1.0.0\ntype: knowledge\ndescription: x\nrequires:\n  andere: "*"\n'
   assert_contains "$(PY "$N" "from aibos import package
try:
    package.load(__import__('pathlib').Path('$SANDBOX/kein'))
except package.ManifestError as e:
    print(e)")" 'requires needs aibos: "<range>"' "manifest without aibos and aios"
   OUT="$(A "$N" --fetch knowledge-alt --plan)"; RC=$?
   assert_contains "$OUT" "knowledge-alt 1.0.0 needs a version for AIBOS 0.7.0 (requires.aios >=0.6,<0.7)" "package of AIOS: refused with the message (FL10)"
   [ "$RC" != "0" ] && [ ! -e "$N/.aibos/lock.yaml" ] && ok || fail "package of AIOS: nothing written"
   OUT="$(A "$N" --fetch knowledge-beide --yes)"
   assert_contains "$(cat "$N/.aibos/lock.yaml" 2>/dev/null)" "1.1.0" "the version for 0.7 is chosen"
   unset AIBOS_HUBS

#===============================================================================
# step 3: Altbindung aios: 0.6.x in .aios/config.yaml (F270, F272, FL12)
#===============================================================================

   O="$SANDBOX/work/§Alt"; mk "$O/.aios/config.yaml" $'aios: 0.6.6\n'; mkdir -p "$O/@" "$O/P/@"
   assert_eq "$(PY "$O/P" "from aibos import config; c = config.load('.'); print(c.kind, c.binding, c.aibos)")" "alt 0.6.6 None" "Altbindung: kind alt, binding 0.6.6"
   mk "$O/.aios/config.yaml" $'legacy: ai-brain\n'
   assert_eq "$(PY "$O" "from aibos import config; print(config.load('.').kind)")" "legacy" "legacy: in .aios/config.yaml"
   mk "$O/.aios/config.yaml" $'aios: 0.5.1\n'
   assert_eq "$(PY "$O" "from aibos import config; print(config.load('.').kind)")" "none" "binding below 0.6 in .aios/: no binding (FL9)"
   mk "$O/.aibos/config.yaml" $'aibos: 0.7.0\n'; mk "$O/.aios/config.yaml" $'aios: 0.6.6\n'
   assert_eq "$(PY "$O" "from aibos import config; c = config.load('.'); print(c.kind, c.binding)")" "aibos 0.7.0" ".aibos/ wins over .aios/"
   mk "$O/P/.aios/config.yaml" $'aios: 0.6.6\n'; rm -rf "$O/.aibos" "$O/.aios"
   assert_eq "$(PY "$O/P" "from aibos import config; print(config.load('.').binding)")" "None" ".aios/ counts only at the vault root"

#===============================================================================
# step 5: installing 0.7 over a real 0.6.6 from the tag v0.6.6 of this repo (FL18): changeover
# ~/.aios -> ~/.aibos with a link, alias aios, hooks rewritten; 0.6.6 runs on (spec 04, Umstieg auf v0.7)
#===============================================================================

   export HOME="$SANDBOX/home5" AIBOS_CLAUDE_DIR="$SANDBOX/home5/.claude"; mkdir -p "$HOME"   # a fresh user
   export AIOS_PREFIX="$SANDBOX/opt/aios" AIOS_CLAUDE_DIR="$AIBOS_CLAUDE_DIR"     # the names 0.6.6 reads
   export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
   unset AIOS_HOME
   YAML="$(python3 -c 'import os, yaml; print(os.path.dirname(yaml.__file__))')"
   mkdir -p "$SANDBOX/fake"
   printf '#!/bin/bash\ncp -R "%s" "$(dirname "$1")"/lib/python*/site-packages/\n' "$YAML" > "$SANDBOX/fake/pip"
   chmod +x "$SANDBOX/fake/pip"
   export AIOS_PIP="$SANDBOX/fake/pip" AIBOS_PIP="$SANDBOX/fake/pip"            # PyYAML without network
   K66="$SANDBOX/k066"; mkdir -p "$K66"
   git -C "$SRC" archive v0.6.6 | tar -x -C "$K66"
   G -C "$K66" init -q; G -C "$K66" add -A; G -C "$K66" commit -q -m v0.6.6; G -C "$K66" tag v0.6.6
   K07="$SANDBOX/k070"                             # sandbox clone of the working tree with a tag v0.7.0
   (cd "$SRC" && git -c core.quotePath=false ls-files -co --exclude-standard) | while IFS= read -r F; do
      mkdir -p "$K07/$(dirname "$F")"; cp -p "$SRC/$F" "$K07/$F"
   done
   G -C "$K07" init -q; G -C "$K07" add -A; G -C "$K07" commit -q -m v0.7.0; G -C "$K07" tag v0.7.0

   OUT="$(at "$SANDBOX" "$K66/bin/aios" --install v0.6.6 --yes)"; RC=$?
   [ "$RC" == "0" ] && [ -x "$HOME/.aios/bin/aios" ] && [ -d "$HOME/.aios/versions/v0.6.6" ] && ok || fail "0.6.6 installed: $OUT"
   V="$SANDBOX/work/§Sechs"; mkdir -p "$V/PA"
   at "$SANDBOX" "$HOME/.aios/bin/aios" --activate v0.6.6 "$V" --yes >/dev/null
   at "$V/PA" "$HOME/.aios/bin/aios" --init --yes >/dev/null
   assert_contains "$(at "$V/PA" "$HOME/.aios/bin/aios" --context --id)" "mode=aios-0.6.6" "before: vault on 0.6.6"

   OUT="$(at "$SANDBOX" "$K07/bin/aibos" --install v0.7.0 --plan)"; RC=$?
   assert_eq "$RC" "0" "changeover: --plan exit 0"
   assert_contains "$OUT" "move $HOME/.aios to $HOME/.aibos and leave $HOME/.aios as a link to it (until AIBOS 0.8)" "changeover: plan moves ~/.aios"
   assert_contains "$OUT" "then: the plan of the installation in ~/.aibos" "changeover: the second plan is named (FL30)"
   [ -d "$HOME/.aios" ] && [ ! -L "$HOME/.aios" ] && [ ! -e "$HOME/.aibos" ] && ok || fail "changeover: --plan writes nothing"

   OUT="$(at "$SANDBOX" "$K07/bin/aibos" --install v0.7.0 --yes)"; RC=$?
   assert_eq "$RC" "0" "changeover: exit 0"
   [ -L "$HOME/.aios" ] && [ "$(cd "$HOME/.aios" && pwd -P)" == "$(cd "$HOME/.aibos" && pwd -P)" ] && ok || fail "~/.aios is a link to ~/.aibos"
   [ -d "$HOME/.aibos/versions/v0.6.6" ] && [ -d "$HOME/.aibos/versions/v0.7.0" ] && ok || fail "both versions under ~/.aibos"
   assert_contains "$(head -2 "$HOME/.aibos/bin/aibos")" "# forwarder: ~/.aibos/bin/aibos" "forwarder 0.5.0 in ~/.aibos/bin"
   assert_eq "$(readlink "$HOME/.aibos/bin/aios")" "aibos" "alias ~/.aibos/bin/aios -> aibos (FL29)"
   SETTINGS="$(cat "$AIBOS_CLAUDE_DIR/settings.json")"
   assert_eq "$(grep -c "$HOME/.aibos/bin/aibos --context --" <<< "$SETTINGS")" "3" "three hooks with ~/.aibos/bin/aibos"
   assert_not_contains "$SETTINGS" "/.aios/bin/aios --context" "hooks of 0.6.6 replaced in place (F269)"

   assert_contains "$(at "$V/PA" "$HOME/.aibos/bin/aibos" --context --id)" "mode=aios-0.6.6" "after: the Altbindung runs with 0.6.6 (P19)"
   assert_contains "$(at "$V/PA" "$HOME/.aios/bin/aios" --context --id)" "mode=aios-0.6.6" "after: wrappers of 0.6.6 (~/.aios/bin/aios) still work"
   assert_contains "$(at "$V/PA" "$HOME/.aios/bin/aios" --skill aios-status)" "# Projektstatus" "after: a kernel skill of 0.6.6"
   assert_eq "$(at "$SANDBOX" "$HOME/.aibos/bin/aibos" --version)" "0.7.0" "aibos without binding: the highest version"

   assert_contains "$(at "$SANDBOX" "$K07/bin/aibos" --install v0.7.0 --yes)" "nothing to do" "second install: nothing to do (I8)"
   OUT="$(echo n | at "$SANDBOX" "$HOME/.aibos/bin/aibos" --uninstall)"
   assert_contains "$OUT" "remove the alias $HOME/.aibos/bin/aios" "uninstall: removes the alias"
   assert_contains "$OUT" "remove the link $HOME/.aios" "uninstall: removes the link"
   mkdir -p "$SANDBOX/both/.aios" "$SANDBOX/both/.aibos"
   OUT="$(at "$SANDBOX" env HOME="$SANDBOX/both" "$K07/bin/aibos" --install v0.7.0 --plan)"; RC=$?
   [ "$RC" != "0" ] && ok || fail "~/.aios and ~/.aibos both: abort"
   assert_contains "$OUT" "both exist" "~/.aios and ~/.aibos both: message"

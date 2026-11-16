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
   V="$SANDBOX/work/§Sechs"; mkdir -p "$V/P-Alpha"
   at "$SANDBOX" "$HOME/.aios/bin/aios" --activate v0.6.6 "$V" --yes >/dev/null
   at "$V/P-Alpha" "$HOME/.aios/bin/aios" --init --yes >/dev/null
   printf 'assistant: none\n' > "$V/P-Alpha/.aios/config.yaml" 2>/dev/null || { mkdir -p "$V/P-Alpha/.aios"; printf 'assistant: none\n' > "$V/P-Alpha/.aios/config.yaml"; }
   G -C "$V/P-Alpha" add .aios/config.yaml; G -C "$V/P-Alpha" commit -q -m "config of PA"     # a project of 0.6.6 with .aios/
   at "$V/P-Alpha" "$HOME/.aios/bin/aios" --register --yes >/dev/null
   [ -f "$V/P-Alpha/.aios/registry" ] && [ -d "$V/P-Alpha/.claude/skills/aios-status" ] && ok || fail "PA: wrappers aios-* of 0.6.6"
   assert_contains "$(at "$V/P-Alpha" "$HOME/.aios/bin/aios" --context --id)" "mode=aios-0.6.6" "before: vault on 0.6.6"

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

   assert_contains "$(at "$V/P-Alpha" "$HOME/.aibos/bin/aibos" --context --id)" "mode=aios-0.6.6" "after: the Altbindung runs with 0.6.6 (P19)"
   assert_contains "$(at "$V/P-Alpha" "$HOME/.aios/bin/aios" --context --id)" "mode=aios-0.6.6" "after: wrappers of 0.6.6 (~/.aios/bin/aios) still work"
   assert_contains "$(at "$V/P-Alpha" "$HOME/.aios/bin/aios" --skill aios-status)" "# Projektstatus" "after: a kernel skill of 0.6.6"
   assert_eq "$(at "$SANDBOX" "$HOME/.aibos/bin/aibos" --version)" "0.7.0" "aibos without binding: the highest version"

   assert_contains "$(at "$SANDBOX" "$K07/bin/aibos" --install v0.7.0 --yes)" "nothing to do" "second install: nothing to do (I8)"
   OUT="$(echo n | at "$SANDBOX" "$HOME/.aibos/bin/aibos" --uninstall)"
   assert_contains "$OUT" "remove the alias $HOME/.aibos/bin/aios" "uninstall: removes the alias"
   assert_contains "$OUT" "remove the link $HOME/.aios" "uninstall: removes the link"
   mkdir -p "$SANDBOX/both/.aios" "$SANDBOX/both/.aibos"
   OUT="$(at "$SANDBOX" env HOME="$SANDBOX/both" "$K07/bin/aibos" --install v0.7.0 --plan)"; RC=$?
   [ "$RC" != "0" ] && ok || fail "~/.aios and ~/.aibos both: abort"
   assert_contains "$OUT" "both exist" "~/.aios and ~/.aibos both: message"

#===============================================================================
# step 6: binding the vault to 0.7 changes it over (.aios/ -> .aibos/, aios: -> aibos:, one commit
# per project); a second computer on 0.6.6 sees the vault as unbound (FL8) and follows the
# upstream when it changes over (FL7) (spec 04, Umstieg auf v0.7, step 2; FL32)
#===============================================================================

   A_HOME="$HOME"; RM="$SANDBOX/remotes"; mkdir -p "$RM"
   for P in "$V" "$V/P-Alpha"; do                       # remotes for the root and PA, pushed from 0.6.6
      N="$(basename "$P")"; G init -q --bare "$RM/$N.git"
      G -C "$P" remote add origin "$RM/$N.git"; G -C "$P" push -q -u origin main
   done
   B="$SANDBOX/b"; B_HOME="$SANDBOX/home6"; mkdir -p "$B" "$B_HOME"            # computer B on 0.6.6
   export HOME="$B_HOME" AIBOS_CLAUDE_DIR="$B_HOME/.claude" AIOS_CLAUDE_DIR="$B_HOME/.claude"
   at "$SANDBOX" "$K66/bin/aios" --install v0.6.6 --yes >/dev/null
   G clone -q "$RM/§Sechs.git" "$B/§Sechs"; G clone -q "$RM/P-Alpha.git" "$B/§Sechs/P-Alpha"
   assert_contains "$(at "$B/§Sechs/P-Alpha" "$HOME/.aios/bin/aios" --context --id)" "mode=aios-0.6.6" "B: the clone runs with 0.6.6"

   export HOME="$A_HOME" AIBOS_CLAUDE_DIR="$A_HOME/.claude" AIOS_CLAUDE_DIR="$A_HOME/.claude"   # computer A
   OUT="$(at "$SANDBOX" "$HOME/.aibos/bin/aibos" --activate v0.7.0 "$V" --plan)"; RC=$?
   assert_eq "$RC" "0" "changeover of the vault: --plan exit 0"
   assert_contains "$OUT" "change over 2 projects of $V (., P-Alpha): .aios/ -> .aibos/, aios: -> aibos: 0.7.0" "plan names the projects"
   assert_contains "$OUT" "then: the plan of the activation" "the second plan is named (FL32)"
   [ -d "$V/.aios" ] && [ ! -e "$V/.aibos" ] && ok || fail "--plan writes nothing"
   OUT="$(at "$SANDBOX" "$HOME/.aibos/bin/aibos" --activate v0.7.0 "$V" --yes)"; RC=$?
   assert_eq "$RC" "0" "changeover of the vault: exit 0"
   [ ! -e "$V/.aios" ] && [ ! -e "$V/P-Alpha/.aios" ] && [ -f "$V/.aibos/config.yaml" ] && [ -d "$V/P-Alpha/.aibos" ] && ok || fail ".aios/ -> .aibos/ in both projects"
   assert_eq "$(cat "$V/.aibos/config.yaml")" "aibos: 0.7.0" "binding aibos: 0.7.0"
   assert_eq "$(git -C "$V" log -1 --format=%s) | $(git -C "$V/P-Alpha" log -1 --format=%s)" "AIBOS: auf AIBOS v0.7 umgestellt | AIBOS: auf AIBOS v0.7 umgestellt" "one commit per project"
   assert_eq "$(git -C "$V" status --porcelain)" "" "root: nothing left uncommitted"
   [ -d "$V/P-Alpha/.claude/skills/aibos-status" ] && [ ! -e "$V/P-Alpha/.claude/skills/aios-status" ] && ok || fail "wrappers aibos-* instead of aios-* (F271)"
   assert_contains "$(at "$V/P-Alpha" "$HOME/.aibos/bin/aibos" --context --id)" "mode=aibos-0.7.0" "the vault runs with 0.7"
   assert_contains "$(cd "$V/P-Alpha" && echo '{}' | "$HOME/.aibos/bin/aibos" --context --session 2>&1)" "<aibos-context" "master context with <aibos-context>"
   for P in "$V" "$V/P-Alpha"; do G -C "$P" push -q; done

   export HOME="$B_HOME" AIBOS_CLAUDE_DIR="$B_HOME/.claude" AIOS_CLAUDE_DIR="$B_HOME/.claude"   # computer B
   G -C "$B/§Sechs" pull -q
   assert_contains "$(at "$B/§Sechs" "$HOME/.aios/bin/aios" --context --id)" "mode=none" "B on 0.6.6: the changed-over vault is unbound (FL8)"
   at "$SANDBOX" "$K07/bin/aibos" --install v0.7.0 --yes >/dev/null
   OUT="$(at "$SANDBOX" "$HOME/.aibos/bin/aibos" --activate v0.7.0 "$B/§Sechs" --plan)"
   assert_contains "$OUT" "bring $B/§Sechs/P-Alpha forward to its upstream" "B: PA follows its upstream (FL7)"
   assert_not_contains "$OUT" "change over" "B: nothing renamed twice"
   OUT="$(at "$SANDBOX" "$HOME/.aibos/bin/aibos" --activate v0.7.0 "$B/§Sechs" --yes)"; RC=$?
   assert_eq "$RC" "0" "B: exit 0"
   [ ! -e "$B/§Sechs/.aios" ] && [ ! -e "$B/§Sechs/P-Alpha/.aios" ] && [ -d "$B/§Sechs/P-Alpha/.aibos" ] && ok || fail "B: no .aios/ left"
   assert_eq "$(git -C "$B/§Sechs/P-Alpha" rev-parse HEAD)" "$(git -C "$V/P-Alpha" rev-parse HEAD)" "B: PA at the commit of A, no own commit"
   assert_contains "$(at "$B/§Sechs/P-Alpha" "$HOME/.aibos/bin/aibos" --context --id)" "mode=aibos-0.7.0" "B: the vault runs with 0.7"
   export HOME="$A_HOME" AIBOS_CLAUDE_DIR="$A_HOME/.claude" AIOS_CLAUDE_DIR="$A_HOME/.claude"

   OUT="$(PY "$SANDBOX" "from aibos import changeover
print(changeover.rewrite('''remotes:
  aibex-aios: https://github.com/aibex-aios
projects:
  - repo: git@github.com:aibex-aios/x.git
    remote: aibex-aios
  - repo: file:///srv/aibex-aios/y.git
hubs:
  - aibex-aios
  - aibex-aios-test
packages:
  k: {hub: aibex-aios}'''))")"
   assert_eq "$OUT" $'remotes:\n  aibex-aibos: https://github.com/aibex-aibos\nprojects:\n  - repo: git@github.com:aibex-aibos/x.git\n    remote: aibex-aibos\n  - repo: file:///srv/aibex-aios/y.git\nhubs:\n  - aibex-aibos\n  - aibex-aios-test\npackages:\n  k: {hub: aibex-aibos}' \
      "rewrite: GitHub and hub names only (F281)"

#===============================================================================
# step 6b: a vault filled by 0.6.6 (V0.7, memos 40, 43: B50, B51): the marker .aios-deploy of a
# fetched package becomes .aibos-deploy and is read until 0.8; a project whose .aios/ holds only
# ignored files (registry) is committed without error, its .gitignore included
#===============================================================================

   W="$SANDBOX/work/§Alt66"; mkdir -p "$W/P-Gamma" "$W/P-Delta"
   at "$SANDBOX" "$HOME/.aios/bin/aios" --activate v0.6.6 "$W" --yes >/dev/null
   for P in P-Gamma P-Delta; do at "$W/$P" "$HOME/.aios/bin/aios" --init --yes >/dev/null; done
   [ -f "$W/P-Delta/.aios/registry" ] && [ -z "$(git -C "$W/P-Delta" ls-files .aios)" ] && ok || fail "P-Delta: .aios/ with only ignored files"
   K="$W/P-Gamma/@/@!Package/skill-x"; mk "$K/manifest.yaml" $'name: skill-x\nversion: 1.0.0\n'
   printf '# written by aios --fetch, do not edit\nname: skill-x\nversion: 1.0.0\nhub: aibex-aios\n' > "$K/.aios-deploy"
   G -C "$W/P-Gamma" add -A; G -C "$W/P-Gamma" commit -q -m "skill-x of 0.6.6"
   assert_eq "$(PY "$SANDBOX" "from aibos import deploy; from pathlib import Path; print(deploy.read_marker(Path('$K')).get('version'))")" "1.0.0" "the old marker is read (B50)"
   OUT="$(PY "$SANDBOX" "from aibos import changeover; from pathlib import Path
for p in ('P-Gamma', 'P-Delta'): changeover.change(Path('$W') / p, Path('$W'), '0.7.0')" 2>&1)"
   assert_not_contains "$OUT" "failed" "no failed commit (B51)"
   [ -f "$K/.aibos-deploy" ] && [ ! -e "$K/.aios-deploy" ] && ok || fail "marker renamed (B50)"
   assert_eq "$(git -C "$W/P-Gamma" status --porcelain)" "" "P-Gamma: renamed marker committed"
   assert_eq "$(git -C "$W/P-Gamma" ls-files "@/@!Package/skill-x")" $'@/@!Package/skill-x/.aibos-deploy\n@/@!Package/skill-x/manifest.yaml' "P-Gamma: only the new marker in git"
   assert_eq "$(git -C "$W/P-Delta" status --porcelain)" "" "P-Delta: nothing left uncommitted (B51)"
   assert_eq "$(git -C "$W/P-Delta" log -1 --format=%s)" "AIBOS: auf AIBOS v0.7 umgestellt" "P-Delta: one commit"
   assert_contains "$(git -C "$W/P-Delta" show --stat HEAD)" ".gitignore" "P-Delta: the .gitignore is in the commit"
   [ -f "$W/P-Delta/.aibos/registry" ] && ok || fail "P-Delta: registry moved into .aibos/"

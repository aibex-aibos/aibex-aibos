# t09-deploy.sh: step 5 of the plan v0.4 (V0.4, memos 18, 39) - aibos --deploy (deploy elements),

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac
# .aibos/registry, elements of fetched packages in the chain: skills, assistants, knowledge (K6),
# precedence (S6), not deployed elements (H3) (spec 02, 03, 06)

#===============================================================================
# setup: python3 with PyYAML, test hubs, vault §Demo with project G-Garten, packages fetched
#===============================================================================

   PYDIR=""
   for P in $(type -ap python3) /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
      [ -x "$P" ] && "$P" -c "import yaml" 2>/dev/null && { PYDIR="$(dirname "$P")"; break; }
   done
   [ -n "$PYDIR" ] && ok || fail "t09 needs a python3 with PyYAML (pip install pyyaml)"
   export PATH="$PYDIR:/usr/bin:/bin:/usr/sbin:/sbin"
   "$SRC/tests/hub/build" "$SANDBOX/hubs" >/dev/null
   export AIBOS_HUBS="aibex-aibos=file://$SANDBOX/hubs/aibex-aibos"
   D="$SANDBOX/work/§Demo"; G="$D/G-Garten"
   mk() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" > "$1"; }
   mk "$D/.aibos/config.yaml" $'aibos: 0.6.0\n'
   mkdir -p "$D/@" "$G/@"
   at() { (cd "$1" && shift && "$@" 2>&1); }
   A() { local d="$1"; shift; at "$d" "$SRC/bin/aibos" "$@"; }
   A "$D" --fetch app-taschenrechner --yes >/dev/null
   A "$D" --fetch knowledge-orion --yes >/dev/null
   A "$D" --fetch test-assistent --yes >/dev/null

#===============================================================================
# elements of fetched packages act in the chain: registration, knowledge, assistant
#===============================================================================

   at "$G" "$SRC/bin/aibos" --context --sync --yes >/dev/null
   assert_eq "$(ls "$G/.claude/skills" | grep -v -e '^aibos-' -e '^gui$' | tr '\n' ' ')" "memo taschenrechner taschenrechner-gui " "skills of the packages registered in a project below"
   assert_file "$G/.aibos/registry"
   assert_contains "$(cat "$G/.aibos/registry")" "source: \"$D/@/@!Package/app-taschenrechner/skills/taschenrechner\"" "registry: source in @!Package/"
   OUT="$(at "$G" "$SRC/bin/aibos" --context)"
   assert_contains "$OUT" "$D/@/@!Package/knowledge-orion/knowledge/@@Orion/Sterne.md — Die 20 hellsten Sterne des Orion" "K6: knowledge of a package available, path in @!Package/"
   [ "$(printf '%s' "$OUT" | grep -c 'Funktionstasten')" == "0" ] && ok || fail "K6: hidden knowledge of a package not in the context"
   assert_contains "$(at "$G" "$SRC/bin/aibos" --context --assistants)" "Testassistent 0.1.0" "assistant of a package in the chain"
   assert_contains "$(at "$G" "$SRC/bin/aibos" --context --assistants)" "(§Demo, package test-assistent)" "assistant: origin with package"
   assert_contains "$(at "$G" "$SRC/bin/aibos" --context --assistant test-assistent)" "Du bist der Testassistent des Test-Hubs." "assistant of a package resolved"

#===============================================================================
# aibos --deploy: show, --only, --all, checks
#===============================================================================

   OUT="$(A "$D" --deploy)"
   assert_contains "$OUT" "app-taschenrechner 0.5.0 (aibex-aibos) — all elements deployed" "show: all elements deployed after fetching (H2)"
   assert_contains "$OUT" "      deployed      knowledge" "show: knowledge as an element"
   assert_contains "$(A "$D" --deploy skill-memo==6.0.0)" "to fetch skill-memo==6.0.0 use: aibos --fetch skill-memo==6.0.0" "old form: hint to aibos --fetch"
   assert_contains "$(A "$D" --deploy skill-memo --only memo)" "only packages fetched for this project can be deployed in part (H4)" "dependency: always whole"
   assert_contains "$(A "$D" --deploy app-taschenrechner --only gibtsnicht)" "app-taschenrechner has no element gibtsnicht" "unknown element"
   assert_contains "$(A "$D" --deploy app-taschenrechner)" "usage: aibos --deploy" "neither --only nor --all"
   OUT="$(A "$D" --deploy app-taschenrechner --only taschenrechner-gui --plan)"
   assert_contains "$OUT" "packages: app-taschenrechner: {range: \"~=0.5.0\", only: [taschenrechner-gui]}" "plan: only: in packages:"
   A "$D" --deploy app-taschenrechner --only taschenrechner-gui --yes >/dev/null
   assert_contains "$(cat "$D/.aibos/config.yaml")" "app-taschenrechner: {range: \"~=0.5.0\", only: [taschenrechner-gui]}" "--only written"
   assert_contains "$(A "$D" --deploy)" "      not deployed  skill taschenrechner" "show: not deployed element"
   at "$G" "$SRC/bin/aibos" --context --sync --yes >/dev/null
   assert_eq "$(ls "$G/.claude/skills" | grep -v -e '^aibos-' -e '^gui$' | tr '\n' ' ')" "memo taschenrechner-gui " "H3: not deployed skill not registered"
   assert_contains "$(at "$G" "$SRC/bin/aibos" --context --list)" "fetched, not deployed: skill taschenrechner" "/aibos-context: fetched, not deployed"
   assert_contains "$(A "$D" --deploy app-taschenrechner --only taschenrechner-gui)" "nothing to do" "--only again: nothing to do (I8)"
   assert_contains "$(A "$D" --fetch)" "nothing to do" "fetch keeps the selection"
   A "$D" --deploy app-taschenrechner --all --yes >/dev/null
   assert_contains "$(cat "$D/.aibos/config.yaml")" 'app-taschenrechner: "~=0.5.0"' "--all: back to the range"
   A "$D" --deploy test-assistent --only test-assistent --yes >/dev/null
   OUT="$(at "$G" "$SRC/bin/aibos" --context --list)"                    # v0.5.1, O2
   assert_contains "$OUT" "(§Demo, package test-assistent)" "O2: assistant of a package under Hidden"
   assert_contains "$OUT" "1 assistant," "O2: counted under Hidden"
   mk "$G/.aibos/config.yaml" $'assistant: test-assistent\n'                 # v0.5.1, O5
   OUT="$(A "$D" --fetch --remove test-assistent --plan)"
   assert_contains "$OUT" "note: assistant: test-assistent in $G/.aibos/config.yaml then points nowhere; assign another one with /aibos-assistant" "O5: --remove names the assignment that points nowhere"
   mk "$G/@/@!Assistant/test-assistent/ASSISTANT.md" $'---\nname: test-assistent\nversion: 0.1.0\ndescription: lokal\n---\n\nLokal.\n'
   assert_not_contains "$(A "$D" --fetch --remove test-assistent --plan)" "points nowhere" "O5: not when a local blueprint stays"
   rm -rf "$G/@/@!Assistant" "$G/.aibos/config.yaml"
   sed -i.bak 's/knowledge-orion: "~=0.1.1"/knowledge-orion: {range: "~=0.1.1", only: [nichts]}/' "$D/.aibos/config.yaml"; rm "$D/.aibos/config.yaml.bak"
   OUT="$(at "$G" "$SRC/bin/aibos" --context)"
   [ "$(printf '%s' "$OUT" | grep -c 'Sterne.md')" == "0" ] && ok || fail "H3: knowledge not deployed, not in the context"
   sed -i.bak 's/knowledge-orion: {range: "~=0.1.0", only: \[nichts\]}/knowledge-orion: "~=0.1.0"/' "$D/.aibos/config.yaml"; rm "$D/.aibos/config.yaml.bak"

#===============================================================================
# precedence: local blueprint before the package in the same masterspace, nearest masterspace
#===============================================================================

   mk "$D/@/@!Skill/memo/SKILL.md" $'---\nname: memo\nversion: 9.0.0\ndescription: lokal\n---\n\n# Lokal\n'
   at "$G" "$SRC/bin/aibos" --context --sync --yes >/dev/null
   assert_contains "$(cat "$G/.claude/skills/memo/SKILL.md")" "# Lokal" "local blueprint before the package (S6)"
   assert_contains "$(at "$G" "$SRC/bin/aibos" --context --list)" "skill memo: covered by local blueprint (§Demo)" "/aibos-context reports the covering"
   mk "$G/@/@!Skill/memo/SKILL.md" $'---\nname: memo\nversion: 9.1.0\ndescription: Garten\n---\n\n# Garten\n'
   at "$G" "$SRC/bin/aibos" --context --sync --yes >/dev/null
   assert_contains "$(cat "$G/.claude/skills/memo/SKILL.md")" "# Garten" "nearest masterspace wins"

#===============================================================================
# .aibos/registry replaces .aibos/manifest of v0.3
#===============================================================================

   mv "$G/.aibos/registry" "$G/.aibos/manifest"
   OUT="$(at "$G" "$SRC/bin/aibos" --register --plan)"
   assert_contains "$OUT" "rename   .aibos/manifest -> .aibos/registry" "register: plan renames the manifest"
   at "$G" "$SRC/bin/aibos" --register --yes >/dev/null
   [ -f "$G/.aibos/registry" ] && [ ! -e "$G/.aibos/manifest" ] && ok || fail "manifest of v0.3 replaced by the registry"
   assert_eq "$(ls "$G/.claude/skills" | grep -v -e '^aibos-' -e '^gui$' | tr '\n' ' ')" "memo taschenrechner taschenrechner-gui " "skills of the old manifest stay managed"
   unset AIBOS_HUBS

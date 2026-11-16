# t13-gui.sh: step 8 of the plan (V0.3, memo 32) - surfaces: gui.yaml, aibos --gui, alias /gui, aibos-gui (spec 03, 04)

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# setup: a python with PyYAML (gui.yaml is read with PyYAML), vault with the demo Gärtner 0.2.0
#===============================================================================

   PYDIR=""
   for P in $(type -ap python3) /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
      [ -x "$P" ] && "$P" -c "import yaml" 2>/dev/null && { PYDIR="$(dirname "$P")"; break; }
   done
   [ -n "$PYDIR" ] && ok || fail "t13 needs a python3 with PyYAML (pip install pyyaml)"
   export PATH="$PYDIR:/usr/bin:/bin:/usr/sbin:/sbin"
   D="$SANDBOX/work/§Demo"; G="$D/Garten"
   mk() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" > "$1"; }
   mk "$D/.aibos/config.yaml" $'aibos: 0.6.0\n'
   mkdir -p "$D/@/@!Assistant" "$G/@/@!Assistant" "$D/Wiese/@"
   cp -R "$SRC/tests/hub/aibex-aibos/assistant-gaertner/0.3.0/assistants/gaertner" "$G/@/@!Assistant/gaertner"
   cp -R "$SRC/tests/hub/aibex-aibos/assistant-astronom/0.3.0/assistants/astronom" "$D/@/@!Assistant/astronom"
   at() { (cd "$1" && shift && "$@" 2>&1); }
   GUI() { local d="$1"; shift; at "$d" "$SRC/bin/aibos" --gui "$@"; }
   GG="$G/@/@!Assistant/gaertner/@!Skill/gaertner-gui"

#===============================================================================
# /gui: no assistant, assistant without surface, Gärtner with surface
#===============================================================================

   assert_eq "$(GUI "$G")" $'No assistant active.\nAIBOS surface: `/aibos-gui`' "no assignment: no assistant"
   mk "$D/.aibos/config.yaml" $'aibos: 0.6.0\nassistant: astronom\n'
   assert_eq "$(GUI "$D/Wiese")" $'The assistant Astronom has no surface.\nAIBOS surface: `/aibos-gui`' "assistant without gui"
   mk "$G/.aibos/config.yaml" $'assistant: gaertner\n'
   OUT="$(GUI "$G")"
   assert_contains "$OUT" "# Oberfläche des Gärtners" "body of the surface skill"
   case "$OUT" in *"version: 0.1.0"*|*"name: gaertner-gui"*) fail "body without frontmatter" ;; *) ok ;; esac
   assert_contains "$OUT" "## Show the surface" "instruction appended"
   assert_contains "$OUT" "run \`aibos --gui --html\` and show" "instruction: HTML in the desktop app"
   assert_contains "$OUT" "at most 4 entries per level" "instruction: menu otherwise"
   assert_contains "$OUT" "- Apfel-Birnen-Rechner — Rechnet mit Äpfeln und Birnen, ohne Claude (HTML part rechner.html)" "tile with HTML part"
   assert_contains "$OUT" "- Aufgabe rechnen — Eine Apfel-Birnen-Aufgabe mit Rechenweg (sends: Run the skill /apfel-birnen-algebra.)" "skill tile sends /<skill>"
   assert_contains "$OUT" "(sends: Hilf mir, eine Apfelsorte zu bestimmen. Frag mich nach den Merkmalen.)" "prompt tile"

#===============================================================================
# --html: fragment with buttons (sendPrompt) and embedded HTML parts
#===============================================================================

   OUT="$(GUI "$G" --html)"
   case "$OUT" in "<div class=\"aibos-gui\">"*) ok ;; *) fail "--html: fragment" ;; esac
   case "$OUT" in *"<html"*|*"<head"*|*"<body"*) fail "--html: no html, head, body" ;; *) ok ;; esac
   assert_contains "$OUT" "<h2>Gärtner</h2>" "--html: title"
   assert_contains "$OUT" "<p>Was möchtest du heute im Garten wissen?</p>" "--html: intro"
   assert_contains "$OUT" 'data-prompt="Run the skill /apfel-birnen-algebra."' "--html: skill tile sends a sentence (the app drops messages starting with /)"
   case "$OUT" in *'data-prompt="/'*) fail "--html: no data-prompt starting with /" ;; *) ok ;; esac
   assert_contains "$OUT" 'data-prompt="Hilf mir, eine Apfelsorte zu bestimmen. Frag mich nach den Merkmalen."' "--html: prompt tile"
   assert_contains "$OUT" 'data-part="aibos-part-1"' "--html: HTML tile jumps to its part"
   assert_contains "$OUT" 'sendPrompt(b.dataset.prompt)' "--html: one script connects the tiles (sendPrompt)"
   case "$OUT" in *onclick*) fail "--html: no inline handlers (hosts drop them)" ;; *) ok ;; esac
   assert_eq "$(printf '%s\n' "$OUT" | python3 -c '
import sys, re
t = sys.stdin.read()
inner = t[:t.rindex("</div>")]                      # everything up to the end of the container
print(len(re.findall("<script", inner)), len(re.findall("<script", t)))')" "0 2" "--html: no script inside the container, part script and tile script at top level"
   assert_contains "$OUT" '<section class="part" id="aibos-part-1"><h3>Apfel-Birnen-Rechner</h3>' "--html: HTML part embedded"
   assert_contains "$OUT" 'id="abr-out"' "--html: content of rechner.html"

#===============================================================================
# assistant of the session from the marker, switching without registration
#===============================================================================

   mkdir -p "$HOME/.aibos/sessions"
   printf '# written by AIBOS (session), do not edit\ncwd: "%s"\nassistant: astronom\nused: 2026-10-03T10:00:00\n' "$G" > "$HOME/.aibos/sessions/s1.yaml"
   assert_contains "$(GUI "$G" --session s1)" "The assistant Astronom has no surface." "--session: assistant of the session"
   assert_contains "$(GUI "$G" --session s2)" "# Oberfläche des Gärtners" "--session without marker: assignment"
   assert_contains "$(GUI "$G" --session ../x)" "is not a session id" "--session: bad id"
   assert_contains "$(GUI "$G" --session s2)" "\`aibos --gui --session s2 --html\`" "instruction keeps --session"

#===============================================================================
# /aibos-gui: the surface of AIBOS with its 7 tiles
#===============================================================================

   OUT="$(GUI "$G" --aibos)"
   assert_contains "$OUT" "# AIbex AIBOS" "--aibos: title"
   for T in "Projekt initialisieren" "Kontext und Konfiguration" "Assistent zuordnen" "Pakete" "Apps" "Pakete abgleichen und Skills registrieren" "Integrität prüfen" "Projektstatus" "Memo schreiben"; do
      assert_contains "$OUT" "- $T — " "--aibos: tile $T"
   done
   assert_eq "$(printf '%s\n' "$OUT" | grep -c '^- .*(sends: ')" "9" "--aibos: 9 tiles"
   assert_contains "$OUT" "(sends: Run the skill /aibos-init.)" "--aibos: /aibos-init"
   assert_contains "$OUT" "(sends: Run the skill /aibos-integrity.)" "--aibos: /aibos-integrity"
   assert_contains "$OUT" "\`aibos --gui --aibos --html\`" "--aibos: instruction for HTML"
   case "$(GUI "$SANDBOX" --aibos --html)" in "<div class=\"aibos-gui\">"*"<h2>AIbex AIBOS</h2>"*) ok ;; *) fail "--aibos --html outside a vault" ;; esac
   assert_contains "$(at "$G" "$SRC/bin/aibos" --skill aibos-gui)" "Führe \`$HOME/.aibos/bin/aibos --gui --aibos\` über das Bash-Werkzeug aus." "skill aibos-gui calls aibos --gui --aibos"

#===============================================================================
# checks of gui.yaml and of the assistant
#===============================================================================

   CHK() { PYTHONPATH="$SRC/lib" python3 -c "
import sys, yaml
from pathlib import Path
from aibos import gui
print('|'.join(gui.check(yaml.safe_load(sys.argv[1]), Path('$GG'))))" "$1"; }
   assert_eq "$(CHK $'title: T\ntiles:\n  - title: A\n    prompt: p\n')" "" "valid description"
   assert_contains "$(CHK $'tiles:\n  - title: A\n    prompt: p\n')" "title is missing" "title required"
   assert_contains "$(CHK $'title: T\ntiles: []\n')" "tiles must be a list of 1 to 12 tiles" "at least one tile"
   assert_contains "$(CHK "$(printf 'title: T\ntiles:\n'; for i in $(seq 13); do printf '  - title: A%s\n    prompt: p\n' "$i"; done)")" "1 to 12" "at most 12 tiles"
   assert_contains "$(CHK $'title: T\ntiles:\n  - title: A\n    prompt: p\n    skill: s\n')" "tile 1: exactly one of prompt, skill, html" "exactly one action"
   assert_contains "$(CHK $'title: T\ntiles:\n  - title: A\n    html: fehlt.html\n')" "tile 1: HTML part fehlt.html not found" "HTML part must exist"
   assert_contains "$(CHK $'title: T\ncolor: red\ntiles:\n  - title: A\n    prompt: p\n')" "unknown key color" "unknown key"
   printf 'title: [kaputt\n' > "$GG/gui.yaml"
   assert_contains "$(GUI "$G")" "*** aibos --gui: $GG/gui.yaml" "broken gui.yaml: error"
   assert_exit 1 bash -c "cd '$G' && '$SRC/bin/aibos' --gui"
   cp "$SRC/tests/hub/aibex-aibos/assistant-gaertner/0.3.0/assistants/gaertner/@!Skill/gaertner-gui/gui.yaml" "$GG/gui.yaml"
   sed -i.bak 's/^skills: .*/skills: [apfel-birnen-algebra]/' "$G/@/@!Assistant/gaertner/ASSISTANT.md"
   assert_contains "$(GUI "$G")" "gui gaertner-gui of the assistant gaertner is not in its skills" "gui must be in skills"
   assert_contains "$(at "$G" "$SRC/bin/aibos" --context --assistant gaertner)" "gui gaertner-gui of the assistant gaertner is not in its skills" "aibos --context --assistant reports it"
   mv "$G/@/@!Assistant/gaertner/ASSISTANT.md.bak" "$G/@/@!Assistant/gaertner/ASSISTANT.md"
   assert_contains "$(at "$G" "$SRC/bin/aibos" --context --assistant gaertner)" "gui: gaertner-gui" "meta block names the gui"

#===============================================================================
# reserved name gui, alias /gui in --install and --uninstall
#===============================================================================

   mk "$D/@/@!Skill/gui/SKILL.md" $'---\nname: gui\nversion: 0.1.0\ndescription: d\n---\n'
   assert_contains "$(at "$G" "$SRC/bin/aibos" --context --sync --plan)" "the name gui is reserved for the alias /gui, not registered" "blueprint gui: not registered"
   rm -rf "$D/@/@!Skill/gui"
   AL() { PYTHONPATH="$SRC/lib" python3 -c "
from aibos import install, ui
plan = ui.Plan(); install.plan_alias(plan); plan.run(); print(len(plan.steps))" 2>&1; }
   AL >/dev/null
   A="$AIBOS_CLAUDE_DIR/skills/gui/SKILL.md"
   assert_contains "$(cat "$A")" '!`aios --gui --session ${CLAUDE_SESSION_ID}`' "alias written"
   assert_contains "$(cat "$A")" "allowed-tools: Bash(aios --gui *), Bash(aios --context *)" "alias: allowed-tools"
   assert_eq "$(AL)" "0" "alias unchanged: nothing to do"
   printf -- '---\nname: gui\n---\neigener Skill\n' > "$A"
   assert_contains "$(AL)" "was not written by AIBOS, left untouched" "foreign gui folder: warning"
   assert_eq "$(cat "$A")" $'---\nname: gui\n---\neigener Skill' "foreign gui folder: not overwritten"
   rm -rf "$AIBOS_CLAUDE_DIR/skills/gui"; AL >/dev/null
   mkdir -p "$HOME/.aibos/sessions"; touch "$HOME/.aibos/sessions/x.yaml"
   PYTHONPATH="$SRC/lib" python3 -c "from aibos import install, ui; ui.MODE = 'yes'; install.uninstall()" >/dev/null 2>&1
   [ ! -e "$AIBOS_CLAUDE_DIR/skills/gui" ] && ok || fail "uninstall: alias removed"
   [ ! -e "$HOME/.aibos/sessions" ] && ok || fail "uninstall: markers of the sessions removed"

#===============================================================================
# v0.4 step 1: A10 - hint under the HTML surface, menu as fallback
#===============================================================================

   OUT="$(GUI "$SANDBOX" --aibos --html)"
   assert_contains "$OUT" "If a tile only fills the input field, press Enter." "html: hint under the tiles (A10)"
   OUT="$(GUI "$SANDBOX" --aibos)"
   assert_contains "$OUT" "offer the same tiles as the menu below" "instruction: menu as fallback (A10)"

#===============================================================================
# v0.4 step 9: surface of an app, placeholders with the data of the app, --apps
#===============================================================================

   "$SRC/tests/hub/build" "$SANDBOX/hubs" >/dev/null
   export AIBOS_HUBS="aibex-aibos=file://$SANDBOX/hubs/aibex-aibos"
   W="$SANDBOX/work/§Apps"; mkdir -p "$W/@" "$W/.aibos"; printf 'aibos: 0.6.0\n' > "$W/.aibos/config.yaml"
   assert_contains "$(at "$W" "$SRC/bin/aibos" --gui --apps)" "No apps in this project." "--apps: none yet"
   at "$W" "$SRC/bin/aibos" --fetch app-taschenrechner --yes >/dev/null
   assert_contains "$(at "$W" "$SRC/bin/aibos" --gui --apps)" "- /taschenrechner-gui — app-taschenrechner 0.5.0" "--apps: the app with its surface"
   assert_contains "$(at "$W" "$SRC/bin/aibos" --gui --skill taschenrechner-gui)" "run \`aibos --gui --skill taschenrechner-gui --html\`" "--skill: instruction"
   assert_contains "$(at "$W" "$SRC/bin/aibos" --gui --skill taschenrechner-gui --html)" "var saved = null;" "placeholder without data: null"
   assert_contains "$(at "$W" "$SRC/bin/aibos" --gui --skill taschenrechner-gui --html)" "Gespeichert wird im Chat. Kommt dort keine Nachricht an, schreib:" "hint after assigning a function key (B4)"
   mkdir -p "$W/@Data/app-taschenrechner"; printf 'A:\n  title: Quadrat\n  keys: ["ENTER", "×"]\n' > "$W/@Data/app-taschenrechner/funktionstasten.yaml"
   assert_contains "$(at "$W" "$SRC/bin/aibos" --gui --skill taschenrechner-gui --html)" 'var saved = {"A": {"title": "Quadrat", "keys": ["ENTER", "×"]}};' "placeholder: funktionstasten.yaml as JSON"
   assert_contains "$(at "$W" "$SRC/bin/aibos" --gui --skill gibtsnicht)" "no deployed app with the surface gibtsnicht" "--skill: unknown surface"
   unset AIBOS_HUBS

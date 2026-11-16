# t08-skills.sh: step 8 of the plan (memo 18) - aibos --skill, wrappers, --list, aibos --init, --plan/--yes

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# setup: two installations (copies of the clone) with different skill bodies, forwarder
#===============================================================================

   mkdir -p "$HOME/bin"
   export PATH="$HOME/bin:/usr/bin:/bin:/usr/sbin:/sbin"
   export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
   cp "$SRC/templates/forwarder" "$HOME/bin/aibos"; chmod +x "$HOME/bin/aibos"
   for V in 0.6.0 0.7.0; do
      I="$AIBOS_PREFIX/v$V"; mkdir -p "$I"
      cp -R "$SRC/bin" "$SRC/lib" "$SRC/skills" "$SRC/templates" "$I/"
      echo "$V" > "$I/VERSION"
      echo "v$V: $I" >> "$AIBOS_PREFIX/installations.yaml"
   done
   printf '\nNur in Version 0.7.0.\n' >> "$AIBOS_PREFIX/v0.7.0/skills/aibos/aibos-init/SKILL.md"

   D="$SANDBOX/work/§Demo"
   mk() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" > "$1"; }
   skill() { mk "$1/SKILL.md" "$(printf -- '---\nname: %s\ndescription: d\n%s---\n\n# %s\n' "$2" "${3:+version: $3
}" "$2")"; }
   mk "$D/.aibos/config.yaml" $'aibos: 0.6.0\n'
   mk "$D/@/@Rule/stil.md" $'# Stil\nklar\n'
   mk "$D/@/@@Buch/kapitel.md" $'# Kapitel\n'
   skill "$D/@/@!Skill/memo" memo 6.0.0
   skill "$D/@/@!Skill/notiz" notiz 0.1.0
   mk "$D/@/@!Prompt/obstgaertner.md" $'# Prompt\n'
   mk "$D/@/@!Assistant/obstgaertner/ASSISTANT.md" $'---\nname: obstgaertner\nversion: 0.1.0\n---\n'
   skill "$D/@/@!Assistant/obstgaertner/@!Skill/apfel" apfel 0.1.0
   mk "$D/Garten/@/garten.md" $'# Garten\n'
   mk "$D/Garten/.aibos/config.yaml" $'aibos: 0.7.0\n'
   mkdir -p "$SANDBOX/work/§Alt/.aibos" "$D/Wiese" "$D/Garten/Beet" "$SANDBOX/work/§Alt/Feld" "$SANDBOX/outside"; printf 'legacy: ai-brain\n' > "$SANDBOX/work/§Alt/.aibos/config.yaml"
   at() { (cd "$1" && shift && "$@" 2>&1); }

#===============================================================================
# aibos --skill: body without frontmatter, from the version valid for cwd
#===============================================================================

   assert_eq "$(at "$D" aibos --skill aibos-init)" "$(python3 -c "
import sys; t=open(sys.argv[1],encoding='utf-8').read(); e=t.find('\n---',3); print(t[t.find('\n',e+4)+1:].lstrip('\n').replace(chr(96)+'aibos ', chr(96)+sys.argv[2]+' '),end='')" "$SRC/skills/aibos/aibos-init/SKILL.md" "$HOME/.aibos/bin/aibos")" "--skill: body without frontmatter, forwarder with absolute path (F42)"
   case "$(at "$D" aibos --skill aibos-init)" in *"name: aibos-init"*|*"allowed-tools"*) fail "--skill: no frontmatter" ;; *) ok ;; esac
   case "$(at "$D" aibos --skill aibos-init)" in *"Nur in Version 0.7.0"*) fail "--skill in §Demo: version 0.6.0" ;; *) ok ;; esac
   assert_not_contains "$(at "$D/Garten" aibos --skill aibos-init)" "Nur in Version 0.7.0" "--skill in Garten: the vault root decides (I14)"
   for S in aibos-context aibos-init aibos-register aibos-status aibos-deploy aibos-assistant aibos-integrity aibos-memo aibos-gui aibos-fetch aibos-package aibos-distribution aibos-attach aibos-sync aibos-detach aibos-restore; do
      assert_contains "$(at "$D" aibos --skill "$S")" "Ein AIBOS-Skill von AIbex AIBOS" "--skill $S"
   done
   assert_exit 1 "$SRC/bin/aibos" --skill aibos-nope
   assert_exit 1 "$SRC/bin/aibos" --skill aibos-agent
   assert_eq "$(ls "$SRC/skills/aibos" | tr '\n' ' ')" "aibos-assistant aibos-attach aibos-context aibos-deploy aibos-detach aibos-distribution aibos-fetch aibos-gui aibos-init aibos-integrity aibos-memo aibos-package aibos-register aibos-restore aibos-status aibos-sync " "AIBOS skills of v0.6.4 (with aibos-attach, aibos-detach, aibos-restore, aibos-sync)"
   FM() { sed -n '/^allowed-tools:/p' "$SRC/skills/aibos/$1/SKILL.md"; }
   assert_eq "$(FM aibos-distribution)" "allowed-tools: Bash(aibos --library *), Bash(aibos --install * --plan), Bash(aibos --context *), Bash(git -C *), Bash(mkdir -p *), Write" "aibos-distribution: allowed-tools (N16)"
   assert_contains "$(FM aibos-package)" "Bash(aibos --install distribution-*)" "aibos-package: may install distributions"
   B="$(at "$D" aibos --skill aibos-distribution)"
   assert_contains "$B" 'aibos --install distribution-<name> "<scratchpad>/§Probe-<name>" --from "<entwurf>" --plan' "aibos-distribution: check with the resolver"
   assert_contains "$B" "tag v<version>\` (lokal, nicht gepusht)" "aibos-distribution: local tag"
   assert_contains "$(at "$D" aibos --skill aibos-package)" "## Distribution installieren" "aibos-package: recognizes distributions"
   assert_not_contains "$(at "$D" aibos --skill aibos-fetch)" "<paket>/<name> install" "aibos-fetch: no workers of v0.4 any more"

#===============================================================================
# wrapper: name, description and allowed-tools from the version, body from aibos --skill
#===============================================================================

   W="$(PYTHONPATH="$SRC/lib" python3 -c "
from aibos import install
from pathlib import Path
m = install.frontmatter(Path('$SRC/skills/aibos/aibos-context/SKILL.md'))
print(install.wrapper('aibos-context', m['description'], m.get('allowed-tools', '')), end='')")"
   assert_contains "$W" $'---\nname: aibos-context\ndescription: "Prüft, ob der Master-Kontext' "wrapper: name and description"
   assert_contains "$W" "allowed-tools: Bash(aibos --skill *), Bash(aibos --context *), Read" "wrapper: allowed-tools"
   assert_contains "$W" $'---\n\n!`aibos --skill aibos-context`' "wrapper: body"

#===============================================================================
# aibos --context --list: listing for /aibos-context
#===============================================================================

   at "$D" "$SRC/bin/aibos" --context --sync --yes >/dev/null
   rm -rf "$D/.claude/skills/notiz"
   OUT="$("$SRC/bin/aibos" --context --list "$D")"
   ID="$("$SRC/bin/aibos" --context --id "$D" | sed 's/^id=\([^ ]*\).*/\1/')"
   CH="$("$SRC/bin/aibos" --context "$D" | python3 -c 'import sys; print(f"{len(sys.stdin.read()):,}")')"
   assert_eq "$OUT" "Master context id $ID, AIBOS $(cat "$SRC/VERSION") — §Demo

Chain                      §Demo
Assistant                  none (no assignment)

Master context (loaded)    1 file, $CH characters
  §Demo/@/@Rule/stil.md
Available knowledge        1 file (not loaded, table of contents in the master context)
  §Demo/@/@@Buch/kapitel.md
Hidden                     Blueprints: 3 skills, 1 assistant, 1 prompt
  Skills       memo 6.0.0 (§Demo) — registered
               notiz 0.1.0 (§Demo) — not registered
               apfel 0.1.0 (assistant obstgaertner, private)
  Assistants   obstgaertner 0.1.0 (§Demo)
  Prompts      obstgaertner (§Demo)
Note: blueprints and registered skills differ — /aibos-register" "--list: exact listing"
   assert_contains "$("$SRC/bin/aibos" --context --list "$D/Garten")" "Chain                      §Demo → Garten" "--list: chain"
   assert_contains "$("$SRC/bin/aibos" --context --list "$D/Wiese")" "Wiese (not initialized, chain up to §Demo)" "--list: not initialized"
   assert_eq "$("$SRC/bin/aibos" --context --list "$SANDBOX/work/§Alt")" "Legacy mode (ai-brain, no aibos: in the chain) — see /masterspace." "--list: legacy"
   assert_eq "$("$SRC/bin/aibos" --context --list "$SANDBOX/outside")" "No vault — no master context." "--list: outside a vault"
   printf 'aibos: 0.6.0\nassistant: obstgaertner\n' > "$D/.aibos/config.yaml"
   assert_contains "$("$SRC/bin/aibos" --context --list "$D")" "Assistant                  obstgaertner 0.1.0 (assigned in §Demo)" "--list: own assignment"
   assert_contains "$("$SRC/bin/aibos" --context --list "$D/Garten")" "Assistant                  obstgaertner 0.1.0 (inherit, assigned in §Demo)" "--list: inherited assignment"
   printf 'aibos: 0.6.0\nassistant: astronom\n' > "$D/.aibos/config.yaml"
   assert_contains "$("$SRC/bin/aibos" --context --list "$D")" "Assistant                  astronom (not found) (assigned in §Demo)" "--list: assistant not found"
   printf 'aibos: 0.6.0\n' > "$D/.aibos/config.yaml"

#===============================================================================
# aibos --skill --session: the id replaces <session-id>; wrapper: id as a line of text (version-neutral)
#===============================================================================

   assert_contains "$(at "$D" aibos --skill aibos-assistant --session abc-123)" "--yes --session abc-123" "--skill --session: id in the body"
   case "$(at "$D" aibos --skill aibos-assistant --session abc-123)" in *'<session-id>'*) fail "--skill --session: no placeholder left" ;; *) ok ;; esac
   assert_contains "$(at "$D" aibos --skill aibos-assistant)" '<session-id>' "--skill without --session: placeholder stays"
   assert_contains "$(at "$D" aibos --skill aibos-assistant)" 'Zeile *Session-ID dieses Chats* am Ende dieser Anweisung' "body points to the line of the wrapper"
   assert_contains "$(at "$D" aibos --skill aibos-assistant --session ../x)" "is not a session id" "--skill --session: bad id"
   W="$(AIBOS_CLAUDE_DIR="$SANDBOX/claude" PYTHONPATH="$SRC/lib" python3 -c "
from pathlib import Path
from aibos import install
from aibos.ui import Plan
d = Path('$SANDBOX/claude')
plan = Plan(); install.plan_skills(plan, Path('$SRC')); plan.run()
for n in ('aibos-assistant', 'aibos-context', 'aibos-init'):
    print('==', n); print((d / 'skills' / n / 'SKILL.md').read_text())")"
   WA="$(printf '%s\n' "$W" | sed -n '/^== aibos-assistant/,/^== aibos-context/p')"
   WI="$(printf '%s\n' "$W" | sed -n '/^== aibos-init/,$p')"
   assert_contains "$WA" '!`aibos --skill aibos-assistant`' "wrapper calls only aibos --skill <name> (every version understands it)"
   assert_contains "$WA" 'Session-ID dieses Chats: `${CLAUDE_SESSION_ID}`' "wrapper: session id as a line of text"
   case "$W" in *"--skill aibos-assistant --session"*|*"--skill aibos --context --session"*) fail "wrapper: no --session flag (v0.2 does not know it)" ;; *) ok ;; esac
   assert_contains "$(printf '%s\n' "$W" | sed -n '/^== aibos-context/,/^== aibos-init/p')" 'Session-ID dieses Chats' "wrapper of aibos-context with the session line"
   case "$WI" in *"Session-ID"*) fail "wrapper without session id stays plain" ;; *) ok ;; esac

#===============================================================================
# --plan and --yes on writing commands (for skills)
#===============================================================================

   OUT="$("$SRC/bin/aibos" --activate v0.6.0 "$D/Garten/Beet" --plan 2>&1)"; RC=$?
   assert_contains "$OUT" "is not a vault root" "--plan: checks still apply (only the vault root, V0.6)"
   OUT="$("$SRC/bin/aibos" --register "$D" --plan 2>&1)"; RC=$?
   assert_eq "$RC" "0" "--plan: exit 0"
   assert_contains "$OUT" "(plan only, nothing written)" "--plan: plan only"
   [ ! -e "$D/.claude/skills/notiz" ] && ok || fail "--plan: nothing written"
   assert_contains "$(at "$D" "$SRC/bin/aibos" --context --sync --plan)" "changed  notiz" "aibos --context --sync --plan (copy deleted: changed)"
   [ ! -e "$D/.claude/skills/notiz" ] && ok || fail "--sync --plan: nothing written"
   "$SRC/bin/aibos" --register "$D" --yes </dev/null >/dev/null 2>&1
   assert_file "$D/.claude/skills/notiz/SKILL.md"

#===============================================================================
# aibos --init: checks, plan, name rule, project with git and first commit (spec 05)
#===============================================================================

   assert_contains "$("$SRC/bin/aibos" --init "$SANDBOX/outside" 2>&1)" "is not in a vault" "init: outside a vault"
   assert_contains "$("$SRC/bin/aibos" --init "$SANDBOX/work/§Alt/Feld" 2>&1)" "is not activated" "init: legacy vault"
   OUT="$("$SRC/bin/aibos" --init "$D" --plan 2>&1)"
   assert_contains "$OUT" "the project $D" "init: vault root allowed"
   case "$OUT" in *"name "*) fail "init: vault root exempt from the name rule" ;; *) ok ;; esac
   assert_contains "$("$SRC/bin/aibos" --init "$D/Garten" --plan 2>&1)" "git init (branch main)" "init: existing project is completed"

   OUT="$(at "$D/Wiese" "$SRC/bin/aibos" --init --plan)"; RC=$?
   assert_eq "$RC" "0" "init --plan: exit 0"
   assert_contains "$OUT" "name Wiese: the name has no prefix" "init plan: name rule"
   assert_contains "$OUT" "proposal: W-Wiese" "init plan: proposal"
   assert_contains "$OUT" "create @/ (with .gitkeep)" "init plan: masterspace"
   assert_contains "$OUT" ".gitignore: .DS_Store, .claude/skills/, .claude/worktrees/, .agents/, .aibos/registry, .aibos/backup/, .aibos/workspace.local.yaml, @Secret/" "init plan: gitignore"
   assert_contains "$OUT" "git init (branch main)" "init plan: git init"
   [ ! -e "$D/Wiese/@" ] && [ ! -e "$D/Wiese/.git" ] && ok || fail "init --plan: nothing written"
   OUT="$(at "$D/Wiese" "$SRC/bin/aibos" --init --yes)"; RC=$?
   assert_eq "$RC" "2" "init --yes with a name violation: exit 2"
   assert_contains "$OUT" "run again with --name <name> (proposal) or --accept-name" "violation: hint"
   [ ! -e "$D/Wiese/@" ] && ok || fail "violation: nothing written"

   printf 'eigen.txt\n.DS_Store\n' > "$D/Wiese/.gitignore"
   OUT="$(at "$D/Wiese" "$SRC/bin/aibos" --init --accept-name --yes)"; RC=$?
   assert_eq "$RC" "0" "init --accept-name --yes: exit 0"
   assert_eq "$OUT" "=> $D/Wiese is a project" "init --yes: only the result"
   assert_file "$D/Wiese/@/.gitkeep"
   [ ! -e "$D/Wiese/@Memo" ] && ok || fail "init: no @Memo/ (spec 05)"
   assert_eq "$(cat "$D/Wiese/.gitignore")" "$(printf 'eigen.txt\n.DS_Store\n.claude/skills/\n.claude/worktrees/\n.agents/\n.aibos/registry\n.aibos/backup/\n.aibos/workspace.local.yaml\n@Secret/')" "init: .gitignore completed, own lines kept"
   assert_eq "$(git -C "$D/Wiese" symbolic-ref --short HEAD)" "main" "init: branch main"
   assert_eq "$(git -C "$D/Wiese" log --format=%s)" "AIBOS: Projekt initialisiert" "init: first commit"
   assert_eq "$(git -C "$D/Wiese" show --name-only --format= | sort | tr '\n' ' ')" ".gitignore @/.gitkeep " "init: committed files"
   assert_file "$D/Wiese/.claude/skills/memo/SKILL.md"
   assert_eq "$(git -C "$D/Wiese" status --porcelain)" "" "init: working tree clean (build output ignored)"
   assert_eq "$(at "$D/Wiese" "$SRC/bin/aibos" --init --accept-name </dev/null)" "=> $D/Wiese is a complete project, nothing to do" "init again: nothing to do"

   OUT="$(at "$D" sh -c "echo y | '$SRC/bin/aibos' --init '$D/W2-Weide' --accept-name")"
   assert_contains "$OUT" "create the folder $D/W2-Weide" "init: folder created"
   assert_contains "$OUT" "from the next chat" "init: hint next chat without --yes"
   assert_dir "$D/W2-Weide/@"

   OUT="$("$SRC/bin/aibos" --init "$D/wiese drei" --name W-Wiese-Drei --plan 2>&1)"
   assert_contains "$OUT" "create the folder $D/W-Wiese-Drei" "--name: folder under the new name"
   case "$OUT" in *"name W-"*) fail "--name: conforming name, no violation" ;; *) ok ;; esac
   mkdir -p "$D/feld vier"
   "$SRC/bin/aibos" --init "$D/feld vier" --name F-Feld-Vier --yes >/dev/null 2>&1
   [ -d "$D/F-Feld-Vier/@" ] && [ ! -e "$D/feld vier" ] && ok || fail "--name: existing folder renamed"
   assert_contains "$("$SRC/bin/aibos" --init "$D/A-Acker" --assistant Bad_Name --plan 2>&1)" "is not an assistant name" "--assistant: name checked"
   "$SRC/bin/aibos" --init "$D/A-Acker" --assistant gaertner --yes >/dev/null 2>&1
   assert_eq "$(cat "$D/A-Acker/.aibos/config.yaml")" "assistant: gaertner" "--assistant written"
   assert_eq "$(git -C "$D/A-Acker" show --name-only --format= | sort | tr '\n' ' ')" ".aibos/config.yaml .gitignore @/.gitkeep " "--assistant: config committed"

#===============================================================================
# aibos --init and the repo above (S4): exclusion, git rm --cached, commit there
#===============================================================================

   git -C "$D" init -q
   printf '.DS_Store\n' > "$D/.gitignore"
   mkdir -p "$D/G-Garten/B-Beet/@"; printf '# Beet\n' > "$D/G-Garten/B-Beet/@/beet.md"
   git -C "$D" add .gitignore G-Garten && git -C "$D" commit -qm vorher
   OUT="$("$SRC/bin/aibos" --init "$D/G-Garten/B-Beet" --accept-name --plan 2>&1)"
   assert_contains "$OUT" "repo above $D: /G-Garten/B-Beet/ in $D/.gitignore; git rm -r --cached G-Garten/B-Beet (1 files" "init plan: exclusion in the repo above"
   "$SRC/bin/aibos" --init "$D/G-Garten/B-Beet" --accept-name --yes >/dev/null 2>&1
   assert_eq "$(git -C "$D" log -1 --format=%s)" "AIBOS: G-Garten/B-Beet als eigenes Projekt ausgeschlossen" "commit in the repo above"
   assert_eq "$(git -C "$D" ls-files G-Garten)" "" "repo above: files no longer tracked"
   assert_file "$D/G-Garten/B-Beet/@/beet.md"
   assert_eq "$(git -C "$D" status --porcelain -- G-Garten .gitignore)" "" "repo above: exclusion committed, subproject not shown"
   assert_eq "$(git -C "$D/G-Garten/B-Beet" log --format=%s)" "AIBOS: Projekt initialisiert" "own repo of the subproject"
   assert_eq "$(git -C "$D/G-Garten/B-Beet" ls-files @/beet.md)" "@/beet.md" "files taken over from the repo above are committed (A14)"
   assert_eq "$(git -C "$D/G-Garten/B-Beet" status --porcelain)" "" "subproject: nothing left uncommitted (A14)"
   rm "$D/G-Garten/B-Beet/.gitignore"
   OUT="$("$SRC/bin/aibos" --init "$D/G-Garten/B-Beet" --accept-name --yes 2>&1)"
   assert_not_contains "$OUT" "commit failed" "restored .gitignore with the same content: no false warning (A16)"
   assert_eq "$(git -C "$D/G-Garten/B-Beet" log --format=%s | wc -l | tr -d ' ')" "1" "restored .gitignore: no new commit (A16)"
   mkdir -p "$D/F-Fall"
   "$SRC/bin/aibos" --init "$D/F-Fall" --name F-FALL --yes >/dev/null 2>&1
   assert_eq "$(ls "$D" | grep -x 'F-F[Aa][Ll][Ll]')" "F-FALL" "rename only in the case of the name (A13)"
   assert_dir "$D/F-FALL/@"
   mkdir -p "$D/H-Hof"; printf 'x\n' > "$D/notiz.txt"; git -C "$D" add notiz.txt
   "$SRC/bin/aibos" --init "$D/H-Hof" --yes >"$SANDBOX/hof.out" 2>&1
   assert_contains "$(cat "$SANDBOX/hof.out")" "has staged changes; commit the exclusion there by hand" "staged changes above: no commit there"
   assert_contains "$(cat "$D/.gitignore")" "/H-Hof/" "exclusion written anyway"

#===============================================================================
# v0.3 step 7: /aibos-memo - body of memo==6.0.0, precedence of a registered memo
#===============================================================================

   MEMO_BODY="$(python3 -c "
import sys; t=open(sys.argv[1],encoding='utf-8').read(); e=t.find('\n---',3); print(t[t.find('\n',e+4)+1:].lstrip('\n'),end='')" "$SRC/tests/hub/aibex-aibos/skill-memo/6.0.0/skills/memo/SKILL.md")"
   assert_contains "$(head -5 "$SRC/tests/hub/aibex-aibos/skill-memo/6.0.0/skills/memo/SKILL.md")" "version: 6.0.0" "package skill-memo 6.0.0 (aibos-memo carries its body)"
   mkdir -p "$D/Notiz/@"
   OUT="$(at "$D/Notiz" aibos --skill aibos-memo)"
   case "$OUT" in *"$MEMO_BODY"*) ok ;; *) fail "aibos-memo: body of memo==6.0.0" ;; esac
   assert_contains "$OUT" "Fehlt \`@Memo/\` im Projekt, lege ihn beim ersten Memo an." "aibos-memo: creates @Memo/"
   assert_contains "$(sed -n 1,10p "$SRC/skills/aibos/aibos-memo/SKILL.md")" 'Nur verwenden, wenn kein Skill `memo` verfügbar ist.' "aibos-memo: description defers to memo"
   mk "$D/Notiz/.aibos/registry" $'# written by AIBOS (registration), do not edit\nschema: 1\nregistered:\n  memo:\n    source: "x"\n    version: 6.0.0\n    digest: sha256:0\n'
   assert_eq "$(at "$D/Notiz" aibos --skill aibos-memo)" "Use \`/memo\` — the skill \`memo\` is registered in this project." "memo registered: precedence"
   assert_eq "$(at "$D/Notiz/@" aibos --skill aibos-memo)" "Use \`/memo\` — the skill \`memo\` is registered in this project." "precedence from a folder inside the project"
   mk "$D/Notiz/.aibos/registry" $'# written by AIBOS (registration), do not edit\nschema: 1\nregistered:\n  notiz:\n    source: "x"\n    version: 0.1.0\n    digest: sha256:0\n'
   case "$(at "$D/Notiz" aibos --skill aibos-memo)" in *"$MEMO_BODY"*) ok ;; *) fail "other skills registered: body" ;; esac
   OUT="$(at "$SANDBOX/outside" "$SRC/bin/aibos" --skill aibos-memo 2>&1)"; RC=$?
   assert_eq "$RC:$OUT" "1:Kein AIBOS-Workspace: $SANDBOX/outside" "outside an A/W: only the location check (V0.6)"

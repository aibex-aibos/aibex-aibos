# t06-hooks.sh: step 6 of the plan (memo 18) - aibos --context --session/--advise (spec 02, Hooks); v0.3 steps 3, 6

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# setup: activated vault, project, not initialized folder, legacy vault, fake ai-brain
#===============================================================================

   mkdir -p "$SANDBOX/fake" "$SANDBOX/outside" "$HOME/.aibos"
   export PATH="$SANDBOX/fake:/usr/bin:/bin:/usr/sbin:/sbin"
   D="$SANDBOX/work/§Demo"
   mk() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" > "$1"; }
   mk "$D/.aibos/config.yaml"      $'aibos: 0.6.0\n'
   mk "$D/@/@Rule/stil.md"        $'# Stil\nschreib klar\n'
   mk "$D/Garten/@/garten.md"     $'# Garten\nApfel\n'
   mkdir -p "$D/Garten/Neu"
   mk "$D/Garten/.gitignore"      $'.DS_Store\n.claude/skills/\n.claude/worktrees/\n.agents/\n.aibos/registry\n.aibos/backup/\n.aibos/workspace.local.yaml\n@Secret/\n'
   git -C "$D/Garten" init -q                      # Garten is a complete project (spec 05, S1-S4)
   mk "$D/Wiese/@/wiese.md"       $'# Wiese\n'
   mk "$SANDBOX/work/§Alt/@/a.md" $'# A\n'; mk "$SANDBOX/work/§Alt/.aibos/config.yaml" $'legacy: ai-brain\n'
   printf '#!/bin/bash\necho "ai-brain $* stdin=$(cat)"\n' > "$SANDBOX/fake/ai-brain"; chmod +x "$SANDBOX/fake/ai-brain"

   AC() { "$SRC/bin/aibos" --context "$@"; }
   json() { printf '{"session_id":"t","hook_event_name":"SessionStart","source":"%s","cwd":"%s"}' "${SRCE:-startup}" "$1"; }
   HOOK() { json "$2" | (cd "$SANDBOX" && AC "$1"); }          # hook call, cwd only from JSON

#===============================================================================
# outside a vault and legacy mode
#===============================================================================

   assert_eq "$(HOOK --session "$SANDBOX/outside")" "" "outside a vault: session prints nothing"
   assert_eq "$(HOOK --advise "$SANDBOX/outside")" "" "outside a vault: advise prints nothing"
   OUT="$(HOOK --session "$SANDBOX/work/§Alt")"
   assert_eq "$OUT" "ai-brain --session stdin=$(json "$SANDBOX/work/§Alt")" "legacy: ai-brain gets the same hook JSON"
   assert_contains "$(HOOK --advise "$SANDBOX/work/§Alt")" "ai-brain --advise stdin=" "legacy: advise"

#===============================================================================
# --session: small master context inline, cwd taken from the hook JSON
#===============================================================================

   HOOK --session "$D/Garten" >/dev/null         # first session registers the wrappers (AIBOS-SKILLS), V0.6
   OUT="$(HOOK --session "$D/Garten"; echo x)"; OUT="${OUT%x}"
   CTX="$(cd "$D/Garten" && AC --context; echo x)"; CTX="${CTX%x}"
   assert_eq "$OUT" "AIBOS-CONTEXT (loaded automatically by SessionStart hook):
$CTX" "session: inline = header + --context"
   case "$OUT" in *PROJECT-UNINITIALIZED*|*AIBOS-WARNING*) fail "session: no extra lines for an initialized project" ;; *) ok ;; esac
   [ ! -e "$HOME/.aibos/cache" ] && ok || fail "session inline: no part files written"
   ID="$(cd "$D/Garten" && AC --id | sed 's/^id=\([^ ]*\).*/\1/')"
   assert_eq "$(AC --id "$D/Garten" | sed 's/^id=\([^ ]*\).*/\1/')" "$ID" "--id <path> = --id in the directory"
   assert_contains "$OUT" "<aibos-context id=\"$ID\"" "session: id of the hook cwd"

#===============================================================================
# --session: not initialized project
#===============================================================================

   OUT="$(HOOK --session "$D/Garten/Neu")"
   assert_eq "$(printf '%s\n' "$OUT" | head -7)" "PROJECT-UNINITIALIZED: $D/Garten/Neu has no local masterspace (@/). Before your first
answer, call the skill /aibos-init (Skill tool) and follow it: it runs
\`$HOME/.aibos/bin/aibos --init \"$D/Garten/Neu\" --plan\`, shows the dialog \"Projekt initialisieren\"
(title, assistant, initialize or continue in the project $D/Garten) and, after the user's choice,
runs $HOME/.aibos/bin/aibos --init with --yes. Without that skill, do the same yourself: run the plan,
ask these questions, then run with --yes. Never answer a question of aibos yourself.
Give no other answer until the user decides." "uninitialized: skill /aibos-init, dialog, X = project above, --yes (A2, A3)"
   assert_contains "$OUT" "src=\"$D/Garten/@/garten.md\"" "uninitialized: master context up to X"
   case "$OUT" in *PROJECT-INCOMPLETE*) fail "uninitialized: no consistency check" ;; *) ok ;; esac

#===============================================================================
# --session: consistency check at startup only (spec 02, Unvollstaendiges Projekt)
#===============================================================================

   HOOK --session "$D/Wiese" >/dev/null          # registers the wrappers first (V0.6)
   OUT="$(HOOK --session "$D/Wiese")"
   assert_eq "$(printf '%s\n' "$OUT" | head -1)" "PROJECT-INCOMPLETE: $D/Wiese is an AIBOS project but lacks: own git repo, .gitignore lines: .DS_Store, .claude/skills/, .claude/worktrees/, .agents/, .aibos/registry, .aibos/backup/, .aibos/workspace.local.yaml, @Secret/." "incomplete: gaps named"
   assert_contains "$OUT" "call the skill /aibos-init
(Skill tool) for \"$D/Wiese\" and follow it (plan from --plan, after yes run with
--yes; never answer a question of aibos yourself)." "incomplete: offer /aibos-init (A2, A3)"
   assert_contains "$OUT" "src=\"$D/Wiese/@/wiese.md\"" "incomplete: master context follows"
   for S in resume clear compact; do
      case "$(SRCE=$S HOOK --session "$D/Wiese")" in *PROJECT-INCOMPLETE*) fail "incomplete: no check at $S" ;; *) ok ;; esac
   done
   case "$(json "$D/Wiese" >/dev/null; cd "$D/Wiese" && AC --session </dev/null)" in *PROJECT-INCOMPLETE*) ok ;; *) fail "incomplete: without JSON counts as startup" ;; esac

#===============================================================================
# v0.5.1 step 1: worktree of the host (spec 02, Arbeitskopie; V0.5, memos 71, 73: B6)
#===============================================================================

   git -C "$D/Garten" add -A && git -C "$D/Garten" commit -qm init
   git -C "$D/Garten" worktree add -q -b claude/w1 .claude/worktrees/w1 2>/dev/null
   W="$D/Garten/.claude/worktrees/w1"
   HOOK --session "$W" >/dev/null                 # registers the wrappers first (V0.6)
   OUT="$(HOOK --session "$W")"
   assert_eq "$(printf '%s\n' "$OUT" | head -6)" "AIBOS-WORKTREE: this session runs in a git worktree on branch claude/w1
 ($W), not in the chosen folder $D/Garten.
 Before your first work, tell the user in one sentence that results land on
 branch claude/w1 and not in the chosen folder. After writing work (files
 changed or committed), offer to merge the branch into $D/Garten
 instead of only reporting it as done." "worktree: branch, worktree, chosen folder, instruction"
   case "$OUT" in *PROJECT-INCOMPLETE*) fail "worktree: no consistency check" ;; *) ok ;; esac
   for S in resume compact; do
      assert_contains "$(SRCE=$S HOOK --session "$W")" "AIBOS-WORKTREE: this session runs in a git worktree on branch claude/w1" "worktree: also at $S"
   done
   mkdir -p "$W/Neu"
   OUT="$(HOOK --session "$W/Neu")"
   assert_contains "$OUT" "not in the chosen folder $D/Garten/Neu." "worktree: chosen folder keeps the subfolder"
   case "$OUT" in AIBOS-WORKTREE*PROJECT-UNINITIALIZED*) ok ;; *) fail "worktree: before PROJECT-UNINITIALIZED" ;; esac
   git -C "$W" checkout -q --detach
   assert_contains "$(HOOK --session "$W")" "on branch detached HEAD" "worktree: detached HEAD"
   assert_eq "$(git -C "$D/Garten" status --porcelain)" "" "worktree: ignored in the chosen folder (.gitignore template)"
   case "$(HOOK --session "$D/Garten")" in *AIBOS-WORKTREE*) fail "main folder: no worktree line" ;; *) ok ;; esac
   case "$(HOOK --session "$D/Wiese")" in *AIBOS-WORKTREE*) fail "no repo: no worktree line" ;; *) ok ;; esac
   OUT="$(HOOK --session "$W")"                  # B9: the worktree takes the place of Garten
   assert_contains "$OUT" "src=\"$W/@/garten.md\"" "B9: masterspace of the worktree"
   case "$OUT" in *"src=\"$D/Garten/@/garten.md\""*) fail "B9: not the masterspace of the chosen folder" ;; *) ok ;; esac
   assert_contains "$OUT" "src=\"$D/@/@Rule/stil.md\"" "B9: chain continues above the chosen folder"
   assert_contains "$(AC --list "$W")" "§Demo → w1" "B9: chain §Demo → w1"
   H="$SANDBOX/work/§Hirsch"                       # B9: worktree of the vault root
   mk "$H/.aibos/config.yaml" $'aibos: 0.6.0\n'
   mk "$H/@/hirsch.md" $'# Hirsch\n'
   mk "$H/.gitignore" $'.claude/worktrees/\n'
   git -C "$H" init -q && git -C "$H" add -A && git -C "$H" commit -qm init
   git -C "$H" worktree add -q -b claude/h1 .claude/worktrees/h1 2>/dev/null
   OUT="$(HOOK --session "$H/.claude/worktrees/h1")"
   assert_contains "$OUT" "not in the chosen folder $H." "B9 root: chosen folder = vault root"
   assert_contains "$OUT" "src=\"$H/.claude/worktrees/h1/@/hirsch.md\"" "B9 root: masterspace of the worktree"
   case "$OUT" in *"src=\"$H/@/hirsch.md\""*|*AIBOS-WARNING*) fail "B9 root: loaded once, aibos: allowed in the worktree" ;; *) ok ;; esac
   git -C "$D/Garten" worktree remove --force "$W"

#===============================================================================
# --session: master context larger than inline_limit -> part files
#===============================================================================

   printf 'inline_limit: 100\n' > "$HOME/.aibos/config.yaml"
   OUT="$(HOOK --session "$D/Garten")"
   SIZE="$(printf '%s' "$CTX" | python3 -c 'import sys; print(len(sys.stdin.read()))')"   # characters, not bytes
   assert_contains "$OUT" "AIBOS-CONTEXT-MANDATORY: the master context of this project is too large" "mandatory: header"
   assert_contains "$OUT" "($SIZE > 100 characters)" "mandatory: size and limit"
   assert_contains "$OUT" "\"Master-Kontext geladen (id $ID)\"" "mandatory: names the id"
   assert_contains "$OUT" "AIBOS-CONTEXT-LOAD id=$ID files=2 parts=1" "mandatory: part file list"
   assert_file "$HOME/.aibos/cache/$ID/part-1.md"
   case "$OUT" in *"<aibos-file"*) fail "mandatory: no inline content" ;; *) ok ;; esac
   rm "$HOME/.aibos/config.yaml"

#===============================================================================
# --advise: check line with the expected id and an explicit path
#===============================================================================

   OUT="$(HOOK --advise "$D/Garten")"
   assert_eq "$(printf '%s\n' "$OUT" | head -1)" "AIBOS-CONTEXT-CHECK: expected id=$ID (files=2, cwd=$D/Garten)." "advise: first line"
   assert_contains "$OUT" "<aibos-context id=\"$ID\"" "advise: start marker"
   assert_contains "$OUT" "</aibos-context id=\"$ID\">" "advise: end marker"
   assert_contains "$OUT" "run \`$HOME/.aibos/bin/aibos --context --load \"$D/Garten\"\` via Bash" "advise: load with explicit path"
   assert_eq "$(cd "$D/Garten" && AC --advise </dev/null | head -1)" "AIBOS-CONTEXT-CHECK: expected id=$ID (files=2, cwd=$D/Garten)." "advise without JSON: cwd of the process"

#===============================================================================
# warnings and failures never break the session
#===============================================================================

   printf 'aibos: 0.6.0\nfoo: 1\n' > "$D/.aibos/config.yaml"
   assert_contains "$(HOOK --session "$D/Garten")" "AIBOS-WARNING: $D/.aibos/config.yaml: unknown key foo ignored" "session: config warning"
   chmod 000 "$D/Garten/@/garten.md"
   OUT="$(HOOK --session "$D/Garten")"; RC=$?
   chmod 644 "$D/Garten/@/garten.md"
   assert_eq "$RC" "0" "failure: exit 0"
   assert_contains "$OUT" "AIBOS-WARNING: aibos --context --session failed:" "failure: one warning line"

#===============================================================================
# v0.3 step 6: assistant of the session (spec 02, Assistent der Session)
#===============================================================================

   printf 'aibos: 0.6.0\n' > "$D/.aibos/config.yaml"
   mk "$D/@/@!Assistant/gaertner/ASSISTANT.md" $'---\nname: gaertner\ntitle: Gärtner\nversion: 0.1.0\ndescription: Gärtner\n---\n\nNur Äpfel und Birnen.\n'
   mk "$D/Garten/.aibos/config.yaml" $'assistant: gaertner\n'
   SJ() { printf '{"session_id":"%s","source":"%s","cwd":"%s"}' "$1" "$2" "$3"; }
   SH() { SJ "$2" "$3" "$4" | (cd "$SANDBOX" && AC "$1"); }       # SH --session|--advise <sid> <source> <cwd>
   M="$HOME/.aibos/sessions"
   OUT="$(SH --session s1 startup "$D/Garten")"
   assert_contains "$OUT" "AIBOS-ASSISTANT (assistant of this session, from project $D/Garten/.aibos/config.yaml):
 Take on this role for the whole session. In your first answer, confirm
 briefly \"Gärtner aktiv\" (and mention the model wish, if any).
<aibos-assistant name=\"gaertner\" title=\"Gärtner\" version=\"0.1.0\"" "startup: assistant inline after the master context"
   assert_contains "$OUT" '</aibos-assistant name="gaertner">' "startup: end marker"
   case "$OUT" in *"AIBOS-CONTEXT (loaded"*"AIBOS-ASSISTANT ("*) ok ;; *) fail "startup: master context first, then the assistant" ;; esac
   assert_eq "$(sed -n 2,3p "$M/s1.yaml")" "cwd: \"$D/Garten\"
assistant: gaertner" "startup: marker written"

   mk "$D/Garten/.aibos/config.yaml" $'assistant: none\n'
   for S in resume compact; do
      OUT="$(SH --session s1 "$S" "$D/Garten")"
      assert_contains "$OUT" "AIBOS-ASSISTANT (assistant of this session, from session):" "$S: assistant from the marker, not the new assignment"
   done
   OUT="$(SH --advise s1 x "$D/Garten")"
   assert_contains "$OUT" "AIBOS-ASSISTANT-CHECK: expected assistant=gaertner version=0.1.0.
 Verify that BOTH markers <aibos-assistant name=\"gaertner\" and
 </aibos-assistant name=\"gaertner\"> are present in your context. If not: run
 \`$HOME/.aibos/bin/aibos --context --assistant gaertner --load \"$D/Garten\"\` via Bash, read every
 listed part file completely, and continue in this role." "advise: assistant check after the context check"
   case "$OUT" in AIBOS-CONTEXT-CHECK*) ok ;; *) fail "advise: context check first" ;; esac
   OUT="$(SH --session s1 clear "$D/Garten")"
   case "$OUT" in *AIBOS-ASSISTANT*) fail "clear: new chat, assignment none" ;; *) ok ;; esac
   assert_contains "$(cat "$M/s1.yaml")" "assistant: none" "clear: marker rewritten"
   case "$(SH --advise s1 x "$D/Garten")" in *AIBOS-ASSISTANT-CHECK*) fail "advise: no check for none" ;; *) ok ;; esac

   mk "$D/Garten/.aibos/config.yaml" $'assistant: gaertner\n'
   OUT="$(SH --session s2 resume "$D/Garten")"
   assert_contains "$OUT" "from project $D/Garten/.aibos/config.yaml" "resume without marker: assignment of the project"
   assert_contains "$(cat "$M/s2.yaml")" "assistant: gaertner" "resume without marker: marker created"
   assert_contains "$(SH --advise s9 x "$D/Garten")" "AIBOS-ASSISTANT-CHECK: expected assistant=gaertner" "advise without marker: assignment"
   [ ! -e "$M/s9.yaml" ] && ok || fail "advise writes no marker"

   printf '# written by AIBOS (session), do not edit\ncwd: "%s"\nassistant: weg\nused: 2026-01-01T00:00:00\n' "$D/Garten" > "$M/s3.yaml"
   OUT="$(SH --session s3 resume "$D/Garten")"
   assert_contains "$OUT" "AIBOS-WARNING: assistant weg not found, continuing without assistant" "unknown assistant: warning"
   case "$OUT" in *"AIBOS-ASSISTANT ("*) fail "unknown assistant: no role" ;; *) ok ;; esac
   case "$(SH --advise s3 x "$D/Garten")" in *AIBOS-ASSISTANT-CHECK*) fail "unknown assistant: no check" ;; *) ok ;; esac

   printf '# written by AIBOS (session), do not edit\ncwd: "/x"\nassistant: none\nused: 2020-01-01T00:00:00\n' > "$M/alt.yaml"
   SH --session s4 resume "$D/Garten" >/dev/null
   [ -e "$M/alt.yaml" ] && ok || fail "resume: no cleaning"
   SH --session s4 startup "$D/Garten" >/dev/null
   [ ! -e "$M/alt.yaml" ] && [ -e "$M/s1.yaml" ] && ok || fail "startup: markers older than 30 days removed"

   OUT="$(SH --session s5 startup "$D/Garten/Neu")"
   case "$OUT" in *"AIBOS-ASSISTANT ("*) fail "not initialized: no assistant" ;; *) ok ;; esac
   [ ! -e "$M/s5.yaml" ] && ok || fail "not initialized: no marker"
   OUT="$(printf '{"source":"startup","cwd":"%s"}' "$D/Garten" | (cd "$SANDBOX" && AC --session))"
   assert_contains "$OUT" "AIBOS-ASSISTANT (assistant of this session" "without session_id: assignment, no marker"

   printf 'inline_limit: 2000\n' > "$HOME/.aibos/config.yaml"
   python3 -c "print('x' * 3000)" >> "$D/@/@!Assistant/gaertner/ASSISTANT.md"
   OUT="$(SH --session s6 startup "$D/Garten")"
   assert_contains "$OUT" "AIBOS-ASSISTANT-MANDATORY: the assistant gaertner of this session (from project $D/Garten/.aibos/config.yaml) is too" "mandatory: header"
   assert_contains "$OUT" "AIBOS-ASSISTANT-LOAD name=gaertner version=0.1.0 parts=1" "mandatory: part files"
   assert_contains "$OUT" 'The assistant is loaded once </aibos-assistant name="gaertner"> (end of the last part) has been read.' "mandatory: end marker named"
   P1="$(printf '%s\n' "$OUT" | grep -o "$HOME/.aibos/cache/a-gaertner-[0-9a-f]*/part-1.md")"
   assert_file "$P1"
   case "$OUT" in *"AIBOS-ASSISTANT ("*) fail "mandatory: no inline assistant" ;; *) ok ;; esac
   rm "$HOME/.aibos/config.yaml"

#===============================================================================
# v0.6 step 3: quiet outside an A/W, log, marker only in its project (spec 02; V0.6, memos 33, 45)
#===============================================================================

   O="$SANDBOX/work/§Ohne"; mk "$O/@/a.md" $'# A\n'
   assert_eq "$(HOOK --session "$O")$(HOOK --advise "$O")" "" "vault without binding: hooks print nothing"
   F5="$SANDBOX/work/§Fuenf"; mk "$F5/@/a.md" $'# A\n'; mk "$F5/.aibos/config.yaml" $'aibos: 0.5.1\n'
   assert_eq "$(HOOK --session "$F5")$(HOOK --advise "$F5")" "" "binding below 0.6: hooks of 0.6 print nothing"

   X="$SANDBOX/work/§Wechsel"; mk "$X/.aibos/config.yaml" $'aibos: 0.6.0\n'; mk "$X/@/x.md" $'# X\n'
   mk "$X/@/@!Assistant/gaertner/ASSISTANT.md" $'---\nname: gaertner\ntitle: Gärtner\nversion: 0.1.0\ndescription: Gärtner\n---\n\nNur Äpfel.\n'
   mk "$X/P1/@/p.md" $'# P1\n'; mk "$X/P1/.aibos/config.yaml" $'assistant: gaertner\n'; mkdir -p "$X/P1/sub"
   mk "$X/P2/@/p.md" $'# P2\n'
   SH --session w1 startup "$X/P1" >/dev/null
   case "$(SH --advise w1 x "$X/P1/sub")" in *AIBOS-ASSISTANT-CHECK*) fail "marker: not initialized subfolder has no assistant" ;; *) ok ;; esac
   assert_contains "$(SH --advise w1 x "$X/P1")" "AIBOS-ASSISTANT-CHECK: expected assistant=gaertner" "marker: its project keeps the assistant"
   case "$(SH --advise w1 x "$X/P2")" in *AIBOS-ASSISTANT-CHECK*) fail "marker: another project, no assistant of the session" ;; *) ok ;; esac
   OUT="$(SH --session w1 resume "$X/P2")"
   case "$OUT" in *"AIBOS-ASSISTANT ("*) fail "resume in another project: no assistant from the marker" ;; *) ok ;; esac
   assert_contains "$(cat "$M/w1.yaml")" "cwd: \"$X/P1\"" "resume in another project: marker unchanged"
   assert_contains "$(SH --session w1 resume "$X/P1")" "AIBOS-ASSISTANT (assistant of this session, from session):" "back in the project: assistant from the marker"
   assert_eq "$(cd "$SANDBOX" && "$SRC/bin/aibos" --context --assignment "$X/P2" --session w1)" "assistant=none from=-" "--assignment --session: marker only in its project"

   chmod 000 "$X/@/x.md"
   OUT="$(HOOK --session "$X/P1")"
   assert_contains "$OUT" "AIBOS-WARNING: aibos --context --session failed:" "failure in an A/W: warning"
   assert_contains "$(cat "$HOME/.aibos/log/context.log")" "--session cwd=$X/P1 aibos --context --session failed:" "failure: line in the log"
   chmod 644 "$X/@/x.md"

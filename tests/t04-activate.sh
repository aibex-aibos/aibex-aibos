# t04-activate.sh: step 4 of the plan (memo 18) - aibos --activate/--deactivate/--config, configuration chain

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# setup: two fake installations, forwarders, a vault with projects and a container
#===============================================================================

   mkdir -p "$HOME/bin" "$HOME/.aibos"
   export PATH="$HOME/bin:/usr/bin:/bin:/usr/sbin:/sbin"
   export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
   cp "$SRC/templates/forwarder" "$HOME/bin/aibos"; chmod +x "$HOME/bin/aibos"
   for V in 0.1.0 0.2.0; do
      mkdir -p "$AIBOS_PREFIX/v$V/bin"
      printf '#!/bin/bash\necho "%s $*"\n' "$V" > "$AIBOS_PREFIX/v$V/bin/aibos"
      chmod +x "$AIBOS_PREFIX/v$V/bin/aibos"
      echo "v$V: $AIBOS_PREFIX/v$V" >> "$AIBOS_PREFIX/installations.yaml"
   done

   W="$SANDBOX/work"; D="$W/§Demo"
   mkdir -p "$D/Garten/@" "$D/Garten/Beet/@" "$D/Garten/Beet/Reihe" "$D/Wiese" "$SANDBOX/outside" "$W/.aibos"
   A() { "$SRC/bin/aibos" "$@" 2>&1; }               # aibos of the clone
   at() { (cd "$1" && shift && "$@" 2>&1); }        # run in a directory
   CFG() { PYTHONPATH="$SRC/lib" python3 -c "from aibos import config; c=config.load('$1'); print(($2))"; }

#===============================================================================
# --activate: checks before anything is written
#===============================================================================

   assert_contains "$(A --activate v0.1.0 "$SANDBOX/outside")" "is not in a vault" "outside a vault"
   assert_contains "$(A --activate v0.9.0 "$D")" "run: aibos --install v0.9.0" "version not installed"
   assert_contains "$(A --activate 0.x "$D")" "is not a version" "no version"
   assert_contains "$(A --activate v0.1.0 "$D/Wiese")" "is not a vault root; AIBOS binds only a vault root: aibos --activate v0.1.0 $D" "not the vault root: abort with the vault root (F5)"
   assert_exit 1 "$SRC/bin/aibos" --activate v0.1.0 "$D/Wiese"
   [ ! -e "$D/.aibos" ] && [ ! -e "$D/Wiese/.aibos" ] && ok || fail "checks: nothing written"

#===============================================================================
# --activate the vault root (cwd): creates @/, writes aibos:
#===============================================================================

   OUT="$(at "$D" sh -c "echo n | '$SRC/bin/aibos' --activate v0.1.0")"
   [ ! -e "$D/@" ] && [ ! -e "$D/.aibos" ] && ok || fail "activation cancelled: nothing written"
   OUT="$(at "$D" sh -c "echo y | '$SRC/bin/aibos' --activate v0.1.0")"
   assert_contains "$OUT" "create @/ (with .gitkeep)" "plan: root masterspace"
   assert_contains "$OUT" "git init (branch main)" "plan: repo of the root project"
   assert_contains "$OUT" ".gitignore: .DS_Store, .claude/skills/, .claude/worktrees/, .agents/, .aibos/registry, .aibos/backup/, .aibos/workspace.local.yaml, @Secret/" "plan: .gitignore"
   assert_contains "$OUT" "from the next chat" "hint: next chat"
   assert_dir "$D/@"
   assert_eq "$(cat "$D/.aibos/config.yaml")" "aibos: 0.1.0" "vault config written"
   assert_eq "$(git -C "$D" log --format=%s)" "AIBOS: Projekt initialisiert" "root project: first commit"
   assert_eq "$(git -C "$D" show --name-only --format= | sort | tr '\n' ' ')" ".aibos/config.yaml .gitignore @/.gitkeep " "root project: committed files"
   assert_eq "$(at "$D/Garten/Beet/Reihe" aibos --context --id)" "0.1.0 --context --id" "forwarder agrees with the activation"
   assert_eq "$(at "$D" sh -c "'$SRC/bin/aibos' --activate 0.1.0 </dev/null")" "=> $D runs with AIBOS 0.1.0 ($D/.aibos/config.yaml), nothing to do" "same version again: nothing to do, no question"

#===============================================================================
# --activate only at the vault root: a project aborts, nothing written (V0.6, F5)
#===============================================================================

   mkdir -p "$D/Garten/.aibos"
   printf '# Garten\nskills:\n  memo: 6.1.0   # newer memo\n' > "$D/Garten/.aibos/config.yaml"
   OUT="$(echo y | A --activate v0.2.0 "$D/Garten")"; RC=$?
   assert_contains "$OUT" "is not a vault root" "project: abort"
   assert_eq "$(cat "$D/Garten/.aibos/config.yaml")" "$(printf '# Garten\nskills:\n  memo: 6.1.0   # newer memo')" "project: config unchanged"
   echo y | A --activate v0.2.0 "$D" >/dev/null
   assert_eq "$(grep -c '^aibos:' "$D/.aibos/config.yaml")" "1" "vault root: only one aibos: line"
   assert_eq "$(head -1 "$D/.aibos/config.yaml")" "aibos: 0.2.0" "vault root: aibos: replaced in place"
   assert_contains "$(echo n | A --activate v0.1.0 "$D")" "(was 0.2.0)" "plan shows the old version"
   echo y | A --activate v0.1.0 "$D" >/dev/null
   assert_eq "$(at "$D/Garten/Beet/Reihe" aibos --context --id)" "0.1.0 --context --id" "forwarder: only the vault root binds (I14)"
   printf 'legacy: ai-brain\naibos: 0.1.0\n' > "$D/.aibos/config.yaml"
   OUT="$(echo y | A --activate v0.2.0 "$D")"
   assert_contains "$OUT" "remove legacy: from $D/.aibos/config.yaml (aibos: applies)" "legacy: removed with the binding (F33)"
   assert_eq "$(cat "$D/.aibos/config.yaml")" "aibos: 0.2.0" "legacy: gone, aibos: written"
   printf 'aibos: 0.1.0\n' > "$D/.aibos/config.yaml"

#===============================================================================
# configuration chain: per key the nearest entry, skills per name
#===============================================================================

   printf 'aibos: 0.1.0\nskills:\n  memo: 6.0.0\n  astro: 1.0.0\nhosts: [claude-code]\n' > "$D/.aibos/config.yaml"
   printf 'aibos: 0.2.0\ninline_limit: 100\nfoo: bar\nskills:\n  memo: 6.1.0\n' > "$D/Garten/.aibos/config.yaml"
   printf 'aibos: 0.2.0\nhosts:\n  - codex\n  - claude-code\ninline_limit: 5000\n' > "$HOME/.aibos/config.yaml"
   printf 'aibos: 0.9.0\nskills:\n  outside: 9.9.9\n' > "$W/.aibos/config.yaml"
   C="$D/Garten/Beet/Reihe"
   assert_eq "$(CFG "$C" 'c.aibos, str(c.source["aibos"])')" "('0.1.0', '$D/.aibos/config.yaml')" "aibos: only from the vault root (I14)"
   assert_contains "$(CFG "$C" '"|".join(c.warnings)')" "Garten/.aibos/config.yaml: aibos: is only allowed at the vault root, ignored" "warning: aibos in a project (I14)"
   assert_eq "$(CFG "$C" 'sorted(c.skills.items())')" "[('astro', '1.0.0'), ('memo', '6.1.0')]" "skills merged per name, nothing from above the vault"
   assert_eq "$(CFG "$C" 'str(c.skill_source["astro"])')" "$D/.aibos/config.yaml" "skill origin"
   assert_eq "$(CFG "$C" 'c.hosts')" "['claude-code']" "hosts: vault beats home"
   assert_eq "$(CFG "$C" 'c.inline_limit')" "5000" "inline_limit only from home"
   W3="$(CFG "$C" '"|".join(c.warnings)')"
   assert_contains "$W3" "Garten/.aibos/config.yaml: inline_limit is not allowed here" "warning: inline_limit in a project"
   assert_contains "$W3" "foo" "warning: unknown key"
   assert_contains "$W3" "$HOME/.aibos/config.yaml: aibos is not allowed here" "warning: aibos in ~/.aibos"
   assert_eq "$(CFG "$SANDBOX/outside" 'c.aibos, c.hosts, c.inline_limit')" "(None, ['codex', 'claude-code'], 5000)" "outside a vault: only home"
   assert_eq "$(at "$SANDBOX/outside" aibos --context --id)" "id=- files=0 cwd=$SANDBOX/outside mode=none" "forwarder outside a vault: mode=none"

   OUT="$(A --config "$C")"
   assert_contains "$OUT" "aibos      0.1.0 ($D/.aibos/config.yaml)" "--config: aibos with origin"
   assert_contains "$OUT" "kind      alt" "--config: kind of the vault"
   assert_contains "$OUT" "skill     astro 1.0.0 ($D/.aibos/config.yaml)" "--config: skills with origin"
   assert_contains "$(A --config "$SANDBOX/outside")" "aibos      - (no binding)" "--config: no binding outside a vault"

#===============================================================================
# parser: subset of YAML, errors are reported with the line
#===============================================================================

   P() { PYTHONPATH="$SRC/lib" python3 -c "from aibos import config; print(config.parse('''$1'''))" 2>&1; }
   assert_eq "$(P $'aibos: "0.1.0"  # c\nhosts: [a, \'b\']\nskills:\n  x: 1.0.0')" "{'aibos': '0.1.0', 'hosts': ['a', 'b'], 'skills': {'x': '1.0.0'}}" "quotes, comments, flow list, mapping"
   assert_contains "$(P $'aibos: 1\naibos: 2')" "key aibos appears twice" "duplicate key"
   assert_contains "$(P $'  x: 1')" "indented line without a key" "indent without key"

   cp "$D/.aibos/config.yaml" "$SANDBOX/root.keep"; printf 'aibos 0.1.0\n' > "$D/.aibos/config.yaml"
   OUT="$(echo y | A --activate v0.1.0 "$D")"
   assert_contains "$OUT" "expected 'key: value'" "broken config: activate aborts"
   assert_eq "$(cat "$D/.aibos/config.yaml")" "aibos 0.1.0" "broken config: unchanged"
   assert_contains "$(CFG "$D/Garten/Beet" '"|".join(c.warnings)')" "file ignored" "broken config: chain ignores the file"
   mv "$SANDBOX/root.keep" "$D/.aibos/config.yaml"

#===============================================================================
# --deactivate: only the vault root; other keys stay, empty file and .aibos/ are removed
#===============================================================================

   assert_contains "$(echo y | A --deactivate "$D/Garten")" "is not a vault root" "deactivate a project: abort (I14)"
   printf 'aibos: 0.1.0\ninline_limit: 100\nskills:\n  memo: 6.1.0\n' > "$D/.aibos/config.yaml"
   OUT="$(echo y | A --deactivate "$D")"
   assert_contains "$OUT" "(inline_limit, skills stay)" "plan names the remaining keys"
   assert_eq "$(grep -c '^aibos:' "$D/.aibos/config.yaml")" "0" "aibos: removed"
   assert_contains "$(cat "$D/.aibos/config.yaml")" "memo: 6.1.0" "skills stay"
   assert_contains "$OUT" "has no binding (no effect); for ai-brain write legacy: ai-brain" "vault without binding: hint to legacy: ai-brain"

   printf 'aibos: 0.1.0\n' > "$D/.aibos/config.yaml"
   OUT="$(at "$D" sh -c "echo y | '$SRC/bin/aibos' --deactivate")"
   [ ! -e "$D/.aibos" ] && ok || fail "empty config and .aibos/ removed"
   assert_contains "$(A --deactivate "$D" </dev/null)" "nothing to do" "deactivate again: nothing to do"
   assert_eq "$(at "$D/Garten" aibos --context --id)" "id=- files=0 cwd=$D/Garten mode=none" "forwarder: vault without binding, mode=none"

#===============================================================================
# v0.6 step 7: binding to 0.6 registers the vault, wrappers of earlier versions with
# their own question (spec 04, aibos --activate; V0.6, memos 30, 49: F18, F19)
#===============================================================================

   echo "v0.6.0: $SRC" >> "$AIBOS_PREFIX/installations.yaml"
   V6="$W/§Sechs"; mkdir -p "$V6/P-Projekt/@"
   OLDW="$AIBOS_CLAUDE_DIR/skills"; mkdir -p "$OLDW/aios-init" "$OLDW/gui" "$OLDW/synced"
   printf -- '---\nname: aios-init\n---\n\n!`aios --skill aios-init`\n' > "$OLDW/aios-init/SKILL.md"
   printf -- '---\nname: gui\n---\n\n!`aios --gui --session ${CLAUDE_SESSION_ID}`\n' > "$OLDW/gui/SKILL.md"
   printf 'mine\n' > "$OLDW/synced/SKILL.md"
   OUT="$(A --activate v0.6.0 "$V6" --plan)"
   assert_contains "$OUT" "register the wrappers of the kernel skills in" "0.6: plan registers the vault"
   assert_contains "$OUT" "(then with its own question: remove 2 wrappers of earlier versions in $OLDW)" "0.6: plan names the own question"
   OUT="$(printf 'y\nn\n' | A --activate v0.6.0 "$V6")"
   assert_eq "$(ls "$V6/.claude/skills" | grep -c '^aibos-')" "16" "0.6: wrappers at the vault root"
   assert_eq "$(ls "$V6/P-Projekt/.claude/skills" | grep -c '^aibos-')" "16" "0.6: wrappers in the project"
   [ -e "$OLDW/aios-init" ] && [ -e "$OLDW/gui" ] && ok || fail "0.6: no at the own question keeps the wrappers"
   OUT="$(A --activate v0.6.0 "$V6" --yes)"
   assert_contains "$OUT" "to remove them run aibos --activate v0.6.0 $V6 in a terminal" "0.6: --yes removes nothing, names the command"
   OUT="$(echo y | A --activate v0.6.0 "$V6")"
   [ ! -e "$OLDW/aios-init" ] && [ ! -e "$OLDW/gui" ] && [ -e "$OLDW/synced" ] && ok || fail "0.6: yes removes only the AIBOS wrappers"

#===============================================================================
# v0.6.2 step 2 (H7): the registration ends at the vaults inside a vault, bound or not
# (spec 04, aibos --activate, Registrierung; V0.6, memos 111, 120)
#===============================================================================

   V7="$W/§Aussen"; mkdir -p "$V7/@" "$V7/P/@" "$V7/§Innen/@" "$V7/§Innen/Q/@" "$V7/Ordner/§Leer/R/@" "$V7/§Innen/.aibos"
   printf 'aibos: 0.1.0\n' > "$V7/§Innen/.aibos/config.yaml"
   mkdir -p "$V7/§Auch/.aibos" "$V7/§Auch/S/@"; printf 'aibos: 0.6.0\n' > "$V7/§Auch/.aibos/config.yaml"   # an A/W inside (§Obsidian, memo 111)
   OUT="$(A --activate v0.6.0 "$V7" --plan)"
   assert_contains "$OUT" "register the wrappers of the kernel skills in 2 projects of $V7" "H7: only the root and P counted"
   OUT="$(echo y | A --activate v0.6.0 "$V7")"
   assert_eq "$(ls "$V7/P/.claude/skills" 2>/dev/null | grep -c '^aibos-')" "16" "H7: wrappers in the project of the vault"
   [ ! -e "$V7/§Innen/.claude" ] && [ ! -e "$V7/§Innen/Q/.claude" ] && ok || fail "H7: no wrappers in a bound vault inside"
   [ ! -e "$V7/Ordner/§Leer/R/.claude" ] && ok || fail "H7: no wrappers in an unbound vault inside"
   [ ! -e "$V7/§Auch/S/.claude" ] && ok || fail "H7: no wrappers in an A/W inside"
   assert_eq "$(cat "$V7/§Innen/.aibos/config.yaml")" "aibos: 0.1.0" "H7: binding of the vault inside unchanged"
   rm -rf "$V7/P/.claude/skills/aibos-status"          # B20: an A/W with an outdated registration
   assert_contains "$(A --activate v0.6.0 "$V7" --plan)" "register the wrappers of the kernel skills in 2 projects of $V7" "B20: number of projects also for an A/W"
   echo y | A --activate v0.6.0 "$V7" >/dev/null
   assert_contains "$(A --activate v0.6.0 "$V7" --plan)" "nothing to do" "B20: nothing to do when the registration is current"

#===============================================================================
# v0.6.2 step 3 (H5): a distribution whose kernel: does not fit the new binding is named
# as a note with the command; the binding is written anyway (spec 04, aibos --activate, Distribution)
#===============================================================================

   V8="$W/§Dist"; DM="$V8/@/@!Package/distribution-demo/manifest.yaml"; mkdir -p "$(dirname "$DM")" "$V8/@/@!Package/distribution-ohne"
   printf 'name: distribution-demo\nversion: 1.0.0\ntype: distribution\nkernel: "==0.1.0"\n' > "$DM"
   printf 'name: distribution-ohne\nversion: 0.2.0\ntype: distribution\n' > "$V8/@/@!Package/distribution-ohne/manifest.yaml"
   cp "$DM" "$SANDBOX/dm.orig"
   NOTE="note: distribution-demo 1.0.0 wants kernel ==0.1.0; update it with aibos --install distribution-demo"
   assert_not_contains "$(A --activate v0.1.0 "$V8" --plan)" "note: distribution-" "H5: no note when the kernel fits"
   OUT="$(A --activate v0.6.0 "$V8" --plan)"
   assert_contains "$OUT" "$NOTE" "H5: note with the command"
   assert_not_contains "$OUT" "distribution-ohne" "H5: a distribution without kernel: is not named"
   OUT="$(echo y | A --activate v0.6.0 "$V8")"
   assert_eq "$(CFG "$V8" "c.aibos")" "0.6.0" "H5: bound anyway"
   cmp -s "$DM" "$SANDBOX/dm.orig" && ok || fail "H5: the distribution is not changed"
   assert_not_contains "$(A --activate v0.6.0 "$V8" --plan)" "note: distribution-" "H5: no note when nothing changes"

#===============================================================================
# v0.6.4 (H28): the binding completes the .gitignore of the projects after the template, one commit
# of only .gitignore each (spec 04, aibos --activate; V0.6, memos 188, 189)
#===============================================================================

   V9="$W/§Neun"; mkdir -p "$V9/P-Alt/@" "$V9/P-Neu/@"
   for X in P-Alt P-Neu; do git -C "$V9/$X" init -q -b main; done
   printf '.DS_Store\n.claude/skills/\n.claude/worktrees/\n.agents/\n.aibos/registry\n.aibos/backup/\n' > "$V9/P-Alt/.gitignore"
   cp "$SRC/templates/gitignore" "$V9/P-Neu/.gitignore"
   for X in P-Alt P-Neu; do git -C "$V9/$X" add -A; git -C "$V9/$X" -c user.name=t -c user.email=t@t commit -qm init; done
   OUT="$(A --activate v0.6.0 "$V9" --plan)"
   assert_contains "$OUT" "complete the .gitignore of 1 projects of $V9 after the template (.aibos/workspace.local.yaml, @Secret/)" "H28: plan completes the old project only"
   OUT="$(echo y | A --activate v0.6.0 "$V9")"
   assert_contains "$(cat "$V9/P-Alt/.gitignore")" "@Secret/" "H28: line added"
   assert_eq "$(git -C "$V9/P-Alt" log -1 --format=%s)" "AIBOS: .gitignore nach der Vorlage ergänzt" "H28: commit of only .gitignore"
   assert_eq "$(git -C "$V9/P-Alt" status --porcelain -- .gitignore)" "" "H28: .gitignore committed"
   assert_eq "$(git -C "$V9/P-Neu" log -1 --format=%s)" "init" "H28: a complete project is not touched"
   assert_not_contains "$(A --activate v0.6.0 "$V9" --plan)" "complete the .gitignore" "H28: nothing to complete the second time"

#===============================================================================
# v0.6 step 10 (B3): the vault reached through a symlink binds like its physical path (spec 02)
#===============================================================================

   ln -s "$V6" "$SANDBOX/link-sechs"
   OUT="$(A --activate v0.6.0 "$SANDBOX/link-sechs" --plan)"
   assert_not_contains "$OUT" "is not a vault root" "symlink to the vault root: no abort"

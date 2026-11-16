# t23-vaults.sh: v0.6.2 step 1 - aibos --vaults, the vaults AIBOS finds (spec 04, aibos --vaults; V0.6, memos 115, 120, H8)
#               v0.6.3 step 1 - of /opt/aibos/workers.yaml only projects of the current user (B26; V0.6, memos 153, 154)

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# setup: vaults from each source in their own folders a-d, beside, inside and above them, all kinds of binding
#===============================================================================

   mk() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" > "$1"; }
   V() { (cd "$SANDBOX" && "$SRC/bin/aibos" --vaults 2>&1); }
   W="$SANDBOX/w"
   assert_eq "$(V)" "no vault found" "nothing known: no vault found"

   mk "$W/a/§Outer/.aibos/config.yaml" $'aibos: 0.6.1\n'                   # above §Known
   mk "$W/a/§Outer/§Known/.aibos/config.yaml" $'aibos: 0.6.2\n'            # from a session marker
   mk "$W/a/§Outer/§Known/P/x.md" $'# x\n'
   mk "$W/a/§Outer/§Sibling/.aibos/config.yaml" $'legacy: ai-brain\n'     # beside §Known
   mk "$W/a/§Outer/§Known/A/B/§Deep/.aibos/config.yaml" $'aibos: 0.5.1\n'  # inside, level 3
   mk "$W/a/§Outer/§Known/A/B/C/§Deeper/x.md" $'# x\n'                   # inside, level 4: not searched
   mk "$W/a/§Outer/§Known/.git/§Hidden/x.md" $'# x\n'                    # hidden folders are not searched
   mk "$W/b/§Repo/.aibos/config.yaml" $'aibos: 0.6.1\n'                    # from ~/.aibos/repo
   mk "$W/b/§Repo/aibex-aibos/VERSION" $'0.6.2\n'
   mk "$W/c/§Work/P/x.md" $'# x\n'                                       # from workers.yaml, no binding
   mk "$HOME/.aibos/sessions/a.yaml" "cwd: \"$W/a/§Outer/§Known/P\""$'\n'
   mk "$HOME/.aibos/sessions/b.yaml" "cwd: \"$W/d/§Gone/P\""$'\n'          # path no longer exists
   mk "$HOME/.aibos/repo" "$W/b/§Repo/aibex-aibos"$'\n'
   mk "$HOME/.aibos/workers.yaml" "worker-x:"$'\n'"  0.1.0:"$'\n'"    projects: [\"$W/c/§Work/P\"]"$'\n'

#===============================================================================
# aibos --vaults: binding and sources per vault, sorted by path
#===============================================================================

   OUT="$(V)"
   assert_contains "$OUT" "=> 7 vaults" "seven vaults found"
   assert_contains "$OUT" "   aibos 0.6.1  $W/a/§Outer  (above)" "above a known vault (F97)"
   assert_contains "$OUT" "   aibos 0.6.2  $W/a/§Outer/§Known  (session)" "from a session marker"
   assert_contains "$OUT" "   alt 0.5.1    $W/a/§Outer/§Known/A/B/§Deep  (inside)" "inside, binding below 0.6"
   assert_contains "$OUT" "   legacy       $W/a/§Outer/§Sibling  (beside)" "beside, legacy vault"
   assert_contains "$OUT" "   aibos 0.6.1  $W/b/§Repo  (repo)" "from ~/.aibos/repo"
   assert_contains "$OUT" "   none         $W/c/§Work  (workers)" "from workers.yaml, without binding"
   assert_contains "$OUT" "   missing      $W/d/§Gone  (session)" "path of a marker that no longer exists"
   assert_not_contains "$OUT" "§Deeper" "inside: not deeper than 3 levels (F104)"
   assert_not_contains "$OUT" "§Hidden" "inside: hidden folders skipped"
   assert_eq "$(printf '%s\n' "$OUT" | sed -n 2p)" "   aibos 0.6.1  $W/a/§Outer  (above)" "sorted by path"

#===============================================================================
# several sources for one vault; reads only (I7)
#===============================================================================

   mk "$HOME/.aibos/sessions/c.yaml" "cwd: \"$W/c/§Work\""$'\n'
   assert_contains "$(V)" "   none         $W/c/§Work  (session, workers)" "sources in a fixed order"
   find "$W" "$HOME" -type f | sort > "$SANDBOX/before"
   V >/dev/null
   find "$W" "$HOME" -type f | sort > "$SANDBOX/after"
   cmp -s "$SANDBOX/before" "$SANDBOX/after" && ok || fail "aibos --vaults writes nothing"
   assert_exit 1 "$SRC/bin/aibos" --vaults extra

#===============================================================================
# B26: /opt/aibos/workers.yaml is computer-wide; only existing projects of the current user count (F150, F151)
#===============================================================================

   rm -f "$HOME/.aibos/sessions/c.yaml"
   mk "$W/e/§Shared/P/x.md" $'# x\n'
   mk "$AIBOS_PREFIX/workers.yaml" "worker-y:"$'\n'"  0.1.0:"$'\n'"    projects: [\"$W/e/§Shared/P\", \"$W/f/§Vanished/P\"]"$'\n'
   OUT="$(V)"
   assert_contains "$OUT" "   none         $W/e/§Shared  (workers)" "B26: own project from /opt/aibos/workers.yaml"
   assert_not_contains "$OUT" "§Vanished" "B26: missing path from /opt/aibos/workers.yaml not listed"
   assert_contains "$OUT" "   none         $W/c/§Work  (workers)" "B26: project from ~/.aibos/workers.yaml"
   OUT="$(AIBOS_TEST_UID=99999 V)"
   assert_not_contains "$OUT" "§Shared" "B26: project of another user not listed"
   assert_contains "$OUT" "   none         $W/c/§Work  (workers)" "B26: ~/.aibos/workers.yaml counts for any owner"
   mk "$HOME/.aibos/workers.yaml" "worker-x:"$'\n'"  0.1.0:"$'\n'"    projects: [\"$W/c/§Work/P\", \"$W/e/§Shared/P\"]"$'\n'
   assert_contains "$(AIBOS_TEST_UID=99999 V)" "   none         $W/e/§Shared  (workers)" "B26: same project in ~/.aibos/workers.yaml is listed"

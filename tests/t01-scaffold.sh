# t01-scaffold.sh: step 1 of the plan (memo 18) - repo scaffold and sandbox

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# sandbox isolates HOME, AIBOS_PREFIX and AIBOS_CLAUDE_DIR
#===============================================================================

   assert_contains "$HOME" "aibos-test." "HOME in sandbox"
   assert_eq "$AIBOS_PREFIX" "$SANDBOX/opt/aibos" "AIBOS_PREFIX"
   assert_eq "$AIBOS_CLAUDE_DIR" "$HOME/.claude" "AIBOS_CLAUDE_DIR"

#===============================================================================
# repo layout (spec 04, Repo aibex-aibos)
#===============================================================================

   for D in bin lib/aibos skills/aibos templates python spec dev tests; do
      assert_dir "$SRC/$D"
   done
   assert_file "$REPO/CLAUDE.md"
   assert_file "$REPO/dev/Bash-Skript-Struktur.md"
   [ ! -e "$REPO/§AIBOS" ] && ok || fail "no vault in the repo: §AIBOS exists"
   [ ! -e "$REPO/library" ] && ok || fail "library/ replaced by skills/<group>/"
   assert_file "$SRC/VERSION"
   assert_file "$SRC/python/requirements.txt"
   assert_file "$SRC/templates/gitignore"
   [ ! -e "$SRC/bin/aibos-context" ] && ok || fail "bin/aibos-context is gone (aibos --context, V0.5, memo 04)"

   assert_contains "$(cat "$SRC/python/requirements.txt")" "pyyaml" "requirements"
   assert_eq "$(cat "$SRC/templates/gitignore")" "$(printf '.DS_Store\n.claude/skills/\n.claude/worktrees/\n.agents/\n.aibos/registry\n.aibos/backup/\n.aibos/workspace.local.yaml\n@Secret/')" "gitignore template"

#===============================================================================
# bash scripts: syntax, help and version (bash convention)
#===============================================================================

   for S in "$SRC/bin/aibos" "$SRC/templates/forwarder" "$REPO/tests/run"; do
      bash -n "$S" && ok || fail "syntax: $S"
   done
   assert_exit 1 "$SRC/bin/aibos" --context -?
   assert_exit 1 "$SRC/bin/aibos" --context --nope
   assert_eq "$("$SRC/bin/aibos" --version)" "$(cat "$SRC/VERSION")" "aibos --version"
   assert_exit 1 "$SRC/bin/aibos" --context --assistant obstgaertner
   assert_contains "$("$SRC/bin/aibos" -? 2>&1)" "aibos --context --session|--advise" "help names the group --context"

#===============================================================================
# python part: paths follow the redirection variables
#===============================================================================

   PYOUT="$(PYTHONPATH="$SRC/lib" python3 -c '
import aibos, aibos.paths as p
print(aibos.version()); print(p.prefix()); print(p.user_dir()); print(p.claude_dir()); print(p.bin_dir())')"
   assert_eq "$(sed -n 1p <<< "$PYOUT")" "$(cat "$SRC/VERSION")" "aibos.version()"
   assert_eq "$(sed -n 2p <<< "$PYOUT")" "$AIBOS_PREFIX" "paths.prefix()"
   assert_eq "$(sed -n 3p <<< "$PYOUT")" "$HOME/.aibos" "paths.user_dir()"
   assert_eq "$(sed -n 4p <<< "$PYOUT")" "$AIBOS_CLAUDE_DIR" "paths.claude_dir()"
   assert_eq "$(sed -n 5p <<< "$PYOUT")" "$HOME/bin" "paths.bin_dir()"

#===============================================================================
# development state: bin/ holds aibos (spec 04)
#===============================================================================

   assert_exec "$SRC/bin/aibos"
   assert_exit 1 "$SRC/bin/aibos" -?
   assert_eq "$("$SRC/bin/aibos" --version)" "$(cat "$SRC/VERSION")" "aibos --version"
   assert_exit 1 "$SRC/bin/aibos" --deploy memo-6.0.0

   G="$SANDBOX/gone"; mkdir -p "$G" "$SANDBOX/da"           # H34: the working directory is gone
   OUT="$(cd "$G" && rmdir "$G" && "$SRC/bin/aibos" --workspace status 2>&1)"; RC=$?
   assert_eq "$RC" "1" "H34: bin/aibos without directory and path: exit 1"
   assert_contains "$OUT" "the current directory no longer exists" "H34: bin/aibos: message"
   assert_not_contains "$OUT" "Traceback" "H34: bin/aibos: no Python error"
   mkdir -p "$G"; OUT="$(cd "$G" && rmdir "$G" && "$SRC/bin/aibos" --workspace status "$SANDBOX/da" 2>&1)"
   assert_contains "$OUT" "no .aibos/workspace.yaml at or above" "H34: bin/aibos with an absolute path: goes on"
   assert_not_contains "$OUT" "Traceback" "H34: bin/aibos with a path: no Python error"

#===============================================================================
# v0.4: no library in the kernel; manifest.yaml of the kernel (spec 04, 06)
#===============================================================================

   [ ! -e "$SRC/skills/basic" ] && [ ! -e "$SRC/assistants" ] && ok || fail "no library (skills/basic, assistants) in the kernel"
   assert_eq "$(ls "$SRC/skills")" "aibos" "only AIBOS skills"
   assert_eq "$(sed -n 's/^version: //p' "$SRC/manifest.yaml")" "$(cat "$SRC/VERSION")" "manifest.yaml: version as VERSION"
   assert_contains "$(cat "$SRC/manifest.yaml")" "type: kernel" "manifest.yaml: type kernel"

#===============================================================================
# v0.7: the code compiles with the oldest python3 found, because aibos --install runs from a
# clone with the python3 of the system (macOS: 3.9) (V0.7, memo 23: FL27)
#===============================================================================

   OLDEST=""; OLDV=""
   for P in /usr/bin/python3 $(type -ap python3) /opt/homebrew/bin/python3.11 /usr/local/bin/python3; do
      [ -x "$P" ] || continue
      V="$("$P" -c 'import sys; print("%d %d" % sys.version_info[:2])' 2>/dev/null)" || continue
      read -r MA MI <<< "$V"; N=$((MA * 100 + MI))
      { [ -z "$OLDV" ] || [ "$N" -lt "$OLDV" ]; } && { OLDEST="$P"; OLDV="$N"; }
   done
   if [ -n "$OLDEST" ]; then
      OUT="$("$OLDEST" -c "import ast, pathlib, sys
bad = []
for f in sorted(pathlib.Path(sys.argv[1]).glob('*.py')):
    try:
        ast.parse(f.read_text(encoding='utf-8'), str(f))
    except SyntaxError as e:
        bad.append(f'{f.name}:{e.lineno}: {e.msg}')
print('\n'.join(bad))" "$SRC/lib/aibos" 2>&1)"
      assert_eq "$OUT" "" "lib/aibos compiles with $OLDEST ($((OLDV / 100)).$((OLDV % 100)))"
   else
      fail "no python3 found for the check of the syntax"
   fi

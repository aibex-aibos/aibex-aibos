# t17-worker.sh: workhorses (spec 07) - installation per version, workers.yaml, forwarders in

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac
# ~/.aibos/bin, aibos --worker (state, repair), kind python and script (step 6); loading with setup in
# the plan, dependencies, upgrade, reconcile, removal of unused versions, conflict, AIBOS-WORKERS
# (step 7); commands (aibos --run, spec 06); workers: of v0.4 rejected

#===============================================================================
# setup: python3 with PyYAML, test hubs with wheels, vault §Demo on 0.5.0
#===============================================================================

   PYDIR=""
   for P in $(type -ap python3) /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
      [ -x "$P" ] && "$P" -c "import yaml, venv, ensurepip" 2>/dev/null && { PYDIR="$(dirname "$P")"; break; }
   done
   [ -n "$PYDIR" ] && ok || fail "t17 needs a python3 with PyYAML, venv and ensurepip"
   export PATH="$PYDIR:/usr/bin:/bin:/usr/sbin:/sbin"
   "$SRC/tests/hub/build" "$SANDBOX/hubs" >/dev/null
   export AIBOS_HUBS="aibex-aibos=file://$SANDBOX/hubs/aibex-aibos"
   export AIBOS_PIP_FIND_LINKS="$SANDBOX/hubs/wheels"
   D="$SANDBOX/work/§Demo"; G="$D/G-Garten"
   mkdir -p "$D/@" "$D/.aibos" "$G/@" "$SANDBOX/outside"; printf 'aibos: 0.6.0\n' > "$D/.aibos/config.yaml"
   at() { (cd "$1" && shift && "$@" 2>&1); }
   A() { local d="$1"; shift; at "$d" "$SRC/bin/aibos" "$@"; }
   T="$HOME/.aibos/bin/aibos-test-tool"; I="$HOME/.aibos/workers/worker-test/v0.1.0"

#===============================================================================
# workers: of v0.4 is rejected (spec 06, Prüfung beim Holen; V0.5, memo 30, L9)
#===============================================================================

   OUT="$(A "$D" --fetch test-worker --yes)"
   assert_contains "$OUT" "workers: is gone since AIBOS 0.5; a workhorse is a package of type: worker (spec 07)" "fetch: workers: rejected"
   [ ! -e "$D/@/@!Package/test-worker" ] && ok || fail "fetch: nothing fetched"

#===============================================================================
# kind python: setup in the plan of aibos --fetch, installation read-only, workers.yaml (step 7)
#===============================================================================

   OUT="$(A "$D" --fetch 'worker-test==0.1.0' --plan)"
   assert_contains "$OUT" "setup      worker-test 0.1.0 -> $I" "fetch plan: setup of the workhorse"
   assert_contains "$OUT" "1 packages from worker/requirements.lock:" "plan: number of packages"
   assert_contains "$OUT" "| aibos-test-tool==1.0.0" "plan: package==version without hash (L7)"
   assert_contains "$OUT" "check: aibos-test-tool --check" "plan: check"
   [ ! -e "$I" ] && [ ! -e "$D/@/@!Package/worker-test" ] && ok || fail "plan: nothing installed or fetched"
   OUT="$(A "$D" --fetch 'worker-test==0.1.0' </dev/null)"
   assert_contains "$OUT" "cancelled" "no input: nothing runs"
   A "$D" --fetch 'worker-test==0.1.0' --yes >/dev/null
   assert_dir "$D/@/@!Package/worker-test"
   assert_exec "$I/bin/aibos-test-tool"
   [ ! -w "$I" ] && [ ! -e "$I.new" ] && ok || fail "setup: installation read-only, no .new left (N1)"
   W="$(cat "$HOME/.aibos/workers.yaml")"
   assert_contains "$W" "programs:
  aibos-test-tool: [worker-test]" "workers.yaml: program -> packages (N4)"
   assert_contains "$W" "    0.1.0:
      kind: python
      programs: [aibos-test-tool]
      check: ok" "workers.yaml: version, kind, programs, check"
   assert_contains "$W" "projects: [\"$D\"]" "workers.yaml: project that uses it"
   assert_contains "$(cat "$T")" "# worker-forwarder: ~/.aibos/bin/<program>" "forwarder in ~/.aibos/bin"
   assert_contains "$(A "$D" --worker)" "worker-test 0.1.0  $I  programs aibos-test-tool  check ok" "--worker: installed"
   assert_contains "$(A "$D" --fetch --yes)" "match lock.yaml, nothing to do" "reconcile: nothing to do when installed"

#===============================================================================
# forwarder: version from the nearest lock.yaml, errors with exit 127, never a setup (I10)
#===============================================================================

   assert_eq "$(at "$D" "$T" hallo)" "aibos-test-tool 1.0.0 hallo" "forwarder: locked version called with arguments"
   assert_eq "$(at "$G" "$T")" "aibos-test-tool 1.0.0" "forwarder: lock.yaml of the project above"
   assert_contains "$(at "$G" "$T" ---which)" "package=worker-test version=0.1.0 target=$I/bin/aibos-test-tool why=worker-test 0.1.0 in $D/.aibos/lock.yaml" "forwarder: ---which"
   OUT="$(at "$SANDBOX/outside" "$T")"; RC=$?
   assert_eq "$RC" "127" "outside the chain: exit 127"
   assert_contains "$OUT" "no project of the chain from $SANDBOX/outside has worker-test in lock.yaml" "outside the chain: message"
   mkdir -p "$G/.aibos"; printf 'schema: 1\npackages:\n  worker-test:\n    version: 0.1.1\n' > "$G/.aibos/lock.yaml"
   OUT="$(at "$G" "$T")"; RC=$?
   assert_eq "$RC:$OUT" "127:*** aibos-test-tool: worker-test 0.1.1 is not fully loaded; aibos --fetch" "version not installed: message, no setup (I10)"
   [ ! -e "$HOME/.aibos/workers/worker-test/v0.1.1" ] && ok || fail "forwarder never installs"
   rm "$G/.aibos/lock.yaml"
   printf '#!/bin/bash\necho fremd\n' > "$HOME/.aibos/bin/fremd"
   assert_eq "$(PYTHONPATH="$SRC/lib" python3 -c "from aibos import worker; worker.put_forwarder('fremd')" 2>&1)" "   warning: $HOME/.aibos/bin/fremd is not an AIBOS forwarder, left untouched" "foreign file in ~/.aibos/bin stays"

#===============================================================================
# reconcile (second machine, L5), AIBOS-WORKERS, repair with aibos --worker <package> setup
#===============================================================================

   chmod -R u+w "$I"; rm -rf "$I"
   assert_contains "$(A "$D" --worker)" "worker-test 0.1.0  not installed (fetched in $D); run: aibos --worker worker-test setup" "--worker: fetched, not installed"
   assert_contains "$(at "$G" "$SRC/bin/aibos" --context --advise </dev/null)" "AIBOS-WORKERS: missing worker-test 0.1.0 — run $HOME/.aibos/bin/aibos --fetch" "advise: missing workhorse of the chain (N3)"
   OUT="$(echo y | A "$D" --fetch)"
   assert_contains "$OUT" "setup      worker-test 0.1.0 -> $I" "reconcile: setup of the missing version"
   assert_eq "$(at "$D" "$T")" "aibos-test-tool 1.0.0" "reconcile: installed again"
   assert_not_contains "$(at "$G" "$SRC/bin/aibos" --context --advise </dev/null)" "AIBOS-WORKERS" "advise: nothing missing"
   chmod -R u+w "$I"; rm "$I/bin/aibos-test-tool"
   OUT="$(A "$D" --worker worker-test setup --plan)"
   assert_contains "$OUT" "setup worker-test 0.1.0 -> $I" "repair: plan"
   A "$D" --worker worker-test setup --yes >/dev/null
   assert_eq "$(at "$D" "$T")" "aibos-test-tool 1.0.0" "repair: rebuilt"
   assert_contains "$(A "$D" --worker nope setup)" "no fetched worker package nope in $D" "repair: unknown package"
   assert_contains "$(A "$D" --worker worker-test nope)" "usage: aibos --worker [<package> setup]" "--worker: usage"

#===============================================================================
# dependency: a skill that needs a workhorse, two versions side by side, conflict (F9)
#===============================================================================

   J="$HOME/.aibos/workers/worker-test/v0.1.1"
   OUT="$(echo y | A "$G" --fetch skill-test-nutzer)"
   assert_contains "$OUT" "setup      worker-test 0.1.1 -> $J" "dependency: workhorse set up with the skill"
   assert_eq "$(at "$G" "$T"):$(at "$D" "$T")" "aibos-test-tool 1.1.0:aibos-test-tool 1.0.0" "two versions, each project its own"
   OUT="$(A "$G" --fetch worker-test-anders --yes)"
   assert_contains "$OUT" "the packages worker-test and worker-test-anders both bring the program aibos-test-tool in the chain of $G; nothing is fetched" "conflict in the chain"
   [ ! -e "$G/@/@!Package/worker-test-anders" ] && ok || fail "conflict: nothing fetched"

#===============================================================================
# upgrade and removal: a version goes when no project uses it any more (A3)
#===============================================================================

   OUT="$(echo y | A "$D" --fetch 'worker-test~=0.1.0')"
   assert_not_contains "$OUT" "setup      worker-test" "upgrade: version already on the machine, no setup"
   assert_contains "$OUT" "remove     worker-test 0.1.0 -> $I (removed: no known project uses it)" "upgrade: old version removed"
   [ ! -e "$I" ] && [ -d "$J" ] && ok || fail "upgrade: 0.1.0 gone, 0.1.1 stays"
   assert_contains "$(cat "$HOME/.aibos/workers.yaml")" "projects: [\"$D\", \"$G\"]" "upgrade: both projects use 0.1.1"
   OUT="$(echo y | A "$G" --fetch --remove skill-test-nutzer)"
   assert_not_contains "$OUT" "remove     worker-test 0.1.1 ->" "remove: version still used by §Demo stays"
   assert_contains "$(cat "$HOME/.aibos/workers.yaml")" "projects: [\"$D\"]" "remove: project gone from workers.yaml"
   X="$D/X-Weg"; mkdir -p "$X/@"
   A "$X" --fetch 'worker-test~=0.1.0' --yes >/dev/null
   assert_contains "$(cat "$HOME/.aibos/workers.yaml")" "projects: [\"$D\", \"$X\"]" "third project noted"
   chmod u+w "$HOME/.aibos/workers.yaml"; sed -i.bak "s|, \"$X\"||" "$HOME/.aibos/workers.yaml"   # v0.5.1, B8
   OUT="$(A "$X" --fetch --plan)"
   assert_contains "$OUT" "$HOME/.aibos/workers.yaml: $X uses worker-test 0.1.1" "B8: missing entry in workers.yaml alone gives a plan"
   assert_not_contains "$OUT" "nothing to do" "B8: not nothing to do"
   A "$X" --fetch --yes >/dev/null
   assert_contains "$(cat "$HOME/.aibos/workers.yaml")" "projects: [\"$D\", \"$X\"]" "B8: project noted again"
   assert_contains "$(A "$X" --fetch --plan)" "nothing to do" "B8: then nothing to do"
   OUT="$(A "$X" --context --list)"                                     # v0.5.1, O3
   assert_contains "$OUT" "worker-test 0.1.1 (aibex-aibos, X-Weg) — no elements" "O3: package without elements"
   assert_not_contains "$OUT" "no elements deployed" "O3: not 'no elements deployed'"
   rm -rf "$X"
   OUT="$(echo y | A "$D" --fetch --remove worker-test)"
   assert_contains "$OUT" "remove     worker-test 0.1.1 -> $J (removed: no known project uses it)" "orphaned project does not count"
   [ ! -e "$J" ] && [ ! -e "$T" ] && ok || fail "removal: installation and forwarder gone"
   [ ! -e "$(dirname "$J")" ] && ok || fail "removal: no empty folder of the package under workers/ (B5)"

#===============================================================================
# B12 (V0.6, memos 71, 81): a project of a known vault that workers.yaml misses still counts
#===============================================================================

   A "$D" --fetch 'worker-test==0.1.0' --yes >/dev/null
   [ -d "$I" ] && ok || fail "B12: 0.1.0 set up again"
   W="$SANDBOX/work/§Alt"; P="$W/P-Alt"; mkdir -p "$W/@" "$W/.aibos" "$P/@" "$P/.aibos" "$HOME/.aibos/sessions"
   printf 'aibos: 0.5.1\n' > "$W/.aibos/config.yaml"
   printf '# written by AIBOS (fetch, workspace), do not edit\nschema: 1\npackages:\n  worker-test:\n    version: 0.1.0\n' > "$P/.aibos/lock.yaml"
   printf 'cwd: "%s"\nassistant: none\nused: 2026-10-25T10:00:00\n' "$P" > "$HOME/.aibos/sessions/b12.yaml"
   assert_not_contains "$(cat "$HOME/.aibos/workers.yaml")" "$P" "B12: §Alt not in workers.yaml"
   OUT="$(echo y | A "$D" --fetch --remove worker-test)"
   assert_contains "$OUT" "$HOME/.aibos/workers.yaml: worker-test 0.1.0 stays, used by $P" "B12: plan keeps the version"
   assert_not_contains "$OUT" "remove     worker-test 0.1.0" "B12: no removal"
   [ -d "$I" ] && [ -x "$T" ] && ok || fail "B12: 0.1.0 and its forwarder still installed"
   assert_contains "$(cat "$HOME/.aibos/workers.yaml")" "projects: [\"$P\"]" "B12: project of §Alt noted in workers.yaml"
   rm -f "$HOME/.aibos/sessions/b12.yaml"; rm -rf "$W"                   # 0.1.0 stays, orphaned

#===============================================================================
# kind script: plan shows the script, failing setup restores everything (I11)
#===============================================================================

   S="$HOME/.aibos/workers/worker-test-script/v0.1.0"
   OUT="$(A "$D" --fetch worker-test-script --plan)"
   assert_contains "$OUT" "bash worker/setup.sh:" "script: plan names the script"
   assert_contains "$OUT" '| printf' "script: plan shows its content (P3)"
   LOCK="$(cat "$D/.aibos/lock.yaml")"
   OUT="$(AIBOS_TEST_SETUP_FAIL=1 A "$D" --fetch worker-test-script --yes)"
   assert_contains "$OUT" "the plan failed" "script: failing setup fails the plan"
   [ ! -e "$S" ] && [ ! -e "$S.new" ] && [ ! -e "$D/@/@!Package/worker-test-script" ] && ok || fail "script: failing setup leaves nothing"
   [ ! -e "$(dirname "$S")" ] && ok || fail "script: no empty folder of the package under workers/ (B5)"
   [ ! -e "$HOME/.aibos/bin/aibos-test-script" ] && ok || fail "script: no forwarder after a failure"
   assert_eq "$(cat "$D/.aibos/lock.yaml")" "$LOCK" "script: lock.yaml as before"
   A "$D" --fetch worker-test-script --yes >/dev/null
   assert_eq "$(at "$D" "$HOME/.aibos/bin/aibos-test-script" a b)" "aibos-test-script a b" "script: program from AIBOS_WORKER_DIR/bin"
   A "$D" --fetch --remove worker-test-script --yes >/dev/null
   [ ! -e "$S" ] && [ ! -e "$HOME/.aibos/bin/aibos-test-script" ] && ok || fail "script: removed with the package"
   assert_not_contains "$(cat "$HOME/.aibos/workers.yaml")" "worker-test-script" "remove: entry gone from workers.yaml"

#===============================================================================
# aibos --run: deployed commands of the chain, environment, not deployed
#===============================================================================

   A "$D" --fetch test-befehl --yes >/dev/null
   assert_eq "$(A "$G" --run hallo Welt)" "hallo Welt" "run a command of a package in the chain"
   assert_contains "$(A "$D" --deploy test-befehl --only nichts --yes)" "test-befehl has no element nichts" "only existing elements"
   unset AIBOS_HUBS AIBOS_PIP_FIND_LINKS

#===============================================================================
# v0.6 step 2: place of the workhorses (spec 04, Installationen; spec 07; V0.6, F35)
#===============================================================================

   WR() { PYTHONPATH="$SRC/lib" python3 -c "from aibos import worker; print(worker.root())"; }
   mkdir -p "$AIBOS_PREFIX"; rm -f "$AIBOS_PREFIX/workers.yaml"
   assert_eq "$(WR)" "$HOME/.aibos" "workhorses: ~/.aibos without workers.yaml under /opt/aibos"
   printf '# written by AIBOS (worker setup), do not edit\nschema: 1\n' > "$AIBOS_PREFIX/workers.yaml"
   assert_eq "$(WR)" "$AIBOS_PREFIX" "workhorses: /opt/aibos when its workers.yaml exists"
   rm -f "$AIBOS_PREFIX/workers.yaml"

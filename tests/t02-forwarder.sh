# t02-forwarder.sh: forwarder (spec 04); v0.5 step 1: aibos --context; v0.6 step 2: forwarder 0.4.0 (vault root only, legacy: ai-brain)

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# setup: forwarders in ~/bin, fake installations, fake ai-brain, PATH without real ~/bin
#===============================================================================

   mkdir -p "$HOME/bin" "$HOME/.aibos" "$SANDBOX/fake"
   cp "$SRC/templates/forwarder" "$HOME/bin/aibos"
   chmod +x "$HOME/bin/aibos"
   export PATH="$HOME/bin:$SANDBOX/fake:/usr/bin:/bin:/usr/sbin:/sbin"

   fake_install() {                                 # fake_install <dir> <label>
      mkdir -p "$1/bin"
      for T in aibos; do
         printf '#!/bin/bash\necho "%s %s $*"\n' "$2" "$T" > "$1/bin/$T"
         chmod +x "$1/bin/$T"
      done
   }
   fake_install "$AIBOS_PREFIX/v0.1.0" "sys-0.1.0"
   fake_install "$AIBOS_PREFIX/v0.2.0" "sys-0.2.0"
   fake_install "$HOME/dev/aibos clone" "dev-0.1.0"
   fake_install "$HOME/dev/v0.10.0" "dev-0.10.0"
   fake_install "$HOME/dev/v0.2.0-dev" "dev-0.2.0-dev"

   printf 'v0.1.0: %s\nv0.2.0: %s\n' "$AIBOS_PREFIX/v0.1.0" "$AIBOS_PREFIX/v0.2.0" > "$AIBOS_PREFIX/installations.yaml"
   printf '#!/bin/bash\necho "ai-brain $*"\n' > "$SANDBOX/fake/ai-brain"; chmod +x "$SANDBOX/fake/ai-brain"

   V="$SANDBOX/work/§Demo Vault"                    # vault root with space in its name
   mkdir -p "$V/@" "$V/Garten/@" "$V/Garten/Beet/tief" "$V/Sterne/@" "$V/Anderes/@"
   mkdir -p "$SANDBOX/work/.aibos" "$SANDBOX/outside"

   run() { (cd "$1" && shift && "$@" 2>&1); }       # run <dir> <command...>

#===============================================================================
# forwarder: own options, arguments passed unchanged
#===============================================================================

   assert_eq "$(aibos ---version)" "0.5.0" "---version"

#===============================================================================
# the working directory is gone (V0.6, memo 204: H34)
#===============================================================================

   gone() { local G="$SANDBOX/gone.$RANDOM"; mkdir -p "$G"; (cd "$G" && rmdir "$G" && "$@" 2>&1) | grep -v "error retrieving current directory"; return "${PIPESTATUS[0]}"; }
   OUT="$(gone aibos --workspace sync --plan)"; RC=$?
   assert_eq "$RC" "1" "H34: no directory, no path: exit 1"
   assert_contains "$OUT" "the current directory no longer exists; change to an existing one (e.g. cd ~) or give an absolute path" "H34: message"
   assert_not_contains "$OUT" "Traceback" "H34: no Python error"
   OUT="$(gone aibos --workspace sync "$V/Garten" --plan)"; RC=$?
   assert_eq "$RC" "0" "H34: absolute path: goes on"
   assert_contains "$OUT" "aibos --workspace sync $V/Garten --plan" "H34: absolute path: forwarded unchanged"
   OUT="$(gone aibos --workspace sync Garten --plan)"; RC=$?
   assert_eq "$RC" "1" "H34: relative path: exit 1"
   assert_eq "$(gone aibos --context --session 2>/dev/null)" "" "H34: hook: no output"
   assert_contains "$(gone aibos --context --id)" "files=0" "H34: --id: no master context"
   assert_contains "$(gone aibos --context --id)" "mode=none" "H34: --id: mode none"

   assert_exit 1 aibos ---help
   assert_contains "$(aibos ---help)" "aibos ---which" "---help names the tool"

   AIBOS_HOME="$AIBOS_PREFIX/v0.2.0" assert_eq "$(AIBOS_HOME="$AIBOS_PREFIX/v0.2.0" run "$V" aibos -? "a b")" "sys-0.2.0 aibos -? a b" "arguments passed unchanged"

#===============================================================================
# rank 1: AIBOS_HOME
#===============================================================================

   printf 'aibos: 0.1.0\n' > "$V/.aibos.tmp"; mkdir -p "$V/.aibos"; mv "$V/.aibos.tmp" "$V/.aibos/config.yaml"
   assert_eq "$(AIBOS_HOME="$HOME/dev/v0.10.0" run "$V/Garten" aibos --x)" "dev-0.10.0 aibos --x" "AIBOS_HOME beats the chain (aibos)"
   assert_eq "$(AIBOS_HOME="$HOME/dev/v0.10.0" run "$SANDBOX/outside" aibos --context --id)" "dev-0.10.0 aibos --context --id" "AIBOS_HOME outside a vault (aibos --context)"
   assert_exit 1 env AIBOS_HOME="$SANDBOX/nowhere" aibos --x

#===============================================================================
# binding only at the vault root (spec 04, Weiterleiter; I14)
#===============================================================================

   assert_eq "$(run "$V/Garten/Beet/tief" aibos --context --id)" "sys-0.1.0 aibos --context --id" "vault config, deep cwd"
   assert_eq "$(run "$V" aibos --y)" "sys-0.1.0 aibos --y" "vault config, cwd = vault root"

   mkdir -p "$V/Garten/.aibos"; printf 'skills:\n  memo: 6.0.0\naibos: "0.2.0"   # quoted\n' > "$V/Garten/.aibos/config.yaml"
   assert_eq "$(run "$V/Garten/Beet" aibos --context --id)" "sys-0.1.0 aibos --context --id" "project config does not bind (I14)"
   printf 'aibos: "0.2.0"   # quoted\n' > "$V/.aibos/config.yaml"
   assert_eq "$(run "$V/Sterne" aibos --context --id)" "sys-0.2.0 aibos --context --id" "quoted version at the vault root"
   printf 'aibos: 0.1.0\n' > "$V/.aibos/config.yaml"
   assert_eq "$(run "$SANDBOX/outside" aibos --workspace sync "$V/Garten")" "sys-0.1.0 aibos --workspace sync $V/Garten" "H37: --workspace <path>: the binding at the path"
   assert_eq "$(run "$SANDBOX/outside" aibos --workspace restore "$V/Garten/neu.md" --at 2026-11-06)" "sys-0.1.0 aibos --workspace restore $V/Garten/neu.md --at 2026-11-06" "H37: a file that is gone: its folder"

#===============================================================================
# user installations.yaml wins over the system one, ~ and quotes are resolved
#===============================================================================

   printf 'v0.1.0: "~/dev/aibos clone"\n' > "$HOME/.aibos/installations.yaml"
   assert_eq "$(run "$V/Sterne" aibos --context --id)" "dev-0.1.0 aibos --context --id" "user entry wins, ~ expanded"
   assert_contains "$(run "$V/Sterne" aibos ---which)" "why=aibos: 0.1.0 in $V/.aibos/config.yaml" "---which explains"

#===============================================================================
# bound, but version not installed: --context quiet with a line in the log, else exit 1
#===============================================================================

   printf 'aibos: 0.9.0\n' > "$V/.aibos/config.yaml"
   OUT="$(run "$V/Sterne" aibos --context --session)"; RC=$?
   assert_eq "$RC:$OUT" "0:" "missing version: hook quiet, exit 0"
   assert_contains "$(cat "$HOME/.aibos/log/context.log")" "forwarder cwd=$V/Sterne AIBOS v0.9.0 is not installed" "missing version: line in the log"
   assert_eq "$(run "$V/Sterne" aibos --context --id)" "id=- files=0 cwd=$V/Sterne mode=none" "missing version: --id mode=none"
   OUT="$(run "$V/Sterne" aibos --fetch)"; RC=$?
   assert_eq "$RC" "1" "missing version, other command: exit 1"
   assert_contains "$OUT" "aibos --install v0.9.0" "missing version, other command: hint"

#===============================================================================
# no binding: quiet, legacy only with legacy: ai-brain at the vault root
#===============================================================================

   rm -rf "$V/.aibos" "$V/Garten/.aibos"
   printf 'aibos: 0.1.0\n' > "$SANDBOX/work/.aibos/config.yaml"
   printf 'aibos: 0.1.0\n' > "$HOME/.aibos/config.yaml"
   OUT="$(run "$V/Garten" aibos --context --session)"; RC=$?
   assert_eq "$RC:$OUT" "0:" "vault without binding: no output (I12)"
   assert_eq "$(run "$SANDBOX/outside" aibos --context --advise)" "" "outside a vault: no output"
   assert_eq "$(run "$V/Garten" aibos --context --id)" "id=- files=0 cwd=$V/Garten mode=none" "vault without binding: mode=none"
   assert_eq "$(run "$SANDBOX/outside" aibos --context --list)" "No AIBOS workspace — no master context." "--list outside an A/W"
   assert_eq "$(run "$V/Garten" aibos --fetch)" "sys-0.2.0 aibos --fetch" "other commands: the highest version"
   mkdir -p "$V/Garten/.aibos"; printf 'legacy: ai-brain\n' > "$V/Garten/.aibos/config.yaml"
   assert_eq "$(run "$V/Garten" aibos --context --session)" "" "legacy: in a project does not mark (I14)"
   rm -rf "$V/Garten/.aibos"

   mkdir -p "$V/.aibos"; printf 'legacy: ai-brain\n' > "$V/.aibos/config.yaml"
   assert_eq "$(run "$V/Garten" aibos --context --session)" "ai-brain --session" "legacy: ai-brain with same arguments"
   assert_eq "$(run "$V/Garten" aibos --context)" "ai-brain --context" "legacy: aibos --context is ai-brain --context"
   assert_eq "$(run "$V/Garten" aibos --context "$V/Garten")" "ai-brain --context" "legacy: path argument, ai-brain gets no path"
   assert_eq "$(run "$V/Garten" aibos --context --permit)" "" "legacy: no permission from ai-brain"
   mkdir -p "$V/Anderes/sub"
   assert_eq "$(HOME="$V/Anderes" run "$V/Anderes/sub" "$HOME/bin/aibos" --context)" "ai-brain --context" "~/.aibos/config.yaml never binds, even inside a vault"

   printf '#!/bin/bash\n[ "$*" == "--id" ] && echo "id=abcd1234 files=3 cwd=$PWD" || echo "ai-brain $*"\n' > "$SANDBOX/fake/ai-brain"
   assert_eq "$(run "$V/Garten" aibos --context --id)" "id=abcd1234 files=3 cwd=$V/Garten mode=legacy" "legacy --id: ai-brain output plus mode=legacy"
   assert_eq "$(run "$SANDBOX/outside" aibos --context --id)" "id=- files=0 cwd=$SANDBOX/outside mode=none" "--id outside a vault: mode=none"
   A2="$SANDBOX/work/§Aktiv"; mkdir -p "$A2/.aibos" "$A2/@"; printf 'aibos: 0.1.0\n' > "$A2/.aibos/config.yaml"
   assert_eq "$(run "$SANDBOX/outside" aibos --context --id "$A2")" "dev-0.1.0 aibos --context --id $A2" "path argument: version follows the path, not cwd"
   assert_eq "$(run "$A2" aibos --context --id "$V/Garten")" "id=abcd1234 files=3 cwd=$V/Garten mode=legacy" "path argument: legacy path, ai-brain runs in it"
   assert_eq "$(run "$A2" aibos --context --load "$V/Garten")" "ai-brain --load" "path argument: ai-brain gets no path"
   assert_eq "$(run "$A2" aibos --context --id "$SANDBOX/outside")" "id=- files=0 cwd=$SANDBOX/outside mode=none" "path argument: quiet path"
   assert_eq "$(run "$V/Garten" aibos --context --list)" "Legacy mode (ai-brain, legacy: ai-brain at the vault root) — see /masterspace." "legacy --list"
   rm -rf "$A2"
   rm "$SANDBOX/fake/ai-brain"
   assert_eq "$(run "$V/Garten" aibos --context --id)" "id=- files=0 cwd=$V/Garten mode=legacy" "legacy --id without ai-brain"
   OUT="$(run "$V/Garten" aibos --context --session)"; RC=$?
   assert_eq "$RC:$OUT" "0:" "legacy without ai-brain: no output, exit 0"
   rm -rf "$V/.aibos"

#===============================================================================
# not bound: aibos calls the highest installed version (semver)
#===============================================================================

   printf 'v0.10.0: %s\nv0.2.0-dev: %s\n' "$HOME/dev/v0.10.0" "$HOME/dev/v0.2.0-dev" > "$HOME/.aibos/installations.yaml"
   assert_eq "$(run "$V/Garten" aibos --z)" "dev-0.10.0 aibos --z" "0.10.0 is higher than 0.2.0"

   printf 'v0.2.0-dev: %s\n' "$HOME/dev/v0.2.0-dev" > "$HOME/.aibos/installations.yaml"
   assert_eq "$(run "$SANDBOX/outside" aibos --z)" "sys-0.2.0 aibos --z" "0.2.0 is higher than 0.2.0-dev"

#===============================================================================
# aibos --activate v<version>: that version, whatever cwd is bound to (V0.3, memo 54, A1)
#===============================================================================

   mkdir -p "$V/.aibos"; printf 'aibos: 0.1.0\n' > "$V/.aibos/config.yaml"
   assert_eq "$(run "$V/Sterne" aibos --z)" "sys-0.1.0 aibos --z" "bound vault: its version"
   assert_eq "$(run "$V/Sterne" aibos --activate v0.2.0 /x)" "sys-0.2.0 aibos --activate v0.2.0 /x" "--activate v0.2.0 from a 0.1.0 vault: v0.2.0"
   assert_contains "$(run "$V/Sterne" aibos ---which)" "why=aibos: 0.1.0" "---which: other commands follow cwd"
   assert_eq "$(run "$V/Sterne" aibos --activate v9.9.9 /x)" "sys-0.1.0 aibos --activate v9.9.9 /x" "--activate of a version not installed: cwd decides (it reports the missing version)"
   assert_eq "$(run "$V/Sterne" aibos --context --activate v0.2.0)" "sys-0.1.0 aibos --context --activate v0.2.0" "only aibos --activate, not aibos --context --activate"

#===============================================================================
# aibos --install distribution-*: the highest installed version (V0.5, step 9; v0.7: no lower limit, FL9)
#===============================================================================

   assert_eq "$(run "$V/Sterne" aibos --install distribution-demo)" "sys-0.2.0 aibos --install distribution-demo" "distribution: highest installed version"
   fake_install "$AIBOS_PREFIX/v0.5.0" "sys-0.5.0"
   printf 'v0.5.0: %s\n' "$AIBOS_PREFIX/v0.5.0" >> "$AIBOS_PREFIX/installations.yaml"
   assert_eq "$(run "$V/Sterne" aibos --install distribution-demo "$V")" "sys-0.5.0 aibos --install distribution-demo $V" "distribution: highest version, not that of cwd"
   assert_eq "$(run "$V/Sterne" aibos --install aibex-aibos/distribution-demo==1.0.0)" "sys-0.5.0 aibos --install aibex-aibos/distribution-demo==1.0.0" "distribution with hub and version"
   assert_eq "$(run "$V/Sterne" aibos --install v0.2.0)" "sys-0.1.0 aibos --install v0.2.0" "--install of a version: cwd decides as before"
   assert_eq "$(run "$V/Sterne" aibos --remove-version v0.1.0)" "sys-0.5.0 aibos --remove-version v0.1.0" "B21: --remove-version: highest version, not that of cwd"
   assert_eq "$(run "$V/Sterne" aibos --vaults)" "sys-0.5.0 aibos --vaults" "B21: --vaults: highest version"
   rm -rf "$V/.aibos" "$AIBOS_PREFIX/v0.5.0"

#===============================================================================
# v0.7: Altbindung aios: 0.6.x in .aios/config.yaml calls bin/aios of that version; aios: below 0.6
# counts as no binding; AIOS_HOME and AIOS_PREFIX until 0.8 (spec 04, Weiterleiter; FL6, FL9, FL11)
#===============================================================================

   mkdir -p "$AIBOS_PREFIX/v0.6.6/bin"
   printf '#!/bin/bash\necho "sys-0.6.6 aios $*"\n' > "$AIBOS_PREFIX/v0.6.6/bin/aios"; chmod +x "$AIBOS_PREFIX/v0.6.6/bin/aios"
   printf 'v0.6.6: %s\n' "$AIBOS_PREFIX/v0.6.6" >> "$AIBOS_PREFIX/installations.yaml"
   mkdir -p "$V/.aios"; printf 'aios: 0.6.6\n' > "$V/.aios/config.yaml"
   assert_eq "$(run "$V/Sterne" aibos --context --session)" "sys-0.6.6 aios --context --session" "Altbindung: bin/aios of 0.6.6"
   assert_contains "$(run "$V/Sterne" aibos ---which)" "why=aios: 0.6.6 in $V/.aios/config.yaml" "Altbindung: ---which names .aios/config.yaml"
   printf 'aios: 0.5.1\n' > "$V/.aios/config.yaml"
   assert_eq "$(run "$V/Sterne" aibos --context --id)" "id=- files=0 cwd=$V/Sterne mode=none" "aios: below 0.6: no binding (FL9)"
   printf 'legacy: ai-brain\n' > "$V/.aios/config.yaml"
   assert_contains "$(run "$V/Sterne" aibos --context --id)" "mode=legacy" "legacy: ai-brain in .aios/config.yaml"
   mkdir -p "$V/.aibos"; printf 'aibos: 0.2.0\n' > "$V/.aibos/config.yaml"; printf 'aios: 0.6.6\n' > "$V/.aios/config.yaml"
   assert_eq "$(run "$V/Sterne" aibos --fetch)" "sys-0.2.0 aibos --fetch" ".aibos/ wins over .aios/"
   rm -rf "$V/.aibos" "$V/.aios" "$AIBOS_PREFIX/v0.6.6"; sed -i.bak -e '/^v0.6.6:/d' -e '/^v0.5.0:/d' "$AIBOS_PREFIX/installations.yaml"
   assert_eq "$(cd "$V/Sterne" && AIOS_HOME="$AIBOS_PREFIX/v0.1.0" aibos --z)" "sys-0.1.0 aibos --z" "AIOS_HOME until 0.8"
   assert_eq "$(cd "$V/Sterne" && env -u AIBOS_PREFIX AIOS_PREFIX="$AIBOS_PREFIX" aibos --z)" "sys-0.2.0 aibos --z" "AIOS_PREFIX until 0.8"

   rm -f "$HOME/.aibos/installations.yaml" "$AIBOS_PREFIX/installations.yaml"
   assert_exit 1 aibos --z
   assert_contains "$(aibos --z 2>&1)" "no installation of AIBOS found" "no installation: message"

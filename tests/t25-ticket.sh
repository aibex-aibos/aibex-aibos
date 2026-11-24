# t25-ticket.sh: v0.7.1 step 1 - tickets in the mailbox @/@!Ticket, aibos --ticket (spec 06, Tickets;
#                V0.7, memos 74-76, 81: F389, F392, F393, FL62-FL64)

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# setup: vault §V bound to 0.7.1, project PA with skill-memo 6.1.0 in lock.yaml, mailbox with tickets
#===============================================================================

   mk() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" > "$1"; }
   V="$SANDBOX/work/§V"
   T="$V/@/@!Ticket"
   mk "$V/.aibos/config.yaml" $'aibos: 0.7.1\n'
   mk "$V/@/.gitkeep" ""
   mk "$V/PA/@/.gitkeep" ""
   mk "$V/PA/.aibos/lock.yaml" $'packages:\n  skill-memo:\n    version: 6.1.0\n    hub: aibex-aibos\n'
   tk() {                                           # tk <file> <package> <version> [<extra lines>]
      mk "$1" "---"$'\n'"type: improvement"$'\n'"package: $2"$'\n'"version: $3"$'\n'"date: 2026-11-24"$'\n'"author: iHux"$'\n'"project: PA"$'\n'"${4:-}---"$'\n\n'"# Wunsch"$'\n'
   }
   tk "$T/2026-11-24-0901 Memo kuerzer.md" skill-memo 6.1.0
   tk "$T/2026-11-24-0902 Memo alt.md" skill-memo 6.0.0
   tk "$T/2026-11-24-0903 Gaertner freundlicher.md" assistant-gaertner 0.4.0 $'element: gaertner\n'
   tk "$T/2026-11-24-0904 Erledigt.md" skill-memo 6.1.0 $'status: aufgenommen\nmemo: PA, Memo 01\n'
   tk "$T/2026-11-24-0905 Kernel.md" aibos 0.7.0
   tk "$T/2026-11-24-0906 Ein sehr langer Titel fuer einen Wunsch an den Memo-Skill.md" skill-memo 6.1.0
   mk "$T/2026-11-24-0907 Ohne Paket.md" $'---\ntype: improvement\nversion: 0.1.0\n---\n# x\n'
   mk "$T/2026-11-24-0908 Ohne Kopf.md" $'# nur Text\n'
   tk "$V/@/@!Improve/2026-11-16-1200 Alter Ordner.md" skill-memo 6.1.0
   SUM="$(cd "$V/@" && find . -type f -exec cksum {} + | sort)"
   A() { (cd "$1" && "$SRC/bin/aibos" --ticket "${@:2}" 2>&1); }

#===============================================================================
# aibos --ticket: open tickets, columns, notes, result
#===============================================================================

   OUT="$(A "$V/PA")"
   assert_contains "$OUT" "Tickets §V — $(date +%F)" "header with vault and date"
   assert_contains "$OUT" "Result: 6 open tickets (1 aibos, 1 assistant-gaertner, 4 skill-memo)" "six open tickets, counted per package"
   assert_not_contains "$OUT" "Erledigt" "a ticket with status is not open"
   assert_contains "$OUT" "Element" "column Element when a ticket has an element"
   assert_contains "$OUT" "gaertner" "the element is shown"
   assert_contains "$OUT" "@!Improve/2026-11-16-1200 Alter Ordner" "a ticket of the old folder with the folder in File (F393)"
   assert_contains "$OUT" "- note: @/@!Improve/ is the folder of AIBOS 0.7.0; move its files to @/@!Ticket/" "note on the old folder"
   assert_contains "$OUT" "- 2026-11-24-0902 Memo alt: version 6.0.0 is older than skill-memo 6.1.0 in $V/PA/.aibos/lock.yaml" "older than the version in lock.yaml (FL64)"
   assert_contains "$OUT" "- 2026-11-24-0905 Kernel: version 0.7.0 is older than aibos 0.7.1 in the binding of the vault" "aibos: older than the binding"
   assert_not_contains "$OUT" "0901 Memo kuerzer: version" "same version: no note"
   assert_contains "$OUT" "- 2026-11-24-0907 Ohne Paket: not a ticket (no package); left as it is" "a file without package"
   assert_contains "$OUT" "- 2026-11-24-0908 Ohne Kopf: not a ticket (no front matter); left as it is" "a file without front matter"
   assert_contains "$OUT" "2026-11-24-0906 Ein sehr langer Titel fuer e… " "File shortened to 45 characters"
   assert_exit 0 bash -c "cd '$V/PA' && '$SRC/bin/aibos' --ticket"

   OUT="$(A "$V")"
   assert_not_contains "$OUT" "Memo alt: version" "at the vault root no lock.yaml with skill-memo: no note"
   assert_contains "$OUT" "Kernel: version 0.7.0 is older" "at the vault root the binding counts"

#===============================================================================
# filters
#===============================================================================

   OUT="$(A "$V/PA" skill-memo)"
   assert_contains "$OUT" "Result: 4 open tickets (4 skill-memo)" "filter by package"
   assert_not_contains "$OUT" "Element" "no column Element without an element in the list"
   assert_contains "$(A "$V/PA" --type improvement)" "Result: 6 open tickets" "filter by type"
   assert_contains "$(A "$V/PA" --type bug)" "Result: 0 open tickets" "no ticket of that type"
   assert_contains "$(A "$V/PA" assistant-gaertner --type improvement)" "Result: 1 open ticket (1 assistant-gaertner)" "both filters, singular"
   assert_contains "$(A "$V/PA" a b)" "usage: aibos --ticket [<package>] [--type <type>]" "two packages: usage"
   assert_exit 1 bash -c "cd '$V/PA' && '$SRC/bin/aibos' --ticket a b"

#===============================================================================
# read only, no mailbox, outside an A/W
#===============================================================================

   assert_eq "$(cd "$V/@" && find . -type f -exec cksum {} + | sort)" "$SUM" "the mailbox is unchanged (P6)"
   mk "$SANDBOX/work/§Leer/.aibos/config.yaml" $'aibos: 0.7.1\n'
   OUT="$(A "$SANDBOX/work/§Leer")"
   assert_contains "$OUT" "Result: 0 open tickets" "vault without a mailbox"
   assert_not_contains "$OUT" "Notes" "no notes without a mailbox"
   mkdir -p "$SANDBOX/work/draussen"
   assert_eq "$(A "$SANDBOX/work/draussen")" "Kein AIBOS-Workspace: $SANDBOX/work/draussen" "outside an A/W: the message of aibos --skill"
   assert_exit 1 bash -c "cd '$SANDBOX/work/draussen' && '$SRC/bin/aibos' --ticket"
   mk "$SANDBOX/work/§Alt/.aibos/config.yaml" $'legacy: ai-brain\n'
   assert_contains "$(A "$SANDBOX/work/§Alt")" "Kein AIBOS-Workspace" "legacy vault: no A/W"

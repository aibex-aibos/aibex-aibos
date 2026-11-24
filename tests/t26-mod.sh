# t26-mod.sh: v0.7.1 step 5 - packages of type mod, aibos --mod install|uninstall (spec 06, Mods;
#             V0.7, memos 77-79: F399-F403, FL70-FL75; FL78: a fake claude, never the real one)

   case "$SANDBOX" in */aibos-test.*) ;; *) echo "*** run via tests/run, never directly (it would touch the real HOME)" >&2; exit 1;; esac

#===============================================================================
# setup: python3 with PyYAML, test hubs, vault §M bound to 0.7.1, a fake claude that logs its calls
#===============================================================================

   PYDIR=""
   for P in $(type -ap python3) /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
      [ -x "$P" ] && "$P" -c "import yaml" 2>/dev/null && { PYDIR="$(dirname "$P")"; break; }
   done
   [ -n "$PYDIR" ] && ok || fail "t26 needs a python3 with PyYAML"
   export PATH="$PYDIR:/usr/bin:/bin:/usr/sbin:/sbin"
   export AIBOS_HUBS="$("$SRC/tests/hub/build" "$SANDBOX/hubs")"
   mk() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" > "$1"; }
   M="$SANDBOX/work/§M"; P="$M/PA"
   mk "$M/.aibos/config.yaml" $'aibos: 0.7.1\nhubs: [aibex-aibos]\n'; mk "$M/@/.gitkeep" ""
   mk "$P/@/.gitkeep" ""
   FAKE="$SANDBOX/fake/claude"; ST="$SANDBOX/claude-state.json"; LOG="$SANDBOX/claude.log"
   mk "$FAKE" '#!'"$PYDIR"'/python3
import json, os, sys
st, log = sys.argv[0] + ".state", sys.argv[0] + ".log"
st = os.environ["FAKE_STATE"]; log = os.environ["FAKE_LOG"]
s = json.load(open(st)) if os.path.exists(st) else {"plugins": [], "markets": []}
a = sys.argv[1:]
open(log, "a").write(" ".join(a) + "\n")
if a[:3] == ["plugin", "list", "--json"]:
    print(json.dumps(s["plugins"]))
elif a[:4] == ["plugin", "marketplace", "list", "--json"]:
    print(json.dumps(s["markets"]))
elif a[:3] == ["plugin", "marketplace", "add"]:
    name = json.load(open(os.path.join(a[3], ".claude-plugin", "marketplace.json")))["name"]
    s["markets"].append({"name": name, "source": {"source": "directory", "path": os.path.realpath(a[3])}})
elif a[:2] == ["plugin", "install"]:
    s["plugins"].append({"id": a[2], "version": "0.1.0", "scope": "user", "enabled": True})
elif a[:2] == ["plugin", "uninstall"]:
    s["plugins"] = [p for p in s["plugins"] if p["id"] != a[2]]
elif a[:3] == ["plugin", "marketplace", "remove"]:
    s["markets"] = [m for m in s["markets"] if m["name"] != a[3]]
else:
    sys.exit(2)
json.dump(s, open(st, "w"))
'
   chmod +x "$FAKE"
   export FAKE_STATE="$ST" FAKE_LOG="$LOG" AIBOS_CLAUDE="$FAKE"
   A() { (cd "$P" && "$SRC/bin/aibos" "$@" 2>&1); }
   PKG="$P/@/@!Package"

#===============================================================================
# fetch: type mod without warning, check of mod/.claude-plugin, note, nothing installed
#===============================================================================

   OUT="$(A --fetch mod-kaputt --plan)"
   assert_contains "$OUT" "mod: mod/.claude-plugin/marketplace.json is missing" "mod without marketplace.json: not fetched"
   [ ! -e "$PKG/mod-kaputt" ] && ok || fail "mod-kaputt: nothing written"
   OUT="$(A --fetch mod-probe --plan)"
   assert_contains "$OUT" "note: mod-probe acts for all sessions of this computer once installed with aibos --mod install mod-probe" "plan: the mod acts for the whole computer"
   assert_not_contains "$OUT" "unknown type" "type mod without warning"
   A --fetch mod-probe --yes >/dev/null
   assert_file "$PKG/mod-probe/mod/.claude-plugin/plugin.json"
   [ ! -e "$LOG" ] && ok || fail "fetching calls no claude"
   assert_contains "$(A --deploy)" "mod" "the element mod is shown by --deploy"

#===============================================================================
# aibos --mod: list, install with plan and yes, uninstall; the package stays
#===============================================================================

   assert_contains "$(A --mod)" "mod-probe  not installed" "list: not installed"
   OUT="$(A --mod install mod-probe --plan)"
   assert_contains "$OUT" "claude plugin marketplace add \"$PKG/mod-probe/mod\" --scope user" "plan: marketplace add"
   assert_contains "$OUT" "claude plugin install probe@mod-probe --scope user" "plan: install"
   assert_not_contains "$(cat "$LOG" 2>/dev/null)" "marketplace add" "--plan: no call of claude that writes"
   A --mod install mod-probe --yes >/dev/null
   assert_contains "$(cat "$LOG")" "plugin marketplace add $(cd "$PKG/mod-probe/mod" && pwd -P)" "install: marketplace add called"
   assert_contains "$(cat "$LOG")" "plugin install probe@mod-probe --scope user" "install: install called"
   assert_eq "$(A --mod | grep mod-probe)" "   mod-probe  installed" "list: installed"
   assert_contains "$(A --mod install mod-probe --yes)" "nothing to do" "install twice: nothing to do (I8)"
   OUT="$(A --fetch --remove mod-probe --plan)"
   assert_contains "$OUT" "mod-probe is installed in Claude Code from this folder; run aibos --mod uninstall mod-probe first" "remove: stops while installed"
   assert_dir "$PKG/mod-probe"
   A --mod uninstall mod-probe --yes >/dev/null
   assert_contains "$(cat "$LOG")" "plugin uninstall probe@mod-probe --scope user" "uninstall: uninstall called"
   assert_contains "$(cat "$LOG")" "plugin marketplace remove mod-probe" "uninstall: marketplace remove called"
   assert_contains "$(A --mod)" "mod-probe  not installed" "list: not installed again"
   assert_dir "$PKG/mod-probe"
   A --fetch --remove mod-probe --yes >/dev/null
   [ ! -e "$PKG/mod-probe" ] && ok || fail "remove after uninstall: removed"

#===============================================================================
# install fetches first; installed elsewhere; no claude; usage
#===============================================================================

   : > "$LOG"
   OUT="$(A --mod install mod-probe --plan)"
   assert_contains "$OUT" "fetch      mod-probe into $P" "install without the package: fetched first"
   A --mod install mod-probe --yes >/dev/null
   assert_file "$PKG/mod-probe/mod/.claude-plugin/plugin.json"
   assert_eq "$(A --mod | grep mod-probe)" "   mod-probe  installed" "fetched and installed in one plan"
   python3 -c "import json,sys; s=json.load(open(sys.argv[1])); s['markets'][0]['source']['path']='/anders'; json.dump(s, open(sys.argv[1],'w'))" "$ST"
   assert_contains "$(A --mod)" "mod-probe  installed elsewhere" "same plugin from another folder"
   assert_eq "$(AIBOS_CLAUDE="" PATH="$PYDIR:/usr/bin:/bin" bash -c "cd '$P' && '$SRC/bin/aibos' --mod install mod-probe --yes" 2>&1)" "*** aibos --mod: claude not found" "no claude: the message (FL74)"
   assert_contains "$(A --mod install)" "usage: aibos --mod" "install without a mod: usage"
   assert_contains "$(A --mod install skill-memo --plan)" "skill-memo is no mod" "a package that is no mod"

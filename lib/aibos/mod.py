"""aibos --mod: mods of Claude Code as packages (spec 06, Mods; V0.7, memos 77-79: F399-F403, FL70-FL75).

A package of type mod brings a folder mod/ with .claude-plugin/plugin.json and marketplace.json.
Fetching it installs nothing in Claude Code. aibos --mod install|uninstall does that on the user's
request, with a plan and a yes, through the CLI claude plugin (scope user). AIBOS writes nothing
under ~/.claude/ itself; Claude Code does (spec 01, I13).
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

from . import config, paths, ui
from .ui import Abort, Plan, confirm, say

NOTE = "note: {pkg} acts for all sessions of this computer once installed with aibos --mod install {pkg}"
REMOVE_STOP = "{pkg} is installed in Claude Code from this folder; run aibos --mod uninstall {pkg} first"


def claude():
    """Path of the CLI claude, or None."""
    return os.environ.get("AIBOS_CLAUDE") or shutil.which("claude")


def run(*args):
    exe = claude()
    if exe is None:
        raise Abort("claude not found")
    return subprocess.run([exe, *args], capture_output=True, text=True)


def as_list(text):
    try:
        data = json.loads(text or "[]")
    except ValueError:
        return []
    return data if isinstance(data, list) else []


def state(folder):
    """installed (from this folder), installed elsewhere or not installed (FL72); None without claude."""
    from . import package
    if claude() is None:
        return None
    plugin, market = package.mod_identity(folder)
    plugins = as_list(run("plugin", "list", "--json").stdout)
    ids = [str(x.get("id") or "") for x in plugins if isinstance(x, dict)]
    markets = as_list(run("plugin", "marketplace", "list", "--json").stdout)
    here = os.path.realpath(Path(folder) / "mod")
    ours = any(isinstance(m, dict) and m.get("name") == market and here in json.dumps(m, ensure_ascii=False) for m in markets)
    if f"{plugin}@{market}" in ids and ours:
        return "installed"
    if any(i.split("@")[0] == plugin for i in ids):
        return "installed elsewhere"
    return "not installed"


def installed_here(folder):
    """True if the mod in folder (a package folder under @!Package) is installed from it; never fails."""
    try:
        return state(folder) == "installed"
    except Exception:                               # noqa: BLE001 - only a guard for --remove
        return False


def mods(project):
    """(package name, folder) of the fetched mods of a project."""
    from . import fetch, package
    out = []
    for name, entry in (fetch.read_lock(project).get("packages") or {}).items():
        d = fetch.package_dir(project, name)
        try:
            if package.load(d).type == "mod":
                out.append((name, d))
        except Exception:                           # noqa: BLE001 - a broken package is no mod here
            continue
    return sorted(out)


def show(to=None):
    project = project_root(to)
    found = mods(project)
    if not found:
        say(f"=> no mods fetched in {project}")
        return 0
    say(f"=> mods fetched in {project}")
    if claude() is None:
        for name, _ in found:
            say(f"   {name}  (state unknown: claude not found)")
        return 0
    for name, d in found:
        say(f"   {name}  {state(d)}")
    return 0


def project_root(to):
    """The project the mods are fetched in: --to, else the nearest project of cwd (folder with @/)."""
    start = Path(os.path.realpath(to or paths.cwd()))
    if config.load(start).kind != "aibos":
        raise Abort(f"{start} is not in an AIBOS workspace")
    for d in [start, *start.parents]:
        if (d / "@").is_dir():
            return d
        if config.vault_root(d) == d:
            break
    return start


def install(pkg, to=None):
    """aibos --mod install <mod> [--to <project>]: fetch if needed, then claude plugin marketplace add
    and claude plugin install (scope user), after a plan and a yes (I7)."""
    from . import fetch, package
    if not pkg.startswith("mod-"):
        raise Abort(f"{pkg} is no mod (the name of a mod package starts with mod-)")
    if claude() is None:
        raise Abort("claude not found")
    project = project_root(to)
    d = fetch.package_dir(project, pkg)
    plan = Plan()
    fetched = d.is_dir()
    if fetched:
        plugin, market = package.mod_identity(d)
        if state(d) == "installed":
            say(f"=> {pkg} is installed in Claude Code from {d / 'mod'}, nothing to do")
            return 0
    else:
        plugin, market = pkg[len("mod-"):], "<from marketplace.json>"
        plan.add(f"fetch      {pkg} into {project} (aibos --fetch {pkg} --to {project})",
                 lambda: fetch_quietly(pkg, project))
    folder = d / "mod"
    plan.add(f"claude plugin marketplace add \"{folder}\" --scope user",
             lambda: install_steps(d, "add"))
    plan.add(f"claude plugin install {plugin}@{market} --scope user", lambda: install_steps(d, "install"))
    plan.add(f"the mod acts for all sessions of this computer; it shows after /reload-plugins or in the next chat")
    say(f"=> install the mod {pkg} in Claude Code")
    if not confirm(plan, "install?", "installation cancelled"):
        return 1
    say(f"=> {pkg} installed in Claude Code (from {folder})")
    return 0


def fetch_quietly(pkg, project):
    from . import fetch
    old = ui.MODE
    ui.MODE = "yes"
    try:
        fetch.add(pkg, to=str(project))
    finally:
        ui.MODE = old


def install_steps(d, which):
    from . import package
    plugin, market = package.mod_identity(d)
    if which == "add":
        r = run("plugin", "marketplace", "add", str(d / "mod"), "--scope", "user")
    else:
        r = run("plugin", "install", f"{plugin}@{market}", "--scope", "user")
    if r.returncode != 0:
        raise Abort(f"claude plugin {which} failed: {(r.stderr or r.stdout).strip()}")


def uninstall(pkg, to=None):
    """aibos --mod uninstall <mod>: claude plugin uninstall and marketplace remove; the package stays."""
    from . import fetch, package
    if claude() is None:
        raise Abort("claude not found")
    project = project_root(to)
    d = fetch.package_dir(project, pkg)
    if not d.is_dir():
        raise Abort(f"{pkg} is not fetched in {project}")
    plugin, market = package.mod_identity(d)
    if state(d) != "installed":
        say(f"=> {pkg} is not installed in Claude Code from {d / 'mod'}, nothing to do")
        return 0
    plan = Plan()
    plan.add(f"claude plugin uninstall {plugin}@{market} --scope user",
             lambda: check(run("plugin", "uninstall", f"{plugin}@{market}", "--scope", "user"), "uninstall"))
    plan.add(f"claude plugin marketplace remove {market}",
             lambda: check(run("plugin", "marketplace", "remove", market), "marketplace remove"))
    plan.add(f"the package stays in {project}; remove it with aibos --fetch --remove {pkg}")
    say(f"=> uninstall the mod {pkg} from Claude Code")
    if not confirm(plan, "uninstall?", "uninstallation cancelled"):
        return 1
    say(f"=> {pkg} uninstalled from Claude Code")
    return 0


def check(r, what):
    if r.returncode != 0:
        raise Abort(f"claude plugin {what} failed: {(r.stderr or r.stdout).strip()}")


def command(args):
    """aibos --mod [install <mod> [--to <project>] | uninstall <mod>] [--to <project>]."""
    to, rest, i = None, [], 0
    while i < len(args):
        if args[i] == "--to" and i + 1 < len(args):
            to = args[i + 1]
            i += 2
            continue
        rest.append(args[i])
        i += 1
    usage = "usage: aibos --mod [install <mod> [--to <project>] | uninstall <mod>]"
    if not rest:
        return show(to)
    if len(rest) == 2 and rest[0] == "install":
        return install(rest[1], to)
    if len(rest) == 2 and rest[0] == "uninstall":
        return uninstall(rest[1], to)
    raise Abort(usage)

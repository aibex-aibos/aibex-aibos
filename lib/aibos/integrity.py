"""aibos --integrity: integrity of a project and all its subprojects (spec 05, Integrität).

Read only (spec 01, I7). Init uses the structure check S1-S4 of project.py, the same check
as aibos --init and the consistency check of the SessionStart hook.
"""

from __future__ import annotations

import datetime
import os
import re
from dataclasses import dataclass, field
from pathlib import Path

from . import paths, project, ui

SKIP = ("node_modules",)                            # besides folders starting with . or @


@dataclass
class Result:
    path: Path
    depth: int                                      # number of projects above it in the report
    gaps: list = field(default_factory=list)
    changed: int = 0
    new: int = 0
    repo: bool = False
    hints: list = field(default_factory=list)
    init_note: str = ""                             # workspace: missing: clone, foreign repo (spec 05)

    @property
    def init_ok(self):
        return not self.gaps and self.init_note != "missing: clone"

    @property
    def commit_ok(self):
        return self.repo and not self.changed and not self.new

    @property
    def ok(self):
        return self.init_ok and self.commit_ok

    def init_text(self):
        """Short, so that the table does not wrap in the chat; the gaps are listed under Notes (A15)."""
        if self.init_note:
            return self.init_note
        if self.init_ok:
            return "ok"
        return f"missing: {len(self.gaps)} part" + ("" if len(self.gaps) == 1 else "s")

    def commit_text(self):
        if not self.repo:
            return "—"
        if self.commit_ok:
            return "ok"
        return f"{self.changed} changed, {self.new} new"


def projects(start):
    """(path, depth) of start (if it is a project) and all projects below it, in report order:
    folders with @/, also through containers; hidden folders, @-folders and node_modules are
    not searched, symbolic links are not followed."""
    found = []

    def walk(d, depth):
        is_project = (d / "@").is_dir()
        if is_project:
            found.append((d, depth))
        try:
            children = sorted(c for c in d.iterdir() if c.is_dir() and not c.is_symlink())
        except OSError:
            return
        for c in children:
            if c.name.startswith((".", "@")) or c.name in SKIP:
                continue
            walk(c, depth + 1 if is_project else depth)

    walk(start, 0)
    return found


def commit_state(p):
    """(changed, new) entries of git status --porcelain of the own repo of p."""
    out = project.git(p, "status", "--porcelain", "--untracked-files=all").stdout
    lines = [line for line in out.splitlines() if line]
    new = sum(1 for line in lines if line.startswith("??"))
    return len(lines) - new, new


def commits(n):
    return f"{n} commit" + ("" if n == 1 else "s")


def push_hints(p):
    """Ahead/behind the upstream, from the local state without fetch; nothing without upstream."""
    r = project.git(p, "rev-list", "--left-right", "--count", "@{upstream}...HEAD")
    if r.returncode != 0:
        return []
    behind, ahead = (int(x) for x in r.stdout.split())
    upstream = project.git(p, "rev-parse", "--abbrev-ref", "@{upstream}").stdout.strip()
    remote = upstream.split("/", 1)[0] or upstream
    hints = []
    if ahead:
        hints.append(f"{commits(ahead)} not pushed")
    if behind:
        hints.append(f"{commits(behind)} behind {remote}")
    return hints


def agents_hints(p):
    """Outdated copies in <p>/.agents/skills/ (spec 05, Integrität; V0.5, memos 10, 24, N11):
    copies with the marker .aibos-deploy whose version is not the registered one or whose skill
    is not registered any more. AIBOS changes and removes nothing there (option C)."""
    from . import registry
    base = Path(p) / ".agents" / "skills"
    if not base.is_dir():
        return []
    registered = registry.read_registry(p)
    hints = []
    from . import legacy
    for d in sorted(x for x in base.iterdir() if legacy.marker_file(x) is not None):
        marker = registry.read_manifest_marker(legacy.marker_file(d))
        name, ver = marker.get("name") or d.name, marker.get("version", "?")
        if name not in registered:
            hints.append(f"outdated copy .agents/skills/{d.name} ({name} {ver}): skill not registered here")
        elif registered[name].get("version") != ver:
            hints.append(f"outdated copy .agents/skills/{d.name} ({name} {ver}): registered is "
                         f"{registered[name].get('version')}")
    return hints


def binding_hints(p):
    """aibos: or legacy: outside the vault root, and both together at the vault root (spec 05,
    Integrität; V0.6, memos 16, 17)."""
    from . import config
    f = Path(p) / ".aibos" / "config.yaml"
    if not f.is_file():
        return []
    try:
        data = config.read(f)
    except (config.ConfigError, UnicodeDecodeError):
        return []
    keys = [k for k in config.ROOT_ONLY if k in data]
    if not keys:
        return []
    if config.vault_root(p) != Path(os.path.realpath(p)):
        return [f"{', '.join(k + ':' for k in keys)} in .aibos/config.yaml ignored (only at the vault root)"]
    if len(keys) == 2:
        return ["aibos: and legacy: together in .aibos/config.yaml, aibos: applies"]
    return []


WS_PATH = re.compile(r"""^\s*(?:-\s*)?path:\s*["']?([^"'#\n]+?)["']?\s*(?:#.*)?$""")


def workspace_paths(p):
    """(root, paths) of the nearest workspace.yaml at or above p up to the vault root: every path in
    projects and removed, read with the standard library (t12 runs without PyYAML)."""
    from . import config
    vault = config.vault_root(p)
    d = Path(os.path.realpath(p))
    while True:
        f = d / ".aibos" / "workspace.yaml"
        if f.is_file():
            try:
                lines = f.read_text(encoding="utf-8").splitlines()
            except (OSError, UnicodeDecodeError):
                return d, set()
            return d, {m.group(1).strip().rstrip("/") for m in map(WS_PATH.match, lines) if m}
        if vault is None or d == vault or d.parent == d:
            return None, set()
        d = d.parent


def exclusion_hints(p):
    """v0.7.1 (spec 05, Integrität, Verwaister Ausschluss; W5, F394, FL68): a line /<name>/ in the
    .gitignore of p whose folder is missing and whose path is neither in projects nor in removed of
    the workspace.yaml (Spec 06); a placeholder of a detached subtree is a folder and does not count."""
    f = Path(p) / ".gitignore"
    try:
        lines = f.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        return []
    root, known = workspace_paths(p)
    hints = []
    for line in lines:
        s = line.strip()
        if not (s.startswith("/") and s.endswith("/")) or len(s) < 3 or any(c in s for c in "*?[]!"):
            continue
        name = s[1:-1]
        if name.split("/")[0].startswith((".", "@")) or (Path(p) / name).exists():
            continue
        if root is not None:
            rel = os.path.relpath(os.path.realpath(Path(p)) + "/" + name, root)
            if rel in known:
                continue
        hints.append(f"exclusion /{name}/ in .gitignore has no folder; remove the line")
    return hints


def registration_hints(p):
    """v0.7.1 (spec 05, Integrität, Veraltete Registrierung; F390, FL68): wrappers aibos --register
    would create, change or remove in p; only in an A/W; never changes the result."""
    try:
        from . import config, context, registry
        if config.load(p).kind != "aibos":
            return []
        s = registry.Sync(context.Context(p), with_root=False)
    except Exception:                               # noqa: BLE001 - a hint never breaks the check
        return []
    n = len(s.new) + len(s.changed) + len(s.new_k) + len(s.changed_k) + len(s.removed)
    if not n:
        return []
    return [f"registration out of date ({n} wrappers); run aibos --register \"{p}\""]


def check(p, depth):
    r = Result(p, depth, gaps=project.check(p), repo=project.own_repo(p))
    if r.gaps:
        r.hints.append("missing " + ", ".join(g.text for g in r.gaps))
    if r.repo:
        r.changed, r.new = commit_state(p)
        r.hints += push_hints(p)
    r.hints += agents_hints(p)
    r.hints += binding_hints(p)
    r.hints += exclusion_hints(p)
    r.hints += registration_hints(p)
    if r.repo and not project.git(p, "ls-files", "@").stdout.strip():
        r.hints.append("@/ holds no tracked file, a clone lacks it; commit @/.gitkeep (B32)")
    name = project.check_name(p)
    if not name.ok:
        r.hints.append("name violates the name rule (" + "; ".join(name.problems)
                       + (f"), proposal {name.proposal}" if name.proposal else ")"))
    return r


def report(start, results):
    print(f"Integrity {start.name} — {datetime.date.today().isoformat()}")
    print()
    if not results:
        print(f"No projects in {start}")
        return
    rows = [("Project", "Init", "Commit")]
    rows += [("  " * r.depth + r.path.name, r.init_text(), r.commit_text()) for r in results]
    w1 = max(len(a) for a, _, _ in rows) + 2
    w2 = max(len(b) for _, b, _ in rows) + 2
    for a, b, c in rows:
        print(f"{a:<{w1}}{b:<{w2}}{c}".rstrip())
    hints = [f"- {r.path.name}: {h}" for r in results for h in r.hints]
    if hints:
        print()
        print("Notes")
        print("\n".join(hints))
    print()
    good = sum(1 for r in results if r.ok)
    print(f"Result: {good} of {len(results)} " + ("project" if len(results) == 1 else "projects")
          + " integer")


def run(path=None):
    """aibos --integrity [<path>]: report, exit 0 if all projects are integer, else 1."""
    start = Path(os.path.realpath(path or paths.cwd()))
    if not start.is_dir():
        raise ui.Abort(f"{start} is not a directory")
    results = [check(p, depth) for p, depth in projects(start)]
    from . import workspace
    workspace.integrity(start, results)             # projects of a workspace.yaml (spec 05, F2)
    report(start, results)
    return 0 if all(r.ok for r in results) else 1

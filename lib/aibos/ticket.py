"""Tickets in the mailbox <vault-root>/@/@!Ticket/ (spec 06, Tickets; V0.7, memos 74, 75, 76).

A ticket is a Markdown file with front matter: type, package, version, date, author, project, optional
element and status. A ticket without status is open. AIBOS only reads the mailbox (P6). Until 0.8
the folder of AIBOS 0.7.0, <vault-root>/@/@!Improve/, is read as well (F393).
"""

from __future__ import annotations

import datetime
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path

from . import config, paths, semver, ui

FOLDER = "@!Ticket"                                 # spec 06, Tickets
OLD_FOLDER = "@!Improve"                            # AIBOS 0.7.0, read until 0.8 (F393)
WIDTH = 45                                          # column File, shortened with …
OLD_NOTE = "note: @/@!Improve/ is the folder of AIBOS 0.7.0; move its files to @/@!Ticket/"
PATHS_NOTE = "note: full paths: aibos --ticket [<package>] --paths"   # B70, F423: where the full names are


@dataclass
class Ticket:
    file: Path
    data: dict = field(default_factory=dict)
    old: bool = False                               # lies in @/@!Improve/

    @property
    def name(self):
        return self.file.stem

    @property
    def shown(self):
        """Name in the column File: without .md, with the folder for the old one, at most WIDTH chars."""
        text = (OLD_FOLDER + "/" if self.old else "") + self.name
        return text if len(text) <= WIDTH else text[:WIDTH - 1] + "…"

    def get(self, key):
        v = self.data.get(key)
        return "" if v is None else str(v)

    @property
    def open(self):
        return not self.get("status").strip()


def folders(vault):
    """(folder, old) of the mailboxes of a vault root that exist."""
    out = []
    for name, old in ((FOLDER, False), (OLD_FOLDER, True)):
        d = Path(vault) / "@" / name
        if d.is_dir():
            out.append((d, old))
    return out


def front_matter(file):
    """Front matter of a Markdown file as a dict, or None (no front matter, unreadable)."""
    import yaml
    try:
        text = file.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None
    if not text.startswith("---"):
        return None
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            try:
                data = yaml.safe_load("\n".join(lines[1:i])) or {}
            except yaml.YAMLError:
                return None
            return data if isinstance(data, dict) else None
    return None


def scan(vault):
    """(tickets, problems) of the mailboxes of a vault: all tickets (open and closed) and
    (file, reason) for Markdown files that are no tickets."""
    tickets, problems = [], []
    for d, old in folders(vault):
        for f in sorted(d.glob("*.md")):
            data = front_matter(f)
            if data is None:
                problems.append((f, old, "no front matter"))
                continue
            missing = [k for k in ("type", "package") if not str(data.get(k) or "").strip()]
            if missing:
                problems.append((f, old, "no " + " and no ".join(missing)))
                continue
            tickets.append(Ticket(f, data, old))
    return tickets, problems


def locked_version(name, path):
    """(version, lock.yaml) of the package in the nearest lock.yaml of the chain of path, or (None, None)."""
    import yaml
    for d in config.chain_dirs(path):
        f = d / ".aibos" / "lock.yaml"
        if not f.is_file():
            continue
        try:
            data = yaml.safe_load(f.read_text(encoding="utf-8")) or {}
        except (OSError, UnicodeDecodeError, yaml.YAMLError):
            continue
        e = (data.get("packages") or {}).get(name)
        if isinstance(e, dict) and e.get("version"):
            return str(e["version"]), f
    return None, None


def older(t, cfg, path):
    """Note if the ticket was written for an older version than the one in use, else None (FL64)."""
    if t.get("package") == "aibos":
        current, where = cfg.binding, "the binding of the vault"
    else:
        current, lock = locked_version(t.get("package"), path)
        where = str(lock) if lock else ""
    if not current:
        return None
    try:
        if semver.Version.parse(t.get("version")).release() < semver.Version.parse(current).release():
            return f"version {t.get('version')} is older than {t.get('package')} {current} in {where}"
    except (semver.VersionError, ValueError, AttributeError):
        return None
    return None


def open_tickets(vault, package=None, kind=None):
    tickets, problems = scan(vault)
    out = [t for t in tickets if t.open
           and (package is None or t.get("package") == package)
           and (kind is None or t.get("type") == kind)]
    return out, problems


def session_packages(path, assistant_dir=None, assistant_name=None):
    """Packages of the session (spec 02, Ausgabe; FL65): the package that delivers the assistant of the
    session (a local blueprint counts as assistant-<name>) and the packages in lock.yaml of the chain."""
    import yaml
    out = set()
    if assistant_name and assistant_name != "none":
        parts = Path(assistant_dir).parts if assistant_dir else ()
        if "@!Package" in parts and parts.index("@!Package") + 1 < len(parts):
            out.add(parts[parts.index("@!Package") + 1])
        else:
            out.add(f"assistant-{assistant_name}")
    for d in config.chain_dirs(path):
        f = d / ".aibos" / "lock.yaml"
        if not f.is_file():
            continue
        try:
            data = yaml.safe_load(f.read_text(encoding="utf-8")) or {}
        except (OSError, UnicodeDecodeError, yaml.YAMLError):
            continue
        out.update(str(k) for k in (data.get("packages") or {}))
    return out


def session_message(vault, packages, forwarder):
    """Line AIBOS-TICKET of the SessionStart hook, or "" without open tickets for the packages."""
    if vault is None or not packages:
        return ""
    tickets, _ = open_tickets(Path(vault))
    counts, old = {}, False
    for t in tickets:
        if t.get("package") in packages:
            counts[t.get("package")] = counts.get(t.get("package"), 0) + 1
            old = old or t.old
    if not counts:
        return ""
    detail = ", ".join(f"{n} for {p}" for p, n in sorted(counts.items()))
    where = mailbox_text(Path(vault), old)
    return (f"AIBOS-TICKET: open tickets for this session: {detail}, in the mailbox {where}. "
            f"List them with {forwarder} --ticket [<package>] when they matter for the work, "
            f"and read them by the paths from {forwarder} --ticket [<package>] --paths.")


def mailbox_text(vault, old=False):
    """The folder of the mailbox, with the folder of AIBOS 0.7.0 while it holds tickets (B68, F412)."""
    text = f"{Path(vault) / '@' / FOLDER}/"
    if old:
        text += f" (until 0.8 also {Path(vault) / '@' / OLD_FOLDER}/)"
    return text


def report(vault, tickets, problems, cfg, path):
    print(f"Tickets {vault.name} — {datetime.date.today().isoformat()}")
    print(f"Mailbox: {vault / '@' / FOLDER}/")       # B68 (F412): where the files are
    if any(t.old for t in tickets) or any(old for _, old, _ in problems):
        print(f"Mailbox until 0.8: {vault / '@' / OLD_FOLDER}/")
    print()
    with_element = any(t.get("element") for t in tickets)
    head = ["File", "Type", "Package"] + (["Element"] if with_element else []) \
        + ["Version", "Date", "Author", "Project"]
    rows = [head]
    for t in tickets:
        row = [t.shown, t.get("type"), t.get("package")] + ([t.get("element") or "—"] if with_element else []) \
            + [t.get("version"), t.get("date"), t.get("author"), t.get("project")]
        rows.append(row)
    if tickets:
        widths = [max(len(r[i]) for r in rows) + 2 for i in range(len(head) - 1)]
        for r in rows:
            print("".join(f"{c:<{w}}" for c, w in zip(r, widths)) + r[-1])
        print()
    notes = []
    for t in tickets:
        n = older(t, cfg, path)
        if n:
            notes.append(f"- {t.name}: {n}")
    if any(t.shown.endswith("…") for t in tickets):
        notes.append(f"- {PATHS_NOTE}")
    if any(t.old for t in tickets) or any(old for _, old, _ in problems):
        notes.append(f"- {OLD_NOTE}")
    for f, old, why in problems:
        notes.append(f"- {(OLD_FOLDER + '/') if old else ''}{f.stem}: not a ticket ({why}); left as it is")
    if notes:
        print("Notes")
        print("\n".join(notes))
        print()
    counts = {}
    for t in tickets:
        counts[t.get("package")] = counts.get(t.get("package"), 0) + 1
    detail = ", ".join(f"{n} {p}" for p, n in sorted(counts.items()))
    word = "ticket" if len(tickets) == 1 else "tickets"
    print(f"Result: {len(tickets)} open {word}" + (f" ({detail})" if detail else ""))


def print_paths(tickets):
    """aibos --ticket … --paths (v0.7.2, F418, FL106–FL108): the absolute paths of the open tickets,
    one per line, in the order of the report, for skills that read them with Read."""
    for t in tickets:
        print(t.file)


def command(args):
    """aibos --ticket [<package>] [--type <type>] [--paths]: list the open tickets, read only, exit 0."""
    package = kind = None
    only_paths = False
    rest, i = [], 0
    while i < len(args):
        if args[i] == "--paths":
            only_paths = True
            i += 1
            continue
        if args[i] == "--type" and i + 1 < len(args):
            kind = args[i + 1]
            i += 2
            continue
        rest.append(args[i])
        i += 1
    if len(rest) > 1 or any(r.startswith("-") for r in rest):
        raise ui.Abort("usage: aibos --ticket [<package>] [--type <type>] [--paths]")
    package = rest[0] if rest else None
    path = paths.cwd()
    cfg = config.load(path)
    if cfg.kind != "aibos":
        print(f"Kein AIBOS-Workspace: {path}", file=sys.stderr)
        return 1
    vault = Path(os.path.realpath(cfg.vault))
    tickets, problems = open_tickets(vault, package, kind)
    if only_paths:
        print_paths(tickets)
        return 0
    report(vault, tickets, problems, cfg, path)
    return 0

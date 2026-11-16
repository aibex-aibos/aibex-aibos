"""Changeover of a vault from AIbex AIOS 0.6 to AIbex AIBOS 0.7 with aibos --activate (spec 04,
Umstieg auf v0.7, step 2; V0.7, memos 05, 09, 13-15, 26: F270-F272, F281, FL7, FL8, FL31, FL32).

In every project of the vault: .aios/ becomes .aibos/, the binding aios: becomes aibos:, the
organisation aibex-aios becomes aibex-aibos in workspace.yaml, lock.yaml, config.yaml and the
origin, the lines of .gitignore follow; one commit per project. A project whose upstream is already
changed over (another computer) is brought forward instead (FL7). This module goes away with 0.8
together with legacy.py (FL24, FL31).
"""

from __future__ import annotations

import os
import re
import shutil
from pathlib import Path

from . import legacy, project
from .ui import warn

MESSAGE = "AIBOS: auf AIBOS v0.7 umgestellt"
HUB = re.compile(r"(?m)^(\s*(?:-\s+|hub:\s*|remote:\s*)?)" + re.escape(legacy.OLD_ORG) + r"(\s*(?::.*)?)$")
FILES = ("config.yaml", "lock.yaml", "workspace.yaml", "workspace.local.yaml")


def projects(root):
    """The vault root and every project below it that still has .aios/ (without the vaults inside it)."""
    from .activate import vault_projects
    return [Path(p) for p in vault_projects(root) if (Path(p) / legacy.OLD_DIR).is_dir()]


INLINE = re.compile(r"(\b(?:hub|remote):\s*)" + re.escape(legacy.OLD_ORG) + r"(?![\w-])")


def rewrite(text):
    """aibex-aios -> aibex-aibos in addresses on GitHub and as the name of a hub (F264, F281)."""
    text = HUB.sub(lambda m: m.group(1) + legacy.NEW_ORG + m.group(2), legacy.url(text))
    return INLINE.sub(lambda m: m.group(1) + legacy.NEW_ORG, text)


def upstream_changed(p):
    """FL7: True if p has an upstream that already holds .aibos/ and p can follow it forward
    (no local changes, HEAD is an ancestor of the upstream)."""
    if not (p / ".git").exists() or project.git(p, "rev-parse", "--abbrev-ref", "@{u}").returncode:
        return False
    project.git(p, "fetch", "-q", "origin")
    tree = project.git(p, "ls-tree", "--name-only", "@{u}", legacy.NEW_DIR + "/")
    if tree.returncode or not tree.stdout.strip():
        return False
    if project.git(p, "status", "--porcelain").stdout.strip():
        return False
    return project.git(p, "merge-base", "--is-ancestor", "HEAD", "@{u}").returncode == 0


def plan(root, version):
    """(text, action) for the changeover of the vault root and its projects; [] if none is due."""
    steps = []
    todo = projects(root)
    rest = [p for p in todo if (p / legacy.NEW_DIR).exists()]       # already pulled by hand (FL7)
    forward = [p for p in todo if p not in rest and upstream_changed(p)]
    rename = [p for p in todo if p not in rest and p not in forward]
    for p in rest:
        steps.append((f"move what is left in {p / legacy.OLD_DIR} into {p / legacy.NEW_DIR} (FL7)",
                      lambda p=p: carry(p)))
    for p in forward:
        steps.append((f"bring {p} forward to its upstream (changed over on another computer, FL7)",
                      lambda p=p: follow(p)))
    if rename:
        names = ", ".join(str(p.relative_to(root)) if p != root else "." for p in rename)
        steps.append((f"change over {len(rename)} projects of {root} ({names}): {legacy.OLD_DIR}/ -> "
                       f"{legacy.NEW_DIR}/, {legacy.OLD_KEY}: -> {legacy.NEW_KEY}: {version}, "
                       f"{legacy.OLD_ORG} -> {legacy.NEW_ORG} in workspace.yaml, lock.yaml, hubs: and "
                       f"origin; one commit each ({MESSAGE})",
                      lambda: [change(p, root, version) for p in rename]))
    return steps


def follow(p):
    """FL7: fast-forward to the changed-over upstream, then carry the ignored files of .aios/
    (registry, backup, workspace.local.yaml) over to .aibos/."""
    r = project.git(p, "merge", "-q", "--ff-only", "@{u}")
    if r.returncode:
        warn(f"{p}: could not fast-forward ({(r.stderr or r.stdout).strip()}); run aibos --activate again")
        return
    carry(p)


def carry(p):
    """Move what is left in .aios/ (ignored files) into .aibos/ without overwriting, then drop .aios/."""
    old, new = p / legacy.OLD_DIR, p / legacy.NEW_DIR
    if not old.is_dir():
        return
    new.mkdir(exist_ok=True)
    for item in list(old.iterdir()):
        dest = new / item.name
        if not dest.exists():
            shutil.move(str(item), str(dest))
    shutil.rmtree(old, ignore_errors=True)


def change(p, root, version):
    """Rename .aios/ to .aibos/ in p, rewrite names, commit only these paths."""
    old, new = p / legacy.OLD_DIR, p / legacy.NEW_DIR
    git = (p / ".git").exists()
    tracked = git and bool(project.git(p, "ls-files", "--", legacy.OLD_DIR).stdout.strip())
    os.rename(old, new)
    for name in FILES:
        f = new / name
        if f.is_file():
            text = f.read_text(encoding="utf-8")
            if name == "config.yaml" and p == root:
                text = re.sub(r"^" + legacy.OLD_KEY + r":.*$", f"{legacy.NEW_KEY}: {version}", text, flags=re.M)
            text = rewrite(text)
            f.write_text(text, encoding="utf-8")
    paths = [legacy.NEW_DIR] + ([legacy.OLD_DIR] if tracked else [])
    gi = p / ".gitignore"
    if gi.is_file():
        text = gi.read_text(encoding="utf-8")
        new_text = re.sub(r"^(/?)" + re.escape(legacy.OLD_DIR) + r"/", r"\1" + legacy.NEW_DIR + "/", text, flags=re.M)
        if new_text != text:
            gi.write_text(new_text, encoding="utf-8")
            paths.append(".gitignore")
    if not git:
        return
    url = project.git(p, "remote", "get-url", "origin")
    if url.returncode == 0 and legacy.url(url.stdout.strip()) != url.stdout.strip():
        project.git(p, "remote", "set-url", "origin", legacy.url(url.stdout.strip()))
    project.git(p, "add", "-A", "--", *paths)
    if project.git(p, "diff", "--cached", "--quiet", "--", *paths).returncode:
        r = project.git(p, "commit", "-q", "-m", MESSAGE, "--", *paths)
        if r.returncode:
            warn(f"commit in {p} failed ({(r.stderr or r.stdout).strip()}); commit .aibos/ by hand")

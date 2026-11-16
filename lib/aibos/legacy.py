"""Übergang von AIbex AIOS zu AIbex AIBOS bis 0.8 (spec 01, Vorabversionen; spec 04, Umlenkung
für Tests, Übergang; spec 06, Hubs; V0.7, memos 04, 05, 09, 10, 13: F263, F264, F268, F272, F283, FL4).

All rules that read the names of AIOS live here, so that 0.8 removes them in one place. The
legacy of earlier versions (prototype, forwarders, global wrappers of v0.5) stays in install.py
and is not part of this transition (V0.7, memo 22: FL23).
"""

import os
import re
import sys

OLD_ORG, NEW_ORG = "aibex-aios", "aibex-aibos"      # GitHub organisation (F264)
OLD_PREFIX, NEW_PREFIX = "AIOS_", "AIBOS_"          # environment (F268)
OLD_DIR, NEW_DIR = ".aios", ".aibos"                # vaults and projects (F270)
OLD_KEY, NEW_KEY = "aios", "aibos"                  # binding, requires (F272)
GITHUB_ORG = re.compile(r"((?:https?://|ssh://git@)github\.com[/:]|git@github\.com:)" + re.escape(OLD_ORG) + r"(?=/)")

_noted = set()


def env(name, default=None):
    """AIBOS_<x> from the environment; without it AIOS_<x>, with a note on stderr once per call."""
    value = os.environ.get(name)
    if value is not None:
        return value
    if name.startswith(NEW_PREFIX):
        old = OLD_PREFIX + name[len(NEW_PREFIX):]
        if old in os.environ:
            if name not in _noted:
                _noted.add(name)
                print(f"note: {old} is read as {name} until AIBOS 0.8", file=sys.stderr)
            return os.environ[old]
    return default


def package_env(**values):
    """Variables for packages (setup and remove of workhorses, commands): AIBOS_<x> and, until 0.8,
    AIOS_<x> with the same value, because packages of AIOS read the old names (FL4)."""
    out = {}
    for name, value in values.items():
        out[name] = value
        if name.startswith(NEW_PREFIX):
            out[OLD_PREFIX + name[len(NEW_PREFIX):]] = value
    return out


def hub(name):
    """The name of a hub; aibex-aios is the same hub as aibex-aibos (F264)."""
    return NEW_ORG if name == OLD_ORG else name


def url(text):
    """A remote address with the organisation aibex-aios on GitHub, written with aibex-aibos (F281)."""
    return GITHUB_ORG.sub(lambda m: m.group(1) + NEW_ORG, text) if text else text


def requires_key(requires):
    """The key of requires: aibos, else aios (F283); None if neither is there."""
    if not isinstance(requires, dict):
        return None
    return NEW_KEY if NEW_KEY in requires else OLD_KEY if OLD_KEY in requires else None

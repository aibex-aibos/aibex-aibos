"""Fixed locations of AIBOS, redirectable for tests (spec 04, Umlenkung fuer Tests)."""

import os
from pathlib import Path


def home() -> Path:
    return Path(os.environ.get("HOME", str(Path.home())))


def prefix() -> Path:
    """Shared installations, default /opt/aibos (AIBOS_PREFIX)."""
    return Path(os.environ.get("AIBOS_PREFIX", "/opt/aibos"))


def user_dir() -> Path:
    """Per-user data, ~/.aibos."""
    return home() / ".aibos"


def claude_dir() -> Path:
    """Claude Code configuration, ~/.claude (AIBOS_CLAUDE_DIR)."""
    return Path(os.environ.get("AIBOS_CLAUDE_DIR", str(home() / ".claude")))


def bin_dir() -> Path:
    """Directory of the forwarders, ~/bin."""
    return home() / "bin"


def forwarder() -> Path:
    """Absolute path of the forwarder ~/.aibos/bin/aibos, named in every text of AIBOS (spec 02; V0.6, F34)."""
    return user_dir() / "bin" / "aibos"


def log(hook, cwd, message):
    """One line in ~/.aibos/log/context.log (spec 02, Hooks; V0.6, memo 15); never fails."""
    import time
    try:
        d = user_dir() / "log"
        d.mkdir(parents=True, exist_ok=True)
        with open(d / "context.log", "a", encoding="utf-8") as f:
            f.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} {hook} cwd={cwd} {message}\n")
    except OSError:
        pass


def user_versions() -> Path:
    """Fallback for installations when /opt/aibos cannot be set up, ~/.aibos/versions."""
    return user_dir() / "versions"


def sudo_cmd() -> str:
    """Program used as sudo (AIBOS_SUDO), tests never call the real sudo."""
    return os.environ.get("AIBOS_SUDO", "sudo")


def stup_url() -> str:
    """Source of stup (AIBOS_STUP_URL), may be a file:// URL in tests."""
    return os.environ.get(
        "AIBOS_STUP_URL", "https://raw.githubusercontent.com/bluccino/tool-stup/master/bin/stup")


def pip_cmd() -> str:
    """Command that installs python/requirements.txt into the venv (AIBOS_PIP), empty = default."""
    return os.environ.get("AIBOS_PIP", "")


def cwd() -> str:
    """Logical working directory ($PWD) like the forwarders and the shell, physical as fallback."""
    pwd = os.environ.get("PWD")
    try:
        if pwd and os.path.samefile(pwd, os.getcwd()):
            return os.path.abspath(pwd)
    except OSError:
        pass
    return os.getcwd()


def cache_dir() -> Path:
    """Part files of the master context, ~/.aibos/cache."""
    return user_dir() / "cache"

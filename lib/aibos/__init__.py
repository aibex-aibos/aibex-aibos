"""AIbex AIBOS - operating system for the context of AI assistants.

Python part of AIBOS (logic behind `aibos` and `aibos --context`), see spec/.
"""

from pathlib import Path


def version() -> str:
    """Version of this AIBOS source tree or installation (file VERSION)."""
    here = Path(__file__).resolve().parent
    for candidate in (here.parent.parent / "VERSION", here.parent / "VERSION"):
        if candidate.is_file():
            return candidate.read_text(encoding="utf-8").strip()
    return "unknown"

"""Package manifest manifest.yaml (spec 06, Pakete).

A package is a versioned unit described by manifest.yaml at the root of its repo. This module
reads and checks the manifest, tells modules from plain packages and lists the elements a
package can deploy. The manifest is read with PyYAML.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

from . import semver
from . import legacy
from .install import frontmatter

NAME = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
TYPES = ("kernel", "app", "assistant", "skill", "knowledge", "tutorial", "distribution", "worker", "mod")
MODULE_TYPES = ("kernel", "app", "assistant", "skill", "worker", "mod")      # mod: v0.7.1 (spec 06, Mods)
RESERVED = ("aibos", "gui", "none", "inherit")      # besides the prefix aibos-
CONTENT_LISTS = ("skills", "assistants", "commands", "hooks")
WORKER_KINDS = ("python", "script")                 # spec 07; binary comes later
PROGRAM = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._+-]{0,63}$")
REQUIREMENT = re.compile(r"^([A-Za-z0-9][A-Za-z0-9._-]*)==([^\s;]+)$")
HASH = re.compile(r"^--hash=sha256:[0-9a-f]{64}$")


class ManifestError(Exception):
    """manifest.yaml that does not follow spec 06."""


@dataclass
class Manifest:
    name: str
    version: semver.Version
    type: str
    description: str
    requires: semver.Range
    depends: dict = field(default_factory=dict)     # name -> Range
    contents: dict = field(default_factory=dict)
    worker: dict = field(default_factory=dict)      # type: worker (spec 07)
    kernel: object = None                           # type: distribution, exact Range or None
    license: str = ""
    userdata: object = None
    warnings: list = field(default_factory=list)
    requires_key: str = "aibos"                   # aios in packages of AIOS (F283)

    @property
    def is_module(self):
        """A module adds something AIBOS can do (spec 06): a module type, or contents with a
        skill, assistant, command or hook."""
        return self.type in MODULE_TYPES or any(self.contents.get(k) for k in CONTENT_LISTS)

    def elements(self):
        """Names of the elements that can be deployed: skills, assistants and commands by
        their names, the knowledge as 'knowledge' (spec 06, N2). Hooks have no effect in v0.5;
        a worker has no elements (spec 06, L8); a mod has the one element mod (v0.7.1, F403)."""
        if self.type == "mod":
            return ["mod"]
        names = []
        for kind in ("skills", "assistants", "commands"):
            names += list(self.contents.get(kind) or [])
        if self.contents.get("knowledge"):
            names.append("knowledge")
        return names


def name_problem(name):
    """None if name is a valid package name (spec 06), else the reason."""
    if not isinstance(name, str) or not NAME.match(name):
        return f"{name!r} is not a package name (lower case letters, digits, -, at most 64)"
    if name in RESERVED or name.startswith("aibos-"):
        return f"{name} is a reserved name"
    return None


def as_list(value, where):
    if value is None:
        return []
    if isinstance(value, str):
        return [value]
    if isinstance(value, list) and all(isinstance(x, str) for x in value):
        return value
    raise ManifestError(f"{where}: expected a list of names")


def exact(text):
    """True if a range names exactly one version (==X.Y.Z), as a distribution needs (spec 06)."""
    return bool(re.match(r"^==\s*\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$", str(text).strip()))


def parse_worker(spec, where):
    """worker: of a package of type worker (spec 07): kind, programs, check, requirements or
    setup and remove."""
    if not isinstance(spec, dict):
        raise ManifestError(f"{where}: type worker needs worker: with kind and programs (spec 07)")
    kind = spec.get("kind")
    if kind not in WORKER_KINDS:
        raise ManifestError(f"{where}: worker.kind must be {' or '.join(WORKER_KINDS)}, not {kind!r}")
    programs = as_list(spec.get("programs"), f"{where}: worker.programs")
    if not programs:
        raise ManifestError(f"{where}: worker.programs names no program")
    bad = [x for x in programs if not PROGRAM.match(x)]
    if bad:
        raise ManifestError(f"{where}: worker.programs: not a program name: {', '.join(bad)}")
    if spec.get("check") is not None and not isinstance(spec.get("check"), str):
        raise ManifestError(f"{where}: worker.check must be a command line")
    need = ("requirements",) if kind == "python" else ("setup", "remove")
    for key in need:
        if not isinstance(spec.get(key), str) or not spec[key]:
            raise ManifestError(f"{where}: worker of kind {kind} needs {key}: <file in the package>")
    return dict(spec, programs=programs)


def requirements_problems(text):
    """Problems of a requirements file with hashes (spec 07, kind python; V0.5, memo 22, F14):
    every entry <name>==<version> with at least one --hash=sha256:<hex>; comments and line
    continuations with \\ are allowed."""
    logical, cur = [], ""
    for line in text.splitlines():
        line = line.split(" #")[0].strip() if not line.lstrip().startswith("#") else ""
        if line.endswith("\\"):
            cur += line[:-1] + " "
            continue
        cur += line
        if cur.strip():
            logical.append(cur.strip())
        cur = ""
    if cur.strip():
        logical.append(cur.strip())
    problems = []
    for entry in logical:
        parts = entry.split()
        if not REQUIREMENT.match(parts[0]):
            problems.append(f"{parts[0]}: not <package>==<version>")
            continue
        hashes = [x for x in parts[1:] if x.startswith("--hash")]
        if not hashes or any(not HASH.match(x) for x in hashes) or len(hashes) != len(parts) - 1:
            problems.append(f"{parts[0]}: needs --hash=sha256:<hash> and nothing else")
    if not logical:
        problems.append("no requirements")
    return problems


def parse(data, where="manifest.yaml", kernel=False):
    """Manifest from the parsed YAML data; kernel=True allows the name aibos (spec 06, Q1)."""
    if not isinstance(data, dict):
        raise ManifestError(f"{where}: not a mapping")
    for key in ("name", "version", "type", "description", "requires"):
        if data.get(key) in (None, ""):
            raise ManifestError(f"{where}: {key} is missing")
    name = data["name"]
    problem = None if kernel and name == "aibos" else name_problem(name)
    if problem:
        raise ManifestError(f"{where}: {problem}")
    try:
        version = semver.Version.parse(data["version"])
        if version.parts != 3:
            raise semver.VersionError(f"{data['version']!r} is not MAJOR.MINOR.PATCH")
    except semver.VersionError as e:
        raise ManifestError(f"{where}: version {e}")
    warnings = []
    kind = data["type"]
    if kind not in TYPES:
        warnings.append(f"{where}: unknown type {kind!r}, treated as knowledge")
        kind = "knowledge"
    if "workers" in data:
        raise ManifestError(f"{where}: workers: is gone since AIBOS 0.5; a workhorse is a package "
                            "of type: worker (spec 07)")
    requires = data["requires"]
    req_key = legacy.requires_key(requires)
    if req_key is None:
        raise ManifestError(f"{where}: requires needs aibos: \"<range>\"")
    try:
        req = semver.Range.parse(requires[req_key])
        depends = {}
        for dep, rng in (data.get("depends") or {}).items():
            if dep in ("aibos", "aios"):
                raise ManifestError(f"{where}: depends must not name aibos, use requires")
            problem = name_problem(dep)
            if problem:
                raise ManifestError(f"{where}: depends: {problem}")
            depends[dep] = semver.Range.parse(rng)
            if kind == "distribution" and not exact(rng):
                raise ManifestError(f"{where}: a distribution names exact versions: {dep}: {rng!r} is not ==X.Y.Z")
        kernel_range = None
        if data.get("kernel") is not None:
            if kind != "distribution":
                raise ManifestError(f"{where}: kernel: is only allowed for type: distribution")
            if not exact(data["kernel"]):
                raise ManifestError(f"{where}: kernel: {data['kernel']!r} is not ==X.Y.Z")
            kernel_range = semver.Range.parse(data["kernel"])
    except semver.VersionError as e:
        raise ManifestError(f"{where}: {e}")
    contents = dict(data.get("contents") or {})
    for key in CONTENT_LISTS:
        contents[key] = as_list(contents.get(key), f"{where}: contents.{key}")
    gui = contents.get("gui")
    if gui and gui not in contents["skills"]:
        raise ManifestError(f"{where}: contents.gui {gui} is not in contents.skills")
    names = [n for k in ("skills", "assistants", "commands") for n in contents[k]]
    dup = sorted({n for n in names if names.count(n) > 1})
    if dup:
        raise ManifestError(f"{where}: element names are not unique: {', '.join(dup)}")
    if "knowledge" in names:
        raise ManifestError(f"{where}: knowledge is reserved as the name of the knowledge element")
    worker = {}
    if kind == "worker":
        worker = parse_worker(data.get("worker"), where)
        if names or contents.get("knowledge") or contents.get("gui") or contents["hooks"]:
            raise ManifestError(f"{where}: a worker has no elements (contents), spec 06")
    elif "worker" in data:
        raise ManifestError(f"{where}: worker: is only allowed for type: worker")
    if kind == "mod" and (names or contents.get("knowledge") or contents.get("gui") or contents["hooks"]):
        raise ManifestError(f"{where}: a mod has no contents; its files lie in mod/ (spec 06, Mods)")
    return Manifest(name, version, kind, str(data["description"]), req, depends, contents, worker,
                    kernel_range, str(data.get("license") or ""), data.get("userdata"), warnings,
                    requires_key=req_key)


def load(folder, kernel=False):
    """Manifest of the package in folder (manifest.yaml at its root)."""
    import yaml                                     # PyYAML, only where manifests are read
    file = Path(folder) / "manifest.yaml"
    if not file.is_file():
        raise ManifestError(f"{folder} has no manifest.yaml")
    try:
        data = yaml.safe_load(file.read_text(encoding="utf-8"))
    except yaml.YAMLError as e:
        raise ManifestError(f"{file}: {e}")
    return parse(data, str(file), kernel)


def check_tree(folder, m):
    """Problems of the package tree against its manifest (spec 06, Prüfung beim Holen);
    empty if the package may be fetched."""
    folder = Path(folder)
    problems = []
    for name in m.contents["skills"]:
        f = folder / "skills" / name / "SKILL.md"
        if not f.is_file():
            problems.append(f"skill {name}: skills/{name}/SKILL.md is missing")
            continue
        ver = str(frontmatter(f).get("version") or "").strip("'\" ")
        if not re.match(r"^\d+\.\d+\.\d+$", ver):
            problems.append(f"skill {name}: no valid version")
    for name in m.contents["assistants"]:
        if not (folder / "assistants" / name / "ASSISTANT.md").is_file():
            problems.append(f"assistant {name}: assistants/{name}/ASSISTANT.md is missing")
    for name in m.contents["commands"]:
        if not (folder / "commands" / name).is_file():
            problems.append(f"command {name}: commands/{name} is missing")
    if m.contents.get("knowledge") and not (folder / "knowledge").is_dir():
        problems.append("knowledge: the folder knowledge/ is missing")
    if m.type == "worker":
        files = ["requirements"] if m.worker["kind"] == "python" else ["setup", "remove"]
        for key in files:
            f = folder / m.worker[key]
            if not f.is_file():
                problems.append(f"worker: {m.worker[key]} is missing")
            elif key == "requirements":
                problems += [f"worker: {m.worker[key]}: {x}"
                             for x in requirements_problems(f.read_text(encoding="utf-8"))]
    if m.type == "mod":
        problems += mod_problems(folder, m.name)
    return problems


def mod_identity(folder):
    """(plugin, marketplace) of the mod in folder/mod/.claude-plugin/ (spec 06, Mods; FL70), or raises
    ManifestError with the problem."""
    import json
    base = Path(folder) / "mod" / ".claude-plugin"
    out = []
    for f in ("plugin.json", "marketplace.json"):
        try:
            data = json.loads((base / f).read_text(encoding="utf-8"))
        except FileNotFoundError:
            raise ManifestError(f"mod: mod/.claude-plugin/{f} is missing")
        except (OSError, UnicodeDecodeError, ValueError) as e:
            raise ManifestError(f"mod: mod/.claude-plugin/{f} is not readable: {e}")
        if not isinstance(data, dict) or not str(data.get("name") or "").strip():
            raise ManifestError(f"mod: mod/.claude-plugin/{f} has no name")
        out.append(data)
    plugin, market = out
    names = [str(x.get("name")) for x in (market.get("plugins") or []) if isinstance(x, dict)]
    if names != [plugin["name"]]:
        raise ManifestError(f"mod: marketplace.json must name the mod {plugin['name']} as its only plugin")
    return str(plugin["name"]), str(market["name"])


def mod_problems(folder, package):
    """Problems of the folder mod/ of a package of type mod (spec 06, Mods, Prüfung beim Holen)."""
    try:
        plugin, _ = mod_identity(folder)
    except ManifestError as e:
        return [str(e)]
    want = package[len("mod-"):] if package.startswith("mod-") else package
    if plugin != want:
        return [f"mod: plugin.json names {plugin}, the package {package} needs {want}"]
    return []

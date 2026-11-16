![AIbex AIBOS](etc/image/banner.jpg)
--------------------------------------------------------------------------------

# AIbex AIBOS — an Operating System for the Context of AI Assistants

**AIbex AIBOS is an operating system for the context of AI assistants.** It
manages which knowledge a chat loads, reads on demand or does not see, and
provides file system conventions, packages, assistants and skills for this
purpose. Execution is left to a host (in v0.6: Claude Code). From version 0.6.0
on, its name is **AIBOS**; the technical names stay (command `aibos`, folder
`~/.aibos`, key `aibos:`).

AIBOS works on an Obsidian vault: every chat runs in a project directory and
receives the knowledge that belongs to this project — no more, no less. An
assistant, assigned to the project, gives every chat there a personality with
its own selection of skills, knowledge and a surface. Skills, assistants,
knowledge and apps come as **packages** from **hubs** (GitHub organizations),
like Python packages from PyPI. Programs that skills call, such as `yt-dlp`,
come as **workhorses**: AIBOS sets them up once per version on the machine. A
**distribution** installs a kernel with a tested set of packages in one step.


## Requirements

macOS or Linux with `bash`, `git`, `python3` (3.11 or newer, with the modules
`venv` and `pip`; on macOS e.g. `brew install python`, the `python3` of the system
is too old) and [Claude Code](https://claude.com/claude-code) as the host
(`aibos --install` checks this basic kit itself and stops with a hint if something
is missing). `gh` (GitHub CLI) is needed only to search hubs without an index and
for `aibos --contribute`. Setting up workhorses needs access to PyPI.


## Installation

Copy this line into a terminal:

```sh
R=~/git/AIbex/aibex-aibos; ([ -d "$R/.git" ] || git clone https://github.com/aibex-aibos/aibex-aibos "$R") && "$R/bin/aibos" --install v0.7.0
```

It clones the repository to `~/git/AIbex/aibex-aibos` unless a clone is already
there (an existing clone is left as it is), checks the basic kit and installs.
The installed files always come from the tag `v0.7.0`, not from the working
tree of the clone; without a version, the highest release tag is installed.

`aibos --install` shows a plan and asks once before it writes anything. It
installs the kernel read-only to `~/.aibos/versions/v0.7.0/` and puts the
forwarder `aibos` into `~/.aibos/bin/aibos`. It adds three hooks to
`~/.claude/settings.json`, each with the absolute path of the forwarder:
`SessionStart`, `UserPromptSubmit` and `PreToolUse` (matcher `Bash|Skill|Read`; it
allows single calls of the forwarder and the registered kernel skills, and
reading the cached master context and the documentation of the bound version,
in an AIBOS workspace without a permission prompt, while `deny` and `ask`
rules of the user still win). It writes nothing
to `~/bin` and no skills to `~/.claude/skills/`. Hooks of `ai-brain` are saved
and restored by `aibos --uninstall`. Only `aibos --install --system` installs to
`/opt/aibos/` instead (computer-wide, with `sudo`).

The installer never edits shell start files, so `~/.aibos/bin` is usually not in
your `PATH`: call `~/.aibos/bin/aibos` in the terminal or add `~/.aibos/bin` to
your `PATH` yourself. The examples below write `aibos` for short. Hooks and
skills always call the forwarder with its absolute path.

### Vaults and AIBOS workspaces

A **vault** is a folder whose name starts with `§`. Installing does not touch
any vault. A vault becomes an **AIBOS workspace** (A/W) when its root binds it
to a version ≥ 0.7.0 with `aibos:` in `<vault>/.aibos/config.yaml` (a vault of AIOS 0.6 with `aios:` in `.aios/config.yaml` runs with 0.6 until it is changed over); `aibos
--activate` writes this binding. Only the vault root binds: an `aibos:` in a
project is ignored with a warning. Outside an A/W — in a vault without binding
or outside any vault — Claude behaves as if AIBOS were not installed: the hooks
print nothing, no kernel skill is registered there, and a kernel skill called
by hand only says so (see *Quick start*). `legacy: ai-brain` at
the vault root keeps a vault with `ai-brain`; a `§` folder without binding or
marker is not affected at all.

**Changeover from AIbex AIOS 0.6:** run the installer of the clone,
`~/git/AIbex/aibex-aibos/bin/aibos --install v0.7.0` (as under *Install*). Its
first plan moves `~/.aios` to `~/.aibos` and leaves `~/.aios` as a link, so the
installed kernels 0.6.x keep running; then the plan of the installation adds the
forwarder `aibos` with the alias `aios` and rewrites the three hooks in place.
Vaults of AIOS 0.6 keep running with 0.6 until you change each one over with
`aibos --activate v0.7.0 <vault>`: its first plan renames `.aios/` to `.aibos/`
in every project, `aios:` to `aibos:` and `aibex-aios` to `aibex-aibos`, with one
commit per project; the wrappers `aios-*` become `aibos-*`. A second computer of
the same workspace follows the changed-over state of the remote. Until AIBOS 0.8
the old names keep working: the link `~/.aios`, the alias `aios`, the variables
`AIOS_*` (spec 04, *Umstieg auf v0.7*).

A **distribution** installs the kernel, its workhorses and its packages into a
vault in one plan, e.g. Rothirsch with the video analysis and the assistant Anja:

```sh
aibos --install distribution-rothirsch ~/Vaults/§Rothirsch
```

Rothirsch 1.1.0 binds kernel 0.6.1.


## Quick start

```sh
  mkdir ~/Vaults/§Demo
  aibos --activate v0.7.0 ~/Vaults/§Demo      # writes §Demo/.aibos/config.yaml, creates §Demo/@/ and a git repo
```

```
=> activate AIBOS v0.7.0 for ~/Vaults/§Demo
=> ~/Vaults/§Demo runs with AIBOS 0.6.0 (~/Vaults/§Demo/.aibos/config.yaml)
   the master context and the skill registration apply from the next chat
```

The activation also registers the **kernel skills** (`aibos-*`) and the alias
`/gui` as thin wrappers in `.claude/skills/` of the vault root and of each
project; the master context of every chat in the vault lists them in a short
block `<aibos-kernel-skills>` (name and call). Outside an A/W they do not
work:

```sh
  cd ~/tmp && ~/.aibos/bin/aibos --skill aibos-status
```

```
Kein AIBOS-Workspace: ~/tmp
```

Put knowledge into the **masterspace** `@/` of a project. The prefix of a
folder decides what a chat sees:

| Folder | Class | Effect |
|---|---|---|
| `@Rule/`, `@Wissen/@Content/`, files directly in `@/` | load | loaded at the start of every chat (master context) |
| `@@Kapitel/` | available | not loaded; the master context lists it, the chat reads it on demand |
| `@!Skill/`, `@!Assistant/`, `@!Package/` | hidden | blueprints of skills and assistants, fetched packages |

A project is any folder with `@/` and its own git repo; the vault root is the
root project. A chat in a project sees the masterspaces from the vault root down
to the project. Open a chat in a new folder of an A/W and AIBOS offers to initialize it
(`/aibos-init`); at the first start of a chat it checks the structure of the
project and offers to complete it.

Start a chat directly in the project folder. If the host starts it in a git
worktree instead (Claude Code desktop app: `.claude/worktrees/<name>/` on a
branch of its own), results land on that branch and do not appear in the
folder, e.g. in Obsidian, until the branch is merged. AIBOS recognizes this at
the start of the chat: Claude says so before the first work and offers the
merge afterwards. This works only for worktrees inside the vault, as the desktop app
creates them by default; a worktree outside the vault is not recognized.

In a chat in an A/W:

| Skill | Purpose |
|---|---|
| `/aibos-gui` | surface of AIBOS: all tasks below as tiles, including *Packages* and *Apps* |
| `/aibos-package` | packages: search, fetch, deploy, hubs („hol mir den Taschenrechner“) |
| `/aibos-fetch`, `/aibos-deploy` | fetch a package and register its skills; choose which elements of a package are deployed |
| `/aibos-distribution` | compose a distribution from a tested project as a local package repo |
| `/aibos-context` | check and show the master context and the assistant |
| `/aibos-init` | make the folder a project or complete it (`@/`, git, `.gitignore`, exclusion in the repo above) |
| `/aibos-integrity` | check the structure and the commit state of a project and all its subprojects |
| `/aibos-register` | register the project skills for Claude Code |
| `/aibos-assistant Gärtner` | assign an assistant to the project (`--none`, `--inherit`) and switch to it |
| `/gui` | surface of the assistant of the session |
| `/aibos-memo` | memo style in every project (only when no skill `memo` is available) |
| `/aibos-status` | project status from memos and git |
| `/aibos-sync`, `/aibos-detach`, `/aibos-attach` | workspace: sync the project tree with its remotes; detach a subtree (or the workspace) after checking that nothing is lost, or remove a project from the workspace on every machine; get a detached subtree or a removed project back |

Registered skills become available in the **next** chat. The assistant is a
property of the project: `assistant: <name>`, `none` or `inherit` (the default)
in `.aibos/config.yaml`. New chats load it automatically; compaction and resume
keep the assistant a chat started with.


## Packages and hubs

A **package** is a git repo with a `manifest.yaml` (name, version, type,
dependencies, contents) and version tags `v<x.y.z>`. Its name says its type:
`skill-memo`, `assistant-gaertner`, `knowledge-orion`, `app-taschenrechner`,
`worker-yt-dlp`, `distribution-rothirsch`.
A **hub** is a place for packages, a GitHub organization or any git server;
the **hub list** (`hubs:` in `~/.aibos/config.yaml` and at the vault root)
says where AIBOS looks, by default `aibex-aibos`.

```sh
  aibos --library rechner                       # search the hubs of the hub list
  aibos --fetch app-taschenrechner              # fetch, deploy and register (with dependencies)
  aibos --fetch                                 # sync the project with .aibos/lock.yaml
  aibos --fetch --upgrade                       # choose the highest versions anew
  aibos --hubs add aibex-hub --vault            # a second hub for the vault
  aibos --worker                                # workhorses on the machine and who uses them
```

`aibos --fetch` copies the package without `.git` to `@/@!Package/<name>/`,
writes the requested range to `packages:` in `.aibos/config.yaml` and the
resolved versions and commits to `.aibos/lock.yaml`. Every project is complete
in itself. Every plan of `aibos --fetch` backs up what it changes and restores it
if a step fails (all or nothing). The packages of the hub `aibex-aibos`:

| Package | Type | Content |
|---|---|---|
| `app-taschenrechner` | app | programmable RPN calculator like the HP-15C, function keys A–D with *LEARN* (`/taschenrechner-gui`) |
| `assistant-gaertner` | assistant | Gärtner, calculates only with apples and pears, starts every answer with 👩‍🌾; surface with an apple-pear calculator |
| `assistant-astronom` | assistant | Astronom, calculates only with sun and moon, starts every answer with 💫, looks up star data |
| `assistant-anja` | assistant | Anja, specialist for developing AIBOS packages of all types |
| `knowledge-orion` | knowledge | the brightest stars of Orion (SIMBAD, Wikipedia) |
| `skill-memo` | skill | memo style for projects in AIBOS vaults |
| `skill-5-8-zusammenfassung` | skill | 5-8 summary of a document as a memo |
| `skill-video-analyse` | skill | transcript and 5-8 summary of a YouTube video, with `worker-yt-dlp` |
| `worker-yt-dlp`, `worker-deno` | worker | the programs `yt-dlp` and `deno`, set up from PyPI with hashes |
| `distribution-rothirsch` | distribution | kernel 0.6.1 with the video analysis and Anja |

The hub `aibex-hub` holds `knowledge-scorpio` (the brightest stars of
Scorpius). Each demo assistant politely refuses the other one's calculations,
so the answer shows which assistant and which skill are active.

**Workspaces** bring a whole vault to another machine and keep it in sync: the
vault root lists its projects in `.aibos/workspace.yaml`, each project is a repo
of its own at its own remote. Three moves handle it: `aibos --workspace attach
<repo> [<vault-folder>]` binds a workspace to a new machine (in the terminal),
`sync` works like a cloud drive: it clones what is missing, saves local
changes (new, changed, deleted files; secrets stay local), merges new states
(the same file changed on both sides leaves a conflict copy), records new repos
and pushes (never tags); a large deletion is restored unless taken over.
`history` and `restore` bring back earlier versions. `detach <path>` moves a
subtree to the trash after checking that nothing is lost, `attach <path>` gets
it back; `remove <path>` takes a project out of the workspace on every machine
(the repo at the remote stays). Without a path the project of the working
directory counts, at the vault root the whole workspace; `sync --only` takes one
project without its subprojects. With `sync: auto` in the vault root, a new
session merges its project; in cloud folders (Google Drive, iCloud, Dropbox)
the sync is off (a Cloud-Drive; see Tutorial 04 for Lokal-, AIBOS- and Netz-Drive). Skills: `/aibos-sync`, `/aibos-restore`, `/aibos-detach`,
`/aibos-attach`.
**Contributions** go back to a package as a pull request
(`aibos --contribute <file> --to <package>`).


## Tutorials

The tutorials (German) walk through a demo vault:

- [`01 Erste Schritte mit den Demo-Assistenten`](doc/tutorials/01%20Erste%20Schritte%20mit%20den%20Demo-Assistenten.md) — vault, projects, chain, assistants as packages
- [`02 Projekte und Integrität`](doc/tutorials/02%20Projekte%20und%20Integrit%C3%A4t.md) — subprojects, consistency check, `/aibos-integrity`
- [`03 Pakete und Taschenrechner`](doc/tutorials/03%20Pakete%20und%20Taschenrechner.md) — hubs, fetch, deploy, the calculator, contribute
- [`04 Workspaces`](doc/tutorials/04%20Workspaces.md) — `workspace.yaml`, `attach`, `sync`, `detach`, `remove`, `status`, `freeze`, the four kinds of drives
- [`05 Arbeitspferde und Distributionen`](doc/tutorials/05%20Arbeitspferde%20und%20Distributionen.md) — Rothirsch, workhorses, forwarders, a second machine


## Command line

| Command | Purpose |
|---|---|
| `aibos --install [v<version>] [--system]`, `--versions`, `--remove-version v<version>`, `--uninstall` | installations (`aibos --prepare` is legacy and no longer used) |
| `aibos --install distribution-<name> [<vault>] [--from <repo>]` | install or upgrade a distribution: kernel, workhorses, packages |
| `aibos --activate v<version> [<vault-root>]`, `--deactivate [<vault-root>]`, `--config [<path>]` | bind a vault (only at its root) to a version, show the configuration |
| `aibos --init`, `--integrity`, `--register` | projects and their skills |
| `aibos --library`, `--hubs`, `--fetch`, `--deploy` | packages: search, hub list, fetch, deployed elements |
| `aibos --worker [<package> setup]`, `--run`, `--contribute`, `--workspace` | workhorses (state, repair), commands of packages, contributions, workspaces |
| `aibos --assistant <name\|none\|inherit> [--to <project>]`, `--gui [--html] [--aibos] [--apps]` | assignment of the assistant, surfaces |
| `aibos --context [<path>]`, `--load`, `--id`, `--list`, `--assistant <name> [--load [<path>]]`, `--assistants`, `--assignment` | master context and assistants |

`aibos --help` lists all options. Every writing command shows a plan first;
`--plan` only shows it, `--yes` skips the question and prints only the result.
Several versions can be installed side by side; each vault chooses its version
with `aibos: <version>` in `.aibos/config.yaml` of its root.


## Documentation

The specification of each version is part of it: `spec/` in this repository,
installed to `~/.aibos/versions/v<version>/doc/spec/` (with `--system`:
`/opt/aibos/v<version>/doc/spec/`); tutorials are installed from
`doc/tutorials/` to `doc/tutorials/` of the installation.

| Spec | Content |
|---|---|
| `01 AIbex AIBOS v0.7 — Überblick` | definition, terms, scope, pre-releases, invariants, acceptance test |
| `02 Master-Kontext` | projects, chain, kinds of vaults, classes, block of the kernel skills, `aibos --context`, hooks and permit, assistant of the session, consistency check |
| `03 Skills und Assistenten` | skills, versions, registry, assistants and their assignment, GUIs, `aibos-package`, `aibos-distribution`, `aibos-memo` |
| `04 Installation und Konfiguration` | files, formats, forwarders, the command `aibos`, changeover from AIOS 0.6 |
| `05 Projekte` | project structure and naming, init, integrity, status |
| `06 Pakete und Workspaces` | packages, manifest, versions, hubs, fetch, deploy, distributions, lock, workspaces, contribute, the calculator |
| `07 Arbeitspferde` | workhorses (`worker-<name>`), installation per version, forwarders, setup and remove |


## Development

```sh
  tests/run                  # all tests in a sandbox with local test hubs, never touch the machine
  tests/hub/build <dir>      # build the test hubs from tests/hub/ and print AIBOS_HUBS
  tests/live/hooks.sh        # real headless Claude sessions (cost tokens)
  tests/live/skills.sh
  tests/live/assistants.sh
  tests/live/permit.sh       # PreToolUse hook: release in an AIBOS workspace, deny and ask rules
  tests/live/outside.sh      # a session outside an AIBOS workspace
  tests/live/workers.sh      # worker-deno, worker-yt-dlp against the real PyPI
  tests/live/rothirsch.sh    # distribution Rothirsch in a sandbox (PyPI)
  tests/live/changeover.sh   # activation of a vault of 0.5.1 with packages and workhorses (PyPI)
  tests/live/fresh.sh        # install in the smallest environment (fresh HOME, python3 without PyYAML)
  dev/doc-outputs.sh         # outputs of README and tutorials from a sandbox of the package repos
```

A clone can be used without installing: point `AIBOS_HOME` to it, or add a
line `v0.7.0-dev: ~/git/AIbex/aibex-aibos` to `~/.aibos/installations.yaml`.
`AIBOS_HUBS` and `AIBOS_GITHUB` redirect hubs for tests (spec 04).
`CLAUDE.md` holds the rules for working on the repository, `STATUS.md` the
state of the implementation.


## Status

Version **0.7.0** (`STATUS.md`) is the development state and not yet released:
AIbex AIOS becomes **AIbex AIBOS** — the command `aibos`, `~/.aibos`, `.aibos/` in
vaults, the kernel skills `aibos-*`, the keys `aibos:` and `requires.aibos`, the
organisation `aibex-aibos` — with a changeover from 0.6 and the old names as a
transition until 0.8; in `sync` the same repo in another form of address (B40),
the first push with upstream (B41) and a note for a project without remote (H48).
The companion packages come in new minor versions with `requires.aibos: ">=0.7,<0.8"`.
Versions 0.1.0 to 0.6.6 are released as AIbex AIOS (tags `v0.1.0` … `v0.6.6`).
All versions below 1.0 are alpha and beta versions.

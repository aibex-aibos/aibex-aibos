---
title: "Installation und Konfiguration"
date: 2026-11-16
author: iHux
status: Spec
tags: [spec, aibos, v0.7, installation, konfiguration]
number: 04
related:
  - "Spec 01 AIbex AIBOS v0.7 — Überblick"
  - "Spec 02 Master-Kontext"
  - "Spec 03 Skills und Assistenten"
  - "Spec 05 Projekte"
  - "Spec 06 Pakete und Workspaces"
  - "Spec 07 Arbeitspferde"
  - "Memo 04 Der Vault §AIOS, Repo und Installation (AA-AIbex-AIOS, @Memo/V0.1)"
  - "Memo 09 Parallele Versionen und Aktivierung je Projekt (AA-AIbex-AIOS, @Memo/V0.1)"
  - "Memo 10 Das Verzeichnis .aios — global, Vault und Projekt (AA-AIbex-AIOS, @Memo/V0.1)"
  - "Memo 21 Repo ohne Vault und Skill-Gruppen (AA-AIbex-AIOS, @Memo/V0.1)"
  - "Memos 15–17 Versionen, Demo-Assistenten (AA-AIbex-AIOS, @Memo/V0.2)"
  - "Memos 03, 06, 11, 15, 23 (AA-AIbex-AIOS, @Memo/V0.3)"
  - "Memos 08–29 (AA-AIbex-AIOS, @Memo/V0.4)"
  - "Memos 03, 04, 20, 26–35 (AA-AIbex-AIOS, @Memo/V0.5)"
  - "Memos 02, 03, 06, 07, 12, 14–19, 21, 24, 28–30 (AA-AIbex-AIOS, @Memo/V0.6)"
  - "Memos 79–84 (AA-AIbex-AIOS, @Memo/V0.6): v0.6.1"
  - "Memos 01–15 (AA-AIbex-AIOS, @Memo/V0.7): Umbenennung in AIBOS"
---

# Installation und Konfiguration

Diese Spec regelt, welche Dateien AIBOS v0.7 wo anlegt, ihre Formate, die Konfiguration mit Übertrumpfung, die Weiterleiter, das CLI `aibos` und den Umstieg von v0.6 (bis v0.6.6 AIbex AIOS mit `aios`, `~/.aios`, `.aios/`). Plattformen: macOS und Linux.

AIBOS schreibt nur in drei Bereiche (Spec 01, Grundregel 11, I13): a) `~/.aibos`, b) das Innere von Vaults, c) die eigenen Hook-Einträge in `~/.claude/settings.json`. Nach `/opt/aibos` installiert es nur mit `aibos --install --system` (V0.6, Memo 14, K4).

## Dateistrukturen

### Installationen — `~/.aibos/` oder `/opt/aibos/`

Eine Installation hat an beiden Orten denselben Aufbau. **Standard** ist `~/.aibos/`: Kernel in `~/.aibos/versions/v<version>/`, Arbeitspferde in `~/.aibos/workers/`, Verzeichnisse `~/.aibos/installations.yaml` und `~/.aibos/workers.yaml`. Mit `aibos --install --system` (computerweit, mit `sudo`) liegt dasselbe unter `/opt/aibos/`, wie bis v0.5:

```
/opt/aibos/                          bzw. ~/.aibos/ mit versions/ statt der Versionen direkt
├── installations.yaml
├── workers.yaml                    Verzeichnis der Arbeitspferde (Spec 07)
├── workers/<paket>/v<version>/     Installationen der Arbeitspferde, unveränderlich (Spec 07)
├── shared/                         in v0.7 leer
└── v0.7.0/                         unveränderlich (unter ~/.aibos: versions/v0.7.0/)
    ├── VERSION
    ├── bin/
    │   └── aibos
    ├── lib/aibos/                   Python-Paket: Logik von aibos
    ├── manifest.yaml               Paket-Manifest des Kernels (type: kernel, Spec 06)
    ├── skills/
    │   └── aibos/aibos-<name>/SKILL.md   Kernel-Skills (vollständig; aibos-gui mit gui.yaml)
    ├── templates/
    │   ├── forwarder               Quelle des Weiterleiters ~/.aibos/bin/aibos
    │   └── gitignore               Vorlage für aibos --init
    ├── doc/
    │   ├── spec/                   die Spec dieser Version (Pflicht)
    │   └── tutorials/              Tutorials (Demo-Assistenten, Projekte)
    └── python/                     venv mit PyYAML, vorkompiliert
```

Künftig kommt `doc/wiki/` hinzu.

| Pfad | angelegt von | Inhalt | änderbar |
|---|---|---|---|
| `~/.aibos/` bzw. `/opt/aibos/` | `aibos --install` (`/opt/aibos` nur mit `--system`) | gehört dem Benutzer (v0.7: ein Benutzer) | — |
| `installations.yaml` | `aibos --install`, `--remove-version` | Verzeichnis der Installationen | nur durch AIBOS |
| `versions/v<version>/` bzw. `/opt/aibos/v<version>/` | `aibos --install` | vollständige Installation, danach schreibgeschützt | nie (I5) |
| `workers/<paket>/v<version>/` | setup eines Arbeitspferds (`aibos --fetch`, `aibos --install`) | Installation einer Version eines Arbeitspferds, danach schreibgeschützt | nie (Spec 07, A2) |
| `workers.yaml` | setup und remove | Verzeichnis der Arbeitspferde | nur durch AIBOS |

Installationen aus früheren Versionen unter `/opt/aibos/` bleiben gültig; die Weiterleiter finden sie weiter (*Weiterleiter*). Arbeitspferde richtet AIBOS dort ein, wo es `/opt/aibos/workers.yaml` schon gibt, sonst unter `~/.aibos/` (Spec 07).

### Benutzer — `~`

```
~/.aios -> ~/.aibos                  Verweis für den Übergang bis 0.8 (*Umstieg auf v0.7*)
~/.aibos/
├── bin/aibos                        Weiterleiter des Kernels
├── bin/aios -> aibos                Alias für den Übergang bis 0.8
├── bin/<programm>                  Weiterleiter der Arbeitspferde (Spec 07)
├── config.yaml                     Voreinstellungen
├── installations.yaml              Installationen unter ~/.aibos und eigene Einträge (z. B. Entwicklungsstand)
├── repo                            Pfad des Klons, aus dem zuletzt installiert wurde (darf außerhalb von ~/.aibos liegen)
├── versions/v<version>/            Installationen des Kernels (Standard)
├── workers/, workers.yaml          Installationen der Arbeitspferde (Standard, Spec 07)
├── hooks-backup.json               vom Installieren ersetzte Hook-Einträge
├── cache/<id>/part-<n>.md          Part-Dateien des Master-Kontexts (Assistenten: cache/a-<name>-<id>/)
├── sessions/<session-id>.yaml      Merker: Assistent der Session (Spec 02)
├── packages/<hub>/<name>/<version>/ Cache der geholten Pakete (Spec 06)
├── hub/<hub>/                      Klon des Index-Repos eines Hubs, falls vorhanden (Spec 06)
└── log/context.log                 Fehler der Hooks außerhalb eines A/W und von --permit (Spec 02)
~/.claude/
└── settings.json                   drei AIBOS-Hooks
```

| Pfad | angelegt von | entfernt von |
|---|---|---|
| `~/.aibos/bin/aibos` | erstes `aibos --install` | `aibos --uninstall` |
| Verweis `~/.aios`, Alias `~/.aibos/bin/aios` | erstes `aibos --install` von v0.7 (*Umstieg auf v0.7*) | `aibos --uninstall`; ab 0.8 der Umstieg |
| `~/.aibos/bin/<programm>` | erstes setup eines Arbeitspferds mit diesem Programm | remove der letzten Version (Spec 07) |
| `~/.aibos/config.yaml` | erstes `aibos --install` (nur wenn fehlend) | nie |
| `~/.aibos/installations.yaml`, `log/`, `cache/`, `packages/`, `hub/` | bei Bedarf | `cache/`: Einträge älter als 7 Tage bei jedem `--load` |
| `~/.aibos/sessions/` | SessionStart-Hook, `aibos --assistant` | Merker mit `used` älter als 30 Tage beim Session-Start (`startup`); ganz bei `aibos --uninstall` |
| `~/.aibos/repo` | `aibos --install` aus einem Klon | nie |
| `~/.aibos/versions/v<version>/` | `aibos --install` ohne `--system` | `aibos --remove-version` |
| `~/.aibos/hooks-backup.json` | erstes `aibos --install` | `aibos --uninstall` (nach Wiederherstellung) |
| Hooks in `~/.claude/settings.json` | erstes `aibos --install` | `aibos --uninstall` |

AIBOS legt nichts in `~/bin`, `~/etc`, `~/tmp` oder `~/git` an und ändert keine Startdatei der Shell; `~/.aibos/bin` steht deshalb in der Regel nicht im `PATH`, und Hooks, Hüllen und Texte von AIBOS rufen den Weiterleiter mit absolutem Pfad auf (V0.6, Memos 06, 07). `ai-brain` in `~/bin` bleibt unverändert. Ein Weiterleiter `~/bin/aios` früherer Versionen bleibt stehen (Altbestand, *Legacy und Umstieg*). Globale Hüllen von v0.5 in `~/.claude/skills/aios-*/` und `~/.claude/skills/gui/` entfernt `aibos --uninstall`; es entfernt nur, was AIBOS erkennbar selbst geschrieben hat (Kopfzeile des Weiterleiters bzw. `` !`aios --skill `` oder `` !`aios --gui `` im Rumpf).

### Vault

```
§<Vault>/
├── .git/                           Root-Projekt (Spec 05)
├── .gitignore                      mit den Ausschlüssen der Unterprojekte
├── .aibos/config.yaml               Bindung oder Markierung, Pakete, Zuordnung
├── .aibos/lock.yaml                 aufgelöste Pakete (Spec 06)
├── .aibos/workspace.yaml            Manifest des Workspace, falls die Vault-Root ein Workspace ist (Spec 06)
├── .aibos/workspace.local.yaml      nur für diesen Rechner: ausgelagerte Teilbäume (Spec 06)
├── .aibos/registry                  Build-Output
├── .claude/skills/<name>/          Build-Output: Hüllen der Kernel-Skills und des Alias, Projekt-Skills (Spec 03)
└── @/                              Root-Masterspace (Klassen, Spec 02)
    ├── @!Skill/<name>/             lokale Blueprints
    ├── @!Assistant/<name>/         lokale Blueprints
    └── @!Package/<name>/           nach aibos --fetch (Spec 06)
```

| Pfad | angelegt von | Git |
|---|---|---|
| `.aibos/config.yaml` | `aibos --activate`, `aibos --fetch`, `aibos --deploy`, `aibos --hubs --vault`, `aibos --assistant`; `legacy:` der Umstieg nach Rückfrage | ja |
| `.aibos/registry`, `.claude/skills/<name>/` | Registrierung (Spec 03) | nie |
| `.aibos/lock.yaml` | `aibos --fetch`, `aibos --install` (Distribution), `aibos --activate` (Umstellung), `aibos --workspace freeze` | ja |
| `.aibos/workspace.yaml` | User; `aibos --workspace sync` trägt Repos mit Remote ein (Spec 06) | ja |
| `.aibos/workspace.local.yaml` | `aibos --workspace detach <pfad>`, `attach <pfad>` | nie |
| `@/`, `.git/`, `.gitignore` | `aibos --activate` bzw. `aibos --init`, falls fehlend | ja |
| `@/@!Skill/<name>/`, `@/@!Assistant/<name>/` | User | ja |
| `@/@!Package/<name>/` | `aibos --fetch` | ja |

### Projekt

```
<Projekt>/
├── .git/
├── .gitignore
├── @/
├── @Memo/                          vom Memo-Skill beim ersten Memo angelegt
├── @Data/<paket>/                  Daten der Pakete (Spec 06)
├── @Secret/                        Geheimnisse des Projekts, nie versioniert (Spec 06, *sync*)
├── .aibos/
│   ├── config.yaml                 optional
│   ├── lock.yaml                   optional (Spec 06)
│   ├── workspace.yaml              nur im Wurzelprojekt eines Workspace, der Vault-Root (Spec 06)
│   ├── backup/                     Sicherung während eines Plans (Spec 06)
│   └── registry                    Build-Output
└── .claude/skills/<name>/          Build-Output
```

| Pfad | angelegt von | Git | vom User bearbeitbar |
|---|---|---|---|
| `@/`, `.gitignore`, `.git/` | `aibos --init` (Spec 05) | ja | ja |
| `@Memo/` | `/memo` oder `/aibos-memo` beim ersten Memo | ja | ja (Memos werden nie geändert, I1) |
| `.aibos/config.yaml` | `aibos --fetch --to <projekt>`, `aibos --deploy --to <projekt>`, `aibos --assistant`, `aibos --init --assistant` | ja | ja |
| `@Data/<paket>/` | das Paket (Spec 06) | ja | ja |
| `.aibos/lock.yaml` | `aibos --fetch`, `aibos --install`, `aibos --activate`, `aibos --workspace freeze` | ja | nein |
| `.aibos/backup/` | Plan mit „alles oder nichts" (Spec 06) | nie | nein |
| `.aibos/workspace.yaml` | User; `aibos --workspace sync` (Spec 06) | ja | ja |
| `@Secret/` | User | nie | ja |
| `.aibos/registry` | Registrierung (Spec 03) | nie | nein |
| `.claude/skills/<name>/` | Registrierung | nie | nein |

Lokale Skills werden als Blueprint in `@/@!Skill/<name>/` geschrieben, nicht direkt in `.claude/skills/`.

## Formate

### `.aibos/config.yaml`

```yaml
aibos: 0.6.0
packages:
  skill-memo: "~=6.0"
  assistant-gaertner: "~=0.2.0"
  knowledge-scorpio: {range: "~=0.1.0", hub: aibex-hub}
assistant: gaertner
hosts: [claude-code]
```

| Schlüssel | erlaubt in | Wert | Regel |
|---|---|---|---|
| `aibos` | Vault-Root | Version ohne `v` | bindet den Vault an eine Version (Spec 02, *Arten von Vaults*); muss als einzelne Zeile `aibos: <version>` stehen, weil die Weiterleiter sie ohne YAML-Parser lesen. In einem Projekt wird er mit Warnung übergangen, `aibos --integrity` meldet ihn (Spec 01, I14; V0.6, Memos 14, 16) |
| `legacy` | Vault-Root | `ai-brain` | Markierung des Legacy-Modus (Spec 02); als einzelne Zeile `legacy: ai-brain`. Neben `aibos` gilt `aibos`, mit Warnung (V0.6, Memo 17) |
| `packages` | Vault, Projekt | Name → Bereich oder `{range, hub, from, only}` | gewünschte Pakete dieses Projekts, nicht vererbt (Spec 06, *Konfiguration und Lock*) |
| `skills`, `assistants` | Vault, Projekt | Name → exakte Version | aus v0.3; gelten als `packages` mit `==<version>` (Umstellung in Spec 06 im Tag `v0.6.6`) |
| `assistant` | Vault, Projekt | `<name>`, `none` oder `inherit` | Zuordnung des Assistenten (Spec 03, *Zuordnung*); fehlt der Schlüssel, gilt `inherit` |
| `hosts` | alle Ebenen | Liste | in v0.7 nur `claude-code` |
| `hubs` | Home, Vault-Root | Liste von Namen bzw. `name: url` | Hub-Liste in Suchreihenfolge; die Vault-Root vor Home, bei gleichem Namen gilt die Vault-Root; ohne Eintrag `[aibex-aibos]` (Spec 06, *Hub-Liste*) |
| `sync` | Vault-Root | `auto`, `manual`, `off` | Abgleich des Workspace mit den Remotes (Spec 06, *Schlüssel `sync:`*); Standard `auto` mit `workspace.yaml`, sonst `off`; in einem Cloud-Ordner (Cloud-Drive) gilt immer `off`, auf einem Netz-Drive wird `off` empfohlen (V0.6, Memos 174, 224; Spec 06, *Arten der Führung*) |
| `inline_limit` | Home | Zeichenzahl | Grenze für die Inline-Ladung von Master-Kontext und Assistent, Standard 9000 |

`aibos`, `legacy` und `assistant` in `~/.aibos/config.yaml` sind nicht erlaubt: Die Voreinstellung des Rechners darf keinen Vault binden (Grundregel 6) und keinen Assistenten festlegen (Grundregel 8). Unbekannte Schlüssel, Schlüssel auf einer Ebene, auf der sie nicht erlaubt sind, ein `aibos`-Wert, der keine Version ist, und ein `assistant`-Wert, der kein gültiger Name ist, werden mit Warnung ignoriert.

`config.yaml` verwendet eine Untermenge von YAML, die AIBOS ohne PyYAML liest: Zeilen `schlüssel: wert` ohne Einrückung, Listen als `[a, b]` oder als eingerückte `- eintrag`, eine eingerückte Ebene `name: wert` (für `packages` sowie `skills` und `assistants` aus v0.3), als Wert auch eine einzeilige Abbildung `{schlüssel: wert, …}` mit Listen `[a, b]` darin (für `packages`), Listen mit gemischten Einträgen `- name` und `- name: wert` (für `hubs`), Kommentare mit `#`, Werte in Anführungszeichen und Blocktexte (`schlüssel: >` bzw. `|` mit eingerückten Zeilen, wie im Frontmatter einer `ASSISTANT.md`). Jeder Schlüssel darf je Datei nur einmal vorkommen. Eine Datei außerhalb dieser Untermenge wird in der Kette mit Warnung übergangen; `aibos --activate`, `aibos --deactivate` und `aibos --assistant` brechen dann ab, ohne sie zu ändern.

### Konfigurationskette

Gelesen wird von `cwd` aufwärts jede `.aibos/config.yaml` bis zur Vault-Root, danach `~/.aibos/config.yaml`. **Je Schlüssel gilt der nächstgelegene Eintrag**. Ausnahmen: `aibos` und `legacy` gelten nur aus der Vault-Root. `packages` gilt nur im eigenen Projekt und wird nicht vererbt, weil jedes Projekt seine Pakete vollständig selbst enthält (Spec 06); die geholten und ausgerollten Pakete wirken trotzdem über die Kette. `hubs` wird aus Vault-Root und Home zusammengesetzt (Spec 06, *Hub-Liste*). Beim Schlüssel `assistant` zählt der Wert `inherit` als „kein Eintrag": Die Suche geht weiter nach oben (Spec 03). Außerhalb eines Vaults gilt nur `~/.aibos/config.yaml`; liegt `~` in einem Vault, zählt `~/.aibos/config.yaml` trotzdem als Ebene *Home*. `aibos --config [<pfad>]` zeigt die wirksamen Werte mit ihrer Herkunft.

| Rang | Quelle |
|---|---|
| 1 | Umgebungsvariable `AIBOS_HOME` (Pfad einer Installation oder eines Entwicklungsstands) — nur für die Wahl der Version |
| 2 | `<cwd>/.aibos/config.yaml` |
| 3 | `.aibos/config.yaml` übergeordneter Projekte, aufwärts |
| 4 | `§<Vault>/.aibos/config.yaml` |
| 5 | `~/.aibos/config.yaml` (ohne `aibos`, `legacy` und `assistant`) |

### `installations.yaml`

```yaml
v0.7.0: ~/.aibos/versions/v0.7.0
```

Eine Zeile je Version, `v<version>: <pfad>`. `~/.aibos/installations.yaml` hat dasselbe Format; bei gleichem Namen gewinnt der Eintrag des Benutzers.

### `lock.yaml` und `workers.yaml`

Beide schreibt nur AIBOS, in einer festen Untermenge von YAML, die ein Bash-Skript ohne YAML-Parser lesen kann (V0.5, Memo 37, K-a): Einrückung immer zwei Leerzeichen je Ebene, ein Schlüssel je Zeile, Werte ohne Anführungszeichen außer bei Bereichen (`"~=0.1.0"`), Listen nur einzeilig `[a, b]`, keine Blocktexte, eine Kopfzeile `# written by AIBOS (…), do not edit`. Das Format von `lock.yaml` steht in Spec 06 (*Konfiguration und Lock*).

```yaml
# written by AIBOS (worker setup), do not edit
schema: 1
programs:
  yt-dlp: [worker-yt-dlp]
  deno: [worker-deno]
workers:
  worker-yt-dlp:
    0.1.0:
      kind: python
      check: ok
      projects: ["/Users/<user>/vault/§Wald", "/Users/<user>/vault/§Wald/P-Probe-Alt"]
  worker-deno:
    0.1.0:
      kind: python
      check: ok
      projects: ["/Users/<user>/vault/§Wald"]
```

`programs` nennt je Programm die Pakete, die es bereitstellen (gelesen vom Weiterleiter, Spec 07). Unter `workers` steht je Paket und Version die Art, das letzte Ergebnis von `check` (`ok` oder `failed`) und die nutzenden Projekte. Der Ort einer Version ergibt sich aus dem Ort der Datei (`<workers.yaml>/../workers/<paket>/v<version>/`). Pfade mit Leerzeichen oder Sonderzeichen stehen in Anführungszeichen.

### `.aibos/registry`

```yaml
# written by AIBOS (registration), do not edit
schema: 1
registered:
  memo:
    source: "/…/§Demo/@/@!Skill/memo"
    version: 6.0.0
    digest: sha256:…
  aibos-init:
    source: kernel
    version: 0.6.0
    digest: sha256:…
```

Bei den Hüllen der Kernel-Skills und des Alias `gui` steht `source: kernel` und als `version` die Version des Kernels, der sie geschrieben hat (Spec 03, *Kernel-Skills im Vault*). `digest` ist SHA-256 über alle Dateien des Skills, je Datei in Pfadfolge `<relativer pfad>⏎<inhalt>⏎`; die Registrierung erkennt damit Änderungen am Blueprint und an der Kopie in `.claude/skills/`. `version` ist immer gesetzt, weil Skills ohne Version nicht registriert werden (Spec 03). Die Registry hat dieses feste Format und wird nur von AIBOS geschrieben; in v0.3 hieß sie `.aibos/manifest`. `aibos --skill aibos-memo` liest sie, um den Vorrang von `memo` zu prüfen (Spec 03).

### Merker der Session — `~/.aibos/sessions/<session-id>.yaml`

```yaml
# written by AIBOS (session), do not edit
cwd: "/…/§Demo/G-Garten"
assistant: gaertner
used: 2026-10-03T14:05:00
```

`assistant` ist ein Name oder `none`, nie `inherit`. Geschrieben vom SessionStart-Hook und von `aibos --assistant --session` (Spec 02, 03), gelesen vom Hook, von `aibos --context --assignment --session` und `aibos --gui --session`; er gilt nur, solange das `cwd` des Aufrufs gleich seinem `cwd` ist (Spec 02). Format: die Untermenge von `config.yaml`.

### Hooks in `~/.claude/settings.json`

```json
{
  "hooks": {
    "SessionStart":     [ { "hooks": [ { "type": "command", "command": "/Users/…/.aibos/bin/aibos --context --session" } ] } ],
    "UserPromptSubmit": [ { "hooks": [ { "type": "command", "command": "/Users/…/.aibos/bin/aibos --context --advise" } ] } ],
    "PreToolUse":       [ { "matcher": "Bash|Skill|Read", "hooks": [ { "type": "command", "command": "/Users/…/.aibos/bin/aibos --context --permit" } ] } ]
  }
}
```

`aibos --install` schreibt den absoluten Pfad des Weiterleiters aus (V0.6, Memo 06). Zusammengeführt mit dem `json`-Modul von Python; andere Schlüssel und fremde Hooks bleiben erhalten, auch fremde Hooks in derselben Gruppe. Vorhandene AIBOS-Hooks (`aibos --context --session` bzw. `--advise`, auch mit `~/bin/aios` oder ohne Pfad) ersetzt `aibos --install` an ihrer Stelle durch den Aufruf mit absolutem Pfad; der Hook `PreToolUse` kommt dazu (V0.6, Memo 19, F10). Die Hooks `ai-brain --session` bzw. `ai-brain --advise` werden entfernt und in `~/.aibos/hooks-backup.json` gesichert, im selben Aufbau wie `settings.json` (`{"hooks": {…}}`). Ist `settings.json` kein gültiges JSON, bricht `aibos` ab, bevor etwas geschrieben wird. Hooks `aibos-context --session` bzw. `--advise` aus v0.3 und v0.4 ersetzt `aibos --install` durch die neuen Aufrufe (V0.5, Memo 04). Regeln in `permissions` schreibt AIBOS nicht (Spec 01, I13).

### Hüllen der Kernel-Skills und des Alias

```markdown
---
name: aibos-init
description: "<Feld description aus <installation>/skills/aibos/aibos-init/SKILL.md, ungekürzt>"
allowed-tools: Bash(/Users/…/.aibos/bin/aibos --skill aibos-init)
---

!`/Users/…/.aibos/bin/aibos --skill aibos-init`
```

Die Hüllen schreibt die Registrierung im A/W an die Vault-Root und in die Projekte (Spec 03, *Kernel-Skills im Vault*), mit dem absoluten Pfad des Weiterleiters; `allowed-tools` nennt nur den eigenen Aufruf, alle weiteren Befehle gibt der Hook `PreToolUse` frei (Spec 02, *Freigabe*; V0.6, Memos 29, 30). `aibos --skill <name>` gibt den Rumpf (ohne Frontmatter) der `SKILL.md` der **gültigen** Version aus; gültig ist die Version, die der Weiterleiter für `cwd` wählt. Außerhalb eines A/W gibt es nur `Kein AIBOS-Workspace: <cwd>` auf stderr aus und endet mit Exit-Code 1 (Spec 03). Die Beschreibung wird bei jeder Registrierung aus der gültigen Version übernommen. Der Rumpf eines Kernel-Skills enthält keine `!`-Befehle, weil Claude Code die Ausgabe von `` !`aibos --skill …` `` nicht noch einmal auswertet; er weist Claude an, die Befehle selbst auszuführen. Braucht ein Skill die Session-ID (`aibos-assistant`, `aibos-context`), bleibt der Aufruf `` !`aibos --skill <name>` ``, den jede Version versteht, und die Hülle nennt die ID in einer Textzeile nach dem Aufruf: `` Session-ID dieses Chats: `${CLAUDE_SESSION_ID}` ``. Claude Code ersetzt den Platzhalter im Text der Hülle (V0.3, Memo 31); der Rumpf schreibt `<session-id>` und verweist auf diese Zeile. So bleibt der Aufruf in der Hülle gleich, wenn der Vault an eine neue Version gebunden wird (V0.3, Memo 50). `aibos --skill <name> --session <id>` setzt die ID für `<session-id>` direkt in den Rumpf ein (für Tests und Aufrufe von Hand).

Der Alias `/gui` hat dieselbe Form mit festem Text:

```markdown
---
name: gui
description: "Zeigt die Oberfläche des aktiven Assistenten (AIbex AIBOS). Auslöser: /gui, „Oberfläche", „Menü"."
allowed-tools: Bash(/Users/…/.aibos/bin/aibos --gui --session *)
---

!`/Users/…/.aibos/bin/aibos --gui --session ${CLAUDE_SESSION_ID}`
```

v0.7 liefert die Kernel-Skills `aibos-context`, `aibos-init`, `aibos-register`, `aibos-status`, `aibos-package`, `aibos-fetch`, `aibos-deploy`, `aibos-distribution`, `aibos-assistant`, `aibos-integrity`, `aibos-memo` und `aibos-gui` sowie den Alias `gui` (Spec 02, 03, 05). Das Feld `allowed-tools` in der `SKILL.md` eines Kernel-Skills wird nicht mehr in die Hülle übernommen.

### `.gitignore`-Vorlage

```gitignore
.DS_Store
.claude/skills/
.claude/worktrees/
.agents/
.aibos/registry
.aibos/backup/
.aibos/workspace.local.yaml
@Secret/
```

`.claude/worktrees/` enthält Arbeitskopien, die der Host für eine Session anlegen kann (V0.5, Memos 71, 73), `.agents/` Kopien von Skills für andere Agenten (V0.5, Memo 10), `.aibos/backup/` die Sicherung während eines Plans (Spec 06), `.aibos/workspace.local.yaml` was nur für diesen Rechner gilt und `@Secret/` die Geheimnisse eines Projekts (Spec 06, *Workspaces*; V0.6, Memos 170, 172).

## Umlenkung für Tests

Alle festen Orte lassen sich über Umgebungsvariablen umlenken, damit Tests in einem Sandkasten laufen und den Rechner nicht verändern:

| Variable | ersetzt | Standard |
|---|---|---|
| `AIBOS_PREFIX` | `/opt/aibos` (Installationen mit `--system` und solche früherer Versionen) | `/opt/aibos` |
| `HOME` | `~` (damit `~/.aibos`) | Home-Verzeichnis |
| `AIBOS_CLAUDE_DIR` | `~/.claude` | `$HOME/.claude` |
| `AIBOS_SUDO` | Programm für `sudo` | `sudo` |
| `AIBOS_STUP_URL` | Quelle von stup (auch `file://`), nur für `aibos --prepare` (Altbestand) | `https://raw.githubusercontent.com/bluccino/tool-stup/master/bin/stup` |
| `AIBOS_HUBS` | Hub-Liste für Tests, ersetzt `hubs` aus Vault-Root und Home: Einträge `name=url` (auch `file://`), durch Leerzeichen getrennt | — |
| `AIBOS_GITHUB` | Basis-URL für Hubs außerhalb der Hub-Liste (statt `https://github.com/`), für Tests auch `file://` | `https://github.com/` |
| `AIBOS_PIP` | Befehl, der `python/requirements.txt` in die venv installiert; gesetzt wird die venv ohne `pip` angelegt | `<venv>/bin/python -m pip install -q -r` |
| `AIBOS_TEST_FAIL` | `<n>` lässt den n-ten Schritt eines Plans scheitern, `<n>:crash` beendet den Prozess dort ohne Aufräumen (Tests der Sicherung, Spec 06; V0.5, Memo 51) | — |
| `AIBOS_PREPARE_PATH` | `PATH` für die Prüfung der Grund- und Entwicklerausstattung in `aibos --prepare` und `aibos --install` (V0.5, Memo 49) | `PATH` |
| `AIBOS_MANAGED_SETTINGS` | Managed Settings für `aibos --context --permit` (Spec 02, *Freigabe*), statt der Standardorte | — |
| `AIBOS_TEST_UID` | eigene uid bei der Prüfung des Eigentümers von Projekten aus `/opt/aibos/workers.yaml` (*`aibos --install`*, Schritt 7); damit wirken Vaults im Sandkasten fremd (V0.6, Memos 153, 154: F151) | eigene uid |
| `AIBOS_PIP_FIND_LINKS` | Ordner mit Wheels für das setup von Arbeitspferden: `pip` läuft dann mit `--no-index --find-links <ordner>`, nie ohne `--no-index` (Spec 07) | — |

Tests rufen damit nie das echte `sudo` auf und greifen nie auf das Netzwerk zu.

**Übergang bis 0.8:** Fehlt eine Variable `AIBOS_<name>`, liest AIBOS `AIOS_<name>` und gibt einmal je Aufruf auf stderr aus: `note: AIOS_<name> is read as AIBOS_<name> until AIBOS 0.8` (V0.7, Memo 04: F268). Variablen, die AIBOS an Pakete weitergibt (`AIBOS_WORKER_DIR`, `AIBOS_DATA`, `AIBOS_PACKAGE`, `AIBOS_PROJECT`, `AIBOS_GUI`; Spec 06, 07), setzt es unter beiden Namen (V0.7, Memo 13: FL4).

Weiterleiter und `aibos` verwenden ausschließlich diese Variablen, nie fest verdrahtete Pfade.

## Weiterleiter

`~/.aibos/bin/aibos` enthält keine Logik außer der Wahl der Version; `aibos --install` legt es aus `templates/forwarder` an, dazu `~/.aibos/bin/aios` als Verweis darauf (Alias bis 0.8; V0.7, Memo 04: F268). Er bedient Vaults mit Bindung `aibos:` (ab 0.7) und mit Altbindung `aios:` (0.6.x) mit dem Kernel ihrer Version; die Kernel 0.6.x finden ihre Orte über den Verweis `~/.aios` (V0.7, Memos 11, 13: P19, FL6). Ein `~/bin/aios` früherer Versionen bleibt als Altbestand stehen; Hooks und Hüllen rufen nur `~/.aibos/bin/aibos` auf. `aibos --install` erkennt einen Weiterleiter an seiner Kopfzeile (`# forwarder: ~/.aios/bin/aios` bis 0.4.3, `# forwarder: ~/.aibos/bin/aibos` ab 0.5.0). Die Weiterleiter der Arbeitspferde unter `~/.aibos/bin/` regelt Spec 07.

1. Ist `AIBOS_HOME` gesetzt (sonst `AIOS_HOME`): `$AIBOS_HOME/bin/aibos` aufrufen.
2. `aibos --activate v<version> …`: Ist diese Version installiert, wird sie aufgerufen, unabhängig davon, an welche Version `cwd` gebunden ist; so aktiviert immer die genannte Version (V0.3, Memo 54, A1). Ist sie nicht installiert, gilt die übliche Wahl, und die gewählte Version meldet die fehlende Installation.
3. `aibos --install distribution-…` (auch mit Hub-Präfix), `aibos --remove-version …` und `aibos --vaults`: die höchste installierte Version, unabhängig von `cwd`; nur die neueste Version kennt alle Vaults (V0.6, Memos 137, 138: B21).
4. Sonst vom physischen `cwd` (`pwd -P`) aufwärts die Vault-Root suchen (gibt es `cwd` nicht mehr, siehe *CLI `aibos`*, ohne gültiges Arbeitsverzeichnis; H34); bei `aibos --workspace <befehl> <pfad>` statt vom `cwd` vom Ordner `<pfad>` (bei einer Datei, die es nicht gibt, von ihrem Ordner; V0.6, Memo 208: H37). Dort in `.aibos/config.yaml` die Zeilen `aibos: <version>` und `legacy: ai-brain` lesen; fehlt `.aibos/config.yaml`, in `.aios/config.yaml` die Zeilen `aios: <version>` (Altbindung) und `legacy: ai-brain`. Andere `config.yaml` zählen nicht (Spec 01, I14). Außerhalb eines Vaults wird nicht gesucht, und `~/.aibos/config.yaml` zählt nie, auch wenn `~` in einem Vault liegt.
5. Bindung gefunden: `v<version>` in `~/.aibos/installations.yaml`, danach in `/opt/aibos/installations.yaml` nachschlagen und `<pfad>/bin/aibos` (bei 0.6.x `<pfad>/bin/aios`) mit allen Argumenten aufrufen. Nicht installiert: bei `aibos --context …` nichts ausgeben (`--id`: `mode=none`) und den Fehler ins Log schreiben (Spec 02), sonst Fehler mit Hinweis auf `aibos --install v<version>`. Eine Altbindung `aios:` unter 0.6.0 behandelt der Weiterleiter wie keine Bindung (V0.7, Memo 16: FL9); `aibos:` gibt es erst ab v0.7, deshalb gilt dort keine Untergrenze.
6. Keine Bindung:
   - `aibos --context …` mit `legacy: ai-brain`: **Legacy-Modus**, d. h. `ai-brain` mit den Argumenten nach `--context` aufrufen, falls vorhanden (`--session`, `--advise`, `--load`, `--context`; `--permit` gibt nichts aus); sonst nichts ausgeben. Ausnahme `--id`: Ausgabe von `ai-brain --id` mit angehängtem `mode=legacy` (Spec 02). Nur die Gruppe `--context` ruft `ai-brain` auf (V0.5, Memo 03).
   - `aibos --context …` ohne Markierung (Vault ohne Bindung, außerhalb eines Vaults): nichts ausgeben; `--id` meldet `mode=none` (Spec 02).
   - jeder andere Aufruf: die höchste installierte Version aufrufen.

„Höchste Version" gilt nach Semver: `0.10.0` liegt über `0.3.0`, eine Vorabversion wie `0.3.0-dev` unter `0.3.0`. In `installations.yaml` darf ein Pfad in Anführungszeichen stehen und mit `~/` beginnen.

Alle Argumente werden unverändert durchgereicht, auch `-?`, `--help` und `--version`. Die eigenen Optionen der Weiterleiter haben deshalb drei Striche:

| Option | Wirkung |
|---|---|
| `---which` | gewählte Installation und Grund, z. B. `tool=aibos kind=aibos target=/Users/…/.aibos/versions/v0.7.0/bin/aibos why=aibos: 0.7.0 in /…/§Demo/.aibos/config.yaml` |
| `---version` | Version des Weiterleiters |
| `---help` | Hilfe |

Die Weiterleiter lesen nur kleine Dateien und greifen nie auf das Netzwerk zu.

## CLI `aibos`

| Befehl | Wirkung |
|---|---|
| `aibos -?`, `--help`, `--version` | Hilfe bzw. Version des laufenden Programms |
| `aibos --prepare [--dev]` | Altbestand: Rechner nach v0.5 vorbereiten; wird von keinem Befehl und keiner Anleitung mehr verwendet |
| `aibos --install [v<version>] [--system]` | Version installieren, nach `~/.aibos/versions/` bzw. mit `--system` nach `/opt/aibos/`; beim ersten Install von v0.7 mit dem Umstieg (*Umstieg auf v0.7*) |
| `aibos --install distribution-<name>[<bereich>] [<vault>] [--from <repo>]` | Distribution installieren bzw. aktualisieren: Kernel, Arbeitspferde, Pakete im Vault (Spec 06, *Distributionen*) |
| `aibos --context [--list \| --id \| --load <pfad> \| --assistant <name> \| --assistants \| --assignment \| --session \| --advise \| --permit]` | Master-Kontext und Assistenten lesen, für Hooks und lesende Skills; Freigabe für den Hook `PreToolUse` (Spec 02) |
| `aibos --activate v<version> [<vault-root>]` | Vault an eine Version binden, nur an der Vault-Root |
| `aibos --deactivate [<vault-root>]` | Bindung lösen |
| `aibos --config [<pfad>]` | wirksame Konfiguration mit der Herkunft je Schlüssel, nur lesend |
| `aibos --versions` | installierte Versionen und ihre Orte |
| `aibos --vaults` | gefundene Vaults mit Art, Bindung und Quelle, nur lesend (*`aibos --vaults`*) |
| `aibos --remove-version v<version>` | Installation entfernen |
| `aibos --uninstall` | Benutzereinrichtung entfernen |
| `aibos --register [<pfad>]` | Hüllen der Kernel-Skills und Projekt-Skills registrieren, mit Vorschau (Spec 03) |
| `aibos --fetch [<hub>/]<paket>[<bereich>] [--hub <hub>] [--from <repo>] [--to <projekt>]` | Paket laden: holen, Arbeitspferde einrichten, ausrollen, registrieren (Spec 06, 07) |
| `aibos --fetch [--to <projekt>]` | Projekt mit `lock.yaml` abgleichen (Spec 06) |
| `aibos --fetch --upgrade [<paket>] [--to <projekt>]`, `--remove <paket>` | Pakete aktualisieren bzw. entfernen (Spec 06) |
| `aibos --deploy <paket> --only <element>… \| --all [--to <projekt>]`, `aibos --deploy [--to <projekt>]` | Elemente eines geholten Pakets ausrollen bzw. zeigen (Spec 06) |
| `aibos --library [<suchwort> \| <paket>]` | Pakete der Hub-Liste suchen bzw. Versionen eines Pakets (Spec 06) |
| `aibos --hubs [add <name> [<url>] \| remove <name>] [--vault]` | Hub-Liste zeigen bzw. ändern (Spec 06) |
| `aibos --workspace attach <repo> [<vault-ordner>] \| attach <pfad> \| sync [<pfad>] [--group <g> \| --only] \| detach [<pfad>] \| remove <pfad> \| history <pfad> [--deleted] \| restore <pfad> [--at <zeit>] \| status [<pfad>] \| freeze [<pfad>]` | Workspace anbinden, synchronisieren, lösen bzw. Teilbaum zurückholen und auslagern, Projekt entfernen, frühere Fassungen zeigen und zurückholen, prüfen, einfrieren (Spec 06) |
| `aibos --contribute <datei>… --to <paket> [--message <text>]` | Rückfluss als Pull Request (Spec 06) |
| `aibos --run <befehl> [argumente]` | ausgerollter Befehl eines Pakets (Spec 06) |
| `aibos --worker [<paket> setup] [--to <projekt>]` | Arbeitspferde zeigen bzw. reparieren (Spec 07) |
| `aibos --skill <name> [--session <id>]` | Rumpf eines Kernel-Skills der gültigen Version (für die Hüllen), nur im A/W; außerhalb `Kein AIBOS-Workspace: <cwd>`, Exit-Code 1; mit `--session` ist `<session-id>` im Rumpf ersetzt |
| `aibos --assistant <name\|none\|inherit> [--to <projekt>] [--session <id>]` | Assistent dem Projekt zuordnen (Spec 03, *Wechsel*) |
| `aibos --gui [--session <id>] [--html]` | Rumpf des Oberflächen-Skills des aktiven Assistenten bzw. mit `--html` das HTML-Fragment (Spec 03, *Oberflächen*); `aibos --gui --aibos` für die AIBOS-Oberfläche, `aibos --gui --apps` für die Liste der Oberflächen ausgerollter Apps, `aibos --gui --skill <oberfläche> [--html]` für die Oberfläche einer App |
| `aibos --init [<pfad>] [--assistant <wert>] [--name <name>] [--accept-name]` | Ordner zum Projekt machen oder ein Projekt ergänzen (Spec 05) |
| `aibos --integrity [<pfad>]` | Integrität des Projekts und aller Unterprojekte prüfen, nur lesend (Spec 05) |

Alle schreibenden Befehle zeigen zuerst einen Plan und fragen `[Y/n]` (I7). Für Skills, die im Bash-Werkzeug keine Rückfrage beantworten können, gibt es zwei Schalter: `--plan` zeigt nur den Plan und schreibt nichts (Exit 0), `--yes` überspringt die Frage. Ein Skill zeigt den Plan, fragt im Chat und ruft erst nach Ja mit `--yes` auf; ohne Eingabe auf stdin wird nie geschrieben. Mit `--yes` gibt ein Befehl nur noch das Ergebnis in wenigen Zeilen und Fehler aus. **Ohne gültiges Arbeitsverzeichnis** (der Ordner der Shell wurde gelöscht oder ausgelagert): Nennt der Aufruf einen absoluten Pfad, arbeiten Weiterleiter und `aibos` mit ihm weiter und lesen das Arbeitsverzeichnis nicht. Ohne Pfad, oder mit relativem Pfad, enden sie mit Exit 1 und `*** aibos: the current directory no longer exists; change to an existing one (e.g. cd ~) or give an absolute path`, ohne Python-Fehler (Weiterleiter 0.4.3; V0.6, Memo 204: H34). Hooks schreiben in diesem Fall nur ins Log (Spec 02). **Sprache:** Alle Ausgaben von `aibos` auf stdout und stderr sind englisch, auch Berichte und Aufstellungen; deutsch bleiben nur die Commit-Nachrichten, die AIBOS schreibt, die Meldung `Kein AIBOS-Workspace` sowie die Rümpfe der Kernel-Skills (V0.3, Memo 53, 54). Claude spricht mit dem User in dessen Sprache. `bin/aibos` und die Weiterleiter sind Bash-Skripte nach der Bash-Konvention (Help-, Version- und Dispatch-Blöcke, Fallback); die Logik hinter `aibos` läuft in Python im venv der Installation (`python/`). `--prepare`, `--install`, `--versions`, `--remove-version` und `--uninstall` verwenden nur die Standardbibliothek, weil sie aus einem Klon mit dem `python3` des Systems laufen, bevor eine venv existiert. Voraussetzung ist die **Grundausstattung**: `python3` ≥ 3.11 mit den Modulen `venv` und `pip`, `git`. `aibos --install` prüft sie selbst (unten).

### `aibos --prepare`

**Altbestand:** `aibos --prepare` bleibt bestehen, wird aber von keinem Befehl, keinem Installer und keiner Anleitung mehr verwendet; es legt Verzeichnisse außerhalb von `~/.aibos` an und gehört damit nicht zu AIBOS (V0.6, Memos 06, 07). Es verhält sich wie in v0.5:

| Prüfung | fehlt → |
|---|---|
| `/opt/aibos` existiert und ist beschreibbar | anlegen, wenn das übergeordnete Verzeichnis beschreibbar ist; sonst `sudo mkdir -p /opt/aibos && sudo chown $USER /opt/aibos`; ohne `sudo` Rückfall auf `~/.aibos/versions/`: Installationen liegen dann in `~/.aibos/versions/v<version>/` und werden in `~/.aibos/installations.yaml` eingetragen, damit die Weiterleiter sie finden |
| `~/bin`, `~/etc`, `~/tmp`, `~/git` | anlegen |
| stup vorhanden und aktuell | installieren nach `~/bin/stup` bzw. aktualisieren (von `bluccino/tool-stup`, Vergleich mit `stup --version`); ist die Quelle nicht erreichbar, nur eine Warnung, sofern stup vorhanden ist |
| `~/bin/profile.sh` | mit `stup --profile` anlegen, nur wenn sie fehlt; nie überschreiben |
| **Grundausstattung:** `python3` ≥ 3.11 mit den Modulen `venv` und `pip`, `git` | Meldung mit dem Weg dazu (z. B. Paketverwaltung des Systems, auf macOS `brew install python`); AIBOS installiert nichts davon ohne Rückfrage. Ohne Grundausstattung installiert `aibos --install` nichts (Version und Distribution), und es gibt kein setup von Arbeitspferden; Pakete ohne Arbeitspferde lassen sich weiter holen (V0.5, Memo 31). 3.11, weil Arbeitspferde wie `yt-dlp` und `deno` es verlangen; das `python3` von macOS (3.9) genügt nicht (V0.5, Memos 90, 91: B11) |
| **Entwicklerausstattung** (nur `--dev`): zusätzlich `gh` | Meldung mit dem Weg dazu; gebraucht für Veröffentlichen und `aibos --contribute` |

Ist alles vorhanden: „Rechner vorbereitet", keine Rückfrage. `deno` ist keine Voraussetzung, sondern das Arbeitspferd `worker-deno` (Spec 07).

### `aibos --install [v<version>]`

Aufgerufen aus einem Klon des Repos `aibex-aibos` (`./bin/aibos --install …`) oder über den Weiterleiter; dann gilt der Klon aus `~/.aibos/repo`.

1. **Version bestimmen:** angegeben oder der höchste Tag `v<MAJOR.MINOR.PATCH>` im Repo (Vorabversionen wie `v0.3.0-rc1` nur, wenn angegeben); vorher `git fetch --tags`, sofern der Klon einen Remote hat.
2. **Grundausstattung prüfen:** fehlt sie, meldet `aibos --install`, was fehlt und wie es zu installieren ist (z. B. auf macOS `brew install python`), und bricht ab, ohne etwas zu schreiben (V0.6, Memo 07).
3. **Plan zeigen und fragen**; mit `--system` steht im Plan, dass `sudo` nach einem Passwort fragen kann; ohne `sudo` bricht `--system` ab, mit Hinweis auf den Standardort (V0.6, Memo 44, F49). Schritte mit eigener Frage nennt der Plan als Zeile „(then with its own question: …)"; gefragt wird nach dem Ja zum Plan (F60). Beim ersten Install von v0.7 enthält der Plan den Umstieg (*Umstieg auf v0.7*).
4. **Installieren**, falls `v<version>` noch nicht installiert ist: Stand des Tags mit `git archive` nach `~/.aibos/versions/v<version>/` (mit `--system`: `/opt/aibos/v<version>/`) übertragen (Abbildung siehe *Repo*), venv in `python/` anlegen und `pyyaml` installieren, `python -m compileall`, Dateien schreibschützen, Eintrag in `installations.yaml` desselben Orts.
5. **Benutzer einrichten**, was fehlt: Weiterleiter nach `~/.aibos/bin/aibos` mit Alias `~/.aibos/bin/aios`; ein vorhandener wird nur durch einen neueren ersetzt. Nichts in `~/bin`; ein `~/bin/aios` früherer Versionen nennt der Plan als Altbestand und lässt es stehen. `~/.aibos/config.yaml` mit `hosts: [claude-code]`, die drei Hooks mit absolutem Pfad eintragen bzw. an ihrer Stelle ersetzen (*Hooks in `~/.claude/settings.json`*) und `ai-brain`-Hooks sichern, `~/.aibos/repo` merken.
6. **Keine globalen Hüllen:** `aibos --install` schreibt nichts nach `~/.claude/skills/`; die Hüllen der Kernel-Skills entstehen mit der Registrierung im Vault (Spec 03). Pakete holt der User mit `aibos --fetch` bzw. `/aibos-package` (Spec 06).
7. **Bekannte Vaults** nennt der Plan mit ihrer Art (Spec 02, *Arten von Vaults*): Vaults mit Altbindung mit dem Befehl `aibos --activate v0.7.<n> <vault>`; bekannt sind die Vaults aus den Merkern der Sessions (`cwd`), aus `~/.aibos/repo` und aus den Projekten in `workers.yaml`; nur bekannte Vaults zählen (V0.6, Memo 49, F61). Aus `~/.aibos/workers.yaml` zählt jedes Projekt. `/opt/aibos/workers.yaml` ist computerweit und nennt auch Projekte anderer Benutzer; daraus zählt ein Projekt nur, wenn sein Ordner existiert und dem aktuellen Benutzer gehört (Eigentümer gleich der eigenen uid); ein fehlender oder nicht lesbarer Pfad von dort zählt nicht (V0.6, Memos 153, 154: B26, F150). Die erweiterte Suche aus *`aibos --vaults`* gilt hier nicht (V0.6, Memo 122, F93). Für die Markierung `legacy: ai-brain` bietet der Plan bekannte Vaults ohne Bindung und die `§`-Ordner daneben im selben Elternordner an.

Das Übertragen geschieht in ein temporäres Verzeichnis neben dem Ziel, das erst am Ende umbenannt wird; ein Abbruch hinterlässt keine halbe Installation.

Eine bereits installierte Version wird nicht erneut installiert (I5, I8).

### `aibos --install distribution-<name>`

Erkennt AIBOS am Argument ein Paket `distribution-<name>` statt einer Version, installiert es eine Distribution (Spec 06, *Distributionen*; V0.5, Memos 26, 27):

1. Distribution aus der Hub-Liste bzw. mit `--from <repo>` aus einem lokalen Repo (getaggte Version) lesen, auflösen (Kernel aus `kernel:`, Pakete mit Abhängigkeiten).
2. Ziel: `<vault>` oder der Vault von `cwd`.
3. Ein Plan mit zwei Teilen: **Rechner** (Kernel installieren, falls fehlend, wie `aibos --install v<version>`; Arbeitspferde einrichten, Spec 07) und **Vault** (an den Kernel binden, mit Umstellung, falls nötig; Pakete holen, `packages:` und `lock.yaml` der Vault-Root schreiben; registrieren, immer im Ziel-Vault, unabhängig vom Arbeitsverzeichnis; V0.6, Memo 03, K2). Der Plan nennt offene Dateien des Ziels, die er ändert (Spec 06, *Holen*). Ein Ja.
4. Zuerst der Rechnerteil; scheitert er, bleibt der Vault unberührt. Dann der Vaultteil mit Sicherung (Spec 06, *Holen*).

Ist die Distribution schon installiert, aktualisiert derselbe Befehl auf die höchste Version im Bereich.

**Frischer Rechner ohne PyYAML** (V0.5, Memos 71, 73: B7): Läuft `aibos` aus einem Klon und fehlt im `python3` des Systems PyYAML (das ist die Regel, z. B. bei Homebrew oder einer Linux-Distribution), kann AIBOS die Manifeste nicht lesen, bevor ein Kernel installiert ist. Derselbe Befehl zeigt dann **zwei Pläne** nacheinander:

1. **Plan des Kernels**, nur mit der Standardbibliothek: Version aus der Zeile `kernel: "==X.Y.Z"` der gewählten Version der Distribution (Auflösung über die Tags der Hubs bzw. `--from`), ohne `kernel:` die Bindung der Vault-Root, sonst der höchste Release-Tag des Klons. Der Plan entspricht `aibos --install v<version>` und nennt als letzte Zeile `then: aibos --install … with AIBOS v<version> (plan of the distribution)`. Ein Ja.
2. Danach übergibt AIBOS mit `exec` an `bin/aibos` der neuen Installation, mit denselben Argumenten (auch `--plan` bzw. `--yes`); diese zeigt den Plan der Distribution wie oben. Ein zweites Ja.

Ist der Kernel schon installiert, entfällt der erste Plan. Mit `--plan` zeigt der Befehl nur den Plan des Kernels; mit `--yes` laufen beide ohne Rückfrage. Läuft `aibos` nicht aus einem Klon und fehlt PyYAML, bricht es mit Hinweis auf `aibos --install` ab.

Ziel der Arbeitspferde ist der Ort nach *Installationen* (Spec 07); der Plan nennt ihn.

### `aibos --activate v<version> [<vault-root>]`

| Schritt | Regel |
|---|---|
| Pfad | angegeben oder `cwd` |
| Prüfung | Pfad ist eine Vault-Root (Name beginnt mit `§`), sonst Abbruch mit Hinweis auf die Vault-Root, die gebunden werden kann (V0.6, Memo 16, F5); `v<version>` ist installiert, sonst Abbruch mit Hinweis auf `aibos --install` |
| Vault-Root | Die Aktivierung macht sie zum Root-Projekt: Was von der Struktur eines Projekts fehlt (`@/`, `.git` mit Branch `main`, `.gitignore`), gehört in den Plan und wird nach Ja angelegt, mit erstem Commit wie bei `aibos --init` (Spec 05; V0.3, Memo 23). Die Namensregel gilt für die Vault-Root nicht |
| Wirkung | `aibos: <version>` in `<vault-root>/.aibos/config.yaml` schreiben bzw. ersetzen; eine Markierung `legacy:` in derselben Datei wird dabei entfernt. Eine Altbindung `aios:` in `.aios/config.yaml` stellt das Umbinden auf v0.7 um (*Umstieg auf v0.7*). `.aibos/config.yaml` ist Teil des ersten Commits, sonst committet `aibos --activate` nicht |
| Registrierung | ab v0.6: die Hüllen der Kernel-Skills und des Alias an der Vault-Root und in allen Projekten des Vaults (Spec 03; V0.6, Memo 30, F18). Ein Unterordner, dessen Name mit `§` beginnt, ist eine eigene Vault-Root (`config.vault_root`): Er und alles darunter gehören nicht zum Vault und werden übersprungen, ob er gebunden ist oder nicht (V0.6, Memos 111, 120, H7). Der Plan nennt die Zahl der Projekte (`in N projects of …`), auch wenn der Vault schon ein A/W ist (V0.6, Memo 138, B20) |
| Vorlage | ab v0.6.4: Fehlen einem Projekt des Vaults (mit eigenem Repo, nicht die Vault-Root) Zeilen der `.gitignore`-Vorlage, ergänzt der Plan sie, mit einem Commit nur der `.gitignore` je Projekt („AIBOS: .gitignore nach der Vorlage ergänzt"); der Plan nennt die Zahl der Projekte und die Zeilen. So bringt der Umstieg auf eine Version mit neuen Zeilen der Vorlage alle Projekte auf einmal nach (V0.6, Memos 188, 189: H28) |
| Hüllen früherer Versionen | Hüllen `aios-*` aus v0.6 in den Projekten des Vaults ersetzt das Umbinden durch `aibos-*` (*Umstieg auf v0.7*); fremde Ordner bleiben (Spec 01, I6) |
| Offene Dateien | Der Plan nennt offene Dateien des Vaults, die er ändert oder committet, zusammengefasst je Paketordner wie Spec 06, *Holen*, Schritt 4; er committet sie nicht selbst (V0.6, Memos 02, 81) |
| Version | mit oder ohne `v` angegeben, geschrieben ohne `v`; steht dieselbe Version schon in der Datei, fehlt nichts von der Struktur, ist die Registrierung aktuell und fehlt keine Zeile der Vorlage: „nichts zu tun", keine Rückfrage |
| Umstellung | Pakete, die mit der neuen Version nicht laufen, im selben Plan mit allen Unterschritten (Spec 06, *Paketwechsel bei der Aktivierung*) |
| Distribution | Hält der Vault eine Distribution mit `kernel:`, das die neue Version nicht erfüllt, nennt der Plan sie als Hinweis: `note: distribution-<name> <version> wants kernel <bereich>; update it with aibos --install distribution-<name>`. Umgebunden wird trotzdem; die Distribution wird nicht geändert. Der Hinweis erscheint nur, wenn sich die Bindung ändert, und nicht im Plan von `aibos --install distribution-<name>`, der den Kernel selbst bringt (Spec 06, *Distributionen*; V0.6, Memos 108, 120, 130: H5, F105) |
| Hinweis | Master-Kontext und Registrierung gelten ab dem nächsten Chat |

### `aibos --deactivate [<vault-root>]`

Entfernt den Schlüssel `aibos` aus `<vault-root>/.aibos/config.yaml`. Danach ist der Vault ohne Bindung und damit wirkungslos; das wird gemeldet, mit dem Hinweis auf `legacy: ai-brain` für den Legacy-Modus. `skills`, `assistant` und andere Schlüssel bleiben stehen, ebenso Kommentare; eine leere Datei wird entfernt, ein danach leeres `.aibos/` ebenfalls. `@/`, `.git` und `.gitignore` bleiben. Steht kein `aibos` in der Datei: „nichts zu tun".

### `aibos --vaults`

Listet die Vaults, die AIBOS findet, nur lesend (V0.6, Memos 115, 120, H8). Gesucht wird flach, ohne versteckte Ordner wie `.git`; `beside`, `inside` und `above` gehen nur von vorhandenen Vaults der ersten drei Quellen aus, nicht von Vaults, die selbst erst so gefunden wurden:

| Quelle | Vaults |
|---|---|
| `session` | Vault-Roots der `cwd` aus den Merkern der Sessions (`~/.aibos/sessions/`) |
| `repo` | Vault-Root von `~/.aibos/repo`, falls der Klon in einem Vault liegt |
| `workers` | Vault-Roots der Projekte in `workers.yaml` an beiden Orten (`~/.aibos/`, `/opt/aibos/`); aus `/opt/aibos/` nur Projekte des aktuellen Benutzers, wie in *`aibos --install`*, Schritt 7 (B26) |
| `beside` | `§`-Ordner im selben Elternordner wie ein Vault aus den drei Quellen oben |
| `inside` | `§`-Ordner in einem Vault aus den Quellen oben, bis zu drei Ebenen tief, ohne versteckte Ordner und nicht unter einem gefundenen `§`-Ordner (V0.6, Memo 128, F104) |
| `above` | `§`-Ordner über einem Vault aus den Quellen oben, wie `§Obsidian` über `§Hugo` (V0.6, Memo 124, F97) |

Je Vault eine Zeile mit Pfad, Art und Bindung nach Spec 02, *Arten von Vaults* (`aibos 0.7.0`, `alt 0.6.6` für eine Altbindung, `legacy`, `none`), und den Quellen, die ihn gefunden haben; ein Pfad aus einer Quelle, den es nicht mehr gibt, steht als `missing`, außer er stammt nur aus `/opt/aibos/workers.yaml` (dann fehlt er, B26). Die Zeilen sind nach Pfad sortiert, die Quellen in der Reihenfolge der Tabelle; ohne Fund meldet der Befehl `no vault found`. Die Suche nutzen auch `aibos --remove-version` (unten) und der Bestandslauf einer Abnahme. `aibos --install` bleibt bei den bekannten Vaults (*Installieren*, Schritt 7).

### `aibos --remove-version v<version>`

Entfernt `~/.aibos/versions/v<version>/` (bzw. `/opt/aibos/v<version>/`) und den Eintrag in `installations.yaml` nach Warnung und Bestätigung. Der Plan nennt die Vaults aus der Suche von *`aibos --vaults`*, die an diese Version gebunden sind, je mit Pfad; sie laufen nach dem Entfernen nicht mehr, bis die Version wieder installiert oder der Vault umgebunden ist (V0.6, Memos 110, 120, H6). Findet die Suche keinen, sagt der Plan das ausdrücklich (`no vault found that is bound to <version>`). Zeigt der Eintrag auf ein anderes Verzeichnis, etwa einen Klon als Entwicklungsstand, wird nur der Eintrag entfernt. Ist die Version die einzige installierte, wird zusätzlich auf `aibos --uninstall` hingewiesen.

### `aibos --uninstall`

Entfernt die Benutzereinrichtung: den Weiterleiter `~/.aibos/bin/aibos`, Hüllen früherer Versionen in `~/.claude/skills/aibos-*/` und `~/.claude/skills/gui/`, die drei AIBOS-Hooks und `~/.aibos/sessions/`; stellt die Hooks aus `~/.aibos/hooks-backup.json` wieder her und nennt ein `~/bin/aios` früherer Versionen, ohne es zu entfernen. Installationen in `~/.aibos/versions/` und `/opt/aibos`, `~/.aibos/config.yaml` sowie alle `.aibos/` und `.claude/skills/` in Vaults und Projekten bleiben erhalten; die Hüllen dort finden ohne Weiterleiter nichts mehr und können mit `/aibos-register` nach einer neuen Installation erneuert werden.

## Repo `aibex-aibos` und Abbildung auf die Installation

```
aibex-aibos/                          GitHub aibex-aibos/aibex-aibos, Tags v<version>
├── README.md
├── CLAUDE.md                        Regeln für die Arbeit am Repo
├── manifest.yaml                    Paket-Manifest des Kernels (type: kernel, Spec 06)
├── VERSION                          Entwicklungsstand, z. B. 0.5.0-dev
├── bin/                             aibos (Einstieg: ./bin/aibos --install)
├── lib/aibos/                        Python-Paket
├── skills/aibos/<name>/SKILL.md      Kernel-Skills (aibos-gui mit gui.yaml)
├── templates/                       forwarder (Weiterleiter), gitignore (Vorlage für aibos --init)
├── python/requirements.txt          pyyaml
├── spec/                            diese Spec (gepflegt aus dem Konzeptprojekt)
├── doc/README.md                    Inhaltsverzeichnis von doc/ mit den Dateinamen (V0.6, B22)
├── doc/tutorials/                   Tutorials; künftig auch doc/wiki/
├── dev/                             Entwickler-Doku, nicht installiert
├── tests/                           Tests im Sandkasten (tests/run), nicht installiert;
│                                    tests/live/: Tests mit echten Claude-Sessions (kosten Tokens)
├── etc/image/                       Bilder des README, nicht installiert
└── .pimp/                           optionale Entwicklungsumgebung (venv @aibos)
```

Das Repo enthält keinen Vault. Vaults legt der User an und bindet sie mit `aibos --activate` an eine Version; die Tests legen ihre Vaults im Sandkasten an.

**Skills:** Das Repo enthält nur noch die Kernel-Skills (`skills/aibos/`). Die Registrierung schreibt ihre Hüllen im A/W an die Vault-Root und in die Projekte (Spec 03). Der Rumpf von `skills/aibos/aibos-memo/` ist der Rumpf von `memo` in der Version 6.0.0 und wird nicht angeglichen (Spec 03). Die bisherige Bibliothek (`skills/basic/`, `assistants/demo/`) ist in eigene Paket-Repos übergegangen (`aibex-aibos/skill-memo`, `aibex-aibos/assistant-gaertner`, `aibex-aibos/assistant-astronom`, Spec 06); ihre Historie bleibt im Repo `aibex-aibos` bis zum Tag `v0.3.1`.

| Repo | Installation |
|---|---|
| `bin/`, `lib/`, `templates/` | `v<version>/bin/`, `v<version>/lib/`, `v<version>/templates/` |
| `manifest.yaml`, `VERSION` | `v<version>/manifest.yaml`, `v<version>/VERSION` (beim Installieren mit der Version des Tags überschrieben) |
| `skills/aibos/<name>/` | `v<version>/skills/aibos/<name>/` |
| `python/requirements.txt` | `v<version>/python/` (venv) |
| `spec/` | `v<version>/doc/spec/` |
| `doc/README.md` | `v<version>/doc/README.md`: nennt jede Datei in `doc/spec/` und `doc/tutorials/`, weil eine Session `doc/` lesen, aber nicht auflisten darf (Spec 02, *Freigabe*; V0.6, Memos 139, 140: B22) |
| `doc/tutorials/`, `doc/wiki/` (künftig) | `v<version>/doc/tutorials/`, `v<version>/doc/wiki/` |

Ein Release (Tag `v<version>`) ist nur vollständig, wenn `spec/` den Soll-Stand dieser Version beschreibt und `version` in `manifest.yaml` dem Tag entspricht.

Ein Entwicklungsstand wird ohne Installation genutzt, indem `~/.aibos/installations.yaml` auf die Wurzel des Klons zeigt (z. B. `v0.6.0-dev: ~/git/AIbex/aibex-aibos`) oder `AIBOS_HOME` auf diesen Ort gesetzt wird. Der Weiterleiter findet dort wie in einer Installation `bin/aibos`.

## Legacy und Umstieg

| Situation | Verhalten |
|---|---|
| Vault ohne Bindung und ohne `legacy:` an der Vault-Root | wirkungslos (Spec 02, *Arten von Vaults*) |
| Vault mit `legacy: ai-brain` | Legacy-Modus über `ai-brain` (Spec 02) |
| Vault mit `aios: 0.6.<n>` in `.aios/config.yaml` (Altbindung) | läuft mit v0.6 weiter, solange die Version installiert ist, über den Verweis `~/.aios`; Umstellung mit `aibos --activate v0.7.<n> <vault>` (*Umstieg auf v0.7*) |
| Vault mit `aios:` unter 0.6.0 | wird von v0.7 nicht mehr unterstützt; er läuft nur auf einem Rechner ohne v0.7 weiter (V0.7, Memo 16: FL9) |
| Bindung in einem Projekt statt an der Vault-Root | wird übergangen, mit Warnung (Spec 01, I14) |
| Rückkehr | `aibos --deactivate <vault>`; vollständig mit `aibos --uninstall` |

Ein Rechner mit dem Prototyp von `aios` (Kopie nach `~/bin`, Konfiguration in `~/etc/aios/`) bleibt unberührt; der Plan nennt den Prototyp als Altbestand. Die Umstiege auf v0.3–v0.6 stehen in dieser Spec im Tag `v0.6.6`.

### Umstieg auf v0.7

Der Umstieg eines Rechners mit v0.6 läuft in zwei Schritten, jeder mit Plan und eigener Rückfrage (V0.7, Memos 04, 05, 07, 09, 13–15: F267–F272, F276, F281, FL6–FL8):

| # | Schritt | Wirkung |
|---|---|---|
| 1 | `<klon>/bin/aibos --install v0.7.<n>` aus dem Klon oder über `aibos-installer` | `~/.aios` wird nach `~/.aibos` verschoben, `~/.aios` als Verweis auf `~/.aibos` angelegt; die installierten Versionen bleiben unverändert (Spec 01, I5) und laufen über den Verweis weiter. Weiterleiter `~/.aibos/bin/aibos` mit Alias `~/.aibos/bin/aios`; die drei Hooks rufen danach `~/.aibos/bin/aibos`, auch wo sie vorher `~/.aios/bin/aios` riefen. Mit `--system` zieht ein vorhandenes `/opt/aios` nach `/opt/aibos`, mit Verweis. Der Plan nennt jeden Vault mit Altbindung mit dem Befehl für Schritt 2 |
| 2 | `aibos --activate v0.7.<n> <vault>` je Vault, mit `--plan` vorher | im ganzen Vault (Vault-Root und alle Projekte, bis zu einem eingebetteten `§`-Ordner): `.aios/` → `.aibos/` mit `git mv`; `aios:` → `aibos: <version>`; Hüllen `aios-*` → `aibos-*` (`.aibos/registry` nachgeführt); `aibex-aios` → `aibex-aibos` in `workspace.yaml`, in `hubs:`, in `lock.yaml` und im `origin` jedes Projekts (Spec 06, *Hubs*); Pakete ohne Version für 0.7 im Paketwechsel (Spec 06); ein Commit je Projekt („AIBOS: auf AIBOS v0.7 umgestellt") |

**Zweiter Rechner (FL7):** Ist ein Workspace am Remote schon umgestellt (`.aibos/` im Stand von `origin`), holt Schritt 2 zuerst diesen Stand, nur vorwärts und ohne lokale Änderungen, und benennt danach nur um, was noch fehlt. Lokale Änderungen sind ein Hindernis im Plan; sie werden vorher mit `sync` des Kernels 0.6 gesichert.

**Kernel 0.6.x an einem umgestellten Vault (FL8):** findet keine `.aios/config.yaml` mehr und behandelt den Vault als ungebunden (Spec 01, I4): Hooks geben nichts aus, `sync` und andere Befehle brechen ab, ohne zu schreiben. Deshalb steigen Rechner, die einen Workspace teilen, zeitnah um.

**Bis 0.8** bleiben der Verweis `~/.aios`, der Alias `aios`, das Lesen von `AIOS_*`, `.aios/`, `aios:` und `requires.aios` und die Gleichheit von `aibex-aios` und `aibex-aibos` (Spec 01, *Vorabversionen*). Mit 0.8 fallen sie weg; vorher sind die Installationen 0.6.x zu entfernen, weil sie `~/.aios` fest eingebaut haben (V0.7, Memo 11: P19).

---
title: "Pakete und Workspaces"
date: 2026-11-24
author: iHux
status: Entwurf
tags: [spec, aibos, v0.7, pakete, workspaces]
number: 06
related:
  - "Spec 01 AIbex AIBOS v0.7 — Überblick"
  - "Spec 02 Master-Kontext"
  - "Spec 03 Skills und Assistenten"
  - "Spec 04 Installation und Konfiguration"
  - "Spec 05 Projekte"
  - "Spec 07 Arbeitspferde"
  - "Memos 01–29 (AA-AIbex-AIOS, @Memo/V0.4)"
  - "Memos 05, 07, 08, 11–37 (AA-AIbex-AIOS, @Memo/V0.5)"
  - "Memos 79–84 (AA-AIbex-AIOS, @Memo/V0.6): v0.6.1"
  - "Memos 01–15 (AA-AIbex-AIOS, @Memo/V0.7): Umbenennung in AIBOS"
  - "Memos 68–76 (AA-AIbex-AIBOS, @Memo/V0.7): v0.7.1, Tickets, W4, W5"
---

# Pakete und Workspaces

Diese Spec regelt Pakete und Module: das Paket-Manifest `manifest.yaml`, Versionen und Bereiche, Hubs und die Hub-Liste, den Resolver, das Holen eines Pakets mit `aibos --fetch`, das Ausrollen seiner Elemente mit `aibos --deploy`, den aufgelösten Stand in `.aibos/lock.yaml`, Distributionen, Workspaces mit `.aibos/workspace.yaml` und `aibos --workspace`, den Rückfluss mit `aibos --contribute`, die Daten der Pakete in `@Data/` und die Demo-App Taschenrechner. Arbeitspferde (`type: worker`) stehen in Spec 07. Die Begriffe stehen in Spec 01, die Auflösung entlang der Kette in Spec 02 und 03, die Skills `/aibos-package`, `/aibos-fetch` und `/aibos-deploy` in Spec 03, Dateistrukturen und CLI in Spec 04, Struktur und Integrität von Projekten in Spec 05. Die Gegenüberstellung mit Zephyr steht in V0.4, Memo 14.

## Pakete

Ein **Paket** ist eine versionierte Einheit aus einem oder mehreren Elementen, die eine Datei `manifest.yaml` beschreibt. **Elemente** sind die Teile, die in einem Projekt wirken: Skills, Assistenten, Wissen und Befehle. Ein **Modul** ist ein Paket, nach dessen Holen AIBOS etwas Neues kann. Eine **App** ist ein Modul, das der Anwender direkt benutzt. Eine **Distribution** ist ein Paket, das optional einen Kernel und andere Pakete in exakten Versionen zusammenstellt (*Distributionen*; V0.4, Memos 04, 07; V0.5, Memos 25–27). Ein **Arbeitspferd** ist ein Paket vom Typ `worker` (Spec 07).

Jedes Paket liegt in einem eigenen Git-Repo in einem Hub. Eine Version ist ein Tag `v<version>` in diesem Repo, und `version` in `manifest.yaml` des getaggten Stands muss übereinstimmen. Der Kernel von AIBOS ist ebenfalls ein Paket (`type: kernel`, Name `aibos`, Repo `aibex-aibos/aibex-aibos`), wird aber mit `aibos --install` installiert, nicht geholt (Spec 04).

**Paketnamen:** `<typ>-<name>`, die Art gleich dem Typ: `app-`, `assistant-`, `skill-`, `knowledge-`, `tutorial-`, `distribution-`, `worker-`, ab v0.7.1 `mod-`; der Kernel heißt `aibos` (V0.5, Memos 05, 15). AIBOS wertet nur `type` aus; das Schema ist eine Konvention, die die Pakete von AIbex einhalten.

Für Pakete gelten drei Verben (V0.4, Memos 23, 24):

| Verb | Gegenstand | Bedeutung | CLI |
|---|---|---|---|
| **holen** (fetch) | Paket | eine Version eines Pakets ganz vom Hub ins Projekt holen | `aibos --fetch` |
| **ausrollen** (deploy) | Element | festlegen, welche Elemente eines geholten Pakets im Projekt wirken; ohne Kopie | `aibos --deploy` |
| **registrieren** (register) | Skill | ausgerollte Skills dem Host bekannt machen (Spec 03) | `aibos --register` |

**Installieren** heißt, etwas auf den Rechner zu bringen: den Kernel und Arbeitspferde (je Version, nebeneinander) und Distributionen (Kernel, Arbeitspferde und, in einen Vault, ihre Pakete; Spec 04, 07). Für andere Pakete ist es nur ein Wort der Anwender, das `/aibos-package` versteht.

### Aufbau eines Paket-Repos

```
<paket>/
├── manifest.yaml                   Pflicht
├── skills/<name>/SKILL.md          Skills (Format Spec 03)
├── assistants/<name>/ASSISTANT.md  Assistenten (Aufbau Spec 03)
├── knowledge/                      Wissen, mit Klassen wie ein Masterspace (Spec 02)
├── commands/<name>                 Befehle (ausführbar)
├── worker/                         Datei mit Hashes bzw. Skripte eines Arbeitspferds (nur type: worker, Spec 07)
├── mod/                            Mod von Claude Code mit .claude-plugin/ (nur type: mod, *Mods*)
├── contrib/<user>/…                Rückflüsse (aibos --contribute)
├── STATUS.md                       optional: Schritte des Implementierungsplans mit ☐/☑
└── README.md                       optional
```

Nur `manifest.yaml` ist Pflicht. Welche Ordner ein Paket hat, nennt `contents`. `STATUS.md` hält bei einem Paket mit Implementierungsplan dessen Schritte fest; jeder Schritt wird im Commit abgehakt, der ihn umsetzt. Es wird wie `README.md` beim Holen mitgespiegelt (V0.6, Memo 123).

### `manifest.yaml`

```yaml
name: app-taschenrechner
version: 0.1.0
type: app
description: Programmierbarer Taschenrechner mit lernenden Funktionstasten (Demo-App von AIBOS)
requires:
  aibos: ">=0.7,<0.8"
depends:
  skill-memo: "~=6.1"
contents:
  skills: [taschenrechner, taschenrechner-gui]
  knowledge: true
  gui: taschenrechner-gui
license: MIT
```

| Feld | Pflicht | Regel |
|---|---|---|
| `name` | ja | Kleinbuchstaben, Ziffern, Bindestriche, höchstens 64 Zeichen; gleich dem Namen des Repos in seinem Hub; nicht `aibos` (Kernel), `aibos-…`, `gui`, `none`, `inherit` |
| `version` | ja | SemVer `MAJOR.MINOR.PATCH`, optional mit Vorabkennung (`0.4.0-rc1`) |
| `type` | ja | `kernel`, `app`, `assistant`, `skill`, `knowledge`, `tutorial`, `distribution`, `worker`, ab v0.7.1 `mod`; unbekannte Werte werden mit Warnung als `knowledge` behandelt |
| `description` | ja | ein Satz |
| `requires` | ja | `aibos: "<bereich>"`, Bereich der AIBOS-Version, in der das Paket läuft |
| `depends` | nein | Name → Bereich anderer Pakete; `aibos` ist hier nicht erlaubt, dafür gibt es `requires` |
| `contents` | nein | `skills`, `assistants`, `commands`, `hooks` (Listen von Namen), `knowledge` (`true`), `gui` (Name eines Skills aus `skills`) |
| `worker` | bei `type: worker` | Art, Programme, Prüfung und Bauanleitung des Arbeitspferds (Spec 07); bei anderen Typen nicht erlaubt |
| `kernel` | nein | nur bei `type: distribution`: `"==<version>"` des Kernels (*Distributionen*) |
| `license` | nein | SPDX-Kennung oder Freitext |
| `userdata` | nein | beliebige Daten; AIBOS wertet sie nicht aus |

`manifest.yaml` wird mit PyYAML gelesen. Ein Paket ist ein **Modul**, wenn `type` `kernel`, `app`, `assistant`, `skill`, `worker` oder `mod` ist oder `contents` mindestens einen Skill, Assistenten, Befehl oder Hook nennt. Pakete vom Typ `knowledge`, `tutorial` und `distribution` ohne solche Inhalte sind keine Module (V0.4, Memo 04). Ein `worker` ist ein Modul ohne Elemente: Ausrollen, `only` und Registrieren wirken nicht (V0.5, Memo 30).

**Elemente** eines Pakets und ihre Namen beim Ausrollen: jeder Skill und jeder Assistent unter seinem Namen, jeder Befehl unter seinem Namen und das Wissen als `knowledge`. Die Namen sind innerhalb eines Pakets eindeutig.

**Prüfung beim Holen:** Jeder in `contents` genannte Name muss als Ordner bzw. Datei vorhanden sein, jeder Skill braucht eine gültige `version` (Spec 03), `gui` muss in `skills` stehen, Elementnamen dürfen sich nicht wiederholen. Bei `type: worker` gelten die Regeln von Spec 07 (`kind`, `programs`, Datei mit Hashes bzw. Skripte), bei `type: distribution` exakte Versionen (`==`) in `kernel` und `depends`. Ein Paket mit dem Feld `workers:` aus v0.4 wird abgelehnt, mit Hinweis auf `type: worker` (V0.5, Memo 30, L9). Ein Paket, das die Prüfung nicht besteht, wird nicht geholt.

**Hooks** (`contents.hooks`) sind im Format vorgesehen, in v0.7 aber ohne Wirkung: `aibos --fetch` meldet sie und holt das Paket ohne sie. Hooks einer Mod liegen in ihrem Ordner `mod/` und gehören nicht zu `contents.hooks` (*Mods*).

### Mods

Eine **Mod** ist eine Erweiterung von Claude Code (Plugin mit Hooks, Modul, Oberflächenteilen), verpackt als AIBOS-Paket `type: mod`, Name `mod-<name>` (ab v0.7.1; V0.7, Memos 77, 78: F399–F403; `B-Basics/BM-Mods-In-Claude`, Memos 03, 05, 06). Sie ist ein Modul.

| Punkt | Regel |
|---|---|
| Aufbau | Ordner `mod/` in der Form von Claude Code: `mod/.claude-plugin/plugin.json` mit `name` gleich `<name>` (Paketname ohne `mod-`), `mod/.claude-plugin/marketplace.json`, der die Mod als einziges Plugin nennt, dazu ihre Dateien (`hooks/`, Modul, `types/`) |
| Manifest | `type: mod`, kein `contents` und kein `worker` (wie bei `type: worker` bestimmt der Typ den Inhalt) |
| Prüfung beim Holen | beide Dateien unter `mod/.claude-plugin/` vorhanden und lesbar, `name` passt; sonst wird das Paket nicht geholt |
| Element | genau eines, `mod`; `aibos --deploy` zeigt es, `only` ändert an der Wirkung nichts |
| Ort | jedes Projekt, auch über eine Distribution (`depends` mit `==`); der Plan von `aibos --fetch` sagt: `note: mod-<name> acts for all sessions of this computer once installed with aibos --mod install mod-<name>` |
| Wirkung | Holen meldet die Mod **nicht** bei Claude Code an; das tut nur `aibos --mod install` auf Wunsch des Users |
| andere Hosts | Codex kennt keine Mods; dort ist das Paket nur geholt |

**`aibos --mod install <mod> [--to <projekt>] [--plan|--yes]`** meldet eine Mod für den Rechner bei Claude Code an. Fehlt das Paket im Projekt (bzw. in `--to`), holt der Plan es zuerst wie `aibos --fetch`. Danach ruft es mit dem Ordner `<projekt>/@/@!Package/mod-<name>/mod` und dem Namen `<marketplace>` aus dessen `marketplace.json`:

```
claude plugin marketplace add "<ordner>" --scope user
claude plugin install <name>@<marketplace> --scope user
```

**`aibos --mod uninstall <mod> [--plan|--yes]`** meldet sie wieder ab: `claude plugin uninstall <name>@<marketplace> --scope user`, dann `claude plugin marketplace remove <marketplace>`. Das Paket bleibt geholt; entfernen bleibt `aibos --fetch --remove`. **`aibos --mod`** ohne weitere Argumente listet die geholten Mods des Projekts mit dem Zustand `installed` (von diesem Ordner aus angemeldet), `installed elsewhere` (unter gleichem Namen aus einem anderen Ordner) oder `not installed`, nach `claude plugin list --json`.

Beide schreibenden Formen zeigen den Plan mit den `claude`-Befehlen und fragen (I7); der Skill `/aibos-package` versteht „installiere den Mod …“ und „deinstalliere den Mod …“ (Spec 03). Fehlt `claude` im `PATH`, bricht der Befehl mit `*** aibos --mod: claude not found` ab. Neue Versionen der Mod, die `aibos --fetch --upgrade` in denselben Ordner holt, wirken nach `/reload-plugins` ohne neue Anmeldung. Entfernt `aibos --fetch --remove` ein Paket, dessen Mod von seinem Ordner aus angemeldet ist, bricht `--remove` ab mit `*** aibos --fetch: mod-<name> is installed in Claude Code from this folder; run aibos --mod uninstall mod-<name> first` und ändert nichts. Dasselbe gilt für ein Paket, das ein Upgrade aus `lock.yaml` entfernen würde.

## Versionen und Bereiche

Versionen folgen SemVer. Bereiche folgen den Versionsangaben von pip:

| Angabe | Bedeutung | Beispiel |
|---|---|---|
| `==X.Y.Z` | genau diese Version | `==6.0.0` |
| `!=X.Y.Z` | nicht diese Version | `!=0.2.1` |
| `>=`, `<=`, `>`, `<` | Vergleich | `>=0.4` |
| `~=X.Y` | kompatibel: `>=X.Y,<(X+1).0` | `~=6.0` → `>=6.0,<7.0` |
| `~=X.Y.Z` | kompatibel: `>=X.Y.Z,<X.(Y+1).0` | `~=0.1.2` → `>=0.1.2,<0.2.0` |
| `A,B` | beide Bedingungen | `>=0.4,<0.5` |
| `*` oder leer | jede Version | |

Fehlende Teile einer Version zählen als `0` (`0.4` = `0.4.0`). Vorabversionen eines Pakets erfüllen einen Bereich nur, wenn der Bereich selbst eine Vorabversion nennt (`>=0.4.0-rc1`).

**Version des Kernels:** Für `requires.aibos` zählt die AIBOS-Version **ohne Vorabkennung**: `0.4.0-dev` und `0.4.0-rc1` gelten als `0.4.0` (V0.4, Memo 18, L1). So lassen sich Pakete auch mit Entwicklungsständen und Release-Kandidaten holen.

**Alter Schlüssel bis 0.8:** Fehlt `requires.aibos`, liest AIBOS `requires.aios`; der Bereich gilt unverändert (V0.7, Memo 10: F283). Pakete mit der Obergrenze `<0.7` lassen sich deshalb mit v0.7 nicht holen: `aibos --fetch` lehnt sie ab, ohne zu schreiben; die Konfliktliste des Resolvers nennt als Grund `<paket> <version> needs a version for AIBOS <version> (requires.aios <bereich>)` (V0.7, Memo 23: FL25).

**Standardbereich:** Wird ein Paket ohne Bereich geholt, gilt ab Version 1.0 `~=X.Y` der höchsten Version, die zur Bindung passt (`requires.aibos`; V0.6, Memo 50, B1; `memo` 6.0.0 → `~=6.0`), darunter `~=0.Y.Z` (`app-taschenrechner` 0.1.0 → `~=0.1.0`, also `>=0.1.0,<0.2.0`). Vor 1.0 bleibt ein Paket damit in seiner Minor-Version, weil dort jede Minor-Version brechen darf (V0.4, Memo 19, L5).

## Hubs

Ein **Hub** ist ein Ort mit Paket-Repos: ein Name und eine Basis-URL. Ein Paket `<paket>` liegt dort als Repo `<basis>/<paket>`. Bei GitHub ist der Name des Hubs gleich dem **Owner** (Organisation oder User), die Basis-URL ist `https://github.com/<name>`. Der **volle Paketname** ist `<hub>/<paket>`, z. B. `aibex-aibos/knowledge-orion` (V0.4, Memos 21, 22).

Der Standard-Hub ist `aibex-aibos` (`https://github.com/aibex-aibos`). Für Tests gibt es einen zweiten Hub `aibex-hub` (V0.4, Memos 27, 28).

**Alter Name bis 0.8:** Bis v0.6.6 hieß die Organisation `aibex-aios`. Bis 0.8 gilt `aibex-aios` als derselbe Hub wie `aibex-aibos`: Ein Eintrag in `hubs:`, in `lock.yaml` (`hub`, `repo`), ein `--hub` oder ein voller Paketname mit `aibex-aios` wird als `aibex-aibos` gelesen; das Umbinden auf v0.7 schreibt ihn um (Spec 04, *Umstieg auf v0.7*; V0.7, Memos 03, 09: F264, F281).

### Hub-Liste

Die **Hub-Liste** nennt die Hubs, in denen AIBOS einen Paketnamen ohne Hub sucht, in Suchreihenfolge. Sie steht unter `hubs:` in `~/.aibos/config.yaml` (Home) und in `.aibos/config.yaml` der Vault-Root (V0.4, Memos 21, 26):

```yaml
hubs:
  - aibex-aibos
  - aibex-hub
  - firma-gitlab: https://gitlab.example.com/aibos
```

| Regel | |
|---|---|
| Eintrag | ein Name (GitHub-Hub, Basis-URL `https://github.com/<name>`) oder `name: url` (jeder Git-Server, auch `file://`) |
| Reihenfolge | erst die Liste der Vault-Root, dann die aus Home |
| gleicher Name in beiden | der Eintrag der Vault-Root gilt; `aibos --hubs` zeigt die Überdeckung |
| ohne Eintrag | `[aibex-aibos]`. Sobald es einen Eintrag `hubs:` gibt, zählt `aibex-aibos` nur, wenn er darin steht |
| Tests | `AIBOS_HUBS` ersetzt beide Listen: Einträge `name=url`, durch Leerzeichen getrennt (Spec 04) |

Die Hub-Liste ist eine **Suchliste**, keine Sperrliste. Ein voller Paketname darf jeden Hub nennen (unten).

**Pflege:** `aibos --hubs` zeigt die Liste mit Herkunft (Vault, Home). `aibos --hubs add <name> [<url>] [--vault]` und `aibos --hubs remove <name> [--vault]` ändern sie in Home bzw. mit `--vault` an der Vault-Root, mit Plan und Bestätigung (Spec 01, I7); `--vault` geht auch in einem Vault, der noch nicht gebunden ist, damit eine Distribution aus einem eigenen Hub kommen kann (V0.5, Memo 64). Legt `add` die erste Hub-Liste an (es gibt noch keinen Eintrag `hubs:`), übernimmt AIBOS den Standard-Hub `aibex-aibos` an erster Stelle, damit er weiter gilt (V0.4, Memo 60). `/aibos-package` versteht Sätze wie „füge den Hub aibex-hub hinzu" (V0.4, Memo 25).

### Paket finden

| Angabe | Suche |
|---|---|
| `<paket>` | jeder Hub der Hub-Liste der Reihe nach: `git ls-remote --tags <basis>/<paket>` |
| `<hub>/<paket>` | nur dieser Hub. Steht `<hub>` in der Hub-Liste, gilt dessen Basis-URL, sonst `https://github.com/<hub>` (für Tests umgelenkt mit `AIBOS_GITHUB`, Spec 04) |
| `--from <repo>` | genau dieses Repo (lokaler Pfad oder URL), *Pflegeprojekte* |

Ein Treffer ist ein Repo mit mindestens einem Tag `v<SemVer>`, dessen `manifest.yaml` im gewählten Tag `name: <paket>` trägt. Tags anderer Form werden übergangen.

| Treffer | Verhalten |
|---|---|
| genau einer | auflösen und holen |
| keiner | Abbruch mit den durchsuchten Hubs |
| mehrere | Abbruch mit Exit-Code 3 und der Liste der Hubs; der Skill fragt nach und ruft `aibos --fetch <paket> --hub <hub>` bzw. mit `<hub>/<paket>` auf |

Ein Hub außerhalb der Hub-Liste wird ohne Hinweis verwendet; AIBOS nimmt ihn nicht in die Liste auf und bietet das auch nicht an (V0.4, Memo 25).

Nach dem Holen ist ein Paket an seinen Hub gebunden: `lock.yaml` hält `hub` und `repo` fest, der Abgleich und `--upgrade` suchen nicht erneut.

### Index und Suche

Ein Hub darf ein Repo `aibos-index` mit einer Datei `index.yaml` haben, muss aber nicht:

```yaml
schema: 1
packages:
  - name: skill-memo
    type: skill
    description: Memo-Stil der AIbex-Workspaces
  - name: app-taschenrechner
    type: app
    description: Programmierbarer Taschenrechner mit lernenden Funktionstasten
```

Der Index dient nur der Suche: `aibos --library [<suchwort>]` listet je Hub der Hub-Liste die Pakete aus `index.yaml`; ohne Index bei GitHub-Hubs die Repos mit dem Topic **`aibos-package`** (über `gh`). Bis 0.8 tragen die Pakete des Hubs `aibex-aibos` zusätzlich das alte Topic `aios-package`, der Kernel `aibos-core` und `aios-core` (V0.7, Memo 03: F266). Ein Hub ohne beides lässt sich nicht durchsuchen, nur mit bekanntem Namen holen. `aibos --library <paket>` zeigt die Versionen eines Pakets (aus den Tags), `aibos --library <hub>/<paket>` nur die aus diesem Hub, auch außerhalb der Hub-Liste. Den Index holt AIBOS mit `git clone --depth 1` bzw. `git pull` nach `~/.aibos/hub/<hub>/`.

**Zugriff aufs Netz:** Nur `aibos --fetch`, `aibos --install`, `aibos --library`, `aibos --workspace` und `aibos --contribute` greifen auf das Netz zu, und nur über `git` bzw. `gh` mit den Zugangsdaten des Users sowie über `pip` beim setup eines Arbeitspferds (Spec 07). Ohne Netz arbeitet `aibos --fetch` ohne Argument mit dem Cache, wenn alle Versionen aus `lock.yaml` dort liegen, die Bereiche in `packages:` erfüllen und mit der gebundenen Version laufen (`requires.aibos`). Passt eine gesperrte Version nicht zur Bindung, löst der Abgleich neu auf, auch wenn der Bereich gleich bleibt; das betrifft vor allem die Umstellung mit `aibos --activate` (V0.6, Memo 72, B15).

## Resolver

Der Resolver bestimmt aus den gewünschten Paketen eines Projekts (`packages:` in seiner eigenen `.aibos/config.yaml`) die zu holenden Versionen (V0.4, Memo 15, F5). Pakete der Projekte darüber zählen nicht (V0.4, Memo 17):

1. Für jedes gewünschte Paket den Hub bestimmen (*Paket finden*, bei gebundenen Paketen aus `lock.yaml`) und seine Versionen aus den Tags holen.
2. Je Paket die **höchste Version** wählen, die alle Bereiche erfüllt, die bis jetzt dafür gelten (aus `packages:` und aus `depends` bereits gewählter Pakete).
3. Ihr `manifest.yaml` lesen (aus dem Cache bzw. nach Download): `requires.aibos` gegen die für das Zielprojekt gültige AIBOS-Version prüfen (ohne Vorabkennung), `depends` als neue Bereiche aufnehmen. Eine Abhängigkeit wird **zuerst im Hub des verlangenden Pakets** gesucht, auch wenn dieser nicht in der Hub-Liste steht, dann in der Hub-Liste (V0.4, Memos 21, 26). Mehrere Treffer in der Hub-Liste führen zum Abbruch wie unter *Paket finden*.
4. Ändert ein neuer Bereich die Wahl eines bereits gewählten Pakets, wird dieses neu gewählt und Schritt 3 wiederholt, bis sich nichts mehr ändert.
5. Erfüllt keine Version alle Bereiche eines Pakets oder passt `requires.aibos` bei keiner passenden Version: Abbruch mit einer Liste der Konflikte (Paket, Bereiche, Herkunft je Bereich). Es gibt kein Backtracking über ältere Versionen anderer Pakete. Stammt ein Bereich mit `==` aus einer Distribution (Herkunft `distribution-<name>`), folgt nach der Liste je solcher Distribution eine Zeile (ab v0.7.1; V0.7, Memo 68: W4, Memo 73: F387; MAA, Memo 188: B67):

   ```
   note: distribution-<name> <version> pins <paket> to ==<v>; a newer <paket> needs a new version of distribution-<name>, or remove it with aibos --fetch --remove distribution-<name>
   ```

Zyklen in `depends` sind erlaubt, solange die Bereiche erfüllbar sind. Ein Paket, das in `lock.yaml` steht und dessen Version alle Bereiche weiter erfüllt, bleibt bei dieser Version (kein stilles Update). Ein Update gibt es nur mit `aibos --fetch --upgrade [<name>]`.

## Holen — `aibos --fetch`

`aibos --fetch` holt Pakete ganz in ein Projekt (Anwender-Site, V0.4, Memos 09, 23). Die Skills dazu sind `/aibos-fetch` und darüber `/aibos-package` (Spec 03).

| CLI | Wirkung |
|---|---|
| `aibos --fetch <paket>[<bereich>] [--hub <hub>] [--to <projekt>]` | Paket in `packages:` aufnehmen bzw. dort ändern, auflösen, holen, Arbeitspferde einrichten, ausrollen, registrieren (**Paket laden**) |
| `aibos --fetch <hub>/<paket>[<bereich>] [--to <projekt>]` | ebenso, aus genau diesem Hub |
| `aibos --fetch <paket>[<bereich>] --from <repo> [--to <projekt>]` | ebenso, aus einem Git-Repo außerhalb der Hubs (Pflegeprojekt) |
| `aibos --fetch [--to <projekt>]` | Projekt mit `lock.yaml` abgleichen (z. B. nach `git pull`, auf einem anderen Rechner) |
| `aibos --fetch --upgrade [<paket>] [--to <projekt>]` | höchste passende Versionen neu wählen |
| `aibos --fetch --remove <paket> [--to <projekt>]` | Paket entfernen |
| `aibos --library [<suchwort> \| <paket>]` | Pakete der Hubs suchen bzw. Versionen eines Pakets |
| `aibos --hubs [add <name> [<url>] \| remove <name>] [--vault]` | Hub-Liste zeigen bzw. ändern |

**Pflegeprojekte:** Mit `--from <repo>` (lokaler Pfad oder URL eines Git-Repos mit `manifest.yaml` und Tags `v<version>`) kommt ein Paket aus diesem Repo, z. B. aus einem Projekt, in dem der Skill gepflegt wird. `packages:` und `lock.yaml` halten das Repo fest (`from`), der Abgleich holt das Paket wieder von dort. Geholt wird auch hier nur eine getaggte Version. Fehlt das Repo beim Abgleich (z. B. ein lokaler Pfad auf einem anderen Rechner), meldet `aibos --fetch` das je Paket und nimmt die Version aus dem Cache, wenn sie dort liegt (V0.4, Memo 18, Q4).

**Ziel** ist das Projekt der Session oder `--to <projekt>` (F4). Ein Paket in einem Projekt gilt für dieses Projekt und alle Projekte der Kette darunter, solange dort kein näheres Paket gleichen Namens liegt. Der Skill fragt nach dem Ziel und schlägt das Root-Projekt vor.

**Ablauf:**

1. `packages:` in `<ziel>/.aibos/config.yaml` mit dem neuen Eintrag lesen. `packages:` der Projekte darüber wird nicht berücksichtigt.
2. Auflösen (*Resolver*).
3. Pakete in den Cache holen: `git clone --depth 1 --branch v<version> <repo>` nach `~/.aibos/packages/<hub>/<name>/<version>/`, Commit-SHA merken. Ein vorhandener Cache-Eintrag wird wiederverwendet, wenn sein Commit zu `lock.yaml` passt. Bei `--from` liegt der Cache nach Quelle getrennt, unter `~/.aibos/packages/_from/<12 Zeichen SHA-256 der Quelle>/<paket>/<version>/`; ein Eintrag wird nur wiederverwendet, wenn der Commit des Tags in dieser Quelle zu ihm passt, sonst wird neu geholt (V0.6, Memos 03, 50: K1).
4. Vorschau: je Paket `new`, `upgrade X → Y`, `remove`, `unchanged`, `other commit` (gleiche Version aus einer anderen Quelle oder mit verschobenem Tag; V0.6, Memo 50, F62) mit Hub; Dateien, die sich in `@!Package/<name>/` ändern; direkt geänderte Kopien; je Arbeitspferd, das auf dem Rechner fehlt, das setup mit seinem Inhalt (Spec 07, *Abläufe*); Versionen von Arbeitspferden, die entfernt werden; Änderungen an `config.yaml` und `lock.yaml`; offene Dateien des Ziels (`git status --porcelain`), die der Plan ändert, mit dem Hinweis, dass `aibos --fetch` sie nicht committet (V0.6, Memo 02). Offene Dateien unter `@/@!Package/<name>/` bzw. `@Data/<name>/` stehen zusammengefasst als ein Eintrag `@/@!Package/<name>/ (N files)`, andere einzeln (V0.6, Memo 81, H3).
5. Nach Ja: Sicherung anlegen (unten); je Paket den Inhalt ohne `.git` nach `<ziel>/@/@!Package/<name>/` spiegeln (nur dieser Ordner), die Marke schreiben, `packages:` und `lock.yaml` schreiben.
6. Arbeitspferde einrichten (setup, Spec 07), Abhängigkeiten zuerst; nicht mehr genutzte Versionen entfernen (Spec 07, *Nutzende Projekte*).
7. Ausrollen: Ein neu geholtes Paket wirkt mit **allen** Elementen, solange `packages:` keine Auswahl `only` nennt (V0.4, Memo 24, H2).
8. Hüllen der Kernel-Skills und Projekt-Skills registrieren (Spec 03), im Projekt der Session bzw. bei `--to` und bei `aibos --install <distribution> <vault>` im Ziel, unabhängig vom Arbeitsverzeichnis (V0.6, Memo 03, K2), **erst nach erfolgreichem setup** (V0.5, Memo 17).
9. Sicherung löschen.

**Alles oder nichts** (Spec 01, I11): Scheitert ein Schritt ab 5, stellt AIBOS die Dateien aus der Sicherung wieder her und meldet den Schritt; der Vault steht wie vor dem Plan, registriert wird nichts. Die **Sicherung** liegt während des Plans unter `<ziel>/.aibos/backup/` und enthält genau, was der Plan ändert: `.aibos/config.yaml`, `.aibos/lock.yaml`, die betroffenen Ordner in `@/@!Package/` und die Registrierung (`.claude/skills/`, `.aibos/registry`) des Projekts der Session. Bleibt sie nach einem Abbruch liegen (z. B. Absturz), meldet `aibos --fetch` sie und bietet die Wiederherstellung an (V0.5, Memos 28, 29). Das Repo des Projekts muss dafür nicht sauber sein.

**Jedes Projekt ist in sich vollständig** (V0.4, Memo 17): Abhängigkeiten werden immer in dasselbe Ziel geholt wie das Paket, das sie verlangt, auch wenn ein Projekt darüber dasselbe Paket schon hat. `lock.yaml` eines Projekts beschreibt damit alles, was es braucht, und Änderungen an Paketen darüber können es nicht brechen. Liegt dasselbe Paket in der Kette mehrfach, gilt das nächstgelegene (*Vorrang*).

**Marke `.aibos-deploy`** (F3): `@!Package/<name>/.aibos-deploy` mit `name`, `version`, `hub`, `repo`, `commit` und `digest` (Verfahren wie Spec 04, *`.aibos/registry`*, über alle Dateien des Pakets ohne die Marke). Weicht der Inhalt vom `digest` ab, meldet `aibos --fetch` die Kopie als „direkt geändert" und ersetzt sie nach Rückfrage.

**Abgleich ohne Argument:** Für jedes Paket aus `lock.yaml` des Ziels prüfen, ob `@!Package/<name>/` mit Version und `digest` übereinstimmt. Fehlende, abweichende und direkt geänderte Kopien werden aus dem Cache bzw. dem Hub neu gespiegelt. Arbeitspferde aus `lock.yaml`, deren Version auf dem Rechner fehlt (z. B. auf einem zweiten Rechner), werden im selben Plan eingerichtet (V0.5, Memo 29). Ein Paketordner mit Marke, der in `lock.yaml` nicht mehr steht, wird nach Rückfrage entfernt.

**Entfernen:** `--remove <paket>` entfernt den Eintrag aus `packages:`, löst neu auf und entfernt `@!Package/<name>/` sowie Pakete, die nur noch als Abhängigkeit dieses Pakets im Ziel lagen. Projekte darunter sind davon nicht betroffen, weil sie ihre Abhängigkeiten selbst enthalten. Verlangt ein anderes Paket es noch, bricht `--remove` mit dieser Angabe ab. Für ein Arbeitspferd wird das Projekt aus `workers.yaml` entfernt; eine Version, die kein Projekt mehr nutzt, wird im selben Plan entfernt (Spec 07). Bringt das Paket einen Assistenten, den ein Projekt im Ziel oder darunter mit `assistant:` zuordnet, und liefert ihn danach nichts anderes in dessen Kette (lokaler Blueprint, anderes Paket), nennt der Plan das: `note: assistant: <name> in <config.yaml> then points nowhere; assign another one with /aibos-assistant`. Die Zuordnung bleibt stehen (V0.5, Memo 71, O5).

## Ausrollen — `aibos --deploy`

Ausrollen legt fest, **welche Elemente** eines geholten Pakets im Projekt wirken (V0.4, Memos 23, 24). Es kopiert nichts; es ändert nur die Auswahl `only` in `packages:`. Der Skill dazu ist `/aibos-deploy` (Spec 03).

| CLI | Wirkung |
|---|---|
| `aibos --deploy <paket> --only <element>… [--to <projekt>]` | nur diese Elemente des Pakets wirken (`only:` in `packages:`) |
| `aibos --deploy <paket> --all [--to <projekt>]` | alle Elemente wirken (`only:` entfernt) |
| `aibos --deploy [--to <projekt>]` | zeigt je Paket die Elemente und ob sie ausgerollt sind; schreibt nichts |

Nach einer Änderung registriert `aibos --deploy` die Projekt-Skills im Projekt der Session neu (Spec 03). Ein Element, das das Paket nicht hat, ist ein Fehler. `only` gilt nur für Pakete aus `packages:`; Abhängigkeiten werden immer ganz ausgerollt (H4).

**Nicht ausgerollte Elemente wirken nicht** (H3): Sie werden nicht registriert, nicht als Assistent aufgelöst, ihr Wissen kommt nicht in den Master-Kontext, und ihre Befehle sind nicht aufrufbar. `/aibos-context` nennt sie als „fetched, not deployed".

### Wirkung ausgerollter Elemente

Ein ausgerolltes Element wirkt über die Masterspace-Kette (Spec 02, 03):

| Element | Wirkung |
|---|---|
| `skills/<name>/` | Projekt-Skill wie ein Blueprint `@!Skill/<name>/` desselben Masterspace; wird registriert (Spec 03) |
| `assistants/<name>/` | Assistent wie `@!Assistant/<name>/` desselben Masterspace; zuordnen mit `/aibos-assistant` |
| `knowledge/` | Teil des Masterspace: Dateien darin werden nach den Klassen von Spec 02 eingeteilt, als lägen sie direkt in `@/` (K6); Pfadangaben im Master-Kontext nennen den Ort in `@!Package/<name>/knowledge/` |
| `commands/<name>` | aufrufbar mit `aibos --run <name> [argumente]` in Projekten, für die das Paket gilt |
| `gui` | Oberfläche einer App; der Skill dieses Namens zeigt sie. `/aibos-gui` listet die Oberflächen ausgerollter Apps unter der Kachel *Apps* (Spec 03, *Oberflächen*) |

**Vorrang** (V0.4, Memo 12): Zuerst gilt der nächstgelegene Masterspace (Spec 01, Grundregel 3). Innerhalb eines Masterspace gewinnt ein lokaler Blueprint in `@!Skill/` bzw. `@!Assistant/` vor einem Element gleichen Namens aus `@!Package/`. `/aibos-context` meldet jede solche Verdeckung. Zwei Pakete mit Elementen gleichen Namens im selben Masterspace sind ein Fehler, den `aibos --fetch` vor dem Schreiben meldet.

## Distributionen

Eine Distribution stellt eine geprüfte Zusammenstellung zusammen: optional einen Kernel und Pakete in exakten Versionen (V0.5, Memos 25–27, 34).

```yaml
name: distribution-rothirsch
version: 1.1.0
type: distribution
description: Rothirsch — AIBOS mit Video-Analyse und der Assistentin Anja
requires:
  aibos: ">=0.7,<0.8"
kernel: "==0.7.0"
depends:
  skill-video-analyse: "==0.2.1"
  assistant-anja: "==0.2.1"
```

| Regel | |
|---|---|
| Versionen | `kernel` und alle Einträge in `depends` mit `==`; neue Stände sind eine neue Version der Distribution, deren Version unabhängig von der des Kernels ist |
| Kernel | `kernel:` ist optional; ohne `kernel:` ist die Distribution eine reine Sammlung von Paketen, und `requires.aibos` aller Pakete muss zum gebundenen Kernel passen |
| Abhängigkeiten | Abhängigkeiten der Pakete (z. B. `worker-yt-dlp` der Video-Analyse) stehen nicht in `depends`; der Resolver holt sie |
| Installieren | `aibos --install distribution-<name> [<vault>] [--from <repo>]` (Spec 04): erst der Rechner (Kernel, Arbeitspferde), dann der Vault (binden, holen, registrieren); ein Plan, ein Ja. Scheitert der Rechnerteil, bleibt der Vault unberührt; schon Installiertes bleibt liegen. Scheitert der Vaultteil, gilt die Sicherung (*Holen*) |
| im Vault | die Distribution steht in `packages:` der Vault-Root (`distribution-rothirsch: "==1.1.0"`), ihre Pakete in `lock.yaml` mit `required_by: [distribution-rothirsch]` |
| eine je Vault | höchstens eine Distribution mit `kernel:` je Vault; eine zweite ist ein Konflikt im Plan; Distributionen ohne `kernel:` dürfen daneben stehen |
| anderer Kernel | ist der Vault an einen anderen Kernel gebunden, zeigt der Plan die Umstellung (`aibos: 0.7.0 → 0.7.1`) samt dem Paketwechsel (*Paketwechsel bei der Aktivierung*) und führt sie im selben Plan aus. Umgekehrt nennt `aibos --activate` eine Distribution, deren `kernel:` die neue Bindung nicht erfüllt, nur als Hinweis mit dem Befehl zum Aktualisieren (Spec 04, *`aibos --activate`*, Zeile *Distribution*; V0.6, Memo 120, H5) |
| Aktualisieren | `aibos --install distribution-<name>` erneut, ohne Version die höchste; der Plan zeigt `upgrade 1.0.0 → 1.1.0` mit Kernel, Arbeitspferden und Paketen |
| Entfernen | `aibos --fetch --remove distribution-<name>` nach den allgemeinen Regeln (*Holen*); die Bindung an den Kernel bleibt |
| Übersteuern | nur mit `only` (*Ausrollen*); eine andere Version eines Pakets der Distribution, z. B. durch einen eigenen Eintrag in `packages:`, ist ein Konflikt im Plan |
| `--from` | nimmt die Distribution aus einem lokalen Repo, eine getaggte Version wie `aibos --fetch --from` (auch ein lokaler, nicht gepushter Tag; V0.5, Memo 56); ihre Pakete kommen weiter aus den Hubs |

Zusammengestellt werden Distributionen mit dem Kernel-Skill `/aibos-distribution` (Spec 03). Gepflegt werden die Distributionen des Hubs `aibex-aibos` in eigenen Projekten des Vaults `§AIBOS` (`D-Distribution/DC-Capricorn`, `D-Distribution/DR-Rothirsch`; V0.6, Memo 83).

**Vorabversionen:** Ein Bereich mit `==` nimmt eine Vorabversion nur an, wenn er sie selbst nennt (*Versionen und Bereiche*). Für die Abnahme eines Release-Kandidaten des Kernels (z. B. `v0.6.1-rc1`) gibt es deshalb Testversionen der Distribution mit Vorabversion (`1.1.0-rc1` mit `kernel: "==0.6.1-rc1"`), nur lokal getaggt; die endgültige Version nennt den endgültigen Kernel (V0.6, Memo 82, F49). Liegt ein Paket der Distribution noch in keinem Hub, weil es mit dem Kernel erst veröffentlicht wird, kommt sein Kandidat für die Abnahme aus einem lokalen Hub in der Hub-Liste des Probe-Vaults (`aibos --hubs add <name> file://<ordner> --vault`), der nach dem Veröffentlichen wieder entfernt wird (V0.6, Memo 122, F94).

## Konfiguration und Lock

`<ziel>/.aibos/config.yaml` nennt unter `packages:` die gewünschten Pakete (Spec 04). Ein Eintrag ist ein Bereich oder eine Abbildung mit `range` und optional `hub`, `from` und `only`:

```yaml
aibos: 0.5.0
packages:
  app-taschenrechner: "~=0.1.0"
  knowledge-scorpio: {range: "~=0.1.0", hub: aibex-hub}
  skill-sammlung: {range: "~=1.0", only: [memo]}
assistant: none
```

`<ziel>/.aibos/lock.yaml` schreibt nur AIBOS. Es ist versioniert:

```yaml
# written by AIBOS (fetch, workspace), do not edit
schema: 1
packages:
  app-taschenrechner:
    version: 0.1.0
    hub: aibex-aibos
    repo: https://github.com/aibex-aibos/app-taschenrechner
    tag: v0.1.0
    commit: 3f2a…
    requested: "~=0.1.0"
  skill-memo:
    version: 6.0.0
    hub: aibex-aibos
    repo: https://github.com/aibex-aibos/skill-memo
    tag: v6.0.0
    commit: 9c1d…
    required_by: [app-taschenrechner]
workspace:
  AA-AIbex-AIOS: 8f31…
```

`requested` steht bei Paketen aus `packages:`, `required_by` bei Abhängigkeiten, `from` statt `hub` bei Paketen aus einem Pflegeprojekt. `workspace` hält den eingefrorenen Stand eines Workspace (unten). AIBOS schreibt `lock.yaml` in der festen Untermenge von YAML aus Spec 04, damit die Weiterleiter der Arbeitspferde es ohne PyYAML lesen können (Spec 07); AIBOS selbst liest es mit PyYAML.

## Arbeitspferde

Arbeitspferde sind Pakete vom Typ `worker` und stehen in Spec 07. Das Feld `workers:` aus v0.4 gibt es nicht mehr.

## Paketwechsel bei der Aktivierung

`aibos --activate v<version> <vault-root>` prüft für die Vault-Root und alle Projekte darunter, ob die geholten Pakete mit dem neuen Kernel laufen (`requires.aibos`), und stellt sie im selben Plan und mit derselben Bestätigung um (V0.5, Memos 30, 35; V0.6, Memo 72, B15):

- Läuft ein Paket nicht, setzt der Plan in `packages:` den Standardbereich der höchsten Version, die passt, und holt sie. Gibt es keine solche Version, bricht die Aktivierung ab, bevor etwas geschieht, und nennt jedes Paket mit dem Hinweis auf `aibos --fetch --remove`.
- Der Plan zeigt den Wechsel je Projekt unter der Überschrift `packages for AIBOS <version>`, mit **allen Unterschritten** des Holens wie *Holen*, Schritt 4: je Paket `<paket> X -> Y (requires.aibos)`, das setup jeder fehlenden Version eines Arbeitspferds, jede Version, die entfernt wird, mit ihrem Grund (Spec 07, *Nutzende Projekte*), und die offenen Dateien (V0.6, Memos 71, 81: B13; Spec 01, I7).
- **Umstieg auf v0.7:** Pakete mit `requires.aios` und der Obergrenze `<0.7` laufen nicht (*Versionen und Bereiche*); der Plan wechselt sie auf ihre Version für 0.7, z. B. `skill-memo 6.0.2 -> 6.1.0 (requires.aibos)`. Fehlt sie im Hub, bricht das Umbinden ab, bevor etwas geschieht (V0.7, Memo 10: F283).

Die Umstellungen von v0.3 und v0.4 stehen in dieser Spec im Tag `v0.6.6` (V0.7, Memo 16: FL9).

## Daten der Pakete — `@Data/`

Daten, die ein Paket im Projekt erzeugt, liegen in `<projekt>/@Data/<paket>/` (F6). Das gilt für jedes Paket, dessen Elemente schreiben: Apps, Assistenten und andere (V0.5, Memo 07); ein Assistent schreibt nach `@Data/assistant-<name>/`. Die Daten eines Arbeitspferds liegen unter `@Data/` des Pakets, das sie erzeugt, nicht unter `@Data/worker-<name>/` (Spec 07, K7). `@Data/` ist ein Schlüsselordner wie `@Memo/`: Er gehört nicht zum Masterspace, wird nicht in den Kontext geladen und ist versioniert. Das Paket legt `@Data/<paket>/` selbst an, wenn sie zum ersten Mal schreibt (V0.4, Memo 18, Q3). `aibos --fetch --remove` lässt `@Data/` unberührt.

## Tickets — `@/@!Ticket/`

Ein **Ticket** ist ein Anliegen an ein Paket oder an AIBOS selbst, abgelegt als eine Markdown-Datei im **Postfach** `<vault-root>/@/@!Ticket/` (ab v0.7.1; V0.7, Memos 68, 74, 75: F389, F392). Es gibt ein Postfach je Vault, im Masterspace der Vault-Root; Projekte haben keines. Als Ordner der Klasse *Verborgen* (Spec 02, *Klassen*) kommt es nie in den Master-Kontext. Ein Ticket ist kein Vorgang eines Ticketsystems: Es hat keine Zuständigen, Prioritäten oder Fristen, nur Typ, Paket und Status.

Tickets legen Skills an (z. B. `improve` aus `skill-improve` mit Typ `improvement`) oder der User; AIBOS liest sie nur (P6). Format (Frontmatter, danach freier Text):

| Feld | Pflicht | Bedeutung |
|---|---|---|
| `type` | ja | Art des Tickets; bis jetzt `improvement`; weitere Typen (etwa `bug`, `question`, `task`) brauchen keine Änderung an AIBOS |
| `package` | ja | Paket, an das sich das Ticket richtet; `aibos` für den Kernel |
| `element` | nein | Element des Pakets (Skill, Assistent) |
| `version` | ja | Version des Pakets, mit der das Ticket entstand |
| `date`, `author`, `project` | ja (`author` darf leer sein) | Datum, Autor, Projekt relativ zur Vault-Root (`.` für die Vault-Root) |
| `status` | nein | fehlt bei einem offenen Ticket; z. B. `aufgenommen` oder `abgelehnt`, gesetzt vom Skill des Pakets |

Eine Datei ohne Frontmatter oder ohne `type` oder `package` ist kein Ticket; `aibos --ticket` nennt sie unter *Notes* und lässt sie liegen.

**`aibos --ticket [<paket>] [--type <typ>]`** listet die offenen Tickets (ohne `status`) des Postfachs, nur lesend, mit Exit 0, auch wenn es keine gibt. Mit `<paket>` nur die Tickets an dieses Paket, mit `--type` nur diesen Typ. Ein Ticket gilt als **älter**, wenn seine `version` kleiner ist als die Version des Pakets im `lock.yaml` des nächsten Projekts der Kette von `cwd`, das das Paket hält (für `aibos`: die Bindung des Vaults); der Bericht nennt es unter *Notes*. Außerhalb eines A/W: `Kein AIBOS-Workspace: <cwd>`, Exit 1 wie `aibos --skill`.

```
Tickets §AIBOS — 2026-11-24

File                                          Type         Package         Version  Date        Author  Project
2026-11-23-0523 Postfach lesen ohne Rückfr…   improvement  aibos           0.7.0    2026-11-23  iHux    M-Module/MA-Assistants/MAA-Anja-AIBOS-Expert
2026-11-22-0924 Evals vor dem Abnahmetest…    improvement  assistant-anja  0.5.0    2026-11-22  iHux    M-Module/MS-Skills/MSI-Improve

Notes
- 2026-11-22-0924 Evals vor dem Abnahmetest: version 0.5.0 is older than assistant-anja 0.6.0 in /…/§AIBOS/.aibos/lock.yaml

Result: 2 open tickets (1 aibos, 1 assistant-anja)
```

Die Spalte *File* zeigt den Namen ohne `.md`, gekürzt auf 45 Zeichen mit `…`. Eine Spalte *Element* steht nach *Package* nur, wenn ein Ticket der Liste ein `element` hat; sonst fehlt sie.

**Übergang von v0.7.0** (F393): Bis 0.8 liest AIBOS zusätzlich `<vault-root>/@/@!Improve/`, den Ordner der Pakete `skill-improve` 0.1.0 und `assistant-anja` 0.6.0. Seine Dateien gelten als Tickets; `aibos --ticket` nennt sie mit dem Ordner in *File* und unter *Notes* `note: @/@!Improve/ is the folder of AIBOS 0.7.0; move its files to @/@!Ticket/`. AIBOS verschiebt sie nicht selbst.

## Workspaces

Ein **Workspace** ist eine Vault-Root mit `.aibos/workspace.yaml` und alle Projekte darunter (V0.4, Memo 10; V0.6, Memos 163–174). Die Vault-Root ist das **Wurzelprojekt** des Workspace (F156). Sie hat ein eigenes Repo; die Projekte liegen verschachtelt darunter, jedes mit eigenem Repo an seinem eigenen Remote, und sind im jeweils darüberliegenden Repo ausgeschlossen (Spec 05, S4). Ein Paket im Workspace liegt als Checkout an seinem Pfad (Entwickler-Site), in einem Vault als Kopie in `@!Package/` (Anwender-Site).

Ein **Projekt des Workspace** ist ein Repo an seinem Pfad. Mit `@/` ist es zugleich ein AIBOS-Projekt. Ohne `@/` ist es ein **Fremd-Repo**, z. B. ein Paket-Repo oder das Code-Repo: kein Container, nicht Teil des Master-Kontexts, und `aibos --integrity` prüft es nur über `workspace.yaml` (V0.4, Memo 18, L2). Projekte des Workspace müssen keine Pakete sein.

Ein Workspace kann Projekte verschiedener Eigentümer tragen, z. B. Branchenwissen bei AIbex und Kundenwissen beim Kunden (V0.8, Memo 16). Jedes Repo geht nur an sein eigenes `origin`. Das Remote ist jede Git-URL: GitHub, ein Git-Server des Kunden, ein Repo über `ssh`, `file://` (V0.6, Memo 169).

Die Arbeit mit einem Workspace kennt drei Handgriffe, je für den ganzen Workspace oder, mit Pfad, für einen Teilbaum (V0.6, Memos 166, 168, 170):

| Handgriff | Lesart | ganzer Workspace | mit Pfad |
|---|---|---|---|
| **attach** | anbinden | den Workspace an diesen Rechner anbinden | einen ausgelagerten Teilbaum zurückholen |
| **sync** | synchronisieren | den Projektbaum mit den Remotes abgleichen | nur diesen Teilbaum |
| **detach** | lösen | den Workspace von diesem Rechner lösen | einen Teilbaum auslagern |

Dazu kommt **remove**: ein Projekt mit seinen Unterprojekten aus dem Workspace entfernen, auf allen Rechnern; das Repo am Remote bleibt (*remove*; V0.6, Memo 226).

**Arten der Führung** (V0.6, Memos 223, 224): Ein A/W wird auf eine von vier Arten über Rechner geführt. Die Begriffe sagen, wo die Daten liegen und wer sie repliziert; es sind keine Arten von Vaults.

| Art | wo liegen die Daten | wer repliziert | `sync` |
|---|---|---|---|
| **Lokal-Drive** | nur auf diesem Rechner | niemand | `off` |
| **Cloud-Drive** | auf dem Rechner und beim Cloud-Dienst (Google Drive, OneDrive, iCloud Drive, Dropbox); die Vault-Root liegt in einem **Cloud-Ordner** | der Cloud-Dienst | immer `off`; Git von Hand bleibt erlaubt |
| **AIBOS-Drive** | auf dem Rechner und an den Git-Remotes; die Vault-Root hat eine `workspace.yaml` | AIBOS mit `attach`, `sync`, `detach`, `remove` | `auto` (Standard) oder `manual` |
| **Netz-Drive** | nur am Server, eingebunden als Netzlaufwerk (NAS, Server über SMB, NFS, AFP, WebDAV, SSHFS) | niemand, es gibt nur eine Kopie | `off` (Empfehlung) |

AIBOS erkennt den Cloud-Drive am Ort (*Schlüssel `sync:`*) und den AIBOS-Drive an der `workspace.yaml`. Einen Netz-Drive erkennt es nicht; dort wird `sync: off` empfohlen, weil Git auf einem Netzlaufwerk und mehrere Rechner auf derselben Kopie sich in die Quere kommen können. Ein Lokal-Drive ist der Rest. Ein Vault in einem anderen Sync-Ordner (z. B. Nextcloud, Synology Drive) mit `workspace.yaml` würde vom Dienst und von AIBOS zugleich abgeglichen; dort `sync: off` setzen bzw. keine `workspace.yaml` anlegen.

**Umfang ohne Pfad** (V0.6, Memo 203: B33): Ohne Pfad gilt das **Projekt des Arbeitsverzeichnisses** mit seinen Unterprojekten, also der nächste Eintrag von `workspace.yaml` an oder über dem Arbeitsverzeichnis; an der Vault-Root (oder außerhalb jedes Eintrags) ist das der ganze Workspace. Das gilt für `sync` und `detach` gleich; `attach` mit Pfad holt ausdrücklich einen Teilbaum zurück. Der Plan nennt den Umfang. Die Kernel-Skills übersetzen die Worte des Users: „Projekt" oder kein Wort ohne Pfad, „Workspace" bzw. „Vault" mit der Vault-Root als Pfad (Spec 03, *Workspaces*).

`aibos --workspace` arbeitet nur in einem A/W (Spec 01, I4). Ausgenommen ist `attach <repo>`, das den A/W erst anlegt.

### `.aibos/workspace.yaml`

```yaml
schema: 1
remotes:
  aibex: https://github.com/aibex-aibos
projects:
  - name: Work-A-Admin
    remote: aibex
    revision: main
    path: A-Admin
  - name: Work-AT-Templates
    remote: aibex
    revision: main
    path: A-Admin/AT-Templates
  - name: app-taschenrechner
    remote: aibex
    revision: v0.1.0
    path: A-Admin/AT-Templates/app-taschenrechner
    groups: [apps]
removed:
  - path: A-Admin/AX-Archiv
    name: Work-AX-Archiv
    remote: aibex
    revision: main
    since: 2026-11-14
```

| Feld | Pflicht | Regel |
|---|---|---|
| `remotes` | nein | Name → Basis-URL; die URL eines Projekts ist `<basis>/<name>` |
| `projects[].name` | ja | eindeutig im Workspace; bei `remote` zugleich der Name des Repos am Remote |
| `projects[].remote` oder `repo` | genau eines | Remote aus `remotes` oder volle URL |
| `projects[].revision` | ja | Zweig, Tag oder Commit-SHA |
| `projects[].path` | ja | relativ zum Wurzelprojekt, darunter, ohne `..` |
| `projects[].groups` | nein | Liste von Gruppennamen |
| `projects[].import` | nein | im Format vorgesehen, ohne Wirkung; `aibos --workspace` meldet ihn und übergeht ihn |
| `removed` | nein | Liste der Projekte, die mit `remove` aus dem Workspace entfernt wurden: `path`, `name`, `remote` oder `repo` und `revision` wie in `projects`, dazu `since` (Datum); je Unterprojekt ein eigener Eintrag. Ein Pfad steht nie zugleich in `projects` und `removed` (*remove*) |

Die Datei wird mit PyYAML gelesen. Der User pflegt sie; `sync` trägt neue Repos mit Remote ein (*sync*, Schritt 5), nie an einem Pfad aus `removed`, und `remove` bzw. `attach <pfad>` verschieben Einträge zwischen `projects` und `removed`. Die Reihenfolge der Einträge ist ohne Bedeutung: AIBOS klont Elternprojekte immer vor ihren Kindern, sortiert nach der Tiefe des Pfads (F155).

### Namensschema am Remote

Für Projekte mit `@/` schlägt AIBOS Namen nach einem festen Schema vor (V0.6, Memo 173):

| Ordner | Repo am Remote |
|---|---|
| Vault-Root `§<Workspace>` | `<Workspace>` |
| jedes Projekt darunter, in jeder Tiefe | `<Workspace>-<Ordnername>` |

Beispiel `§Work`: `Work`, `Work-A-Admin`, `Work-AT-Templates`, `Work-ATP-Powerpoint`.

- **Paket-Repos** folgen nicht dem Schema: Ihr Name ist der Paketname, klein geschrieben, `<typ>-<name>` (*Pakete*); der Kernel liegt im Repo `aibex-aibos`. Ein Repo mit `manifest.yaml` an seiner Wurzel und ohne `@/` gilt als Paket-Repo; `sync` schlägt dafür keinen Namen vor und meldet keine Abweichung (V0.6, Memo 177: F200, F201). Andere **Fremd-Repos** ohne `@/` behalten ihren Namen ebenso (F178).
- **Zeichen:** erlaubt sind `A–Z a–z 0–9 . _ -`; `ä ö ü Ä Ö Ü ß` werden zu `ae oe ue Ae Oe Ue ss`, jedes andere Zeichen zu `-` (F180).
- **Eindeutigkeit:** Es zählt nur der letzte Ordnername. Haben zwei Projekte des Workspace denselben Ordnernamen, meldet `sync` die Kollision und schlägt keinen Namen vor (F179).
- Das Schema ist ein **Vorschlag**: Ein abweichender Name funktioniert, `sync` nennt ihn als Hinweis (F181). AIBOS legt keine Repos an; bei einem Projekt ohne Remote nennt `sync` den Namen und den Befehl, der das Repo anlegt und den ersten Stand pusht, z. B. `gh repo create aibex-aibos/Work-AT-Templates --private --source <pfad> --remote origin --push` (F182; V0.6, Memos 222, 225: B36). Hat ein Repo ein `origin`, aber sein Zweig keinen Upstream (etwa nach `gh repo create` ohne `--push`), pusht `sync` es nicht (F217) und nennt es in Plan, Bericht und `status` als Hinweis: `note: <pfad>: no upstream; git -C <pfad> push -u origin <zweig>`.

### `.aibos/workspace.local.yaml`

Was nur für diesen Rechner gilt, steht in `.aibos/workspace.local.yaml` der Vault-Root. Die Datei ist in der `.gitignore`-Vorlage (Spec 04) und reist nie mit; so wirkt eine Auslagerung auf dem Notebook nicht auf dem Arbeitsrechner (F164). Es schreiben nur `detach <pfad>` und `attach <pfad>`.

```yaml
# written by AIBOS (workspace), do not edit
schema: 1
detached:
  - path: Y-Youtube
    since: 2026-11-05
```

### Schlüssel `sync:`

`.aibos/config.yaml` der Vault-Root nennt mit `sync:` die Art des Abgleichs (F183). Der Schlüssel ist versioniert und reist mit dem Workspace.

| Wert | Wirkung |
|---|---|
| `auto` | Beim Start einer Session holt der SessionStart-Hook für das Projekt der Session neue Stände und führt sie zusammen, nur ohne lokale Änderungen und ohne Konflikt; er sichert nichts und fragt nie (Spec 02, *Hooks*; F185, F230). Die Kernel-Regel im Master-Kontext sagt Claude, nach jedem Commit sofort `/aibos-sync` für das Projekt anzubieten, damit eine Sicherung am Remote besteht (F186) |
| `manual` | kein Holen beim Start; die Kernel-Regel nennt nur `/aibos-sync` (F187) |
| `off` | keine Kernel-Regel; `attach` und `sync` verweigern mit Hinweis (F187) |

**Standard:** `auto`, wenn die Vault-Root eine `workspace.yaml` hat, sonst `off`.

**Cloud-Ordner** (Cloud-Drive, *Arten der Führung*): Liegt die Vault-Root unter `~/Library/CloudStorage/` (Google Drive, OneDrive u. a.), unter `~/Library/Mobile Documents/` (iCloud Drive) oder unter `~/Dropbox/`, gilt `off`, auch wenn etwas anderes eingetragen ist; der Master-Kontext sagt das in einer Zeile. Dort repliziert der Cloud-Dienst, und ein Abgleich über Git-Remotes käme ihm in die Quere (V0.6, Memo 169). Git selbst bleibt erlaubt: Commit, Push und Pull von Hand bzw. auf Wunsch des Users (F188).

### `aibos --workspace`

| Befehl | Wirkung |
|---|---|
| `aibos --workspace attach <repo> [<vault-ordner>]` | Workspace an diesen Rechner anbinden: Vault-Root klonen, dann `sync` |
| `aibos --workspace attach <pfad>` | ausgelagerten Teilbaum zurückholen bzw. ein entferntes Projekt wieder aufnehmen (*remove*) |
| `aibos --workspace sync [<pfad>] [--group <g>… \| --only]` | Projektbaum mit den Remotes abgleichen; mit `--only` nur das eine Projekt ohne Unterprojekte |
| `aibos --workspace remove <pfad>` | Projekt mit seinen Unterprojekten aus dem Workspace entfernen (*remove*) |
| `aibos --workspace history <pfad> [--deleted]` | frühere Fassungen und gelöschte Dateien zeigen (*Zurückholen*) |
| `aibos --workspace restore <pfad> [--at <zeit>]` | Datei oder Projekt auf eine frühere Fassung zurückholen (*Zurückholen*) |
| `aibos --workspace detach [<pfad>]` | Teilbaum auslagern; an der Vault-Root bzw. mit ihrem Pfad: Workspace von diesem Rechner lösen |
| `aibos --workspace status [<pfad>]` | je Projekt: vorhanden, ausgelagert, Zweig, Revision enthalten, voraus/hinter dem Remote, offene Änderungen |
| `aibos --workspace freeze [<pfad>]` | Commit-SHA jedes Projekts in `lock.yaml` des Wurzelprojekts schreiben (Abschnitt `workspace`) |

Die Befehle `init` und `update` aus v0.4 gehen in `attach` und `sync` auf (F163). Alle Befehle außer `status` sind schreibend und folgen I7 (Plan, `--plan`, `--yes`); sie zeigen einen Plan und fragen einmal.

**URL oder Pfad:** Ein Argument von `attach` mit `://`, der Form `<user>@<host>:` oder der Endung `.git` ist ein Repo, sonst ein Pfad (F171). `<pfad>` ist das Wurzelprojekt oder ein Ordner darunter; AIBOS sucht die nächste `workspace.yaml` aufwärts. Ohne `--group` gelten alle Projekte; mit `--group` nur Projekte dieser Gruppen und Projekte ohne Gruppe. `--only` beschränkt `sync` auf das eine Projekt an `<pfad>` (ohne Pfad das Projekt des Arbeitsverzeichnisses, an der Vault-Root diese allein), ohne Unterprojekte; `--only` mit `--group` ist ein Fehler (V0.6, Memos 222, 227: H42).

**Klonen** (in `attach` und `sync`): `git clone <url> <path>`. Ist `revision` ein Zweig, wird er ausgecheckt. Ist sie ein Tag oder Commit, legt AIBOS einen lokalen Zweig `ws/<revision>` an diesem Commit an und checkt ihn aus; es gibt kein *detached HEAD* (V0.4, Memo 10). Danach trägt AIBOS `/<path>/` in die `.gitignore` des Repos darüber ein, wenn sie fehlt, und committet nur diese Zeile („AIBOS: <path> als Projekt des Workspace ausgeschlossen", I9).

#### attach — Workspace anbinden

`aibos --workspace attach <repo> [<vault-ordner>]` läuft ohne Vault (F161):

1. **Ziel:** `<vault-ordner>`, Standard `§<Name des Repos>` im aktuellen Ordner. Gibt es den Ordner schon, bricht `attach` ab und verweist auf `sync`. Liegt das Ziel in einem Cloud-Ordner (*Schlüssel `sync:`*), bricht es ab.
2. **Vault-Root klonen** nach *Klonen*, ohne Ausschluss darüber. Fehlt im Klon `.aibos/workspace.yaml` oder gilt dort `sync: off`, bleibt der Klon stehen, und `attach` endet mit Hinweis.
3. **Kernel:** Ist die Version aus `aibos:` der geklonten `config.yaml` nicht installiert, nimmt der Plan `aibos --install v<version>` aus dem Klon unter `~/.aibos/repo` auf (Spec 04); fehlt der Klon, bricht `attach` vor Schritt 2 mit dem Befehl zum Installieren ab.
4. **sync** für den ganzen Workspace, im selben Plan. Bindet die Vault-Root eine andere Version als die aufrufende, übergibt `attach` den sync an die gebundene (`aibos --workspace sync --yes` im Klon); eine gebundene Version vor 0.6.4 kennt den sync nicht, dann läuft er mit Warnung in der aufrufenden (V0.6, Memo 199: H30).

Der Plan zeigt alle Schritte; ein Ja. Danach ist der Rechner ohne `aibos --activate` bereit: Die Bindung reist in `config.yaml` mit, und der SessionStart-Hook registriert die Hüllen in jedem Projekt beim ersten Chat (Spec 02, *Hooks*). Im allerersten Chat ist `/aibos-sync` deshalb noch kein Slash-Befehl; der Wunsch in Worten wirkt über den Block der Kernel-Skills (V0.6, Memo 167).

#### sync — Projektbaum abgleichen

`aibos --workspace sync [<pfad>]` gleicht den Projektbaum mit den Remotes ab, nach dem **Drive-Modell** (V0.6, Memo 204: L38): Was der User lokal ändert, neu anlegt oder löscht, sichert `sync` selbst; neue Stände anderer Rechner führt es zusammen; dieselbe Datei auf beiden Seiten ergibt eine Konfliktkopie statt eines Stillstands. Der User braucht kein Git: Er sieht keinen Commit, und jede frühere Fassung bleibt in der Geschichte (*Zurückholen*). Die Schritte gelten für die Projekte an oder unter `<pfad>`, ohne Pfad unter dem Projekt des Arbeitsverzeichnisses (*Umfang ohne Pfad*); an der Vault-Root für den ganzen Workspace. Ausgelagerte Teilbäume (`workspace.local.yaml`) überspringt `sync` ganz: Es holt sie nicht zurück und pusht nichts aus ihnen (F175). Mit `--only` gelten die Schritte 2, 3 und 6 nur für das eine Repo und Schritt 5 nur an der Vault-Root; Schritt 1, Schritt 4 und das Entfernen nach `removed` entfallen (V0.6, Memo 227: H42).

1. **Klonen, was fehlt:** Projekte aus `workspace.yaml`, deren Pfad fehlt, nach *Klonen*, Eltern vor Kindern. Ein fehlender Projektordner wird immer neu geklont; soll ein Projekt nicht zurückkommen, wird es mit `remove` aus dem Workspace entfernt, auf diesem Rechner allein hilft `detach`. **Entfernt auf einem anderen Rechner:** Liegt ein Ordner an einem Pfad aus `removed` noch auf diesem Rechner, nimmt `sync` „remove <pfad> (removed on another computer)" in den Plan auf und entfernt ihn nach der *Prüfung* von `detach` wie `remove` (Papierkorb, ohne Commit, weil `workspace.yaml` schon stimmt). Besteht er die Prüfung nicht, bleibt er stehen; der Plan nennt die Hindernisse, und `sync` sichert, holt und pusht ihn nicht mehr (V0.6, Memo 226: F241). Als entfernt gelten die Pfade aus `removed` der eigenen `workspace.yaml` und der am Upstream der Vault-Root (nach `git fetch` beim Planen), damit ein Rechner das Entfernen schon in dem sync übernimmt, der es holt (V0.6, Memo 235: F258). Hat die `workspace.yaml` lokal ungepushte Änderungen, gilt für die Pfade, die sie in `projects` führt, der lokale Stand: Ein mit `attach <pfad>` wieder aufgenommenes Projekt wird vor dem Push nicht erneut entfernt (V0.6, Memo 238: B37). Auch die Hinweise aus Schritt 5 übergehen diese Pfade (H44). Scheitert ein Klon (z. B. ein Remote, das es auf diesem Rechner nicht gibt), nennt der Bericht das Projekt mit Grund (`not cloned`), überspringt seine Unterprojekte und macht mit den übrigen weiter (V0.6, Memo 194: B30).
2. **Sichern** (F225): In jedem vorhandenen Repo mit Upstream, dessen `revision` ein Zweig ist und das diesen Zweig ausgecheckt hat, übernimmt `sync` alle lokalen Änderungen (neue, geänderte, gelöschte Dateien; Ausgeschlossenes nach `.gitignore` bleibt draußen) in einen Commit „AIBOS: gesichert von `<benutzer>@<Rechner>` am `<JJJJ-MM-TT hh:mm>`" (H38). **Geheimnisse** (Dateien unter `@Secret/` und mit den Namen `.env`, `.env.*`, `*.pem`, `*.key`, `id_rsa*`, `id_ed25519*`) nimmt es nicht auf; sie bleiben lokal, und der Bericht nennt sie als „nicht gesichert (Geheimnis)". **Große Löschung** (F228): Fehlen in einem Repo mehr als 10 getrackte Dateien, oder fehlen alle getrackten Dateien unter `@/` oder `.aibos/`, fragt `sync` einmal für dieses Repo: „Löschen übernehmen" oder „wiederherstellen" (Standard). Wiederherstellen holt die gelöschten Dateien aus dem letzten Commit zurück; die übrigen Änderungen werden gesichert. Ohne Frage (`--yes`, kein Terminal, Hook) gilt wiederherstellen.
3. **Holen und zusammenführen** (F226, F227). Bringt das Zusammenführen an der Vault-Root eine `workspace.yaml` mit Projekten, die hier fehlen (von einem anderen Rechner eingetragen oder wieder aufgenommen), klont `sync` sie im selben Lauf und macht sie lauffähig wie in Schritt 4 (V0.6, Memo 238: B38). Im Einzelnen: `git fetch --tags origin` für jedes Repo mit Upstream, auch die Vault-Root. Ist `revision` ein Zweig, führt `sync` `origin/<zweig>` zusammen: per fast-forward, sonst mit einem Merge-Commit „AIBOS: zusammengeführt auf `<benutzer>@<Rechner>`". Haben beide Seiten dieselbe Datei geändert, gilt die Fassung des Remote; die lokale bleibt daneben als `<Name> (Konflikt <benutzer>@<Rechner> <JJJJ-MM-TT>).<Endung>` und wird im selben Commit gesichert. Ist eine Datei auf einer Seite gelöscht und auf der anderen geändert, bleibt die geänderte Fassung. Der Bericht nennt jede Konfliktkopie. Ist `revision` ein Tag oder Commit (fester Stand), wird nichts gesichert; enthält der ausgecheckte Zweig den Stand nicht, setzt `sync` ihn per fast-forward darauf, lokale Änderungen nennt der Bericht. Unverändert bleibt ein Repo mit anderem ausgecheckten Zweig oder mit einem `origin`, das auf ein anderes Repo als `workspace.yaml` zeigt (F160), ebenso ein Ordner am Pfad, der kein Git-Repo ist; der Bericht nennt den Grund in Alltagssprache (H35). **Gleiche Repos** (B40; V0.7, Memo 07: F278): Zwei Adressen nennen dasselbe Repo, wenn sie sich nur in der Form (`git@github.com:<owner>/<repo>` und `https://github.com/<owner>/<repo>`), in der Endung `.git` oder, bis 0.8, in der Organisation `aibex-aios` bzw. `aibex-aibos` unterscheiden. Dieser Vergleich gilt in Schritt 3, in Schritt 5 und überall, wo AIBOS ein `origin` mit `workspace.yaml` vergleicht.
4. **Lauffähig machen:** für jedes in Schritt 1 geklonte Projekt mit `@/` den Abgleich der Pakete und Arbeitspferde mit `lock.yaml` (wie `aibos --fetch` ohne Argument) und die Registrierung (wie `aibos --register`) (F158). Git hält keinen leeren Ordner: Enthält `@/` keine getrackte Datei, fehlt es im Klon. Ein Klon ohne `@/`, dessen `.gitignore` die Zeile `.aibos/registry` der Vorlage enthält und der kein Paket-Repo ist, gilt deshalb als Projekt; `sync` legt `@/` an und nennt das im Bericht. Der Bericht zeigt den Abgleich der Pakete und die Registrierung mit je einer Zeile je Projekt, ohne die Liste der einzelnen Skills (V0.6, Memo 199: B32, H31; Memo 202: H33).
5. **Manifest nachführen:** Repos unter dem Wurzelprojekt mit `origin`, die in `workspace.yaml` fehlen, nicht ausgelagert sind und an keinem Pfad aus `removed` liegen, werden eingetragen: `name` aus der URL, `remote`, wenn die URL nach dem Vergleich *Gleiche Repos* (Schritt 3) mit der Basis eines Eintrags in `remotes` beginnt, sonst `repo`; `revision` der ausgecheckte Zweig; `path` relativ zum Wurzelprojekt (F176). AIBOS committet im Wurzelprojekt `workspace.yaml` („AIBOS: workspace.yaml nachgeführt"). Repos ohne Remote, Repos ohne Upstream, Kollisionen und Abweichungen vom Namensschema nennt der Bericht als Hinweis (*Namensschema am Remote*).
6. **Pushen:** jedes Repo mit Upstream und ausgehenden Commits, das Schritt 3 nicht ausgenommen hat: `git push origin <zweig>` für den ausgecheckten Zweig, nie Tags, nie `--force` (F159). Vorher prüft AIBOS die ausgehenden Commits auf Geheimnisse (Namen wie in Schritt 2); ein Treffer, etwa ein früher von Hand committetes `.env`, hält den Push dieses Repos an, mit Datei und Commit im Bericht; die übrigen Repos laufen weiter (F172). **Erster Push** (B41; V0.7, Memo 07: F278): Steht ein Repo in `workspace.yaml`, hat es ein `origin`, aber keinen Upstream, und fehlt sein ausgecheckter Zweig am Server, nimmt `sync` `first push of <zweig>` in den Plan und pusht nach Ja mit `git push -u origin <zweig>`, mit derselben Prüfung auf Geheimnisse; das Sichern in Schritt 2 gilt dann auch für dieses Repo.

**Neuer Workspace:** Läuft sync an einer Vault-Root ohne `workspace.yaml`, legt es sie im selben Plan an: `remotes` mit der Basis des `origin` der Vault-Root, wenn sie bei GitHub liegt (`<owner>: https://github.com/<owner>`), `projects` mit allen Repos mit Remote wie in Schritt 5; Commit nur dieser Datei („AIBOS: workspace.yaml angelegt"); danach die Schritte 2, 3 und 6 für die Vault-Root und diese Projekte. Unterhalb der Vault-Root und bei `sync: off` legt sync nichts an (V0.6, Memo 194: B29).

**Plan und Bericht:** Der Plan nennt nur, was geschieht: zu klonende Projekte, zu entfernende Projekte (nach `removed`), je Repo das Sichern (Zahl der neuen, geänderten, gelöschten Dateien), eine Zeile für das Holen und Zusammenführen aller Projekte (bis zu fünf mit Namen), Einträge ins Manifest und Pushes mit den ausgehenden Commits (Kurz-SHA, Autor, Betreff). Steht für ein Repo ein Sichern im Plan, nennt er auch den Push danach („push <pfad> after saving"); Geheimnisse zählt er nicht mit, er nennt sie. Pushes, die erst durch Zusammenführen entstehen, nennt der Bericht. Der Bericht nennt nur Änderungen und fasst Projekte, die weder gesichert noch geholt noch gepusht wurden, in einer Zeile zusammen (V0.6, Memo 208: H36; Memo 211: H39–H41). Der Skill `/aibos-sync` zeigt den Plan vor jedem Push, auch für den ganzen Workspace an der Vault-Root, und nennt dem User dazu die Commits, die nicht aus der laufenden Session stammen (Regel *Weiter*; V0.6, Memos 216, 217, 227: R34); der Kernel erzwingt das nicht. `sync` macht keinen Rebase, ändert nie die Geschichte und legt keine Repos am Remote an. **Projekt ohne Remote** (H48; V0.7, Memo 07: F278): Steht das Projekt des Arbeitsverzeichnisses nicht in `workspace.yaml` (eigenes Repo ohne Remote) und gilt der Plan deshalb für ein Projekt darüber (*Umfang ohne Pfad*), beginnt der Plan mit `note: <projekt> has no remote and is not in workspace.yaml; this plan is for <eintrag>`.

**Grenzen:** `sync` gleicht nicht laufend ab wie ein Cloud-Laufwerk, sondern beim Start eines Chats (nur holen, Spec 02), nach Commits und auf Wunsch; je seltener, desto häufiger Konfliktkopien. Große Dateien (z. B. Videos) machen ein Repo schwer; sie gehören in `.gitignore`.

#### Zurückholen — `history`, `restore`

Jede gesicherte Fassung bleibt in der Geschichte des Repos (F229). Zwei Befehle machen sie ohne Git-Wissen zugänglich:

| Befehl | Wirkung |
|---|---|
| `aibos --workspace history <pfad> [--deleted]` | Fassungen einer Datei oder eines Projekts: Datum, Rechner bzw. Autor, Betreff, neueste zuerst; mit `--deleted` die gelöschten Dateien eines Projekts mit dem Datum des Löschens |
| `aibos --workspace restore <pfad> [--at <zeit>]` | eine Datei auf ihre letzte Fassung (eine gelöschte auf die Fassung vor dem Löschen) bzw. auf die Fassung zu `<zeit>`; ein Projektordner auf den Stand zu `<zeit>` (`--at` dann Pflicht). `<zeit>` ist ein Datum (`2026-11-06`), Datum mit Uhrzeit oder ein Kurz-SHA aus `history` |

`restore` ändert nur den Arbeitsbaum, nie die Geschichte; der nächste `sync` sichert das Ergebnis als neue Fassung. Dateien, die `restore` überschreiben oder entfernen würde und die nicht gesichert sind, legt es vorher in den Papierkorb (`~/.Trash/<Projekt> <JJJJ-MM-TT hh-mm>/`). Plan, eine Rückfrage, dann ausführen. Der Kernel-Skill `/aibos-restore` übersetzt Sätze wie „hol die gelöschte Datei … zurück", „zeig frühere Fassungen von …", „setz das Projekt auf den Stand von gestern zurück" in diese Befehle (Spec 03).

#### detach — Teilbaum auslagern, Workspace lösen

`aibos --workspace detach [<pfad>]` lagert einen Teilbaum auf diesem Rechner aus, um Platz zu sparen (V0.6, Memo 170). `<pfad>` ist ein Projekt aus `workspace.yaml`; ohne Pfad das Projekt des Arbeitsverzeichnisses (*Umfang ohne Pfad*). Ist es die Vault-Root, wird der Workspace gelöst (unten).

**Prüfung** (F165): Für jedes Repo im Teilbaum, auch für Unterprojekte, die nicht im Manifest stehen, gilt:

- es hat ein `origin` und einen Upstream, und `git fetch` gelingt;
- keine nicht committeten und keine unversionierten Dateien, kein Eintrag in `git stash`;
- keine ausgehenden Commits; der ausgecheckte Stand liegt auf dem Remote;
- keine ausgeschlossenen Dateien außer solchen, die sich neu erzeugen lassen (`.DS_Store`, `.claude/skills/`, `.aibos/registry`); insbesondere kein Inhalt unter `@Secret/`.

Verletzt ein Repo eine Bedingung, nennt der Plan jedes Hindernis mit Pfad, und `detach` ändert nichts. Offene Änderungen und ungepushte Commits räumt ein `sync` vorher aus; der Bericht schlägt ihn vor.

**Auslagern:** Der Teilbaum wandert in den Papierkorb (`~/.Trash/<ordnername> <datum uhrzeit>`), nicht endgültig gelöscht (F173). An seiner Stelle legt AIBOS einen **Platzhalter** an: einen Ordner mit demselben Namen, damit Ausschluss, Pfade und `status` gültig bleiben, mit zwei Dateien (F166):

- `DETACHED.md`: was ausgelagert ist, seit wann, die Repos mit URL, und wie man es zurückholt (`/aibos-attach <pfad>` im Chat, `aibos --workspace attach <pfad>` im Terminal);
- `DETACHED.command`: ausführbar; ein Doppelklick im Finder öffnet das Terminal und ruft `~/.aibos/bin/aibos --workspace attach <pfad>` auf, den Pfad aus dem eigenen Ort bestimmt; das Terminal zeigt den Plan und fragt (F167). Nur unter macOS; auf anderen Systemen steht der Befehl in `DETACHED.md`.

Dazu ein Eintrag in `workspace.local.yaml`.

**Zurückholen:** `aibos --workspace attach <pfad>` für einen Pfad aus `removed` nimmt das Projekt wieder auf (*remove*). Sonst prüft es, dass `<pfad>` in `workspace.local.yaml` steht und der Ordner nur den Platzhalter enthält, entfernt den Platzhalter, klont das Projekt und seine Unterprojekte aus `workspace.yaml` (Eltern vor Kindern), führt für sie die Schritte 3 und 4 von `sync` aus und entfernt den Eintrag.

**Workspace lösen:** `aibos --workspace detach` an der Vault-Root bzw. mit ihrem Pfad prüft wie oben alle Repos des Workspace einschließlich der Vault-Root und legt danach den Vault-Ordner in den Papierkorb (F174). Installation, Hooks und andere Vaults bleiben.

#### remove — aus dem Workspace entfernen

`aibos --workspace remove <pfad>` entfernt ein Projekt mit allen Unterprojekten aus dem Workspace, auf diesem und auf jedem anderen Rechner (V0.6, Memos 204, 205: F231; Memo 226: FG20, F239–F243). Das Repo am Remote bleibt; AIBOS löscht nie ein Remote. `<pfad>` ist ein Projekt aus `workspace.yaml`; einen Pfad muss man nennen.

1. **Ziel:** Die Vault-Root lässt sich nicht entfernen; dafür gibt es `detach` (Workspace lösen). Ein ausgelagerter Teilbaum lässt sich entfernen: Statt des Teilbaums kommt der Platzhalter in den Papierkorb, und der Eintrag in `workspace.local.yaml` entfällt (F240).
2. **Prüfung** wie bei `detach` (*Prüfung*, F165) für jedes Repo im Teilbaum. Verletzt ein Repo eine Bedingung, nennt der Plan jedes Hindernis mit Pfad, und `remove` ändert nichts; der Bericht schlägt `sync` vor.
3. **Ordner:** Der Teilbaum wandert in den Papierkorb (`~/.Trash/<ordnername> <datum uhrzeit>`), ohne Platzhalter. Die Zeile `/<pfad>/` in der `.gitignore` des Repos darüber bleibt, damit ein Ordner, der auf einem anderen Rechner noch liegt, dort nicht ins Repo darüber gesichert wird. `aibos --integrity` meldet sie deshalb nicht als verwaist, solange der Pfad in `removed` steht (Spec 05, *Integrität*; V0.7, Memo 76).
4. **Manifest:** Die Einträge des Projekts und aller Unterprojekte wandern von `projects` nach `removed` (mit `since`); AIBOS committet im Wurzelprojekt nur `workspace.yaml` („AIBOS: <pfad> aus dem Workspace entfernt"). `remove` pusht nicht; das tut der nächste `sync` (F239). `remove` und `attach <pfad>` schreiben die `workspace.yaml` dabei neu; Kommentare darin bleiben nicht erhalten (F257).

Der Plan zeigt Prüfung, Papierkorb und Commit; ein Ja. **Andere Rechner** übernehmen das Entfernen beim nächsten `sync` (*sync*, Schritt 1); der Hook beim Start entfernt nichts (Spec 02, *Hooks*).

**Wieder aufnehmen:** `aibos --workspace attach <pfad>` für einen Pfad aus `removed` verschiebt die Einträge des Pfads und seiner Unterprojekte zurück nach `projects` (ohne `since`), committet `workspace.yaml` („AIBOS: <pfad> wieder in den Workspace aufgenommen") und klont wie *sync*, Schritte 1, 3 und 4. Liegt der Ordner noch da, wird nur das Manifest geändert (F242).

#### status

`aibos --workspace status [<pfad>]` zeigt eine Tabelle wie `aibos --integrity` (Spec 05), mit dem Zustand `detached` für ausgelagerte Teilbäume (F169), dem Zustand `removed` für Pfade aus `removed`, deren Ordner auf diesem Rechner noch liegt (F243), und mit den Hinweisen aus *sync*, Schritt 5 (Repos ohne Eintrag, ohne Remote, ohne Upstream). Grundlage ist der lokale Stand ohne `git fetch`.

```
Workspace AIBOS — 2026-11-05

Project              Path                    Branch  Revision  Remote    Changes
AIBOS-A-AIOS          A-AIOS                  main    ok        ok        ok
AIBOS-AA-AIbex-AIOS   A-AIOS/AA-AIbex-AIOS    main    ok        2 ahead   ok
AIBOS-Y-Youtube       Y-Youtube               —       detached  —         —

Notes
- B-Basics: no remote; suggested: gh repo create aibex-aibos/AIBOS-B-Basics --private --source B-Basics --remote origin --push
- C-Clients: no upstream; git -C C-Clients push -u origin main
```

**Freeze** schreibt in `lock.yaml` des Wurzelprojekts den Abschnitt `workspace:` mit `<name>: <commit-sha>` je geklontem Projekt; der Abschnitt `packages:` bleibt, und `aibos --fetch` lässt `workspace:` stehen.

## Rückfluss — `aibos --contribute`

Ein Rückfluss bringt Dateien von der Anwender-Site zurück in ein Paket-Repo seines Hubs (V0.4, Memo 11). Er ist kein Modul.

`aibos --contribute <datei>… --to <paket> [--message <text>]`:

1. Paket aus `lock.yaml` der Kette bestimmen (Hub und Repo), `gh` und Anmeldung prüfen; ohne Zugang: Meldung, nichts anlegen.
2. Plan: Repo, Zweig `contrib/<gh-user>/<datum>-<kurzname>`, Ziel `contrib/<gh-user>/<dateiname>`, Titel des Pull Requests.
3. Nach Ja: Repo in ein temporäres Verzeichnis klonen (bei fehlenden Schreibrechten einen Fork), Zweig anlegen, Dateien kopieren, committen, pushen und mit `gh pr create` den Pull Request gegen den Standardzweig anlegen. Ausgabe: URL des Pull Requests.

Jeder Beitrag bekommt einen eigenen Zweig und einen eigenen Pull Request; gibt es den Zweig schon, hängt AIBOS `-2`, `-3` … an. Im neuen Zweig ersetzt die Datei `contrib/<gh-user>/<dateiname>` eine frühere desselben Namens; den Verlauf hält Git. Der Pull Request heißt „Beitrag: <dateiname> von <gh-user>" (oder `--message`) und nennt im Text das Paket, die geholte Version und den Commit aus `lock.yaml` (V0.4, Memo 55). Ohne Schreibrechte (`gh api repos/<owner>/<repo>` ohne `permissions.push`) legt AIBOS mit `gh repo fork` einen Fork an und pusht den Zweig dorthin.

Der Maintainer prüft und übernimmt den Beitrag in den Inhalt des Pakets, beim Taschenrechner nach `knowledge/@!Funktionstasten/` (unten), und taggt eine neue Version. Mit `aibos --fetch --upgrade` kommt er zu anderen Usern (V0.4, Memo 19, L3). Wird ein Beitrag als eigenes Paket veröffentlicht (z. B. `type: knowledge`), ist er ein Paket, aber kein Modul (V0.4, Memo 11).

**Tests:** `gh` wird nicht umgelenkt. Die Tests legen eine Attrappe für `gh` in den `PATH` des Sandkastens, Zweig und Push gehen in einen Hub unter `file://` (V0.4, Memo 19, L4).

## Demo-App Taschenrechner

Paket `app-taschenrechner` (`type: app`) im Repo `aibex-aibos/app-taschenrechner`, Version `0.4.2` (Funktionstasten statt Kacheln, V0.4, Memo 54; README mit *LEARN* in 0.4.1, Memo 61; Hinweis zum Speichern im Chat in 0.4.2, Memo 67; ältere Versionen 0.1.x–0.3.x bleiben im Hub). Ein programmierbarer Taschenrechner mit umgekehrter polnischer Notation nach dem Vorbild des HP-15C. Er zeigt Holen, Version, Abgleich und Rückfluss (V0.4, Memos 01, 05, 51).

| Element | Inhalt |
|---|---|
| Skill `taschenrechner-gui` | Oberfläche (`gui.yaml`) mit einem HTML-Teil `rechner.html` |
| Skill `taschenrechner` | speichert, liest und listet Funktionstasten in `@Data/app-taschenrechner/funktionstasten.yaml`; bietet mitgelieferte Funktionstasten an |
| `knowledge` | `knowledge/@!Funktionstasten/<name>.yaml`: mitgelieferte Funktionstasten, verborgen (Spec 02), also nicht im Kontext |
| Tasten | vier Funktionstasten `A`–`D`; `7 8 9 ÷`, `4 5 6 ×`, `1 2 3 −`, `0 . CHS +`; unten **LEARN** und **ENTER**, je doppelt breit. Kein `=` und kein `C` (V0.4, Memo 51) |
| Stack | vier Register X, Y, Z, T mit Stack-Lift wie beim HP-15C: eine neue Zahl schiebt den Stack hoch, ENTER kopiert X nach Y und die nächste Zahl überschreibt X, eine Rechnung verknüpft Y mit X (Ergebnis in X, der Stack rückt nach, T bleibt), CHS wechselt das Vorzeichen. Quadrat: `ENTER ×`. Anzeige: X groß, Y klein darüber |
| LEARN | erster Druck startet die Aufnahme der folgenden Tasten, zweiter Druck beendet sie; die nächste gedrückte Funktionstaste übernimmt die Folge |
| Funktionstaste | beendet eine laufende Zahleneingabe und spielt dann ihre Tastenfolge ab, als würde sie getippt (`100` und *plus 19 %* ergibt 119) |
| Speichern | Der HTML-Teil kann keine Dateien schreiben. Nach dem Belegen einer Funktionstaste sendet er mit `sendPrompt` eine Nachricht an Claude, die den Skill `taschenrechner` aufruft und die Belegung speichert (Spec 01, I7: Claude zeigt, was gespeichert wird). Beim Öffnen setzt `aibos --gui --skill taschenrechner-gui --html` die Datei über den Platzhalter `{{aibos-data funktionstasten.yaml}}` in den HTML-Teil ein (Spec 03) |
| Mitgeliefert | Der Skill `taschenrechner` zeigt die Funktionstasten aus `knowledge/@!Funktionstasten/` als „mitgeliefert" und übernimmt eine davon auf Wunsch in `@Data/app-taschenrechner/funktionstasten.yaml` (V0.4, Memo 19, L3) |
| Rückfluss | `aibos --contribute @Data/app-taschenrechner/funktionstasten.yaml --to app-taschenrechner` |

`funktionstasten.yaml`:

```yaml
A:
  title: Quadrat
  keys: ["ENTER", "×"]
B:
  title: plus 19 %
  keys: ["1", ".", "1", "9", "×"]
```

## Invarianten der Pakete

Zusätzlich zu Spec 01 (I1–I9):

| # | Regel |
|---|---|
| P1 | AIBOS schreibt in `@!Package/` nur mit `aibos --fetch` und nur ganze Paketordner mit Marke. |
| P2 | `lock.yaml` schreiben nur `aibos --fetch`, `aibos --install` (Distribution), `aibos --activate` (Umstellung) und `aibos --workspace freeze`. |
| P3 | Skripte und Installationen eines Pakets (setup und remove von Arbeitspferden, Befehle) laufen nie ohne Bestätigung, außer `aibos --run` mit einem Befehl, den der User selbst aufruft; der Plan zeigt bei `kind: python` die Pakete, bei Skripten den Inhalt (Spec 07). |
| P4 | `aibos --workspace` ändert nie die Geschichte (kein Rebase, kein Zurücksetzen eines Zweigs) und verwirft nie Änderungen: `sync` sichert sie (Drive-Modell, Memo 204), `restore` legt Überschriebenes vorher in den Papierkorb. Es pusht nur den ausgecheckten Zweig, nie Tags, nie mit `--force`, und nie ein Repo mit Geheimnissen in den ausgehenden Commits. `detach` entfernt nur nach der Prüfung und nur in den Papierkorb. |
| P5 | `aibos --contribute` schreibt nur in einen neuen Zweig; es pusht nie auf den Standardzweig. |
| P6 | `@Data/<paket>/` wird von keinem Befehl außer dem Paket selbst geändert; `--remove` lässt ihn stehen. Das Postfach `@/@!Ticket/` (und bis 0.8 `@/@!Improve/`) liest AIBOS nur; es schreibt, verschiebt und löscht dort nichts. |
| P7 | `aibos --deploy` kopiert nichts; es ändert nur `only` in `packages:`. |
| P8 | Ein Plan mit „alles oder nichts" legt vor dem ersten Schreiben eine Sicherung unter `.aibos/backup/` an und löscht sie erst nach Erfolg (Spec 01, I11). |

## Entschiedene Festlegungen

Die beim Schreiben getroffenen Festlegungen sind entschieden: S1–S9 in V0.4, Memo 17 (S9 als „jedes Projekt ist in sich vollständig"), L1–L6 und Q1–Q7 in den Memos 18–20, Hubs und Hub-Liste in den Memos 21, 22, 25 und 26, holen und ausrollen mit H1–H5 in den Memos 23–26, die Wissenspakete in Memo 27. Für v0.5: Arbeitspferde und Paket laden in V0.5, Memos 15–22 und 28–33, Distributionen in den Memos 25–28 und 34, Paketnamen und Umstellung in den Memos 05, 30 und 35, `@Data/` in Memo 07, Skizze in Memo 37. Für v0.6.4: Workspaces mit attach, sync, detach, Namensschema, `workspace.local.yaml` und Schlüssel `sync:` in V0.6, Memos 163–174 (F155–F189), Skizze in Memo 171.

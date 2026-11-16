---
title: "AIbex AIBOS v0.7 — Überblick"
date: 2026-11-16
author: iHux
status: Spec
tags: [spec, aibos, v0.7]
number: 01
related:
  - "Spec 02 Master-Kontext"
  - "Spec 03 Skills und Assistenten"
  - "Spec 04 Installation und Konfiguration"
  - "Spec 05 Projekte"
  - "Spec 06 Pakete und Workspaces"
  - "Spec 07 Arbeitspferde"
  - "Memo 12 Umfang von AIOS v0.1.0 — Entscheidungen vor der Spec (AA-AIbex-AIOS, @Memo/V0.1)"
  - "Memo 13 Umfang von v0.2, Memos 01–12 nach V0.3 (AA-AIbex-AIOS, @Memo/V0.2)"
  - "Memo 13 Herkunft der Memos und Begriffe von v0.2 (AA-AIbex-AIOS, @Memo/V0.3)"
  - "Memos 22–28 (AA-AIbex-AIOS, @Memo/V0.3)"
  - "Memos 01–29 (AA-AIbex-AIOS, @Memo/V0.4)"
  - "Memos 01–41 (AA-AIbex-AIOS, @Memo/V0.5), Soll-Bild Memo 36, Skizze Memo 37"
  - "Memos 01–36 (AA-AIbex-AIOS, @Memo/V0.6), Soll-Bild Memo 34, Skizze Memo 35"
  - "Memos 79–84 (AA-AIbex-AIOS, @Memo/V0.6), v0.6.1, Skizze Memo 84"
  - "Memos 01–15 (AA-AIbex-AIOS, @Memo/V0.7), v0.7: Soll-Bild Memo 13, Skizze Memo 14"
---

# AIbex AIBOS v0.7 — Überblick

## Definition

**AIbex AIBOS ist ein Betriebssystem für den Kontext von KI-Assistenten.** Es verwaltet, welches Wissen ein Chat lädt, bei Bedarf liest oder nicht sieht, und stellt dafür Dateisystem-Konventionen, Assistenten und Skills bereit. Die Ausführung übernimmt ein Host (in v0.7: Claude Code).

**AIBOS** ist die Kurzform von AIbex AIBOS. Bis v0.6.6 hieß das Produkt AIbex AIOS, mit Befehl `aios`, Ordner `~/.aios`, Schlüssel `aios:`, Organisation `aibex-aios` auf GitHub; ab v0.7.0 tragen alle Namen „aibos" (V0.7, Memos 02–05, 13). Die alten Namen gelten während 0.7.x als Übergang weiter und fallen mit 0.8 weg (*Vorabversionen*; Spec 04, *Umstieg auf v0.7*).

AIBOS hat keinen Kernel im Sinne eines Betriebssystems, kein Scheduling und keine Prozessisolation. Sessions, Modellaufrufe und Werkzeuge stellt der Host bereit. AIBOS setzt darauf auf, mit Konventionen im Dateisystem, Hooks, Skills und einem Installer. *Kernel* heißt in AIBOS das Grundpaket `aibos` mit CLI, Hooks und Kernel-Skills (Spec 04, 06).

| Betriebssystem | AIBOS |
|---|---|
| Dateisystem | Vault mit `§`-Wurzel und Verzeichnisbaum |
| Speicherverwaltung | Klassen *Laden* (resident), *Verfügbar* (bei Bedarf eingelesen), *Verborgen* (nicht eingeblendet) |
| Adressraum eines Prozesses | Master-Space-Kette: der Kontext, den ein Chat sieht |
| Programm starten | Chat mit dem Assistenten des Projekts beginnen |
| Treiber | Registrierung der Skills beim Host |
| Paketverwaltung | Pakete aus Hubs laden und ausrollen, `/aibos-package` (Spec 06) |
| Systemprogramme | Arbeitspferde, je Version installiert, aktiviert über `lock.yaml` (Spec 07) |
| Distribution | Kernel und Pakete in einer geprüften Zusammenstellung, `aibos --install` (Spec 06) |
| Boot | SessionStart-Hook |
| Dateisystemprüfung (`fsck`) | Konsistenzprüfung beim Start, `/aibos-integrity` |

## Diese Spec

Die Spec v0.7 besteht aus sieben Dokumenten, die sich nicht wiederholen:

| Spec | Inhalt |
|---|---|
| **01 Überblick** (dieses Dokument) | Definition, Begriffe, Grundregeln, Umfang, Vorabversionen, Invarianten, Abnahmetest, offene Punkte |
| **02 Master-Kontext** | Vault, Projekt und Kette, Arten von Vaults, Klassen, Block der Kernel-Skills, `aibos --context`, Hooks (mit Assistent, Konsistenzprüfung und Freigabe), `/aibos-context`, Legacy-Modus |
| **03 Skills und Assistenten** | Arten von Skills, Versionen, Ausführungsmodell, Auslösen der Kernel-Skills, `/aibos-distribution`, `/aibos-register`, Assistenten und ihre Zuordnung, `/aibos-assistant`, Oberflächen (`/aibos-gui`, `/gui`), `/aibos-memo` |
| **04 Installation und Konfiguration** | Dateistrukturen, Formate, CLI `aibos`, Versionen und Aktivierung, Weiterleiter, Installieren von Distributionen, Umstieg |
| **05 Projekte** | Struktur und Name eines Projekts, `/aibos-init`, Konsistenzprüfung, `/aibos-integrity`, `/aibos-status` |
| **06 Pakete und Workspaces** | Paket-Manifest, Versionen und Bereiche, Hubs und Hub-Liste, Resolver, Paket laden (`aibos --fetch`), ausrollen (`aibos --deploy`), Distributionen, Lock, `@Data/`, Workspaces, Rückfluss, Demo-App Taschenrechner |
| **07 Arbeitspferde** | Definition, Pakete `worker-<name>`, Installation je Version, Aktivierung über `lock.yaml`, Weiterleiter, Abläufe, `aibos --worker`, Tests |

Die Begründungen stehen in den Memos der Konzeptprojekte unter `§AIBOS/A-AIOS/AA-AIbex-AIOS/`: `@Memo/V0.1/` für die Grundlage, `@Memo/V0.2/` (Memos 13–18) für die Änderungen in v0.2, `@Memo/V0.3/` (Memos 01–28) für die Änderungen in v0.3, `@Memo/V0.4/` (Memos 01–29) für die Änderungen in v0.4, `@Memo/V0.5/` (Memos 11–41, Soll-Bild Memo 36) für die Änderungen in v0.5, dort auch die Memos 70–86 für v0.5.1, `@Memo/V0.6/` (Memos 01–36, Soll-Bild Memo 34, Skizze Memo 35) für die Änderungen in v0.6, dort auch die Memos 79–84 (Bewertung Memo 79, Skizze Memo 84) für v0.6.1 die Memos 114–123 (Bewertung Memo 118, Soll-Bild und Skizze Memo 122) für v0.6.2 die Memos 152–154 (Bewertung und Skizze Memo 153) für v0.6.3, die Memos 163–174 (Bewertung Memo 164, Skizze Memo 171) für v0.6.4, die Memos 218–220 für v0.6.5 und die Memos 221–227 für v0.6.6; `@Memo/V0.7/` (Memos 01–15, Soll-Bild Memo 13, Skizze Memo 14) für die Umbenennung in v0.7. In den Memos 01–11 von V0.3 heißt der Assistent noch *Agent* (V0.3, Memo 13). Die Spec beschreibt nur den Soll-Stand. Sie wird im Repo `aibex-aibos` unter `spec/` gepflegt und mit jeder Version nach `doc/spec/` ausgeliefert.

## Begriffe

| Begriff | Bedeutung |
|---|---|
| **AIBOS** | AIbex AIBOS; bis v0.6.6 AIbex AIOS |
| **Vault** | ein Ordner, dessen Name mit `§` beginnt (z. B. `§Demo`), mit allem darunter; in der Regel ein Obsidian-Vault. Ein Vault hat eine Bindung an AIBOS oder nicht |
| **Vault-Root** | das `§`-Verzeichnis selbst; der einzige Ort einer Bindung (`aibos:`) oder Markierung (`legacy:`) |
| **AIBOS-Workspace (A/W)** | ein Vault, dessen `<vault>/.aibos/config.yaml` eine Bindung `aibos:` an eine Version ≥ 0.7.0 enthält, oder ein Vault mit Altbindung (V0.6, Memo 14; V0.7, Memo 05) |
| **Arbeitsverzeichnis** | das `cwd`, das der Host den Hooks bei jedem Prompt mitgibt (V0.6, Memos 13, 31) |
| **AIBOS-Verhalten** | AIBOS beeinflusst den Kontext der KI: Master-Kontext, Kernel-Skills, Assistent, Freigabe von Befehlen (Spec 02) |
| **Masterspace** | ein Verzeichnis namens `@`; Container von Unterverzeichnissen je einer Klasse |
| **Projekt** | jeder Ordner mit `@/`, auch die Vault-Root; die Vault-Root mit `@/` ist das **Root-Projekt** |
| **Unterprojekt** | ein Projekt unterhalb eines anderen Projekts, auch durch Container hindurch |
| **Container** | Ordner ohne `@/`; gliedert nur, trägt keinen Kontext bei und hat kein eigenes Repo; eine Vault-Root ohne `@/` ist ebenfalls ein Container. Ausnahme ist ein Fremd-Repo |
| **Root-Masterspace** | `@/` der Vault-Root |
| **lokaler Masterspace** | `@/` des Projekts, in dem ein Chat läuft |
| **Master-Space-Kette** | die Masterspaces aller Projekte vom Projekt des Chats aufwärts bis zum Root-Projekt |
| **Master-Kontext** | der geladene Teil der Master-Space-Kette: alles, was beim Chatbeginn in den Kontext des Hosts gelangt, einschließlich des Inhaltsverzeichnisses des verfügbaren Wissens und des Blocks der Kernel-Skills |
| **verfügbares Wissen** | die Dateien der Klasse *Verfügbar* in der Kette; gehört nicht zum Master-Kontext, das Modell liest sie bei Bedarf |
| **Klasse** | *Laden* (`@…`), *Verfügbar* (`@@…`), *Verborgen* (`@!…`); steht im Namen eines Unterverzeichnisses eines Masterspace |
| **Blueprint** | Beschreibung eines Skills, Prompts oder Assistenten in einem verborgenen Verzeichnis (`@!Skill`, `@!Prompt`, `@!Assistant`) |
| **Build-Output** | aus Blueprints erzeugte Dateien für den Host (z. B. `.claude/skills/`); nie Quelle, jederzeit neu erzeugbar |
| **Kernel-Skill** | Skill, der zum Kernel selbst gehört (Präfix `aibos-`); im A/W an der Vault-Root und in jedem Projekt als dünne Hülle registriert und im Master-Kontext aufgeführt (Spec 03). Bis v0.6.6 hieß er `aios-<name>`, bis v0.5 *AIOS-Skill* und war global registriert |
| **Projekt-Skill** | Skill aus `@!Skill` der Kette, projektlokal registriert |
| **Assistent** | eine Rolle, die AIBOS dem KI-Assistenten des Hosts gibt: Bündel aus Rollentext, Prompt, Skills, Oberfläche, Wünschen an Modell und Werkzeuge und eigenem Wissen in `@!Assistant/<name>/`. Wie der Host ihn umsetzt, regelt die Abbildung je Host (Spec 03) |
| **Zuordnung** | der Assistent eines Projekts: `assistant:` in `.aibos/config.yaml` mit dem Wert `<name>`, `none` oder `inherit` (Spec 03) |
| **Assistent der Session** | der Assistent, mit dem eine Session begonnen hat oder auf den sie mit `/aibos-assistant` gewechselt hat; gilt bis zum Ende der Session, solange ihr Arbeitsverzeichnis dasselbe ist wie bei der Zuordnung (Spec 02) |
| **Oberfläche** | Startseite eines Assistenten (`/gui`) bzw. von AIBOS (`/aibos-gui`): Kacheln mit Text und Prompt, in der Desktop-App als HTML, in der CLI als Menü (Spec 03) |
| **Paket** | versionierte Einheit mit `manifest.yaml`, in einem eigenen Repo eines Hubs, Versionen als Tags `v<version>` (Spec 06) |
| **Element** | Teil eines Pakets, der in einem Projekt wirkt: Skill, Assistent, Wissen, Befehl |
| **Kernel** | das Grundpaket `aibos` mit CLI, Hooks und Kernel-Skills; wird installiert, nicht geholt (Spec 04) |
| **Modul** | Paket, nach dessen Holen AIBOS etwas Neues kann (Kernel, App, Assistent, Skill, Arbeitspferd) |
| **App** | Modul, das der Anwender direkt benutzt (Oberfläche, Befehle, Skills) |
| **Distribution** | Paket, das optional einen Kernel und Pakete in exakten Versionen zusammenstellt; wird installiert (Spec 06) |
| **Arbeitspferd** | Programm, das ausgeführt wird, auf dem Rechner wohnt und vor Ort gebaut wird (K1–K3); Paket vom Typ `worker` (Spec 07) |
| **Werkzeug**, **Dienst** | Arbeitspferd, das nur während eines Aufrufs läuft bzw. dauerhaft läuft; Dienste sind in v0.7 nicht umgesetzt (Spec 07) |
| **Paket laden** | für den User ein Vorgang mit einem Plan und einem Ja: holen, Arbeitspferde einrichten, registrieren (Spec 06) |
| **setup**, **remove** | eine Version eines Arbeitspferds einrichten bzw. abbauen (Spec 07) |
| **Hub** | Ort mit Paket-Repos: Name und Basis-URL; bei GitHub ist der Name der Owner (z. B. `aibex-aibos`). Ein Paket liegt dort als Repo `<basis>/<paket>`, voller Paketname `<hub>/<paket>` (Spec 06) |
| **Hub-Liste** | die Hubs, in denen AIBOS einen Paketnamen ohne Hub sucht, in Suchreihenfolge (`hubs:`, Spec 04, 06) |
| **holen** (fetch) | eine Version eines Pakets ganz vom Hub nach `@!Package/` eines Projekts bringen (`aibos --fetch`) |
| **ausrollen** (deploy) | festlegen, welche Elemente eines geholten Pakets im Projekt wirken (`aibos --deploy`) |
| **registrieren** | Kernel-Skills und ausgerollte Skills dem Host bekannt machen (`.claude/skills/`, Spec 03) |
| **Anwender-Site** | Vault mit Paketen als Kopie in `@!Package/` |
| **Entwickler-Site** | Workspace mit Paketen als Git-Checkout |
| **Workspace** | Projekt mit `.aibos/workspace.yaml`, das Repos mit Revision und Pfad nennt (Spec 06); nicht zu verwechseln mit dem AIBOS-Workspace |
| **Lokal-Drive**, **Cloud-Drive**, **AIBOS-Drive**, **Netz-Drive** | die vier Arten, einen A/W über Rechner zu führen: nur auf diesem Rechner; repliziert von einem Cloud-Dienst (Vault-Root in einem Cloud-Ordner); abgeglichen von AIBOS über Git-Remotes (`workspace.yaml`); eine einzige Kopie auf einem Netzlaufwerk (Spec 06, *Arten der Führung*; V0.6, Memo 224) |
| **Fremd-Repo** | Repo eines Workspace ohne `@/`, z. B. ein Paket-Repo; kein Projekt und kein Container (Spec 06) |
| **Lock** | `.aibos/lock.yaml`: aufgelöste Pakete und eingefrorener Stand eines Workspace |
| **Demo-Assistent** | Assistent als Paket zum Ausprobieren und für Tutorials (`assistant-gaertner`, `assistant-astronom`) |
| **Paket-Skill** | ausgerollter Skill aus einem geholten Paket in `@!Package/` |
| **lokaler Skill** | Skill, der im Projekt selbst geschrieben wurde (`@!Skill/`) und aus keinem Paket stammt |
| **Struktur eines Projekts** | was ein Projekt nach `aibos --init` hat: `@/`, eigenes Repo, `.gitignore`, Ausschluss im Repo darüber (Spec 05) |
| **integer** | ein Projekt, dessen Struktur vollständig und dessen Repo vollständig committet ist (Spec 05) |
| **Host** | das Programm, das die Session ausführt; in v0.7 nur Claude Code |
| **Installation** | eine Version des Kernels (`~/.aibos/versions/v<version>/`, auf ausdrücklichen Wunsch `/opt/aibos/v<version>/`) oder eines Arbeitspferds (`~/.aibos/workers/<paket>/v<version>/` bzw. `/opt/aibos/workers/…`) auf dem Rechner; Versionen liegen nebeneinander. *Installieren* gilt für Kernel, Arbeitspferde und Distributionen (Spec 04) |
| **Aktivierung** | Bindung eines Vaults an eine installierte Version: Kernel über `aibos:` in `<vault>/.aibos/config.yaml`, nur an der Vault-Root; Arbeitspferd über `lock.yaml` |
| **Altbindung** | Bindung eines Vaults mit dem alten Schlüssel `aios:` in `<vault>/.aios/config.yaml` an eine Version 0.6.x; der Vault läuft mit dem Kernel dieser Version weiter, bis er mit `aibos --activate v0.7.<n>` umgebunden wird (Spec 04, *Umstieg auf v0.7*). Bindungen unter 0.6.0 unterstützt v0.7 nicht mehr |
| **Legacy-Modus** | Verhalten eines Vaults mit der Markierung `legacy: ai-brain`: Den Kontext liefert `ai-brain` wie vor AIBOS; kein A/W (Spec 02) |
| **Weiterleiter** | Programm ohne eigene Logik, das die gültige Version bestimmt und deren Programm aufruft: `~/.aibos/bin/aibos` für den Kernel, `~/.aibos/bin/<programm>` für Arbeitspferde |

## Grundregeln

1. **Der Pfad liefert den Projektkontext, der Assistent die Persönlichkeit und die Auswahl von Skills und Wissen.**
2. **Chat-Verzeichnis = Projektverzeichnis.** Innerhalb eines A/W läuft ein Chat immer in einem Projekt; ein Ordner ohne `@/` wird initialisiert oder verlassen (Spec 02).
3. **Der nächstgelegene Eintrag gewinnt**: bei Blueprints entlang der Kette und bei Schlüsseln der Konfiguration, auch bei der Zuordnung des Assistenten. Ausgenommen sind `aibos:` und `legacy:`, die nur an der Vault-Root gelten.
4. **Blueprint ist Quelle, Build-Output ist abgeleitet.**
5. **Installieren und Aktivieren sind getrennt**: Installieren bringt eine Version auf den Rechner, Aktivieren bindet einen Vault an sie. Eine Distribution tut beides in einem Plan.
6. **AIBOS ist pro Vault eingeschaltet**: AIBOS-Verhalten gibt es genau dann, wenn das Arbeitsverzeichnis in einem A/W liegt. Außerhalb bekommt die KI denselben Kontext, als wäre AIBOS nicht installiert; die Hooks laufen und enden ohne Ausgabe (V0.6, Memos 12, 13).
7. **Jedes Paket, jeder Skill und jeder Assistent hat eine Version** (Semver `MAJOR.MINOR.PATCH`, Spec 03, 06).
8. **Der Assistent ist eine Eigenschaft des Projekts**: Er gilt für alle User gleich; es gibt keine persönliche Zuordnung und keine Aktivierung nur für einen Chat (Spec 03).
9. **Jedes Projekt hat ein eigenes Git-Repo**, auch das Root-Projekt und jedes Unterprojekt; das Repo darüber schließt es aus (Spec 05).
10. **Das Arbeitsverzeichnis entscheidet allein**, welche Bausteine aktiv sind (Master-Kontext, Kernel-Skills, Assistent, Freigabe), von Prompt zu Prompt. Bei einem Wechsel des Arbeitsverzeichnisses wandert nichts mit; was die Session vorher geladen hat, bleibt in ihrem Verlauf (V0.6, Memo 33).
11. **AIBOS schreibt nur in drei Bereiche**: a) `~/.aibos`, b) das Innere von Vaults, c) die Hook-Einträge in der Einrichtung des Hosts (`~/.claude/settings.json`). Nach `/opt/aibos` nur auf ausdrücklichen Wunsch (V0.6, Memo 14, K3, K4).

## Umfang von v0.7

v0.7.0 baut auf v0.6.6 auf und **benennt AIbex AIOS in AIbex AIBOS um** (V0.7, Memos 01–15). Neue Funktion kommt nur mit B40, B41, H48 und H49. Alles aus v0.6.6, das hier nicht geändert wird, gilt weiter; der Umfang der Versionen v0.6.0–v0.6.6 steht in dieser Spec im Tag `v0.6.6`.

| in v0.7.0 | Memos |
|---|---|
| Name AIbex AIBOS in Spec, Doku, Meldungen und `NOTICE` | 02 (F261) |
| Organisation `aibex-aibos`, Repos `aibex-aibos`, `aibos-index`, `aibos-installer`; Topics `aibos-core`, `aibos-package`, die alten zusätzlich bis 0.8 (Spec 06) | 03, 09 (F264–F266, F279–F281) |
| Rechner: `~/.aibos/`, `/opt/aibos/`, Verweis `~/.aios`; Befehl `aibos` mit Alias `aios`; Variablen `AIBOS_*`, `AIOS_*` als Ausweich; Hooks auf `~/.aibos/bin/aibos` (Spec 04) | 04 (F267–F269) |
| Vaults: `.aibos/`, Schlüssel `aibos:` und `requires.aibos`, Kernel-Skills `aibos-*`, Marken `<aibos-…>` und `AIBOS-…` (Spec 02–06) | 05 (F270–F272) |
| Umstieg: installieren, dann je Vault umbinden; Remotes und Hub-Namen werden umgeschrieben (Spec 04, *Umstieg auf v0.7*) | 07, 09, 15 (F276, F281, FL7) |
| Pakete: Bereiche gelten streng; 19 Pakete in einer Minor-Version mit `requires.aibos: ">=0.7,<0.8"`; Altpakete `assistent-*` archiviert (Spec 06) | 06, 10, 15 (F273, F283–F286, F295) |
| `aibos-installer` 0.2.0, neue Version von `distribution-capricorn` | 07 (F277) |
| `sync`: Gleichheit von Remote-Adressen (B40), erster Push mit Upstream (B41), Hinweis bei einem Projekt ohne Remote (H48) (Spec 06) | 07 (F278) |
| `tests/run` prüft zu Beginn auf PyYAML (H49) | 07, 11 (F290) |

| später | |
|---|---|
| Wegfall des Übergangs: Verweis `~/.aios`, Alias `aios`, `AIOS_*`, Topics `aios-*`, Lesen von `.aios/`, `aios:` und `requires.aios` | 0.8 |
| Workflows, Wissen mit Rohwissen und Fassung | 0.8 und später |
| Wünsche aus V0.99, Memo 19 (Auslagern, Drive für große Dateien, weitere Sync-Dienste, Netz-Drive) | offen |

## Vorabversionen

Alle Versionen unter 1.0 sind Alpha- und Beta-Versionen; an Kunden wird erst ab v1.0 ausgeliefert. Das gilt für AIBOS selbst und für die Pakete der Grundausstattung, die deshalb mit `0.1.0` beginnen (Ausnahme: `memo` behält seine Versionsfolge, 6.0.0).

Vor v1.0 wird keine Migration zwischen Versionen verlangt: Eine neue Version darf Begriffe, Ordnernamen und Formate ändern. Die Versionsbindung hält einen Vault auf seiner Version lauffähig. **Ausnahme v0.7:** Weil die Umbenennung jeden Ordner, Befehl und Schlüssel betrifft, bringt v0.7 einen Umstieg mit (Spec 04, *Umstieg auf v0.7*): Ein Vault mit Altbindung an 0.6.x läuft nach der Installation von v0.7.0 über den Verweis `~/.aios` weiter und wird mit `aibos --activate v0.7.<n>` umgebunden. Die Namen des Übergangs (Verweis `~/.aios`, Alias `aios`, `AIOS_*` als Ausweich, Lesen von `.aios/`, `aios:`, `requires.aios`, `aibex-aios` als gleicher Hub) gelten bis 0.8 (V0.7, Memos 02, 12: F263, F293). Migrierbarkeit wird ab v1.0 angestrebt.

## Invarianten

AIBOS hält diese Regeln in jedem Befehl ein (für Pakete zusätzlich P1–P8, Spec 06, für Arbeitspferde A1–A4, Spec 07):

| # | Regel |
|---|---|
| I1 | AIBOS ändert nie ein bestehendes Memo in `@Memo/`. `/aibos-memo` legt nur neue Memos an. |
| I2 | AIBOS schreibt in einen Masterspace `@/` nur mit `aibos --fetch`, und nur nach `@!Package/<name>/`. Ausnahmen: `aibos --activate` und `aibos --init` legen ein fehlendes `@/` mit `.gitkeep` an; `aibos --activate` benennt beim Umstieg auf v0.7 `.aios/` in `.aibos/` um (Spec 04, *Umstieg auf v0.7*). |
| I3 | AIBOS registriert nie einen Skill global. Kernel-Skills und Projekt-Skills werden nur im Vault registriert, an der Vault-Root und in Projekten (Spec 03). Beim Umstieg entfernt AIBOS die globalen Hüllen früherer Versionen (Spec 04). |
| I4 | AIBOS fasst in Vaults ohne Bindung nichts an und liefert dort keinen Kontext. Ausnahmen sind `aibos --activate`, das die Bindung schreibt, `aibos --install distribution-<name>`, das den Vault an den Kernel der Distribution bindet, der Umstieg, der nach Rückfrage `legacy: ai-brain` einträgt (Spec 04), und `aibos --workspace attach <repo>`, das einen gebundenen Vault aus einem Repo holt (Spec 06); `aibos --fetch`, `aibos --deploy`, `aibos --workspace`, `aibos --init`, `aibos --assistant` und die Registrierung brechen ab bzw. tun nichts. In einem Legacy-Vault liefert `ai-brain` den Kontext. |
| I5 | AIBOS verändert nie eine installierte Version (`v<version>/` oder `workers/<paket>/v<version>/` unter `~/.aibos` bzw. `/opt/aibos`); es entfernt sie nur ganz. |
| I6 | AIBOS fasst in `.claude/skills/` nur Ordner an, die in `.aibos/registry` stehen oder die es beim Registrieren neu anlegt; Ordner, die schon da sind und nicht in der Registry stehen, nie. In `~/.claude/skills/` entfernt der Umstieg nur die Hüllen früherer Versionen (Spec 04). |
| I7 | Jeder schreibende Befehl zeigt vorher, was er tut, und wartet auf Bestätigung. Ausnahmen sind beim Session-Start die Registrierung, der Merker der Session (`~/.aibos/sessions/`), das Log (`~/.aibos/log/`) und im Workspace mit `sync: auto` das Holen und Zusammenführen neuer Stände für das Projekt der Session, nur ohne lokale Änderungen und ohne Konflikt, sodass nichts verloren gehen kann (Spec 02, *Hooks*; V0.6, Memo 174: F189; Memo 204: F230). Ein Skill holt den Plan mit `--plan`, fragt im Chat und ruft erst nach Ja mit `--yes` auf (Spec 04). Prüfungen (Konsistenzprüfung, `/aibos-integrity`) schreiben nie; sie bieten eine Ergänzung nur an. |
| I8 | Jeder Befehl ist idempotent: Ein zweiter Aufruf ohne Änderung ändert nichts. |
| I9 | AIBOS committet nur, was es selbst angelegt oder geändert hat: den ersten Commit eines Projekts (mit den Dateien, die es dabei aus dem Repo darüber übernimmt, Spec 05) den Ausschluss eines Unterprojekts im Repo darüber (Spec 05, Spec 06 *Workspaces*) mit `aibos --workspace sync` die nachgeführte `workspace.yaml` (Spec 06), mit `aibos --workspace remove` und `attach <pfad>` die geänderte `workspace.yaml` (Spec 06, *remove*), dazu mit `aibos --contribute` die genannten Dateien in einem eigenen Zweig eines Paket-Repos (Spec 06). Arbeitsstände des Users committet es nur mit `aibos --workspace sync` nach dem Drive-Modell, nach Plan und Ja bzw. mit `--yes`: das Sichern („AIBOS: gesichert von …", F225) und das Zusammenführen mit Merge-Commit und Konfliktkopien („AIBOS: zusammengeführt auf …", F226, F227); der Hook beim Start führt nur ohne lokale Änderungen zusammen (F230). Sonst committet AIBOS Arbeitsstände des Users nie, auch Hooks und Prüfungen nicht (V0.6, Memo 229). |
| I10 | Ein Weiterleiter oder Skill löst nie ein setup aus; fehlt ein Arbeitspferd, meldet er das und nennt höchstens `aibos --fetch` (Spec 07). |
| I11 | Ein Plan mit „alles oder nichts" (Paket laden, Distribution installieren) stellt bei einem Fehler den Stand vor dem Plan wieder her (Sicherung, Spec 06); registriert wird erst nach erfolgreichem setup. |
| I12 | Liegt das Arbeitsverzeichnis außerhalb eines A/W, geben die Hooks von AIBOS nichts aus und geben keinen Befehl frei; Fehler stehen nur im Log `~/.aibos/log/context.log` (Spec 02). |
| I13 | AIBOS schreibt außerhalb von `~/.aibos` und Vaults nur die eigenen Hook-Einträge in `~/.claude/settings.json` und entfernt beim Umstieg die Hüllen früherer Versionen in `~/.claude/skills/`; es ändert keine Startdateien der Shell und keine Regeln in `permissions`. Beim Umstieg auf v0.7 verschiebt es `~/.aios` nach `~/.aibos` und legt `~/.aios` als Verweis an; dabei bleiben die installierten Versionen unverändert (I5). Nach `/opt/aibos` schreibt es nur mit `aibos --install --system` (Spec 04). |
| I14 | Eine Bindung `aibos:` und eine Markierung `legacy:` gelten nur an der Vault-Root; in einem Projekt werden sie mit Warnung übergangen (Spec 04). |

## Abnahmetest

Der Abnahmetest von v0.7.0 läuft auf dem letzten Kandidaten `v0.7.0-rc<n>` des Kernels und den Kandidaten der Pakete mit derselben Nummer (V0.7, Memos 10, 14: FL1). Die Schritte 2–11 laufen in einem **Probe-Workspace** im Scratchpad: zwei Sandkasten-Rechner A und B (je eigenes `HOME`, `AIBOS_PREFIX`, `AIBOS_CLAUDE_DIR`), ein Vault `§Probe-Umstieg` mit Projekten `PA-Alpha` (mit Unterprojekt `PAA-Kind`) und `PB-Beta`, lokale Bare-Repos unter einem Ordner `…/aibex-aios/` als Remotes (über `AIBOS_GITHUB` bzw. `AIOS_GITHUB` umgelenkt), Test-Hub mit `skill-memo` 6.0.2 und 6.1.0-rc<n>. Schritte im Chat dürfen headless laufen (`claude -p`, Spec 03). Jeder Schritt nach außen hat eine eigene Rückfrage.

| # | Wer, wo | Schritt | erwartet |
|---|---|---|---|
| 1 | Terminal | `tests/run` einmal ohne und einmal mit `python3` samt PyYAML; alle `tests/live/*.sh` | ohne PyYAML eine Zeile und Abbruch (H49); sonst alle grün |
| 2 | Rechner A, B | Kernel 0.6.6 aus dem Tag installieren; `§Probe-Umstieg` auf A anlegen, binden, Projekte mit `aios --init`, Remotes, `aios --fetch skill-memo`; `aios --workspace sync --yes`; auf B `aios --workspace attach <remote der Root> <ordner>` | beide Klone mit allen Projekten auf 0.6.6; `status` ohne Abweichung |
| 3 | Rechner A | `<klon>/bin/aibos --install v0.7.0-rc<n> --plan`, dann `--yes` | Plan nennt Umzug `~/.aios` → `~/.aibos`, Verweis, Weiterleiter `aibos` mit Alias `aios`, drei Hooks; danach ist `~/.aios` ein Verweis, die Hooks rufen `~/.aibos/bin/aibos`; `aios --version` und `aibos --version` antworten |
| 4 | Rechner A | `aibos --activate v0.7.0-rc<n> §Probe-Umstieg --plan`, dann `--yes` | Plan: `.aios/` → `.aibos/` in 4 Projekten, Hüllen `aibos-*` statt `aios-*`, `aibex-aios` → `aibex-aibos` in `workspace.yaml` und `origin`, Paketwechsel `skill-memo` 6.0.2 → 6.1.0-rc<n>, ein Commit je Projekt; danach Bindung `aibos: 0.7.0-rc<n>` |
| 5 | Rechner A, `PA-Alpha` | `aibos --context --session`; PreToolUse mit `~/.aibos/bin/aibos --skill aibos-status`; `AIOS_HUBS=… aibos --library` | `<aibos-context>`, Block mit `aibos-*`; `"allow"`; Hub gelesen, Hinweis auf `AIOS_HUBS` |
| 6 | Rechner A | `aibos --fetch "skill-memo==6.0.2"` | abgelehnt mit `needs a version for AIBOS 0.7.0-rc<n> (requires.aios …)`, nichts geschrieben |
| 7 | Rechner A | `aibos --workspace sync --yes` | Umbenennungen gepusht |
| 8 | Rechner B (0.6.6) | `aios --workspace sync --plan` nach `git pull` von Hand in einem Projekt | Vault gilt als ungebunden, nichts geschrieben |
| 9 | Rechner B | `aibos --install …`; `aibos --activate v0.7.0-rc<n> <vault> --plan`, dann `--yes`; `aibos --workspace sync --yes` | Plan holt zuerst den umgestellten Stand; danach keine doppelten Umbenennungen, `status` ohne Abweichung |
| 10 | Rechner A | `workspace.yaml` mit `git@github.com:…`, `origin` mit `https://github.com/…`; neues Projekt mit `origin` ohne Push; ein Projekt ohne Remote als Projekt der Session; je `sync --plan` | gleiches Repo erkannt (B40); „erster Push von `main`", nach `--yes` mit Upstream (B41); Satz zum fehlenden Remote (H48) |
| 11 | Chat auf A, headless | „/aibos-status", „/aibos-sync"; „/aios-status" | Skills laufen; `/aios-status` gibt es nicht |
| 12 | Terminal | `aibos-installer` 0.2.0: `tests/run`; Lauf B (Terminal) im Sandkasten bis zum Ende | grün; Kernel, Zustimmung und Ergebnis unter `~/.aibos` |
| 13 | iHux, GitHub | je mit Rückfrage: Organisation umbenennen; Repos `aibex-aibos`, `aibos-index`, `aibos-installer`; Topics; dann `git ls-remote https://github.com/aibex-aios/skill-memo` und `gh api orgs/aibex-aios` | Weiterleitung für `git`, 404 für die API |
| 14 | Arbeitsrechner | Bestandslauf mit `aibos --activate v0.7.0-rc<n> <vault> --plan` für jeden Vault aus `aibos --vaults`; dann installieren und `§AIBOS`, `§Hugo` umbinden | keine Konflikte; alle Pakete der Locks in einer Version für 0.7 |
| 15 | neuer Chat in `§AIBOS` | „Wo stehen wir?", `/aibos-sync` | Master-Kontext mit `<aibos-context>`, Plan vor dem Push |
| 16 | Notebook | installieren, `attach` bzw. `sync` des Workspace `§AIBOS` | wie Schritt 9 am echten Workspace |
| 17 | iHux | leere Organisation `aibex-aios` anlegen | Weiterleitungen enden; `git ls-remote` auf eine alte Adresse scheitert |
| 18 | — | Abnahme-Memo | Schritte 1–17 bestanden |
| 19 | nach Freigabe | `VERSION` 0.7.0, Tags `v0.7.0` im Kernel und in den Paketen; veröffentlichen, jeder Schritt mit eigener Rückfrage | Bindung `aibos: 0.7.0` |

Die Abnahmetests von v0.6.6, v0.6.4 (mit zweitem Benutzer und Notebook), v0.6.3, v0.6.2, v0.6.1, v0.6.0 und v0.5 stehen in dieser Spec in den Tags `v0.6.6`, `v0.6.4`, `v0.6.3`, `v0.6.2`, `v0.6.1`, `v0.6.0` bzw. `v0.5.1`.

## Offen

| # | Punkt | vorläufige Festlegung für v0.7 |
|---|---|---|
| O1 | Wirkt `/reload-skills` in einer interaktiven Session auf Skills, die nach dem Start angelegt wurden? | Getestet (V0.1, Memo 16): Ein beim Session-Start angelegter Skill ist erst im nächsten Chat verfügbar; die Registrierung ist darauf ausgelegt (Spec 03). Offen ist nur `/reload-skills` |
| O2 | Detailregeln der Klassen | siehe Spec 02, *Vorläufige Regeln der Klassen* |
| O4 | Stehen HTML-Oberflächen im Chat in jeder Installation der Desktop-App bereit? (V0.3, Memo 10, 25, 31) | Geprüft: in der Desktop-App vorhanden, in Headless-Sessions und der CLI nicht. Ohne HTML-Oberfläche zeigen `/gui` und `/aibos-gui` das Menü der CLI |
| O5 | Löst der Host `~` in `allowed-tools` und im Rumpf einer Hülle auf? (V0.6, Memo 29) | Die Hülle trägt den absoluten Pfad des Weiterleiters, den AIBOS beim Registrieren einsetzt (Spec 03); der Abnahmetest (Schritt 9) prüft es |
| O6 | Wirkt ein Wechsel des Arbeitsverzeichnisses mit `/cd` wie der Wechsel über die Desktop-App, und wie stark wirkt der Verlauf nach dem Verlassen eines A/W nach? (V0.6, Memo 31) | AIBOS gibt nach dem Wechsel nach außen nichts mehr aus (I12); den Verlauf entfernt es nicht |

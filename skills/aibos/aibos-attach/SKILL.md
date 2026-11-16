---
name: aibos-attach
description: Holt einen ausgelagerten Teilbaum eines AIbex-AIBOS-Workspace zurück (klont Projekt und Unterprojekte, macht sie lauffähig). Einen ganzen Workspace an einen neuen Rechner anbinden geht nur im Terminal (aibos --workspace attach <repo>). Verwenden bei "/aibos-attach", "zurückholen", "Teilbaum zurückholen", "attach", nach AIBOS-DETACHED.
allowed-tools: Bash(aibos --workspace *)
---

# Ausgelagerten Teilbaum zurückholen

Ein AIBOS-Skill von AIbex AIBOS (Spec 06, *detach*, Zurückholen; Spec 03, *Workspaces*).

**Arbeitsverzeichnis:** Führe alle Befehle dieses Skills im Arbeitsverzeichnis der Session aus und wechsle nie mit `cd`; AIBOS bestimmt den Workspace aus dem aktuellen Verzeichnis. Andere Orte nur als ausdrücklichen Pfad angeben. Rufe `aibos …` immer als einzelnen Befehl auf, ohne `;`, `&&`, `|`, Umleitung oder vorangestelltes `cd`; nur so gibt AIBOS den Aufruf ohne Rückfrage frei.

## Ablauf

1. **Argument:** der Pfad des ausgelagerten Teilbaums (absolut oder relativ zum Arbeitsverzeichnis). Ist es eine URL eines Repos, sag: Einen Workspace bindet man im Terminal an, mit `~/.aibos/bin/aibos --workspace attach <repo> [<vault-ordner>]`, weil es vorher keinen Vault gibt; beende.
2. **Plan:** `aibos --workspace attach "<pfad>" --plan`. Meldet der Befehl `is not detached` oder `holds more than the placeholder`, nenne das und beende.
3. **Zeigen und fragen:** Plan zeigen (was geklont wird), einmal fragen. Ohne Ja nichts ausführen.
4. **Ausführen:** dasselbe mit `--yes`, Ergebnis kurz melden. Die Skills des zurückgeholten Projekts gelten ab dem nächsten Chat dort.

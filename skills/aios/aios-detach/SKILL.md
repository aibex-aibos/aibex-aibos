---
name: aios-detach
description: Lagert einen Teilbaum eines AIbex-AIOS-Workspace auf diesem Rechner aus (Papierkorb, Platzhalter mit DETACHED.md und DETACHED.command), löst den ganzen Workspace vom Rechner oder entfernt ein Projekt auf allen Rechnern aus dem Workspace (remove) - erst nach der Prüfung, dass nichts verloren geht. Verwenden bei "/aios-detach", "auslagern", "Teilbaum auslagern", "Platz sparen", "Workspace lösen", "detach", "detach project", "detach workspace", "aus dem Workspace entfernen", "nicht mehr im Workspace", "überall entfernen".
allowed-tools: Bash(aios --workspace *)
---

# Teilbaum auslagern, Workspace lösen, Projekt entfernen

Ein AIOS-Skill von AIbex AIOS (Spec 06, *detach* und *remove*; Spec 03, *Workspaces*).

**Arbeitsverzeichnis:** Führe alle Befehle dieses Skills im Arbeitsverzeichnis der Session aus und wechsle nie mit `cd`; AIOS bestimmt den Workspace aus dem aktuellen Verzeichnis. Andere Orte nur als ausdrücklichen Pfad angeben. Rufe `aios …` immer als einzelnen Befehl auf, ohne `;`, `&&`, `|`, Umleitung oder vorangestelltes `cd`; nur so gibt AIBOS den Aufruf ohne Rückfrage frei.

## Ablauf

1. **Umfang** (V0.6, Memo 203: B33), nach den Worten des Users:
   - **Projekt** („detach project", „lagere das Projekt aus") **oder kein Wort**: das Projekt der Session mit seinen Unterprojekten; gib **keinen Pfad** an. An der Vault-Root heißt das: den ganzen Workspace lösen; sag das dann ausdrücklich, bevor du weitermachst.
   - **Workspace** („detach workspace", „löse den Workspace"): den ganzen Workspace lösen; gib die Vault-Root als Pfad an und sag das ausdrücklich.
   - **Ein Pfad** (ein Projekt aus `workspace.yaml`): dieser Teilbaum.
2. **Plan:** `aios --workspace detach ["<pfad>"] --plan`. Meldet der Befehl `nothing detached, something would be lost`, zeige jedes Hindernis (offene Dateien, ungepushte Commits, Repos ohne Remote, ignorierte Dateien wie unter `@Secret/`) und beende; lösen kann der User die Hindernisse selbst oder mit `/aios-sync`.
3. **Zeigen und fragen:** Plan zeigen (Ziel im Papierkorb, Platzhalter), einmal fragen. Ohne Ja nichts ausführen.
4. **Ausführen:** dasselbe mit `--yes`, Ergebnis kurz melden, mit dem Weg zurück: `/aios-attach <pfad>` im Chat, `DETACHED.command` im Finder.

## Aus dem Workspace entfernen

Bei „entferne … aus dem Workspace", „nicht mehr im Workspace", „überall entfernen" (V0.6, Memo 226):

1. **Unterscheiden:** Sag in einem Satz, was der Unterschied ist: **Auslagern** gilt nur für diesen Rechner und lässt sich mit `/aios-attach` zurückholen; **Entfernen** gilt für alle Rechner, das Projekt mit seinen Unterprojekten verschwindet beim nächsten sync auch dort, das Repo am Remote bleibt. Pakete entfernt `/aios-package`, nicht dieser Skill. Ist unklar, was der User meint, frag nach.
2. **Plan:** `aios --workspace remove "<pfad>" --plan`; ein Pfad ist Pflicht, die Vault-Root geht nicht. Bei `nothing removed, something would be lost` die Hindernisse zeigen wie oben und beenden.
3. **Zeigen und fragen:** Papierkorb, Einträge nach `removed:`, Commit nur der `workspace.yaml`, kein Push; einmal fragen.
4. **Ausführen:** dasselbe mit `--yes`. Melde, dass der nächste `/aios-sync` den Eintrag hinausbringt und dass `/aios-attach <pfad>` das Projekt wieder aufnimmt; biete `/aios-sync` an.

## Grenzen

- Die Auslagerung gilt nur für diesen Rechner; andere Rechner merken nichts. Das Entfernen gilt für alle Rechner.
- Leere den Papierkorb nie; das bleibt beim User.

---
name: aibos-gui
description: Zeigt die Oberfläche von AIbex AIBOS mit den Aufgaben von AIBOS (Projekt initialisieren, Kontext und Konfiguration, Assistent zuordnen, Pakete, Apps, Pakete abgleichen und Skills registrieren, Integrität, Projektstatus, Memo). Verwenden bei "/aibos-gui", "AIBOS-Oberfläche", "AIBOS-Menü".
allowed-tools: Bash(aibos --gui *)
---

# AIBOS-Oberfläche

Ein AIBOS-Skill von AIbex AIBOS (Spec 03, *Oberflächen*). Die Oberfläche ist eine Abkürzung zu den AIBOS-Skills; alles läuft weiter über deren Regeln, z. B. die Rückfrage vor dem Schreiben.

**Arbeitsverzeichnis:** Führe alle Befehle dieses Skills im Arbeitsverzeichnis der Session aus und wechsle nie mit `cd`; AIBOS bestimmt das Projekt der Session aus dem aktuellen Verzeichnis. Andere Orte nur als ausdrücklichen Pfad angeben. Rufe `aibos …` immer als einzelnen Befehl auf, ohne `;`, `&&`, `|`, Umleitung oder vorangestelltes `cd`; nur so gibt AIBOS den Aufruf ohne Rückfrage frei.

## Ablauf

1. Führe `aibos --gui --aibos` über das Bash-Werkzeug aus.
2. Folge der Anweisung *Show the surface* in der Ausgabe: in der Desktop-App mit HTML-Oberflächen das Fragment von `aibos --gui --aibos --html` zeigen, sonst das Menü mit dem Auswahlwerkzeug.
3. Nach der Wahl einer Kachel: Ihr Text gilt, als hätte der User ihn getippt; `/<skill>` ist ein Aufruf dieses Skills.

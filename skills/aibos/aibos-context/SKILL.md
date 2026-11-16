---
name: aibos-context
description: Prüft, ob der Master-Kontext von AIbex AIBOS (das geladene Wissen der Masterspace-Kette) in diesem Chat vollständig geladen ist, lädt ihn bei Bedarf nach und zeigt Kette, geladene Dateien, verfügbares Wissen und Blueprints. Nachfolger von /masterspace. Verwenden bei "/aibos-context", "Master-Kontext", "was ist geladen?", "Kontext prüfen".
allowed-tools: Bash(aibos --context *), Read
---

# Master-Kontext

Ein AIBOS-Skill von AIbex AIBOS (Spec 02, *Skill `/aibos-context`*). Er ändert nichts außer dem Nachladen.

**Arbeitsverzeichnis:** Führe alle Befehle dieses Skills im Arbeitsverzeichnis der Session aus und wechsle nie mit `cd`; AIBOS bestimmt das Projekt der Session aus dem aktuellen Verzeichnis. Andere Orte nur als ausdrücklichen Pfad angeben. Rufe `aibos …` immer als einzelnen Befehl auf, ohne `;`, `&&`, `|`, Umleitung oder vorangestelltes `cd`; nur so gibt AIBOS den Aufruf ohne Rückfrage frei.

## Ablauf

1. **Soll-Stand ermitteln:** Führe `aibos --context --id` über das Bash-Werkzeug aus. Die Ausgabe hat die Form `id=<id> files=<n> cwd=<cwd> mode=<mode>`.

2. **Kein Vault:** Bei `mode=none` antworte nur: „Kein Vault — kein Master-Kontext." und beende.

3. **Legacy-Modus:** Bei `mode=legacy` antworte nur: „Dieser Vault läuft im Legacy-Modus (ai-brain). Prüfe den Masterspace mit `/masterspace`." und beende.

4. **Prüfen:** Der Master-Kontext gilt nur dann als geladen, wenn **beide** exakten Marken mit genau dieser id in deinem Kontext stehen:
   - `<aibos-context id="<id>"` (Anfang)
   - `</aibos-context id="<id>">` (Ende)

   Eine Erinnerung, eine Zusammenfassung oder die Marken in einer Hook-Meldung (`AIBOS-CONTEXT-CHECK`) zählen **nicht**. Es zählt nur Inhalt, den du tatsächlich aus einem SessionStart-Hook oder aus Part-Dateien gelesen hast.

5. **Nachladen**, wenn die Marken fehlen oder eine andere id im Kontext steht:
   - Steht eine andere id im Kontext, sag „Master-Kontext veraltet (`<alt>` → `<neu>`)", sonst „Lade Master-Kontext".
   - Führe `aibos --context --load "<cwd>"` aus (mit dem `cwd` aus Schritt 1).
   - Lies **jede** aufgelistete Part-Datei vollständig mit dem Read-Tool, in der angegebenen Reihenfolge.
   - Prüfe, dass die Endmarke `</aibos-context id="<id>">` gelesen wurde.

6. **Aufstellung zeigen:** Führe `aibos --context --list "<cwd>"` aus. Zeige die Ausgabe unverändert in einem Codeblock, ersetze nur die erste Zeile `Master context id <id>, AIBOS <version> — <Projekt>` durch „Master-Kontext geladen (id `<id>`, AIBOS `<version>`) — `<Projekt>`".

7. **Assistent der Session:** Führe `aibos --context --assignment "<cwd>" --session <session-id>` aus; `<session-id>` ist die Session-ID aus der Zeile *Session-ID dieses Chats* am Ende dieser Anweisung. Steht dort `from=session` und ein anderer Assistent als in der Zeile *Assistant* der Aufstellung (die Zuordnung des Projekts), nenne beide: „Assistent dieses Chats: <name> (Zuordnung des Projekts: <wert>)".

Steht in der Aufstellung ein Hinweis auf `/aibos-register` (`Note: …`), nenne ihn. Die Aufstellung ist englisch; erkläre sie bei Bedarf in der Sprache des Users. Keine weiteren Kommentare, keine Zusammenfassung des Inhalts.

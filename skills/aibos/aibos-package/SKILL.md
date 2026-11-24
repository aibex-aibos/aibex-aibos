---
name: aibos-package
description: Paketmanager von AIbex AIBOS für Anwender - installiert (holt), entfernt und aktualisiert Pakete, Apps, Assistenten, Wissenspakete und Mods aus den Hubs, meldet Mods bei Claude Code an und ab, sucht Pakete, zeigt, was installiert ist, und pflegt die Hub-Liste. Verwenden bei "/aibos-package", "installiere ...", "hole ...", "entferne ...", "deinstalliere ...", "aktualisiere ...", "installiere den Mod ...", "deinstalliere den Mod ...", "welche Mods gibt es?", "welche Pakete gibt es?", "welche Apps gibt es?", "was ist installiert?", "Hub hinzufügen", "install ...", "remove ...", "update ...", "list packages".
allowed-tools: Bash(aibos --fetch *), Bash(aibos --deploy *), Bash(aibos --library *), Bash(aibos --hubs *), Bash(aibos --install distribution-*), Bash(aibos --mod *)
---

# Pakete

Ein AIBOS-Skill von AIbex AIBOS (Spec 03, *Pakete*; Spec 06). Er versteht Wünsche in Umgangssprache und bedient sich der Hilfs-Skills `/aibos-fetch` (holen, abgleichen, aktualisieren, entfernen) und `/aibos-deploy` (Elemente ausrollen). *Installieren* heißt hier: ein Paket holen, bei einer Distribution (`distribution-<name>`) mit `aibos --install distribution-<name>` installieren (unten); der Kernel allein wird mit `aibos --install v<version>` installiert, nicht mit diesem Skill.

**Arbeitsverzeichnis:** Führe alle Befehle dieses Skills im Arbeitsverzeichnis der Session aus und wechsle nie mit `cd`. Andere Orte nur als ausdrücklichen Pfad angeben. Rufe `aibos …` immer als einzelnen Befehl auf, ohne `;`, `&&`, `|`, Umleitung oder vorangestelltes `cd`; nur so gibt AIBOS den Aufruf ohne Rückfrage frei.

## Wunsch bestimmen

| Wunsch | Vorgehen |
|---|---|
| „installiere …", „hole …", *install* | Paket finden (unten), dann wie `/aibos-fetch` holen; ist es eine Distribution, *Distribution installieren* (unten) |
| „entferne …", „deinstalliere …", *remove* | wie `/aibos-fetch --remove <paket>` |
| „aktualisiere …", *update* | wie `/aibos-fetch --upgrade [<paket>]` |
| „welche Pakete bzw. Apps gibt es?", Suche | `aibos --library [<suchwort>]` zeigen |
| „was ist installiert?" | `aibos --deploy` ausführen und die Pakete mit ihren ausgerollten Elementen zeigen |
| „füge den Hub … hinzu", „entferne den Hub …" | `aibos --hubs add <name> [<url>]` bzw. `remove <name>` mit `--plan`, Rückfrage, `--yes`; mit `--vault`, wenn der Hub für den ganzen Vault gelten soll (fragen) |
| nur einen Teil eines Pakets nutzen | `/aibos-deploy` |
| „stelle eine Distribution zusammen" | `/aibos-distribution` |
| „installiere den Mod …", „deinstalliere den Mod …", „welche Mods gibt es?", ein Paket `mod-…` | *Mods* (unten) |

## Paket finden

1. Nennt der User einen vollen Paketnamen `<hub>/<paket>`, gib ihn unverändert weiter.
2. Sonst `aibos --library <name>` ausführen. Nennt die Ausgabe Versionen (`<hub>/<name>  0.1.0 …`), ist das Paket gefunden; stehen dort mehrere Hubs, frage, welcher gemeint ist.
3. Sonst ist der Name unscharf („der Rechner", *calculator*): `aibos --library <suchwort>` mit einem passenden Wort ausführen. Ein Treffer: nimm ihn und nenne ihn. Mehrere Treffer: frage mit dem Auswahlwerkzeug (`AskUserQuestion`). Kein Treffer: sag das und zeige `aibos --library`.

**Version:** Einen Versionswunsch hängst du als Bereich an den Namen, ohne Leerzeichen und nie mit `@` (V0.4, Memo 67, B3):

| Wunsch | Bereich |
|---|---|
| „Version 0.4.0" | `app-taschenrechner==0.4.0` |
| „mindestens 0.4" | `app-taschenrechner>=0.4` |
| „irgendeine 0.4.x" | `app-taschenrechner~=0.4.0` |
| „nicht 0.4.1" | `app-taschenrechner!=0.4.1` |

Danach weiter wie im Skill `/aibos-fetch` (Ziel klären, Plan, Rückfrage, `--yes`, Abschluss). Den Plan zeigst du immer und fragst; der Wunsch „installiere …" ist keine Bestätigung. Pakete holt nur der User; schlage das Holen nicht von dir aus vor.

## Distribution installieren

Eine Distribution erkennst du am Namen `distribution-<name>` bzw. am Typ `distribution` in `aibos --library`. Sie kommt immer in die **Vault-Root** und kann den Rechner ändern (Kernel, Arbeitspferde; Spec 06, *Distributionen*).

1. **Plan:** `aibos --install distribution-<name>[<bereich>] --plan` (ohne Vault-Angabe gilt der Vault der Session; einen anderen Vault als Pfad zur Vault-Root angeben).
2. **Rückfrage:** Zeige beide Teile: den **Rechnerteil** (Kernel installieren, Arbeitspferde einrichten, mit den Paketen `paket==version`) und den **Vaultteil** (Bindung, z. B. `aibos: 0.5.0 … (was 0.4.0)`, Pakete `new`, `upgrade`). Weise auf eine Umstellung des Vaults ausdrücklich hin und frage **immer** eigens.
3. **Ausführen:** Nach Ja denselben Befehl mit `--yes`. Braucht die Installation des Kernels `sudo` mit Passwort (steht im Plan), führe sie nicht aus, sondern nenne dem User den Befehl ohne `--plan` für sein Terminal.
4. **Fehler:** Meldungen wie `one distribution with kernel: per vault`, `overridden only with only:` oder `the machine part failed` dem User nennen und beenden. „distributions need AIBOS 0.5 or later" heißt: erst `aibos --install v0.5.<n>`.

Aktualisieren ist derselbe Befehl ohne Version (`upgrade a -> b`); entfernen wie `/aibos-fetch --remove distribution-<name> --to <vault-root>`.

## Mods

Eine Mod ist eine Erweiterung von Claude Code (Paket `mod-<name>`, Spec 06, *Mods*). Holen allein meldet sie nicht an; das tut erst `aibos --mod install`. Sie wirkt dann für **alle Sessions dieses Rechners**, nicht nur für dieses Projekt.

| Wunsch | Vorgehen |
|---|---|
| „installiere den Mod …", „installiere mod-…" | Paket finden (oben, mit `aibos --library mod-`), dann `aibos --mod install mod-<name> --plan`; den Plan zeigen (er holt das Paket bei Bedarf und nennt die beiden Befehle `claude plugin …`), sagen, dass die Mod für den ganzen Rechner wirkt, fragen, nach Ja mit `--yes` |
| „deinstalliere den Mod …", „entferne den Mod …" | `aibos --mod uninstall mod-<name> --plan`, zeigen, fragen, `--yes`. Bei „entferne" danach auch `/aibos-fetch --remove mod-<name>` mit eigenem Plan und eigener Frage |
| „welche Mods gibt es?", „welche Mods sind installiert?" | `aibos --library mod-` für den Hub, `aibos --mod` für die geholten Mods mit `installed`, `installed elsewhere`, `not installed` |

Nach dem Anmelden sagst du: Die Mod erscheint nach `/reload-plugins` oder im nächsten Chat. Meldet `aibos --fetch --remove`, dass die Mod noch angemeldet ist, meldest du sie erst ab. Meldet `aibos --mod`, dass `claude` fehlt, nennst du das und beendest; anmelden lässt sich eine Mod dann nicht.

# Stand der Umsetzung AIBOS v0.7.1

v0.7.1 ist ein Patch für die Wünsche aus der Abnahme von Anja 0.6.0 und `skill-improve` 0.1.0: Tickets im Postfach `@/@!Ticket/` mit `aibos --ticket` und der Zeile `AIBOS-TICKET`, Read im Postfach, Hinweis bei `==` aus Distributionen, Hinweise in `aibos --integrity` und der Pakettyp `mod` mit `aibos --mod install|uninstall`. Kurzer Implementierungsplan: Memo 81 in `AIBOS-AA-AIbex-AIBOS/@Memo/V0.7/`, freigegeben in Memo 82 (Spec freigegeben in Memo 80, Code `d12d7a9`). Jeder Schritt wird im selben Commit `v0.7.1 Schritt N: …` abgehakt, der ihn abschließt.

v0.7.0 ist abgeschlossen (Tag `v0.7.0`, Abnahme in Memo 56, Veröffentlichung in Memo 58 von V0.7); sein Stand steht in `STATUS.md` des Tags `v0.7.0`, frühere in den Tags `v0.6.6`, `v0.6.3`, `v0.6.2`, `v0.6.1` und `v0.6.0`.

| # | Schritt | Ergebnis | Spec | Stand |
|---|---|---|---|---|
| 0 | **Repo auf 0.7.1:** `VERSION`, `manifest.yaml` `0.7.1-dev`; `STATUS.md` neu; `CLAUDE.md` mit den Memos von 0.7.1; Ausgangsprüfung | Ausgangsprüfung auf 0.7.0: `tests/run` 1755 grün; Live-Tests alle grün (hooks 9, outside 6, permit 11, skills 9, assistants 13 mit sonnet, workers 14, fresh 24, changeover 26, rothirsch 25). `VERSION` und `manifest.yaml` `0.7.1-dev`; `STATUS.md` neu (0.7.0 im Tag `v0.7.0`); `CLAUDE.md` mit Plan und Memos von 0.7.1, Arbeitsrechner auf 0.7.0. Danach `tests/run` 1755 grün | 01 | ☑ abgeschlossen |
| 1 | **Tickets:** Postfach, `aibos --ticket [<paket>] [--type <typ>]`, Übergang `@/@!Improve/`; Test `t25-ticket.sh` | | 04, 06 | ☐ |
| 2 | **Hooks:** `AIBOS-TICKET` in `--session` bei jedem `source`; Read im Postfach in `--permit` (R2) | | 02 | ☐ |
| 3 | **Distributionen (W4):** `note: distribution-… pins …` im Resolver und im Plan von `--activate` | | 04, 06 | ☐ |
| 4 | **Integrität:** verwaiste Ausschlüsse, veraltete Registrierung als Hinweise | | 05 | ☐ |
| 5 | **Mods:** Typ `mod`, Prüfung beim Holen, Element `mod`, `aibos --mod [install\|uninstall]`, Abbruch von `--remove`; Test `t26-mod.sh` mit Attrappe `claude` | | 01, 04, 06 | ☐ |
| 6 | **Kernel-Skill und Doku:** `/aibos-package` mit Mods; README, Tutorials | | 03 | ☐ |
| 7 | **Pakete:** `skill-improve`, `assistant-anja` (Postfach `@/@!Ticket/`), `mod-token-statuszeile` 0.1.0 als Kandidaten `-rc1` | | 06 | ☐ |
| 8 | **Kandidat** `0.7.1-rc1`, Live-Tests, Probe-Vault `§Probe-Ticket` | | 01 | ☐ |

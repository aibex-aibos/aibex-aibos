# app-taschenrechner

Demo-App von AIbex AIBOS: programmierbarer Taschenrechner mit umgekehrter polnischer Notation nach dem Vorbild des HP-15C (Stack X, Y, Z, T): Ziffern, Punkt, Grundrechenarten, `CHS`, `ENTER`, vier Funktionstasten A bis D und die Taste *Lernen*. Ein Quadrat ist `ENTER ×`. Mit *LEARN* nimmt der Rechner eine Tastenfolge auf; die nächste gedrückte Funktionstaste übernimmt sie, und Claude speichert sie mit dem Skill `taschenrechner` in `@Data/app-taschenrechner/funktionstasten.yaml`.

```bash
aibos --fetch app-taschenrechner
```

Öffnen mit `/taschenrechner-gui` oder über die Kachel *Apps* von `/aibos-gui`. Mitgelieferte Funktionstasten liegen in `knowledge/@!Funktionstasten/`; Beiträge kommen als Pull Request (`aibos --contribute`) und nach Prüfung dorthin.

# Rosenweg Salz

App für den Salzvorrat der Enthärtungsanlagen in Rosenweg 2, 4, 9 und der
Kooperation. Android zuerst, iOS möglich.

- **Anlieferung**: Lager wählen, Barcode eines Sacks scannen, Anzahl Säcke wählen, buchen.
- **Sack eingefüllt**: Lager wählen und den Sack scannen. Damit ist ein Sack abgebucht.
- Ist ein Barcode noch unbekannt, wird er einmal mit Bezeichnung und Gewicht je Sack erfasst.
- Auf der Startseite stehen für jedes Lager der Bestand und die Reichweite. Eine Buchung lässt sich gleich danach rückgängig machen.

Server: Rosenweg-API `/api/salz` (Repo Rosenweg/Website,
`api/routes/salz.js`, Beschreibung in `docs/salzvorrat.md`). Dort wird auch
die Reichweite gerechnet und die Mail zum Nachbestellen an die Technik verschickt.

## Aufbau

- `lib/salz/`: Datenmodell und API (`SalzApi` über `RosenwegApi` aus rosenweg_basis)
- `lib/oberflaeche/`: Startseite, Buchungsablauf, Scanner (mobile_scanner)
- Anmeldung, API-Client, Thema und Rahmen liefert **rosenweg_basis**
  (`../rosenweg-basis`, path-Abhängigkeit, bis das Repo auf GitHub liegt).
  Die App meldet sich mit dem Authentik-Client `rosenweg-apps` an; die Rücksprungadresse ist
  `ch.rosenweg4303.salz:/anmeldung` und muss in Authentik als „Strikt“ eingetragen sein.
- Logo: aus dem Logo-Baukasten der Basis (Turm, Weg und Rose, dazu die Plakette mit dem
  Salzsack `assets/logo/zeichen/salz.svg`): `sh assets/logo/erzeugen.sh`

## Entwickeln

    flutter analyze
    flutter test
    flutter test test/bildschirmfotos_test.dart --dart-define=BILDSCHIRMFOTOS=$PWD/build/bildschirmfotos
    flutter build apk --debug

## Lizenz

GPL-3.0-or-later, siehe `LICENSE`.

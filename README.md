# Rosenweg Salz

App für den Salzvorrat der Enthärtungsanlagen in Rosenweg 2, 4, 9 und der
Kooperation (Lager im Rosenweg 10). Für Android, iOS, Linux (Debian-Paket für
die Stationen von Rosenweg OS), macOS und Windows.

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
- **Barcode am Desktop**: Kamera-Scan gibt es nur auf Telefonen (Android, iOS).
  Unter Linux, macOS und Windows öffnet „scannen“ eine Eingabeseite
  (`BarcodeEingabeSeite`): das Feld hat sofort den Fokus, ein
  USB-Barcode-Scanner (meldet sich als Tastatur, schickt Ziffern und Enter)
  erfasst den Sack mit einem Scan; ohne Scanner die Nummer unter dem Strichcode
  eintippen und Enter oder „Weiter“.
- Anmeldung, API-Client, Thema und Rahmen liefert **rosenweg_basis**
  (privates Repo Rosenweg/rosenweg-basis, git-Abhängigkeit mit festem Tag in `pubspec.yaml`).
  Die App meldet sich mit dem Authentik-Client `rosenweg-apps` an; die Rücksprungadresse ist
  `ch.rosenweg4303.salz:/anmeldung` und muss in Authentik als „Strikt“ eingetragen sein.
- Logo: aus dem Logo-Baukasten der Basis (Turm, Weg und Rose, dazu die Plakette mit dem
  Salzsack `assets/logo/zeichen/salz.svg`): `sh assets/logo/erzeugen.sh`
  (macOS- und Windows-Symbol allein: `sh assets/logo/desktop-symbole.sh`;
  die Linux-Symbole rechnet `linux/paket/bauen.sh`)

## Entwickeln

Gegen die Basis im Nachbarordner `../rosenweg-basis` statt gegen den Tag
entwickeln: `pubspec_overrides.yaml` anlegen (steht in `.gitignore`):

    dependency_overrides:
      rosenweg_basis:
        path: ../rosenweg-basis

Dann schreibt `flutter pub get` den path-Eintrag in `pubspec.lock`. So nicht
einchecken (die CI bricht dann ab): vor dem Commit `git checkout pubspec.lock`,
oder bei einer neuen Basis-Version den Tag in `pubspec.yaml` erhöhen,
`pubspec_overrides.yaml` kurz wegnehmen und `flutter pub get` laufen lassen.

    flutter analyze
    flutter test
    flutter test test/bildschirmfotos_test.dart --dart-define=BILDSCHIRMFOTOS=$PWD/build/bildschirmfotos
    flutter build apk --debug

## Bau auf GitHub

Desktop-Plattformen und iOS: siehe „Desktop“ unten. Alle Läufe holen die
Basis über `.github/actions/basis-zugang` (gleiches Secret).

`.github/workflows/android.yml` läuft auf dem eigenen Runner (Gruppe
`rosenweg-privat`, wie rosenweg-vm): bei jedem Push auf `main` und jedem PR
`flutter analyze`, `flutter test` und eine Release-APK. Die APK hängt als
Artefakt am Lauf (Actions → Lauf → Artifacts). Bei einem Tag `v*` (gleich der
`version` in `pubspec.yaml`, z. B. `v1.0.0`) entsteht zusätzlich ein
GitHub-Release mit der APK.
Mit dem Rosenweg-Signierschlüssel geht die APK dabei auch an
**www.rosenweg4303.ch/apps** (Anmeldung per GitHub-OIDC, kein Geheimnis; Weg in
Rosenweg/Website, `pbx/README.md`). Ein Debug-Bau bleibt nur im GitHub-Release.

Flutter, JDK und Android-Kommandozeilenwerkzeuge kommen als feste Versionen
mit Prüfsumme in einen Cache im Benutzerverzeichnis des Runners.

Secrets (Settings → Secrets and variables → Actions):

| Secret | Wozu |
|---|---|
| `BASIS_TOKEN` | Fein granulierter Token, nur Rosenweg/rosenweg-basis, *Contents: Read-only* — damit `pub get` die private Basis holen kann. Alternative: `BASIS_DEPLOY_KEY` (privater SSH-Schlüssel eines Deploy-Keys auf rosenweg-basis, sobald Deploy-Keys in der Organisation erlaubt sind). |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Rosenweg-Signierschlüssel (optional). Fehlen sie, ist die APK mit dem Debug-Schlüssel signiert und heisst `…-debug-signiert.apk`. |

## Desktop: Linux, macOS, Windows

| Plattform | Bau | Ergebnis | an /apps |
|---|---|---|---|
| Linux (Debian 13, amd64) | `.github/workflows/linux.yml` (eigener Runner, bei jedem Push/PR); lokal im Bau-Container: `linux/paket/im-container.sh` | `rosenweg-salz_<version>-<bau>_amd64.deb` | bei Tag `v*` (linux-deb) |
| macOS | `.github/workflows/macos.yml` (nur Tag/von Hand); lokal `macos/installer/bauen.sh` | `Rosenweg-Salz-<version>.dmg` | bei Tag `v*` |
| Windows | `.github/workflows/windows.yml` (nur Tag/von Hand), Inno Setup | `Rosenweg-Salz-<version>-Setup.exe` | bei Tag `v*` |
| iOS | `.github/workflows/macos.yml`, Job `ios`: Bau ohne Signatur | unsigniertes `.ipa` als Artefakt | nein (braucht Apple Developer Program) |

**Linux-Paket** (Muster rosenweg-profil / rosenweg-vm): das Flutter-Bündel
liegt unter `/opt/rosenweg-salz`, Starter `rosenweg-salz`, Desktop-Datei
`ch.rosenweg4303.salz.desktop`, Symbole in hicolor. Abhängigkeiten rechnet
`dpkg-shlibdeps`, dazu `libgssapi-krb5-2` (stille Kerberos-Anmeldung der Basis
an den Stationen) und `xdg-utils` (Browser für die Anmeldung). Die Stationen
holen das Paket mit Prüfsumme vom PXE-Server (Rosenweg/os-stationen,
`pakete/rosenweg-salz/`). Debian-Version = `version` aus `pubspec.yaml` mit
der Baunummer als Revision (`1.0.0+1` → `1.0.0-1`): für ein neues Paket die
Baunummer erhöhen.

`linux/paket/im-container.sh` schickt den Arbeitsstand und die Basis in der
Fassung aus `pubspec.yaml` (Tag aus `../rosenweg-basis`) in CT 141 auf pve3 und
holt das .deb nach `linux/paket/out/` zurück. Läuft dort schon ein Flutter-Bau,
bricht es ab.

## Geteilte Rosenweg-Telefone

Auf den geteilten Telefonen (mit Rosenweg Gerät, Anmeldung per Karte am
Sperrbildschirm) zeigt die App keinen Anmeldeschirm und kein „Abmelden“: sie
arbeitet für die Person, die gerade am Telefon angemeldet ist. Jede Anfrage
geht über Rosenweg Gerät und die Telefonanlage an `/api/salz/…`
(rosenweg-basis, `docs/geteilte-telefone.md`); die App sieht kein Token. Ist
niemand angemeldet, steht dort „Bitte zuerst mit der Karte anmelden“.

Voraussetzungen:

- **Rosenweg-Signatur.** Rosenweg Gerät gibt die Anfragen nur an Apps mit
  seiner Signatur weiter (`ch.rosenweg4303.permission.ANLAGE`, signature). Ein
  Debug-Bau bekommt „Rosenweg Gerät verweigert den Zugriff (andere
  Signatur?)“. Also die vier `ANDROID_*`-Secrets oben setzen.
- **Rosenweg Gerät ab v236** (`portal_anfrage`) und die PBX-API mit
  `POST /api/telefon/portal` (Rosenweg/Website, `pbx/README.md`).
- **Katalog** der geteilten Telefone: Eintrag `ch.rosenweg4303.salz` auf
  rosenweg4303.ch/smartphones mit den Gruppen, die die App sehen. Danach
  bringt jeder Release-Tag die APK auch dorthin.

## Lizenz

GPL-3.0-or-later, siehe `LICENSE`.

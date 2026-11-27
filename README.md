<p align="center"><img src="assets/logo/rosenweg-salz-512.png" width="96" alt="Logo"></p>
<h1 align="center">Rosenweg Salz</h1>
<p align="center">Salzvorrat der Enthärtungsanlagen im Rosenweg – für Hauswarte, Bewohner und die Technik.</p>
<p align="center"><a href="https://www.rosenweg4303.ch/apps">Herunterladen</a> · <a href="docs/anleitung.md">Anleitung</a></p>

## Inhalt

- [Überblick](#überblick)
- [Plattformen](#plattformen)
- [Rechte und Gruppen](#rechte-und-gruppen)
- [Bedienung](#bedienung)
- [Geteilte Rosenweg-Telefone](#geteilte-rosenweg-telefone)
- [Aufbau](#aufbau)
- [Bauen](#bauen)
- [CI und Release](#ci-und-release)
- [Konfiguration](#konfiguration)
- [Lizenz](#lizenz)

## Überblick

Die App führt den Salzvorrat der Enthärtungsanlagen. Jedes Lager hat einen eigenen Bestand an Säcken.

| Lager | Ort |
|---|---|
| Rosenweg 2 | Haus 2 |
| Rosenweg 4 | Haus 4 |
| Rosenweg 9 | Haus 9 |
| Rosenweg Kooperation | Lager im Rosenweg 10 |

Was die App kann:

- **Anlieferung buchen:** Sack scannen, Anzahl wählen, fertig.
- **Sack eingefüllt:** ein Scan, ein Sack ist abgebucht.
- **Übersicht:** Bestand, Reichweite und „Nächster Sack etwa am …“ je Lager.
- **Rückgängig:** eine Buchung lässt sich gleich danach zurücknehmen.
- **Erinnerungen:** Mail zum Nachbestellen und am fälligen Tag eine Erinnerung ans Einfüllen (Mail, Web-Push).
- **Geteilte Telefone:** läuft auch dort, Anmeldung per Karte.

Rechnen und Erinnern macht der Server (Rosenweg-API `/api/salz`), die App bucht und zeigt an.

## Plattformen

| Plattform | Stand |
|---|---|
| Android | ja, APK auf [rosenweg4303.ch/apps](https://www.rosenweg4303.ch/apps) |
| Geteilte Rosenweg-Telefone | ja, über den Katalog auf /smartphones |
| Linux (Debian-Paket für die Stationen von Rosenweg OS) | ja, `.deb` (bei Tag `v*` an /apps; Stationen holen es vom PXE-Server) |
| macOS | ja, DMG (bei Tag `v*` an /apps) |
| Windows | ja, Setup mit Inno Setup (bei Tag `v*` an /apps) |
| iOS | Bau ohne Signatur in der CI; nicht verteilt (braucht Apple Developer Program) |

**Updates:** Die App aktualisiert sich selbst (Updater aus `rosenweg_basis` ab 0.5.0): auf Android der Rosenweg Updater (täglich, Android fragt pro Installation), auf eigenen Linux-Rechnern, macOS und Windows eine Leiste „Neue Fassung … verfügbar“ mit *Aktualisieren* (Prüfsumme aus dem Katalog wird geprüft). Aus ist er nur auf geteilten Telefonen (Rosenweg Gerät) und auf Rosenweg-Stationen (os-stationen).

Version 1.0.2 (`rosenweg_basis` v0.5.2: Android-Anmeldeschirm mit „QR-Code scannen“). Kamera-Scan gibt es nur auf Telefonen; am Desktop wird der Barcode eingetippt oder mit einem USB-Scanner erfasst (siehe [Bedienung](#bedienung)).

## Rechte und Gruppen

Die Rechte vergibt der Server; die App zeigt nur, was die angemeldete Person darf.

| Wer | darf |
|---|---|
| Technik, Präsident | alles: alle Lager buchen, Bestand setzen, Schwellen, Sorten, Hauswart-Adressen, Bewohnergruppen (im Portal) |
| Gruppen aus `SALZ_GRUPPEN` | in allen Lagern buchen, neue Sorten beim Scan erfassen |
| Bewohnerinnen und Bewohner des Lagers | nur im eigenen Lager: Anlieferung, Sack eingefüllt, eigene Buchung innert 24 h rückgängig |

| Lager | Bewohnergruppe (im Portal änderbar) |
|---|---|
| Rosenweg 2 und 4 | `stweg7-bewohner` (beide STWEG 7) |
| Rosenweg 9 | `r9-bewohner` |
| Kooperation | `stweg4-bewohner` |

Wer nur in einem Lager buchen darf, bekommt keine Lagerwahl und kommt direkt zum Scanner.

## Bedienung

| Schritt | So geht’s |
|---|---|
| Anlieferung | Lager wählen → Barcode eines Sacks scannen → Anzahl Säcke wählen → buchen |
| Sack eingefüllt | Lager wählen → Sack scannen. Ein Sack ist abgebucht. |
| Unbekannter Barcode | Die Technik erfasst ihn einmal mit Bezeichnung und Gewicht je Sack. Wer das nicht darf, sieht „Technik fragen“ und kann einen anderen Sack scannen. |
| Rückgängig | gleich nach der Buchung auf der Startseite |
| Barcode am Desktop (Linux, macOS, Windows) | „scannen“ öffnet eine Eingabeseite (`BarcodeEingabeSeite`), das Feld hat sofort den Fokus. Ein USB-Barcode-Scanner (meldet sich als Tastatur, schickt Ziffern und Enter) erfasst den Sack mit einem Scan; ohne Scanner die Nummer unter dem Strichcode eintippen und Enter oder „Weiter“. |

Die Startseite zeigt je Lager Ort, Bestand, Reichweite und „Nächster Sack etwa am …“ (wenn der Server einen Termin liefert).

Ausführlich: [docs/anleitung.md](docs/anleitung.md).

## Geteilte Rosenweg-Telefone

Auf den geteilten Telefonen (mit Rosenweg Gerät, Anmeldung per Karte am Sperrbildschirm) gibt es keinen Anmeldeschirm und kein „Abmelden“. Die App arbeitet für die Person, die gerade angemeldet ist; ohne Anmeldung steht dort „Bitte zuerst mit der Karte anmelden“.

Jede Anfrage geht über Rosenweg Gerät und die Telefonanlage an `/api/salz/…`; die App sieht kein Token (rosenweg-basis, `docs/geteilte-telefone.md`).

| Voraussetzung | Warum |
|---|---|
| Rosenweg-Signatur | Rosenweg Gerät gibt Anfragen nur an Apps mit seiner Signatur weiter (`ch.rosenweg4303.permission.ANLAGE`). Ein Debug-Bau bekommt „Rosenweg Gerät verweigert den Zugriff (andere Signatur?)“. |
| Rosenweg Gerät ab v236 | bringt `portal_anfrage` |
| PBX-API mit `POST /api/telefon/portal` | Rosenweg/Website, `pbx/README.md` |
| Katalog-Eintrag `ch.rosenweg4303.salz` | auf rosenweg4303.ch/smartphones, mit den Gruppen, die die App sehen. Danach bringt jeder Release-Tag die APK auch dorthin. |

## Aufbau

| Teil | Inhalt |
|---|---|
| `lib/salz/` | Datenmodell und API (`SalzApi` über `RosenwegApi` aus rosenweg_basis) |
| `lib/oberflaeche/` | Startseite, Buchungsablauf, Scanner (mobile_scanner) |
| [rosenweg-basis](https://github.com/Rosenweg/rosenweg-basis) | Anmeldung, API-Client, Thema und Rahmen (privates Repo, git-Abhängigkeit mit festem Tag in `pubspec.yaml`) |
| `lib/oberflaeche/` Desktop | `BarcodeEingabeSeite`: Barcode per Eingabefeld oder USB-Scanner statt Kamera |
| `linux/`, `macos/`, `windows/`, `ios/` | Desktop- und iOS-Projekte; `linux/paket/` baut das Debian-Paket, `macos/installer/` das DMG |
| `assets/logo/` | Logo aus dem Baukasten der Basis: Turm, Weg und Rose mit der Salzsack-Plakette; neu erzeugen mit `sh assets/logo/erzeugen.sh` (macOS- und Windows-Symbol allein: `sh assets/logo/desktop-symbole.sh`; die Linux-Symbole rechnet `linux/paket/bauen.sh`) |

**Anmeldung:** Authentik-Client `rosenweg-apps`, Rücksprungadresse `ch.rosenweg4303.salz:/anmeldung` (in Authentik als „Strikt“ eingetragen).

**Server:** Rosenweg/Website, `api/routes/salz.js`, Beschreibung in `docs/salzvorrat.md`. Dort werden Reichweite und nächster Sack gerechnet und die Mails verschickt.

## Bauen

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Bildschirmfotos für die Doku:

```sh
flutter test test/bildschirmfotos_test.dart --dart-define=BILDSCHIRMFOTOS=$PWD/build/bildschirmfotos
```

**Gegen eine lokale Basis entwickeln** (Nachbarordner `../rosenweg-basis`): `pubspec_overrides.yaml` anlegen (steht in `.gitignore`):

```yaml
dependency_overrides:
  rosenweg_basis:
    path: ../rosenweg-basis
```

`flutter pub get` schreibt dann den path-Eintrag in `pubspec.lock` – so **nicht** einchecken, die CI bricht sonst ab. Vor dem Commit `git checkout pubspec.lock`, oder bei einer neuen Basis-Version den Tag in `pubspec.yaml` erhöhen, `pubspec_overrides.yaml` kurz wegnehmen und `flutter pub get` laufen lassen.

## CI und Release

Alle Läufe laufen auf GitHub-Runnern (`ubuntu-latest`, das `.deb` im Container `debian:13`; `windows-latest`, `macos-latest`), nie auf eigenen. Die Basis ist öffentlich, `pub get` holt sie ohne Token. Signiert wird nur bei Push auf `main` oder Tag `v*`; ein PR baut immer mit dem Debug-Schlüssel.

| Auslöser | Ergebnis |
|---|---|
| Push auf `main`, jeder PR | `flutter analyze`, `flutter test`, Release-APK als Artefakt am Lauf |
| Tag `v*` (gleich `version` in `pubspec.yaml`, z. B. `v1.0.0`) | zusätzlich GitHub-Release mit der APK |
| Tag mit Rosenweg-Signatur | APK geht auch an **[rosenweg4303.ch/apps](https://www.rosenweg4303.ch/apps)** (GitHub-OIDC, kein Geheimnis; Weg in Rosenweg/Website, `pbx/README.md`) |

Ein Debug-signierter Bau bleibt nur im GitHub-Release. Flutter, JDK und Android-Kommandozeilenwerkzeuge kommen als feste Versionen mit Prüfsumme, zwischen Läufen im `actions/cache`.

### Desktop und iOS

| Plattform | Bau | Ergebnis | an /apps |
|---|---|---|---|
| Linux (Debian 13, amd64) | `.github/workflows/linux.yml` (bei jedem Push/PR); lokal im Bau-Container: `linux/paket/im-container.sh` | `rosenweg-salz_<version>-<bau>_amd64.deb` | bei Tag `v*` (linux-deb) |
| macOS | `.github/workflows/macos.yml` (Tag, von Hand; öffentlich auch jeder Push/PR); lokal `macos/installer/bauen.sh` | `Rosenweg-Salz-<version>.dmg` | bei Tag `v*` |
| Windows | `.github/workflows/windows.yml` (Tag, von Hand; öffentlich auch jeder Push/PR), Inno Setup | `Rosenweg-Salz-<version>-Setup.exe` | bei Tag `v*` |
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
Fassung aus `pubspec.yaml` (Tag aus `../rosenweg-basis`) in den Bau-Container (CT 141; Knoten als
Argument oder in `RW_BAU_KNOTEN`) und holt das .deb nach `linux/paket/out/` zurück. Läuft dort schon ein Flutter-Bau,
bricht es ab.

## Konfiguration

GitHub-Secrets (Settings → Secrets and variables → Actions), nur die Namen:

| Secret | Wozu |
|---|---|
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Rosenweg-Signierschlüssel (optional, nur bei Push auf `main`/Tag `v*` benutzt). Fehlen sie, ist die APK debug-signiert und heisst `…-debug-signiert.apk`. |

Auf dem Server (Rosenweg/Website): `SALZ_GRUPPEN` (wer in allen Lagern buchen darf), `SALZ_MELDUNG_AN` (Empfänger der Meldungen, Vorgabe Technik).

Mehr Details: [docs/entwickeln.md](docs/entwickeln.md).

## Lizenz

GPL-3.0-or-later, siehe [LICENSE](LICENSE).

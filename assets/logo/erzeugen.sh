#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Logo „Rosenweg Salz“ aus dem Logo-Baukasten von rosenweg-basis (Stil A2): Wappen
# (Turm, Weg, Rose) und rechts unten die Plakette mit dem Salzsack; Grund in der
# Gruppenfarbe Bewohner (Rosenweg-Rot #D62828), wie in werkzeug/logo/flutter-apps.txt.
# Erzeugt alle Plattform-Symbole (Android adaptive + monochrom, iOS, macOS samt
# .icns und DMG-Hintergrund, Windows .ico, assets/logo/rosenweg-salz-192.png fuer /apps);
# die Linux-Symbole rechnet linux/paket/bauen.sh beim Bau aus denselben SVGs.
# Aufruf aus dem Repo-Wurzelverzeichnis:
#   sh assets/logo/erzeugen.sh [pfad/zu/rosenweg-basis]
set -eu
BASIS="${1:-../rosenweg-basis}"
# Weitere Gruppenfarben (lib: farbGruppen): Logos, Android-Aliasse, iOS alternate icons
FARBEN="technik"
FARBEN="$FARBEN" sh "$BASIS/werkzeug/logo/app-symbole.sh" . rosenweg-salz "Rosenweg Salz" \
  "$BASIS/werkzeug/logo/zeichen/salz.svg" bewohner
python3 "$BASIS/werkzeug/logo/farben-einbauen.py" . --standard bewohner --farben $FARBEN >/dev/null

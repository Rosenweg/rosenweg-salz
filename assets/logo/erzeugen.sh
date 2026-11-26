#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Logo „Rosenweg Salz“ aus dem Logo-Baukasten von rosenweg-basis:
# Wappen (Turm, Weg, Rose) und rechts unten die Plakette mit dem Salzsack
# (assets/logo/zeichen/salz.svg). Aufruf aus dem Repo-Wurzelverzeichnis:
#   sh assets/logo/erzeugen.sh [pfad/zu/rosenweg-basis]
set -eu
BASIS="${1:-../rosenweg-basis}"
sh "$BASIS/werkzeug/logo/erzeugen.sh" . rosenweg-salz "Rosenweg Salz" assets/logo/zeichen/salz.svg
# Kleines Logo fuer die Titelleiste der App
L=assets/logo
q=$L/rosenweg-salz-klein.svg
rsvg-convert -w 96 -h 96 "$q" -o $L/rosenweg-salz-klein.png

# iOS (vollflaechig ohne Alpha, iOS rundet selbst; die Basis erzeugt dafuer
# mit --alle die Variante -vollflaeche)
python3 "$BASIS/werkzeug/logo/baukasten.py" --name rosenweg-salz --titel "Rosenweg Salz" \
  --zeichen assets/logo/zeichen/salz.svg --ziel $L --alle >/dev/null
I=ios/Runner/Assets.xcassets/AppIcon.appiconset
T=$(mktemp -d)
ios() { q=$L/rosenweg-salz-vollflaeche.svg; [ "$2" -le 108 ] && q=$L/rosenweg-salz-vollflaeche-klein.svg
        [ "$2" -le 40 ] && [ -f $L/rosenweg-salz-vollflaeche-winzig.svg ] && q=$L/rosenweg-salz-vollflaeche-winzig.svg
        rsvg-convert -w "$2" -h "$2" "$q" -o "$T/i.png"
        magick "$T/i.png" -background '#D32F2F' -alpha remove -alpha off "$I/$1"; }
ios Icon-App-20x20@1x.png 20;  ios Icon-App-20x20@2x.png 40;  ios Icon-App-20x20@3x.png 60
ios Icon-App-29x29@1x.png 29;  ios Icon-App-29x29@2x.png 58;  ios Icon-App-29x29@3x.png 87
ios Icon-App-40x40@1x.png 40;  ios Icon-App-40x40@2x.png 80;  ios Icon-App-40x40@3x.png 120
ios Icon-App-60x60@2x.png 120; ios Icon-App-60x60@3x.png 180
ios Icon-App-76x76@1x.png 76;  ios Icon-App-76x76@2x.png 152
ios Icon-App-83.5x83.5@2x.png 167; ios Icon-App-1024x1024@1x.png 1024
rm -rf "$T"

# Desktop-Symbole (Muster rosenweg-vm assets/logo/erzeugen.sh). Detailstufe
# nach Pixelgroesse: bis 40 px *-winzig, bis 108 px *-klein, darueber voll.
# Linux-Symbole fuers .deb rechnet linux/paket/bauen.sh selbst (gleiche Regel).
sh assets/logo/desktop-symbole.sh

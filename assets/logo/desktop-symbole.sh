#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# macOS- und Windows-Symbol aus den SVGs des Logo-Baukastens (assets/logo/).
# Muster: rosenweg-vm assets/logo/erzeugen.sh. Aufruf aus dem Repo-Wurzel-
# verzeichnis (auch einzeln, ohne rosenweg-basis): sh assets/logo/desktop-symbole.sh
# Benoetigt: rsvg-convert (librsvg >= 2.52, fuer feDropShadow), magick (ImageMagick 7).
set -eu
L=assets/logo
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
stufe() { # stufe <quelle ohne .svg> <groesse> -> Pfad der passenden SVG
  if [ "$2" -le 40 ]; then echo "$1-winzig.svg"; elif [ "$2" -le 108 ]; then echo "$1-klein.svg"; else echo "$1.svg"; fi
}
r() { rsvg-convert -w "$2" -h "$2" "$(stufe "$1" "$2")" -o "$3"; }
# macOS: Form nach Apple-Raster (824er Feld auf 1024, Rand aus -macos.svg) plus
# Schlagschatten wie in Apples Vorlage; der Schatten kommt nur beim Rendern dazu.
M=macos/Runner/Assets.xcassets/AppIcon.appiconset
mac() {
  q=$(stufe $L/rosenweg-salz-macos "$1")
  sed -e 's|<g transform="translate(512 512) scale(0.805)|<defs><filter id="rw-schatten" x="-10%" y="-10%" width="120%" height="125%"><feDropShadow dx="0" dy="10" stdDeviation="10" flood-color="#000" flood-opacity="0.3"/></filter></defs><g filter="url(#rw-schatten)"><g transform="translate(512 512) scale(0.805)|' \
      -e 's|</svg>|</g></svg>|' "$q" > "$T/mac.svg"
  rsvg-convert -w "$1" -h "$1" "$T/mac.svg" -o "$M/app_icon_$1.png"
}
for s in 16 32 64 128 256 512 1024; do mac $s; done
# Windows (.ico mit allen ueblichen Groessen)
W=windows/runner/resources/app_icon.ico
for s in 16 24 32 48 64 128 256; do r $L/rosenweg-salz $s "$T/w$s.png"; done
magick "$T/w16.png" "$T/w24.png" "$T/w32.png" "$T/w48.png" "$T/w64.png" "$T/w128.png" "$T/w256.png" $W

// SPDX-License-Identifier: GPL-3.0-or-later
// Bildschirmfotos fuer die Doku (nicht Teil der normalen Tests):
//   flutter test test/bildschirmfotos_test.dart --dart-define=BILDSCHIRMFOTOS=build/bildschirmfotos
// Laedt Roboto und die Material-Symbole aus dem Flutter-SDK, damit Text lesbar ist.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosenweg_salz/oberflaeche/umgebung.dart';
import 'package:rosenweg_salz/salz/modell.dart';

import 'attrappen.dart';

const ziel = String.fromEnvironment('BILDSCHIRMFOTOS');

Future<void> schriftLaden(String familie, List<String> dateien) async {
  final l = FontLoader(familie);
  for (final d in dateien) {
    l.addFont(Future.value(ByteData.sublistView(File(d).readAsBytesSync())));
  }
  await l.load();
}

Future<void> foto(WidgetTester t, GlobalKey k, String name) async {
  await t.runAsync(() async {
    final r = k.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bild = await r.toImage(pixelRatio: 2.5);
    final png = await bild.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$ziel/$name.png')..createSync(recursive: true);
    f.writeAsBytesSync(png!.buffer.asUint8List());
  });
}

DateTime tagIn(int n) {
  final d = DateTime.now().add(Duration(days: n));
  return DateTime(d.year, d.month, d.day);
}

void main() {
  testWidgets('Bildschirmfotos', (t) async {
    final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    await t.runAsync(() async {
      // Auch unter dem Namen der Test-Schrift: Texte ohne eigene Familie
      // (Knoepfe, Monospace) fallen in Tests sonst auf Kaestchen zurueck.
      for (final familie in ['Roboto', 'FlutterTest', 'Ahem', 'monospace']) {
        await schriftLaden(familie, ['$fonts/Roboto-Regular.ttf', '$fonts/Roboto-Medium.ttf', '$fonts/Roboto-Bold.ttf']);
      }
      await schriftLaden('MaterialIcons', ['$fonts/MaterialIcons-Regular.otf']);
    });
    t.view.physicalSize = const Size(1080, 2280);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);

    final q = QuelleAttrappe();
    q.liste = [
      neuesLager(1, 'Rosenweg 2', 2, saecke: 14, wochen: 10.5, naechster: tagIn(4)),
      neuesLager(2, 'Rosenweg 4', 4, saecke: 3, wochen: 2.5, knapp: true, naechster: tagIn(1)),
      neuesLager(3, 'Rosenweg 9', 9, saecke: 20, wochen: 33.8, naechster: tagIn(9)),
      neuesLager(4, 'Rosenweg Kooperation', null, inBetrieb: false, ort: 'Lager im Rosenweg 10'),
    ];
    final k = GlobalKey();
    var scan = '7612345000017';
    await t.pumpWidget(RepaintBoundary(
      key: k,
      child: testApp(Umgebung(quelle: q, scannen: (_) async => scan, abmelden: () async {})),
    ));
    await t.pumpAndSettle();
    // Logo (Asset) laden lassen
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await t.pumpAndSettle();
    await foto(t, k, 'salz-app-start');

    await t.tap(find.byKey(const Key('knopf-anlieferung')));
    await t.pumpAndSettle();
    await foto(t, k, 'salz-app-wo');
    await t.tap(find.byKey(const Key('lager-3')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('sorte-name')), 'Regeneriersalz Tabletten');
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await foto(t, k, 'salz-app-neuer-sack');
    await t.tap(find.byKey(const Key('sorte-speichern')));
    await t.pumpAndSettle();
    await t.tap(find.text('20'));
    await t.pumpAndSettle();
    await foto(t, k, 'salz-app-anzahl');
    await t.tap(find.byKey(const Key('buchen')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 800));
    await foto(t, k, 'salz-app-gebucht');
    q.sorten[scan] = Sorte(barcode: scan, bezeichnung: 'Regeneriersalz Tabletten', gewichtKg: 25);
  }, skip: ziel.isEmpty);
}

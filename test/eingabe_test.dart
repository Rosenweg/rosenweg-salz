// SPDX-License-Identifier: GPL-3.0-or-later
// Desktop (Linux-Stationen, macOS, Windows): kein Kamera-Scan, sondern ein
// Eingabefeld, in das auch ein USB-Barcode-Scanner tippt (Ziffern + Enter).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosenweg_salz/oberflaeche/scanner_seite.dart';

Future<List<String?>> _oeffnen(WidgetTester t) async {
  final ergebnisse = <String?>[];
  await t.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: FilledButton(
          onPressed: () async => ergebnisse.add(await scannerOeffnen(context)),
          child: const Text('los'),
        ),
      ),
    ),
  ));
  await t.tap(find.text('los'));
  await t.pumpAndSettle();
  return ergebnisse;
}

void main() {
  test('Kamera nur auf Telefonen', () {
    for (final (p, erwartet) in [
      (TargetPlatform.android, true),
      (TargetPlatform.iOS, true),
      (TargetPlatform.linux, false),
      (TargetPlatform.macOS, false),
      (TargetPlatform.windows, false),
    ]) {
      debugDefaultTargetPlatformOverride = p;
      expect(mitKamera, erwartet, reason: '$p');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Linux: Eingabeseite statt Kamera, Feld hat den Fokus, Enter geht weiter', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final ergebnisse = await _oeffnen(t);
    expect(find.byType(BarcodeEingabeSeite), findsOneWidget);
    expect(find.byType(ScannerSeite), findsNothing);
    final feld = t.widget<TextField>(find.byKey(const Key('barcode-feld')));
    expect(feld.focusNode!.hasFocus, isTrue);
    // So tippt ein USB-Scanner: Ziffern, dann Enter.
    t.testTextInput.enterText(' 7610000000017 ');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(ergebnisse, ['7610000000017']);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Linux: zu kurz -> Hinweis, Fokus bleibt, nichts zurueck', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final ergebnisse = await _oeffnen(t);
    await t.enterText(find.byKey(const Key('barcode-feld')), '12');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(ergebnisse, isEmpty);
    expect(find.textContaining('ganzen Barcode'), findsOneWidget);
    expect(t.widget<TextField>(find.byKey(const Key('barcode-feld'))).focusNode!.hasFocus, isTrue);
    // Der Knopf "Weiter" geht auch.
    await t.enterText(find.byKey(const Key('barcode-feld')), '4006381333931');
    await t.tap(find.byKey(const Key('barcode-weiter')));
    await t.pumpAndSettle();
    expect(ergebnisse, ['4006381333931']);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Linux: zurueck ohne Eingabe -> null (Ablauf bricht ab)', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final ergebnisse = await _oeffnen(t);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(ergebnisse, [null]);
    debugDefaultTargetPlatformOverride = null;
  });
}

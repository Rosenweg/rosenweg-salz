// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosenweg_basis/rosenweg_basis.dart';
import 'package:rosenweg_salz/oberflaeche/umgebung.dart';
import 'package:rosenweg_salz/salz/modell.dart';

import 'attrappen.dart';

class MerkerAttrappe extends Merker {
  int? lager;
  @override
  Future<int?> letztesLager() async => lager;
  @override
  Future<void> merkeLager(int id) async => lager = id;
}

int abgemeldet = 0;

Future<QuelleAttrappe> starten(WidgetTester t,
    {String? scan = '7610000000017', bool darf = true, bool sortenErfassen = true, List<Lager>? lager}) async {
  final q = QuelleAttrappe(darf: darf, sortenErfassen: sortenErfassen);
  if (lager != null) q.liste = lager;
  await t.pumpWidget(testApp(Umgebung(
    quelle: q,
    scannen: (_) async => scan,
    abmelden: () async => abgemeldet++,
    merker: MerkerAttrappe(),
  )));
  await t.pumpAndSettle();
  return q;
}

void main() {
  testWidgets('Startseite: zwei grosse Knoepfe, alle Lager mit Bestand und Reichweite', (t) async {
    await starten(t);
    expect(find.text('Anlieferung'), findsOneWidget);
    expect(find.text('Sack eingefüllt'), findsOneWidget);
    expect(find.text('Rosenweg 2'), findsOneWidget);
    expect(find.text('12 Säcke'), findsOneWidget);
    expect(find.text('reicht etwa 9.5 Wochen'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Noch nichts gebucht'), 200);
    expect(find.textContaining('Rosenweg Kooperation', findRichText: true), findsOneWidget);
    expect(find.textContaining('Lager im Rosenweg 10', findRichText: true), findsOneWidget);
  });

  testWidgets('Abmelden fragt nach', (t) async {
    await starten(t);
    await t.tap(find.byType(PopupMenuButton<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Abmelden'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Abmelden'));
    await t.pumpAndSettle();
    expect(abgemeldet, 1);
  });

  testWidgets('geteiltes Telefon, niemand angemeldet: Hinweis zur Karte statt endlos laden, kein Abmelden', (t) async {
    final q = _NiemandAngemeldet();
    await t.pumpWidget(testApp(Umgebung(quelle: q, scannen: (_) async => null, abmelden: () async {}, darfAbmelden: false)));
    await t.pumpAndSettle();
    expect(find.textContaining('mit der Karte anmelden'), findsOneWidget);
    expect(find.text('Nochmals'), findsOneWidget);
    q.angemeldet = true;
    await t.tap(find.text('Nochmals'));
    await t.pumpAndSettle();
    expect(find.text('Anlieferung'), findsOneWidget);
    await t.tap(find.byType(PopupMenuButton<String>));
    await t.pumpAndSettle();
    expect(find.text('Abmelden'), findsNothing);
  });

  testWidgets('ohne Freigabe -> Hinweis', (t) async {
    await starten(t, darf: false);
    expect(find.textContaining('nicht freigeschaltet'), findsOneWidget);
  });

  testWidgets('Anlieferung mit neuem Barcode: Sorte erfassen, Anzahl, buchen, Rueckmeldung', (t) async {
    final q = await starten(t);
    await t.tap(find.byKey(const Key('knopf-anlieferung')));
    await t.pumpAndSettle();
    expect(find.text('Wo?'), findsOneWidget);
    await t.tap(find.byKey(const Key('lager-3')));
    await t.pumpAndSettle();
    expect(find.text('Neuer Sack'), findsOneWidget);
    await t.enterText(find.byKey(const Key('sorte-name')), 'Regeneriersalz Tabletten');
    await t.tap(find.byKey(const Key('sorte-speichern')));
    await t.pumpAndSettle();
    expect(q.sorten['7610000000017']!.gewichtKg, 25);
    expect(find.text('Wie viele Säcke?'), findsOneWidget);
    await t.tap(find.text('20'));
    await t.pump();
    await t.tap(find.byKey(const Key('mehr')));
    await t.pump();
    expect(find.text('21'), findsOneWidget);
    await t.tap(find.byKey(const Key('buchen')));
    await t.pumpAndSettle();
    expect(q.buchungen.single['saecke'], 21);
    expect(q.buchungen.single['art'], 'anlieferung');
    expect(q.buchungen.single['lager'], 3);
    expect(find.textContaining('+21 Säcke angeliefert'), findsOneWidget);
    expect(find.text('27 Säcke'), findsOneWidget);
  });

  testWidgets('Sack eingefuellt: bekannter Barcode bucht direkt einen Sack ab', (t) async {
    final q = await starten(t);
    q.sorten['7610000000017'] = Sorte(barcode: '7610000000017', bezeichnung: 'Tabletten', gewichtKg: 25);
    await t.tap(find.byKey(const Key('knopf-eingefuellt')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('lager-1')));
    await t.pumpAndSettle();
    expect(q.buchungen.single['saecke'], 1);
    expect(q.buchungen.single['art'], 'eingefuellt');
    expect(find.text('11 Säcke'), findsOneWidget);
  });

  testWidgets('Fehler beim Buchen bleibt sichtbar, mit Weg zurueck', (t) async {
    final q = await starten(t);
    q.sorten['7610000000017'] = Sorte(barcode: '7610000000017', bezeichnung: 'Tabletten', gewichtKg: 25);
    q.buchenFehler = ApiFehler(409, 'Laut Bestand ist in diesem Lager kein Sack mehr. Bitte zuerst die Anlieferung buchen.');
    await t.tap(find.byKey(const Key('knopf-eingefuellt')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('lager-4')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('fehler')), findsOneWidget);
    expect(find.textContaining('zuerst die Anlieferung'), findsOneWidget);
    expect(find.text('Nochmals scannen'), findsOneWidget);
  });

  testWidgets('Bewohnerin mit einem Lager: keine Lagerwahl, gleich scannen und buchen', (t) async {
    final q = await starten(t, sortenErfassen: false, lager: [neuesLager(3, 'Rosenweg 9', 9, saecke: 6)]);
    q.sorten['7610000000017'] = Sorte(barcode: '7610000000017', bezeichnung: 'Tabletten', gewichtKg: 25);
    expect(find.text('Rosenweg 9'), findsOneWidget);
    await t.tap(find.byKey(const Key('knopf-eingefuellt')));
    await t.pumpAndSettle();
    expect(find.text('Wo?'), findsNothing);
    expect(q.buchungen.single['lager'], 3);
    expect(find.text('5 Säcke'), findsOneWidget);
  });

  testWidgets('Bewohnerin mit unbekanntem Barcode: Hinweis statt Sorten-Formular', (t) async {
    final q = await starten(t, sortenErfassen: false, lager: [neuesLager(3, 'Rosenweg 9', 9, saecke: 6)]);
    await t.tap(find.byKey(const Key('knopf-anlieferung')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sorte-unbekannt')), findsOneWidget);
    expect(find.byKey(const Key('sorte-name')), findsNothing);
    expect(q.buchungen, isEmpty);
  });

  testWidgets('Scan abgebrochen bei nur einem Lager: zurueck zur Startseite', (t) async {
    await starten(t, scan: null, lager: [neuesLager(3, 'Rosenweg 9', 9, saecke: 6)]);
    await t.tap(find.byKey(const Key('knopf-anlieferung')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('knopf-anlieferung')), findsOneWidget);
  });

  testWidgets('Startseite zeigt den naechsten Sack, ohne Termin keine Zeile', (t) async {
    final in3 = DateTime.now().add(const Duration(days: 3));
    await starten(
      t,
      lager: [
        neuesLager(3, 'Rosenweg 9', 9, saecke: 20, wochen: 9, naechster: DateTime(in3.year, in3.month, in3.day)),
        neuesLager(1, 'Rosenweg 2', 2, saecke: 4),
      ],
    );
    expect(find.textContaining('Nächster Sack etwa am'), findsOneWidget);
    expect(find.byIcon(Icons.event_outlined), findsOneWidget);
  });

  group('Desktop (Fenster 1280 x 800)', () {
    // Am Desktop (kein Kamera-Scan): Linux-Station.
    final linux = TargetPlatformVariant.only(TargetPlatform.linux);

    Future<QuelleAttrappe> desktop(WidgetTester t) {
      t.view.physicalSize = const Size(1280, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      return starten(t);
    }

    testWidgets('Startseite: Buchen links, Lager rechts nebeneinander, Neu laden', (t) async {
      await desktop(t);
      expect(find.text('Buchen'), findsOneWidget);
      expect(find.byKey(const Key('neu-laden')), findsOneWidget);
      final knopf = t.getRect(find.byKey(const Key('knopf-anlieferung')));
      final lager2 = t.getRect(find.text('Rosenweg 2'));
      final lager4 = t.getRect(find.text('Rosenweg 4'));
      expect(knopf.width, lessThan(400));
      expect(lager2.left, greaterThan(knopf.right));
      expect(lager4.top, lager2.top, reason: 'Kacheln nebeneinander');
    }, variant: linux);

    testWidgets('Tastatur: Ziffer waehlt das Lager, Pfeil aendert, Enter bucht', (t) async {
      final q = await desktop(t);
      q.sorten['7610000000017'] = Sorte(barcode: '7610000000017', bezeichnung: 'Tabletten', gewichtKg: 25);
      await t.tap(find.byKey(const Key('knopf-anlieferung')));
      await t.pumpAndSettle();
      expect(find.text('3'), findsOneWidget, reason: 'Tastenkappe am dritten Lager');
      await t.sendKeyEvent(LogicalKeyboardKey.digit3);
      await t.pumpAndSettle();
      expect(find.text('Wie viele Säcke?'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      expect(find.byKey(const Key('anzahl')), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(q.buchungen.single['lager'], 3);
      expect(q.buchungen.single['saecke'], 11);
    }, variant: linux);
  });
}

class _NiemandAngemeldet extends QuelleAttrappe {
  bool angemeldet = false;
  @override
  Future<Ich> ich() async {
    if (!angemeldet) throw NichtAngemeldet('Am Telefon ist niemand angemeldet. Bitte zuerst mit der Karte anmelden.');
    return super.ich();
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
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

Future<QuelleAttrappe> starten(WidgetTester t, {String? scan = '7610000000017', bool darf = true}) async {
  final q = QuelleAttrappe(darf: darf);
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
    await t.scrollUntilVisible(find.text('Kooperation'), 200);
    expect(find.text('Noch nichts gebucht'), findsOneWidget);
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
}

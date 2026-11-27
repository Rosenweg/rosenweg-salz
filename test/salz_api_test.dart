// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:rosenweg_basis/rosenweg_basis.dart';
import 'package:rosenweg_salz/salz/modell.dart';
import 'package:rosenweg_salz/salz/salz_api.dart';

import 'attrappen.dart';

const lagerJson = {
  'id': 3, 'name': 'Rosenweg 9', 'haus': 9, 'in_betrieb': true, 'bestand_saecke': 11, 'bestand_kg': 275,
  'verbrauch_kg_woche': 25, 'reichweite_wochen': 11, 'modus': 'reichweite', 'knapp': false,
  'schwelle_wochen': 4, 'mindest_saecke': 4, 'meldung_seit': null,
};

SalzApi api(ApiAntwort Function(String m, String p, Object? k) f) => SalzApi(RosenwegApi(TransportAttrappe(f)));

void main() {
  test('Lager lesen', () async {
    final l = await api((m, p, k) {
      expect(p, '/api/salz/lager');
      return (status: 200, json: {'lager': [lagerJson]});
    }).lager();
    expect(l.single.name, 'Rosenweg 9');
    expect(l.single.reichweiteText, 'reicht etwa 11 Wochen');
  });

  test('unbekannter Barcode -> null, Barcode im Pfad kodiert', () async {
    final s = await api((m, p, k) {
      expect(p, '/api/salz/sorten/76%2F10');
      return (status: 404, json: {'error': 'Unbekannter Barcode', 'unbekannt': true});
    }).sorte('76/10');
    expect(s, isNull);
  });

  test('401 -> NichtAngemeldet', () async {
    await expectLater(api((m, p, k) => (status: 401, json: {'error': 'Anmeldung abgelaufen'})).lager(),
        throwsA(isA<NichtAngemeldet>()));
  });

  test('403 -> KeineBerechtigung mit Text der API', () async {
    await expectLater(api((m, p, k) => (status: 403, json: {'error': 'Nicht freigeschaltet'})).lager(),
        throwsA(isA<KeineBerechtigung>().having((e) => e.text, 'text', 'Nicht freigeschaltet')));
  });

  test('Buchen schickt client_id; 409 wird lesbarer Fehler', () async {
    var n = 0;
    final a = api((m, p, k) {
      n++;
      expect(m, 'POST');
      expect((k as Map)['client_id'], 'abcdefgh-1234');
      expect(k['art'], 'eingefuellt');
      expect(k['saecke'], 1);
      return n == 1
          ? (status: 201, json: {'buchung_id': 7, 'lager': lagerJson})
          : (status: 409, json: {'error': 'Bitte zuerst die Anlieferung buchen.'});
    });
    final b = await a.buchen(lagerId: 3, art: Art.eingefuellt, barcode: '7610000000001', clientId: 'abcdefgh-1234');
    expect(b.id, 7);
    await expectLater(a.buchen(lagerId: 3, art: Art.eingefuellt, barcode: '7610000000001', clientId: 'abcdefgh-1234'),
        throwsA(isA<ApiFehler>().having((e) => e.status, 'status', 409).having((e) => e.text, 'text', contains('Anlieferung'))));
  });

  test('client_id ist eindeutig und passt zur API', () {
    final a = neueClientId(), b = neueClientId();
    expect(a, isNot(b));
    expect(RegExp(r'^[A-Za-z0-9-]{8,64}$').hasMatch(a), isTrue);
  });

  test('Ich: Lager und Sorten-Recht; Lager mit Ort', () async {
    final ich = await api((m, p, k) => (status: 200, json: {
          'name': 'Bea', 'darf_buchen': true, 'darf_einstellen': false, 'darf_sorten_erfassen': false, 'lager_ids': [3],
        })).ich();
    expect(ich.lagerIds, [3]);
    expect(ich.darfSortenErfassen, isFalse);
    final l = Lager.ausJson({...lagerJson, 'name': 'Rosenweg Kooperation', 'haus': null, 'ort': 'Lager im Rosenweg 10'});
    expect(l.ort, 'Lager im Rosenweg 10');
  });

  test('Naechster Sack: aus der API und als Text', () {
    final l = Lager.ausJson({...lagerJson, 'naechster_sack': '2026-12-03'});
    expect(l.naechsterSack, DateTime(2026, 12, 3));
    expect(l.naechsterSackText(heute: DateTime(2026, 11, 28, 18)), 'Nächster Sack etwa am Do, 3. Dez.');
    expect(l.naechsterSackText(heute: DateTime(2026, 12, 2, 9)), 'Nächster Sack etwa morgen (Do, 3. Dez.)');
    expect(l.naechsterSackText(heute: DateTime(2026, 12, 3, 23)), 'Nächster Sack etwa heute');
    expect(l.naechsterSackText(heute: DateTime(2026, 12, 5)), 'Nächster Sack war etwa am Do, 3. Dez. fällig');
    expect(Lager.ausJson(lagerJson).naechsterSackText(), isNull);
  });

  test('Ohne Termin: Hinweis des Servers, sonst ein allgemeiner; mit Termin keiner', () {
    final h = Lager.ausJson({...lagerJson, 'naechster_sack': null, 'naechster_sack_hinweis': 'Noch zu wenig Daten'});
    expect(h.naechsterSackOhneTermin, 'Noch zu wenig Daten');
    expect(Lager.ausJson(lagerJson).naechsterSackOhneTermin, startsWith('Nächster Sack: noch keine'));
    expect(Lager.ausJson({...lagerJson, 'naechster_sack': '2026-12-03'}).naechsterSackOhneTermin, isNull);
    expect(neuesLager(1, 'K', null, inBetrieb: false).naechsterSackOhneTermin, isNull);
  });

  test('Reichweite-Text', () {
    expect(neuesLager(1, 'R2', 2, saecke: 1, wochen: 1).reichweiteText, 'reicht etwa 1 Woche');
    expect(neuesLager(1, 'R2', 2, saecke: 1, wochen: 0.4).reichweiteText, 'reicht weniger als 1 Woche');
    expect(neuesLager(1, 'R2', 2, saecke: 3, wochen: 2.5).reichweiteText, 'reicht etwa 2.5 Wochen');
    expect(neuesLager(1, 'R2', 2, saecke: 3).reichweiteText, startsWith('Reichweite folgt'));
    expect(neuesLager(1, 'K', null, inBetrieb: false).reichweiteText, 'Noch nichts gebucht');
    expect(neuesLager(1, 'R2', 2, saecke: 1).saeckeText, '1 Sack');
  });
}

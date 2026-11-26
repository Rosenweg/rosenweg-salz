// SPDX-License-Identifier: GPL-3.0-or-later
// Attrappen fuer Tests: Salz-API, Transport und App-Rahmen ohne Server.
import 'package:flutter/material.dart';
import 'package:rosenweg_basis/rosenweg_basis.dart';
import 'package:rosenweg_salz/oberflaeche/salz_haupt.dart';
import 'package:rosenweg_salz/oberflaeche/umgebung.dart';
import 'package:rosenweg_salz/salz/modell.dart';
import 'package:rosenweg_salz/salz/salz_api.dart';

/// Antwortet auf Anfragen wie die API; [antwort] bekommt Methode, Pfad, Koerper.
class TransportAttrappe implements Transport {
  TransportAttrappe(this.antwort);
  final ApiAntwort Function(String methode, String pfad, Object? koerper) antwort;
  @override
  Future<ApiAntwort> senden(String methode, String pfad, {Object? koerper}) async => antwort(methode, pfad, koerper);
}

/// Wie RosenwegRahmen, aber ohne Sitzung: Thema der Basis, direkt die App.
Widget testApp(Umgebung u) => MaterialApp(
      theme: rosenwegThema(Brightness.light),
      debugShowCheckedModeBanner: false,
      home: SalzHaupt(umgebung: u),
    );

Lager neuesLager(int id, String name, int? haus, {int saecke = 0, double? wochen, bool knapp = false, bool inBetrieb = true, String? ort}) => Lager(
      id: id, name: name, haus: haus, ort: ort, inBetrieb: inBetrieb, bestandSaecke: saecke, bestandKg: saecke * 25.0,
      verbrauchKgWoche: wochen == null ? null : 25, reichweiteWochen: wochen,
      modus: wochen == null ? 'mindestbestand' : 'reichweite', knapp: knapp, schwelleWochen: 4, mindestSaecke: 4, meldungSeit: null);

class QuelleAttrappe implements SalzQuelle {
  QuelleAttrappe({this.darf = true, this.sortenErfassen = true});
  bool darf;
  bool sortenErfassen;
  final sorten = <String, Sorte>{};
  final buchungen = <Map<String, Object>>[];
  Object? buchenFehler;
  List<Lager> liste = [
    neuesLager(1, 'Rosenweg 2', 2, saecke: 12, wochen: 9.5),
    neuesLager(2, 'Rosenweg 4', 4, saecke: 3, wochen: 2.5, knapp: true),
    neuesLager(3, 'Rosenweg 9', 9, saecke: 6),
    neuesLager(4, 'Rosenweg Kooperation', null, inBetrieb: false, ort: 'Lager im Rosenweg 10'),
  ];

  @override
  Future<Ich> ich() async => Ich(
      name: 'Test Person', darfBuchen: darf, darfEinstellen: false, darfSortenErfassen: sortenErfassen,
      lagerIds: [for (final l in liste) l.id]);
  @override
  Future<List<Lager>> lager() async => liste;
  @override
  Future<Sorte?> sorte(String barcode) async => sorten[barcode];
  @override
  Future<Sorte> sorteAnlegen(String barcode, String bezeichnung, double gewichtKg) async =>
      sorten[barcode] = Sorte(barcode: barcode, bezeichnung: bezeichnung, gewichtKg: gewichtKg);
  @override
  Future<Buchung> buchen({required int lagerId, required Art art, required String barcode, int saecke = 1, required String clientId}) async {
    final f = buchenFehler;
    if (f != null) throw f;
    buchungen.add({'lager': lagerId, 'art': art.wert, 'barcode': barcode, 'saecke': saecke, 'client_id': clientId});
    final alt = liste.firstWhere((l) => l.id == lagerId);
    final neu = mitBestand(alt, art == Art.anlieferung ? saecke : -saecke);
    liste = [for (final l in liste) l.id == lagerId ? neu : l];
    return Buchung(id: buchungen.length, lager: neu);
  }

  @override
  Future<Lager> rueckgaengig(int buchungId) async => liste.first;
}

Lager mitBestand(Lager a, int d) => neuesLager(a.id, a.name, a.haus, saecke: a.bestandSaecke + d, wochen: a.reichweiteWochen, ort: a.ort);

// SPDX-License-Identifier: GPL-3.0-or-later
/// Die Salz-API der Rosenweg-API (/api/salz), ueber den API-Client von
/// rosenweg_basis (Anmeldung, 502/HTML/429, geteilte Telefone).
library;

import 'dart:math';

import 'package:rosenweg_basis/rosenweg_basis.dart';

import 'modell.dart';

/// Schnittstelle, damit sich die Seiten ohne Server pruefen lassen.
abstract class SalzQuelle {
  Future<Ich> ich();
  Future<List<Lager>> lager();

  /// null = Barcode unbekannt.
  Future<Sorte?> sorte(String barcode);
  Future<Sorte> sorteAnlegen(String barcode, String bezeichnung, double gewichtKg);
  Future<Buchung> buchen({required int lagerId, required Art art, required String barcode, int saecke = 1, required String clientId});
  Future<Lager> rueckgaengig(int buchungId);
}

/// Eindeutige Kennung je Buchung: dieselbe Buchung nochmals gesendet
/// (z. B. „Nochmals versuchen“ nach einem Netzfehler) bucht nicht doppelt.
String neueClientId() {
  final r = Random.secure();
  final hex = List<String>.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class SalzApi implements SalzQuelle {
  SalzApi(this.api);
  final RosenwegApi api;

  static const _p = '/api/salz';

  Map<String, dynamic> _objekt(Object? j) =>
      j is Map<String, dynamic> ? j : throw ApiFehler(200, 'Unerwartete Antwort vom Server.', j);

  @override
  Future<Ich> ich() async => Ich.ausJson(await api.objekt('$_p/ich'));

  @override
  Future<List<Lager>> lager() async {
    final j = await api.objekt('$_p/lager');
    return (j['lager'] as List? ?? []).whereType<Map<String, dynamic>>().map(Lager.ausJson).toList();
  }

  @override
  Future<Sorte?> sorte(String barcode) async {
    try {
      final j = await api.objekt('$_p/sorten/${Uri.encodeComponent(barcode)}');
      return Sorte.ausJson(j['sorte'] as Map<String, dynamic>);
    } on ApiFehler catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Sorte> sorteAnlegen(String barcode, String bezeichnung, double gewichtKg) async {
    final j = _objekt(await api.post('$_p/sorten', {'barcode': barcode, 'bezeichnung': bezeichnung, 'gewicht_kg': gewichtKg}));
    return Sorte.ausJson(j['sorte'] as Map<String, dynamic>);
  }

  @override
  Future<Buchung> buchen({required int lagerId, required Art art, required String barcode, int saecke = 1, required String clientId}) async {
    final j = _objekt(await api.post('$_p/buchungen',
        {'lager_id': lagerId, 'art': art.wert, 'barcode': barcode, 'saecke': saecke, 'client_id': clientId}));
    return Buchung(id: (j['buchung_id'] as num).toInt(), lager: Lager.ausJson(j['lager'] as Map<String, dynamic>));
  }

  @override
  Future<Lager> rueckgaengig(int buchungId) async {
    final j = _objekt(await api.delete('$_p/buchungen/$buchungId'));
    return Lager.ausJson(j['lager'] as Map<String, dynamic>);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/// Was die Seiten von aussen brauchen — austauschbar fuer Tests.
library;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../salz/salz_api.dart';

/// Oeffnet den Scanner und liefert den gelesenen Barcode (null = abgebrochen).
typedef Scannen = Future<String?> Function(BuildContext context);

class Umgebung {
  Umgebung({required this.quelle, required this.scannen, required this.abmelden, this.darfAbmelden = true, Merker? merker})
      : merker = merker ?? Merker();
  final SalzQuelle quelle;
  final Scannen scannen;

  /// Abmelden (Sitzung von rosenweg_basis). Auf geteilten Telefonen meldet
  /// Rosenweg Geraet an und ab, dann gibt es den Menuepunkt nicht.
  final Future<void> Function() abmelden;
  final bool darfAbmelden;

  /// Geteiltes Telefon (Rosenweg Geraet meldet an und ab): ohne angemeldete
  /// Person zeigt die App den Hinweis zur Karte — einen Anmeldeschirm gibt es
  /// hier nicht, die Sitzung wechselt also auch nicht dorthin.
  bool get geteiltesTelefon => !darfAbmelden;
  final Merker merker;
}

/// Merkt sich das zuletzt gewaehlte Lager, damit es beim naechsten Mal vorne steht.
class Merker {
  int? _lager;
  Future<int?> letztesLager() async {
    if (_lager != null) return _lager;
    try {
      return _lager = (await SharedPreferences.getInstance()).getInt('letztes_lager');
    } catch (_) {
      return null;
    }
  }

  Future<void> merkeLager(int id) async {
    _lager = id;
    try {
      await (await SharedPreferences.getInstance()).setInt('letztes_lager', id);
    } catch (_) {
      // nur eine Bequemlichkeit
    }
  }
}

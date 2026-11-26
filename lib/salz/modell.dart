// SPDX-License-Identifier: GPL-3.0-or-later
/// Daten der Salz-API (Rosenweg/Website, api/routes/salz.js).
library;

double? _zahl(Object? v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
DateTime? _zeit(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

class Lager {
  Lager({
    required this.id,
    required this.name,
    required this.haus,
    this.ort,
    required this.inBetrieb,
    required this.bestandSaecke,
    required this.bestandKg,
    required this.verbrauchKgWoche,
    required this.reichweiteWochen,
    required this.modus,
    required this.knapp,
    required this.schwelleWochen,
    required this.mindestSaecke,
    required this.meldungSeit,
  });

  factory Lager.ausJson(Map<String, dynamic> j) => Lager(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        haus: (j['haus'] as num?)?.toInt(),
        ort: j['ort'] as String?,
        inBetrieb: j['in_betrieb'] == true,
        bestandSaecke: (j['bestand_saecke'] as num?)?.toInt() ?? 0,
        bestandKg: _zahl(j['bestand_kg']) ?? 0,
        verbrauchKgWoche: _zahl(j['verbrauch_kg_woche']),
        reichweiteWochen: _zahl(j['reichweite_wochen']),
        modus: j['modus'] as String? ?? 'mindestbestand',
        knapp: j['knapp'] == true,
        schwelleWochen: _zahl(j['schwelle_wochen']) ?? 4,
        mindestSaecke: (j['mindest_saecke'] as num?)?.toInt() ?? 0,
        meldungSeit: _zeit(j['meldung_seit']),
      );

  final int id;
  final String name;
  final int? haus;

  /// Wo das Lager steht, falls nicht im Namen ("Lager im Rosenweg 10").
  final String? ort;
  final bool inBetrieb;
  final int bestandSaecke;
  final double bestandKg;
  final double? verbrauchKgWoche;
  final double? reichweiteWochen;
  final String modus;
  final bool knapp;
  final double schwelleWochen;
  final int mindestSaecke;
  final DateTime? meldungSeit;

  /// "Rosenweg 9" -> "9", "Kooperation" -> "K" (fuer die grossen Wahlknoepfe).
  String get kurz => haus?.toString() ?? name.substring(0, 1);

  String get saeckeText => '$bestandSaecke ${bestandSaecke == 1 ? 'Sack' : 'Säcke'}';

  /// Eine Zeile fuer die Startseite.
  String get reichweiteText {
    if (!inBetrieb) return 'Noch nichts gebucht';
    final w = reichweiteWochen;
    if (modus == 'reichweite' && w != null) {
      if (w < 1) return 'reicht weniger als 1 Woche';
      final z = w >= 10 ? w.round().toString() : w.toStringAsFixed(w == w.roundToDouble() ? 0 : 1);
      return 'reicht etwa $z ${z == '1' ? 'Woche' : 'Wochen'}';
    }
    return 'Reichweite folgt nach ein paar Einfüllungen';
  }
}

class Sorte {
  Sorte({required this.barcode, required this.bezeichnung, required this.gewichtKg});
  factory Sorte.ausJson(Map<String, dynamic> j) => Sorte(
        barcode: j['barcode'] as String,
        bezeichnung: j['bezeichnung'] as String? ?? '',
        gewichtKg: _zahl(j['gewicht_kg']) ?? 0,
      );
  final String barcode;
  final String bezeichnung;
  final double gewichtKg;

  String get gewichtText => '${gewichtKg == gewichtKg.roundToDouble() ? gewichtKg.round() : gewichtKg} kg';
}

class Ich {
  Ich({required this.name, required this.darfBuchen, required this.darfEinstellen, this.darfSortenErfassen = false, this.lagerIds = const []});
  factory Ich.ausJson(Map<String, dynamic> j) => Ich(
        name: j['name'] as String?,
        darfBuchen: j['darf_buchen'] == true,
        darfEinstellen: j['darf_einstellen'] == true,
        darfSortenErfassen: j['darf_sorten_erfassen'] == true,
        lagerIds: (j['lager_ids'] as List? ?? const []).whereType<num>().map((n) => n.toInt()).toList(),
      );
  final String? name;
  final bool darfBuchen;
  final bool darfEinstellen;

  /// Neuen Barcode einmal erfassen (Technik); Bewohner bitten die Technik.
  final bool darfSortenErfassen;

  /// Lager, in denen diese Person buchen darf (Bewohner: ihr Haus).
  final List<int> lagerIds;
}

enum Art {
  anlieferung('anlieferung'),
  eingefuellt('eingefuellt');

  const Art(this.wert);
  final String wert;
}

class Buchung {
  Buchung({required this.id, required this.lager});
  final int id;
  final Lager lager;
}

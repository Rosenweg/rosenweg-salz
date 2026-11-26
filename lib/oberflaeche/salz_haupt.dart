// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:rosenweg_basis/rosenweg_basis.dart';

import '../salz/modell.dart';
import 'start_seite.dart';
import 'thema.dart';
import 'umgebung.dart';

/// Nach der Anmeldung: darf diese Person buchen? Dann Startseite, sonst Hinweis.
class SalzHaupt extends StatefulWidget {
  const SalzHaupt({super.key, required this.umgebung});
  final Umgebung umgebung;
  @override
  State<SalzHaupt> createState() => _SalzHauptState();
}

class _SalzHauptState extends State<SalzHaupt> {
  Ich? _ich;
  Object? _fehler;

  @override
  void initState() {
    super.initState();
    _pruefen();
  }

  Future<void> _pruefen() async {
    setState(() { _fehler = null; _ich = null; });
    try {
      final ich = await widget.umgebung.quelle.ich();
      if (mounted) setState(() => _ich = ich);
    } on NichtAngemeldet catch (e) {
      // Eigenes Handy: die Sitzung wechselt selbst zum Anmeldeschirm.
      // Geteiltes Telefon: "Bitte zuerst mit der Karte anmelden", mit Nochmals.
      if (mounted && widget.umgebung.geteiltesTelefon) setState(() => _fehler = e);
    } catch (e) {
      if (mounted) setState(() => _fehler = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ich = _ich;
    final Widget inhalt;
    if (_fehler != null) {
      inhalt = Scaffold(body: FehlerAnzeige(text: '$_fehler', nochmals: _pruefen));
    } else if (ich == null) {
      inhalt = const Scaffold(body: LadeAnzeige());
    } else if (!ich.darfBuchen) {
      inhalt = Scaffold(
        body: FehlerAnzeige(
          titel: 'Nicht freigeschaltet',
          text: 'Du bist angemeldet${ich.name != null ? ' als ${ich.name}' : ''}, aber für den Salzvorrat nicht '
              'freigeschaltet. Bitte bei der Technik melden.',
          nochmals: _pruefen,
        ),
      );
    } else {
      inhalt = StartSeite(umgebung: widget.umgebung, ich: ich);
    }
    return Theme(data: salzThema(Theme.of(context)), child: inhalt);
  }
}

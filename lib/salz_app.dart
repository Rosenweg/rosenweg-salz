// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/painting.dart';
import 'package:rosenweg_basis/rosenweg_basis.dart';

/// Angaben der App fuer rosenweg_basis. kennung = applicationId = Schema des
/// Ruecksprungs (ch.rosenweg4303.salz:/anmeldung, in Authentik eintragen).
const salzApp = RosenwegApp(
  kennung: 'ch.rosenweg4303.salz',
  name: 'Rosenweg Salz',
  ordner: 'rosenweg-salz',
  beschreibung: 'Salzvorrat der Enthärtungsanlagen: Anlieferung und eingefüllte Säcke buchen.',
  logo: AssetImage('assets/logo/rosenweg-salz-512.png'),
  // Anmeldeschirm in der Gruppenfarbe (rosenweg_basis 0.6.1), wie das Logo
  gruppe: RosenwegGruppe.bewohner,
  // Farbe nach freigeschalteter Funktion (rosenweg-basis docs/gruppenfarbe.md): Technik/Praesident: alle Lager, neue Sorten erfassen
  farbGruppen: {RosenwegGruppe.technik},
);

// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:rosenweg_basis/rosenweg_basis.dart';

import 'oberflaeche/salz_haupt.dart';
import 'oberflaeche/scanner_seite.dart';
import 'oberflaeche/umgebung.dart';
import 'salz/salz_api.dart';
import 'salz_app.dart';

void main() => rosenwegStarten(
      salzApp,
      (sitzung) => SalzHaupt(
        umgebung: Umgebung(
          quelle: SalzApi(sitzung.api),
          scannen: scannerOeffnen,
          abmelden: sitzung.abmelden,
          darfAbmelden: !sitzung.geteiltesTelefon,
        ),
      ),
    );

// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// Das Rosenweg-Thema (rosenweg_basis) mit grossen Knoepfen: die App wird
/// im Keller mit einer Hand bedient, oft mit Handschuhen.
ThemeData salzThema(ThemeData basis) {
  final gross = basis.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
  final mittel = basis.textTheme.titleMedium?.copyWith(fontSize: 18);
  return basis.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        textStyle: gross,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: mittel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

/// Ampel der Lagerkarten.
class SalzFarben {
  static const gut = Color(0xFF15803D);
  static const neutral = Color(0xFF64748B);
  static Color knapp(BuildContext c) => Theme.of(c).colorScheme.error;
}

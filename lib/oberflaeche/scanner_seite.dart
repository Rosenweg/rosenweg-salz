// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Lesen mit der Kamera nur auf Telefonen. Am Desktop (Stationen mit Linux,
/// macOS, Windows) gibt es keine Kamera zum Scannen; dort ein Eingabefeld,
/// in das auch ein USB-Barcode-Scanner tippt (er verhaelt sich wie eine
/// Tastatur: Ziffern, dann Enter).
bool get mitKamera =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Kamera auf, Barcode des Sacks lesen, zurueck. Geht die Kamera nicht oder
/// ist der Strichcode zerkratzt: Nummer eintippen. Ohne Kamera (Desktop)
/// gleich die Eingabeseite.
Future<String?> scannerOeffnen(BuildContext context) =>
    Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (_) => Theme(data: Theme.of(context), child: mitKamera ? const ScannerSeite() : const BarcodeEingabeSeite())));

class ScannerSeite extends StatefulWidget {
  const ScannerSeite({super.key});
  @override
  State<ScannerSeite> createState() => _ScannerSeiteState();
}

class _ScannerSeiteState extends State<ScannerSeite> {
  final _steuerung = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE,
      BarcodeFormat.code128, BarcodeFormat.code39, BarcodeFormat.itf14, BarcodeFormat.qrCode,
    ],
  );
  bool _fertig = false;

  @override
  void dispose() {
    _steuerung.dispose();
    super.dispose();
  }

  void _gelesen(BarcodeCapture c) {
    if (_fertig) return;
    final wert = c.barcodes.map((b) => b.rawValue?.trim() ?? '').firstWhere((v) => v.length >= 4, orElse: () => '');
    if (wert.isEmpty) return;
    _fertig = true;
    Navigator.of(context).pop(wert);
  }

  Future<void> _eintippen() async {
    final wert = await barcodeEintippen(context);
    if (wert != null && mounted) {
      _fertig = true;
      Navigator.of(context).pop(wert);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode auf dem Sack')),
      body: Column(children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            MobileScanner(
              controller: _steuerung,
              onDetect: _gelesen,
              errorBuilder: (context, fehler) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Die Kamera lässt sich nicht öffnen. Bitte die Nummer unter dem Strichcode eintippen.',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 280, height: 160,
                  decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _eintippen, icon: const Icon(Icons.keyboard), label: const Text('Nummer eintippen'))),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                iconSize: 32,
                tooltip: 'Licht',
                onPressed: () => _steuerung.toggleTorch(),
                icon: const Icon(Icons.flashlight_on),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Barcode von Hand: die Ziffern unter dem Strichcode.
Future<String?> barcodeEintippen(BuildContext context) {
  final feld = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nummer unter dem Strichcode'),
      content: TextField(
        controller: feld,
        autofocus: true,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 22, letterSpacing: 1.5),
        decoration: const InputDecoration(hintText: 'z. B. 7610000000000'),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim().isEmpty ? null : v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
          onPressed: () => Navigator.of(context).pop(feld.text.trim().length >= 4 ? feld.text.trim() : null),
          child: const Text('Weiter'),
        ),
      ],
    ),
  );
}

/// Desktop: Barcode per USB-Scanner oder von Hand. Das Feld hat sofort den
/// Fokus und behaelt ihn, Enter (vom Scanner mitgeschickt) geht weiter — ein
/// Sack ist also mit einem einzigen Scan erfasst, ohne Maus.
class BarcodeEingabeSeite extends StatefulWidget {
  const BarcodeEingabeSeite({super.key});
  @override
  State<BarcodeEingabeSeite> createState() => _BarcodeEingabeSeiteState();
}

class _BarcodeEingabeSeiteState extends State<BarcodeEingabeSeite> {
  final _feld = TextEditingController();
  final _fokus = FocusNode();
  String? _hinweis;

  @override
  void dispose() {
    _feld.dispose();
    _fokus.dispose();
    super.dispose();
  }

  void _weiter() {
    final wert = _feld.text.trim();
    if (wert.length < 4) {
      setState(() => _hinweis = 'Bitte den ganzen Barcode scannen oder die Nummer darunter eintippen.');
      _fokus.requestFocus();
      return;
    }
    Navigator.of(context).pop(wert);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode auf dem Sack')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
            Icon(Icons.qr_code_scanner, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Den Strichcode mit dem Hand-Scanner lesen oder die Nummer darunter eintippen.',
                textAlign: TextAlign.center, style: t.titleMedium),
            const SizedBox(height: 24),
            TextField(
              key: const Key('barcode-feld'),
              controller: _feld,
              focusNode: _fokus,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 24, letterSpacing: 1.5),
              decoration: InputDecoration(
                hintText: 'z. B. 7610000000000',
                border: const OutlineInputBorder(),
                errorText: _hinweis,
              ),
              onChanged: (_) {
                if (_hinweis != null) setState(() => _hinweis = null);
              },
              // Fokus behalten (sonst ginge er nach Enter verloren und der
              // naechste Scan landete nirgends).
              onEditingComplete: () {},
              onSubmitted: (_) => _weiter(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('barcode-weiter'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: _weiter,
              child: const Text('Weiter'),
            ),
          ]),
        ),
      ),
    );
  }
}

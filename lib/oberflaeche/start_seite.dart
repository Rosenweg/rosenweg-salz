// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rosenweg_basis/rosenweg_basis.dart';

import '../salz/modell.dart';
import '../salz_app.dart';
import 'buchen_ablauf.dart';
import 'thema.dart';
import 'umgebung.dart';

/// Startseite: zwei grosse Knoepfe, darunter jedes Lager mit Bestand und Reichweite.
/// Am Desktop (ab 840 px, RosenwegSpalten) die Knoepfe links und die Lager
/// rechts als Kacheln; F5 laedt neu.
class StartSeite extends StatefulWidget {
  const StartSeite({super.key, required this.umgebung, required this.ich});
  final Umgebung umgebung;
  final Ich ich;
  @override
  State<StartSeite> createState() => _StartSeiteState();
}

class _StartSeiteState extends State<StartSeite> {
  List<Lager>? _lager;
  String? _fehler;
  bool _laedt = false;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    if (_laedt) return;
    setState(() => _laedt = true);
    try {
      final l = await widget.umgebung.quelle.lager();
      if (mounted) setState(() { _lager = l; _fehler = null; });
    } on NichtAngemeldet catch (e) {
      // Eigenes Handy: die Sitzung wechselt selbst zum Anmeldeschirm.
      if (mounted && widget.umgebung.geteiltesTelefon) setState(() => _fehler = e.toString());
    } catch (e) {
      if (mounted) setState(() => _fehler = e.toString());
    } finally {
      if (mounted) setState(() => _laedt = false);
    }
  }

  Future<void> _buchen(Art art) async {
    final lager = _lager;
    if (lager == null || lager.isEmpty) return;
    final ergebnis = await Navigator.of(context).push<AblaufErgebnis>(
      MaterialPageRoute(
        // Das Salz-Thema (grosse Knoepfe) auch auf der neuen Seite.
        builder: (_) => Theme(data: Theme.of(context), child: BuchenAblauf(umgebung: widget.umgebung, art: art, lager: lager, ich: widget.ich)),
      ),
    );
    if (!mounted) return;
    if (ergebnis == null) return _laden();
    final b = ergebnis.buchung;
    setState(() => _lager = [for (final l in _lager!) l.id == b.lager.id ? b.lager : l]);
    final bote = ScaffoldMessenger.of(context);
    bote.showSnackBar(SnackBar(
      // Am Desktop nicht ueber die ganze Fensterbreite.
      width: Fensterklasse.von(context).istBreit ? 560 : null,
      duration: const Duration(seconds: 8),
      content: Text('${ergebnis.text} – ${b.lager.name}: jetzt ${b.lager.saeckeText}', style: const TextStyle(fontSize: 16)),
      action: SnackBarAction(label: 'Rückgängig', onPressed: () => _rueckgaengig(b)),
    ));
  }

  Future<void> _rueckgaengig(Buchung b) async {
    final bote = ScaffoldMessenger.of(context);
    try {
      final l = await widget.umgebung.quelle.rueckgaengig(b.id);
      if (!mounted) return;
      setState(() => _lager = [for (final x in _lager!) x.id == l.id ? l : x]);
      bote.showSnackBar(SnackBar(content: Text('Rückgängig gemacht – ${l.name}: ${l.saeckeText}')));
    } catch (e) {
      bote.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _abmelden() async {
    if (await frage(context, 'Abmelden?', 'Danach braucht es wieder die Anmeldung mit dem Rosenweg-Konto.', ja: 'Abmelden')) {
      await widget.umgebung.abmelden();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lager = _lager;
    final bereit = lager != null && lager.isNotEmpty;
    final t = Theme.of(context).textTheme;
    final breit = Fensterklasse.von(context).istBreit;
    final knoepfe = [
      FilledButton.icon(
        key: const Key('knopf-anlieferung'),
        onPressed: bereit ? () => _buchen(Art.anlieferung) : null,
        icon: const Icon(Icons.local_shipping_outlined, size: 30),
        label: const Text('Anlieferung'),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        key: const Key('knopf-eingefuellt'),
        style: FilledButton.styleFrom(backgroundColor: RosenwegFarben.dunkelrot, foregroundColor: Colors.white),
        onPressed: bereit ? () => _buchen(Art.eingefuellt) : null,
        icon: const Icon(Icons.move_to_inbox_outlined, size: 30),
        label: const Text('Sack eingefüllt'),
      ),
    ];
    final fehler = [
      if (_fehler != null)
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: const Icon(Icons.cloud_off),
            title: Text(_fehler!),
            trailing: TextButton(onPressed: _laden, child: const Text('Nochmals')),
          ),
        ),
      if (lager == null && _fehler == null)
        const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
    ];
    // Desktop: F5 bzw. Strg/Cmd+R laedt neu (Herunterziehen gibt es mit der Maus nicht).
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): _laden,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): _laden,
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): _laden,
      },
      child: Focus(
        autofocus: breit,
        child: RosenwegGeruest(
          logo: Image.asset('assets/logo/rosenweg-salz-klein.png'),
          titel: const Text('Rosenweg Salz'),
          maxBreite: null,
          aktionen: [
            if (breit)
              IconButton(key: const Key('neu-laden'), tooltip: 'Neu laden (F5)', onPressed: _laedt ? null : _laden, icon: const Icon(Icons.refresh)),
            PopupMenuButton<String>(
              onSelected: (w) => w == 'ab' ? _abmelden() : zeigeUeber(context, salzApp),
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text(widget.ich.name ?? 'Angemeldet')),
                if (widget.umgebung.darfAbmelden) const PopupMenuItem(value: 'ab', child: Text('Abmelden')),
                const PopupMenuItem(value: 'ueber', child: Text('Über Rosenweg Salz')),
              ],
            ),
          ],
          // Handy: wie bisher eine Spalte. Desktop: Buchen links, Lager rechts.
          inhalt: RosenwegSpalten(
            schmal: RefreshIndicator(
              onRefresh: _laden,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ...knoepfe,
                  const SizedBox(height: 24),
                  ...fehler,
                  for (final l in lager ?? const <Lager>[]) LagerKarte(lager: l),
                ],
              ),
            ),
            links: ListView(padding: const EdgeInsets.all(24), children: [
              Text('Buchen', style: t.titleLarge),
              const SizedBox(height: 16),
              ...knoepfe,
              const SizedBox(height: 24),
              Text('Den Strichcode mit dem Hand-Scanner lesen oder die Nummer darunter eintippen.',
                  style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
            rechts: ListView(padding: const EdgeInsets.all(24), children: [
              Text('Lager', style: t.titleLarge),
              const SizedBox(height: 16),
              ...fehler,
              // Kacheln nebeneinander, je mindestens 320 px breit.
              LayoutBuilder(builder: (context, c) {
                final spalten = (c.maxWidth / 320).floor().clamp(1, 3);
                const abstand = 12.0;
                final b = (c.maxWidth - abstand * (spalten - 1)) / spalten;
                return Wrap(spacing: abstand, children: [
                  for (final l in lager ?? const <Lager>[]) SizedBox(width: b, child: LagerKarte(lager: l)),
                ]);
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

class LagerKarte extends StatelessWidget {
  const LagerKarte({super.key, required this.lager});
  final Lager lager;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final farbe = !lager.inBetrieb ? SalzFarben.neutral : lager.knapp ? SalzFarben.knapp(context) : SalzFarben.gut;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 10, color: farbe),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text.rich(TextSpan(text: lager.name, style: t.titleMedium, children: [
                      if (lager.ort != null) TextSpan(text: ' · ${lager.ort}', style: t.bodyMedium),
                    ])),
                  ),
                  if (lager.knapp) Icon(Icons.warning_amber_rounded, color: farbe),
                ]),
                const SizedBox(height: 4),
                Text(lager.saeckeText, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(lager.reichweiteText, style: t.bodyLarge?.copyWith(color: lager.knapp ? farbe : null)),
                if (lager.naechsterSackText() case final n?)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(children: [
                      Icon(Icons.event_outlined, size: 18, color: t.bodyMedium?.color),
                      const SizedBox(width: 6),
                      Expanded(child: Text(n, style: t.bodyLarge)),
                    ]),
                  ),
                if (lager.meldungSeit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Nachbestellen ist gemeldet', style: t.bodyMedium?.copyWith(color: farbe)),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

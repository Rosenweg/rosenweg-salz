// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rosenweg_basis/rosenweg_basis.dart';

import '../salz/modell.dart';
import '../salz/salz_api.dart';
import 'scanner_seite.dart' show mitKamera;
import 'umgebung.dart';

class AblaufErgebnis {
  AblaufErgebnis(this.buchung, this.text);
  final Buchung buchung;
  final String text;
}

enum _Schritt { lager, scannen, sorteErfassen, sorteUnbekannt, anzahl, buchen }

/// Eine Buchung in wenigen Schritten:
///   Wo? (Lager; entfaellt, wenn es nur eines gibt) -> Sack scannen ->
///   [neue Sorte einmal erfassen — nur die Technik] ->
///   bei Anlieferung: wie viele Säcke? -> gebucht.
/// „Sack eingefüllt“ bucht direkt nach dem Scan einen Sack ab.
class BuchenAblauf extends StatefulWidget {
  const BuchenAblauf({super.key, required this.umgebung, required this.art, required this.lager, required this.ich});
  final Umgebung umgebung;
  final Art art;
  final List<Lager> lager;
  final Ich ich;
  @override
  State<BuchenAblauf> createState() => _BuchenAblaufState();
}

class _BuchenAblaufState extends State<BuchenAblauf> {
  _Schritt _schritt = _Schritt.lager;
  int? _letztes;
  Lager? _gewaehlt;
  String? _barcode;
  Sorte? _sorte;
  int _anzahl = 10;
  String? _fehler;
  bool _arbeitet = false;
  // Eine Kennung je Buchungsversuch: auch wenn die Person nach einem Fehler
  // nochmals auf "Buchen" tippt, entsteht nur eine Buchung.
  String _clientId = neueClientId();

  bool get _anlieferung => widget.art == Art.anlieferung;
  SalzQuelle get _quelle => widget.umgebung.quelle;

  @override
  void initState() {
    super.initState();
    // Nur ein Lager (Bewohnerin: ihr Haus): gleich zum Scannen.
    if (widget.lager.length == 1) {
      _schritt = _Schritt.scannen;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lagerGewaehlt(widget.lager.single);
      });
      return;
    }
    widget.umgebung.merker.letztesLager().then((v) {
      if (mounted) setState(() => _letztes = v);
    });
  }

  void _fehlerZeigen(Object e) {
    if (e is NichtAngemeldet && !widget.umgebung.geteiltesTelefon) {
      // Die Sitzung zeigt den Anmeldeschirm; diese Seite schliessen.
      Navigator.of(context).pop();
      return;
    }
    setState(() => _fehler = e.toString());
  }

  Future<void> _lagerGewaehlt(Lager l) async {
    _gewaehlt = l;
    widget.umgebung.merker.merkeLager(l.id);
    await _scannen();
  }

  Future<void> _scannen() async {
    setState(() { _schritt = _Schritt.scannen; _fehler = null; });
    final code = await widget.umgebung.scannen(context);
    if (!mounted) return;
    if (code == null) {
      // Abgebrochen: bei nur einem Lager gibt es nichts zu waehlen — zurueck zur Startseite.
      if (widget.lager.length == 1) return Navigator.of(context).pop();
      return setState(() => _schritt = _Schritt.lager);
    }
    HapticFeedback.mediumImpact();
    _barcode = code;
    setState(() => _arbeitet = true);
    try {
      final s = await _quelle.sorte(code);
      if (!mounted) return;
      _sorte = s;
      if (s == null) {
        setState(() => _schritt = widget.ich.darfSortenErfassen ? _Schritt.sorteErfassen : _Schritt.sorteUnbekannt);
      } else {
        await _weiterNachSorte();
      }
    } catch (e) {
      if (mounted) _fehlerZeigen(e);
    } finally {
      if (mounted) setState(() => _arbeitet = false);
    }
  }

  Future<void> _weiterNachSorte() async {
    if (_anlieferung) {
      setState(() => _schritt = _Schritt.anzahl);
    } else {
      await _buchen(1);
    }
  }

  Future<void> _sorteSpeichern(String bezeichnung, double kg) async {
    setState(() { _arbeitet = true; _fehler = null; });
    try {
      _sorte = await _quelle.sorteAnlegen(_barcode!, bezeichnung, kg);
      if (mounted) await _weiterNachSorte();
    } catch (e) {
      if (mounted) _fehlerZeigen(e);
    } finally {
      if (mounted) setState(() => _arbeitet = false);
    }
  }

  Future<void> _buchen(int saecke) async {
    setState(() { _schritt = _Schritt.buchen; _arbeitet = true; _fehler = null; });
    try {
      final b = await _quelle.buchen(
          lagerId: _gewaehlt!.id, art: widget.art, barcode: _barcode!, saecke: saecke, clientId: _clientId);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final text = _anlieferung ? '+$saecke ${saecke == 1 ? 'Sack' : 'Säcke'} angeliefert' : '1 Sack eingefüllt';
      Navigator.of(context).pop(AblaufErgebnis(b, text));
    } on ApiFehler catch (e) {
      // Abgelehnt (z. B. Bestand 0): neue Kennung fuer den naechsten Versuch.
      // Bei Netzfehlern bleibt sie: vielleicht ist die Buchung doch angekommen.
      if (e.status < 500) _clientId = neueClientId();
      if (mounted) _fehlerZeigen(e);
    } catch (e) {
      if (mounted) _fehlerZeigen(e);
    } finally {
      if (mounted) setState(() => _arbeitet = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titel = _anlieferung ? 'Anlieferung' : 'Sack eingefüllt';
    return Scaffold(
      appBar: AppBar(title: Text(titel)),
      body: SafeArea(
        // Am Desktop nicht ueber die ganze Fensterbreite.
        child: RosenwegInhalt(
          maxBreite: 640,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_fehler != null)
                Card(
                  key: const Key('fehler'),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(padding: const EdgeInsets.all(16), child: Text(_fehler!, style: const TextStyle(fontSize: 17))),
                ),
              Expanded(child: _inhalt(context)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _inhalt(BuildContext context) {
    final t = Theme.of(context).textTheme;
    switch (_schritt) {
      case _Schritt.lager:
        final liste = [...widget.lager]..sort((a, b) => (a.id == _letztes ? 0 : 1).compareTo(b.id == _letztes ? 0 : 1));
        // Desktop: Ziffer 1–9 waehlt das Lager (steht rechts am Knopf).
        return CallbackShortcuts(
          bindings: {
            for (var i = 0; i < liste.length && i < 9; i++)
              SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)): () {
                if (!_arbeitet) _lagerGewaehlt(liste[i]);
              },
          },
          child: ListView(children: [
            Text('Wo?', style: t.headlineSmall),
            const SizedBox(height: 12),
            for (final (i, l) in liste.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.tonal(
                  key: Key('lager-${l.id}'),
                  autofocus: !mitKamera && i == 0,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(72), alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20)),
                  onPressed: _arbeitet ? null : () => _lagerGewaehlt(l),
                  child: Row(children: [
                    Expanded(child: Text(l.name, style: const TextStyle(fontSize: 22))),
                    if (l.id == _letztes) const Text('zuletzt', style: TextStyle(fontSize: 14)),
                    if (!mitKamera && i < 9) ...[const SizedBox(width: 16), _Taste('${i + 1}')],
                  ]),
                ),
              ),
          ]),
        );
      case _Schritt.scannen:
      case _Schritt.buchen:
        return Center(
          child: _arbeitet || _fehler == null
              ? const CircularProgressIndicator()
              : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (_schritt == _Schritt.buchen && _sorte != null)
                    FilledButton(
                      onPressed: () => _anlieferung ? setState(() => _schritt = _Schritt.anzahl) : _buchen(1),
                      child: const Text('Nochmals versuchen'),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _scannen, child: const Text('Nochmals scannen')),
                ]),
        );
      case _Schritt.sorteUnbekannt:
        return ListView(key: const Key('sorte-unbekannt'), children: [
          Text('Unbekannter Sack', style: t.headlineSmall),
          const SizedBox(height: 8),
          Text('Diesen Barcode kennt Rosenweg noch nicht. Bitte die Technik, die Sorte einmal zu erfassen – '
              'danach geht das Buchen auch hier.', style: t.bodyLarge),
          const SizedBox(height: 4),
          Text(_barcode ?? '', style: t.bodyMedium?.copyWith(fontFamily: 'monospace')),
          const SizedBox(height: 28),
          OutlinedButton(onPressed: _scannen, child: const Text('Anderen Sack scannen')),
        ]);
      case _Schritt.sorteErfassen:
        return SorteErfassen(barcode: _barcode!, arbeitet: _arbeitet, speichern: _sorteSpeichern);
      case _Schritt.anzahl:
        return _anzahlWahl(context);
    }
  }

  Widget _anzahlWahl(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget knopf(IconData i, int d, String k) => IconButton.filledTonal(
          key: Key(k),
          iconSize: 40,
          onPressed: _arbeitet ? null : () => setState(() => _anzahl = (_anzahl + d).clamp(1, 500)),
          icon: Icon(i),
        );
    void aendern(int d) {
      if (!_arbeitet) setState(() => _anzahl = (_anzahl + d).clamp(1, 500));
    }

    void buchen() {
      if (!_arbeitet) _buchen(_anzahl);
    }

    // Desktop: Enter bucht, Pfeil hoch/runter (oder +/-) aendert die Anzahl.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): buchen,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): buchen,
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => aendern(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => aendern(-1),
        const SingleActivator(LogicalKeyboardKey.numpadAdd): () => aendern(1),
        const SingleActivator(LogicalKeyboardKey.numpadSubtract): () => aendern(-1),
      },
      child: Focus(
        autofocus: true,
        child: ListView(children: [
          Text('${_gewaehlt!.name} · ${_sorte!.bezeichnung} (${_sorte!.gewichtText})', style: t.titleMedium),
          const SizedBox(height: 24),
          Text('Wie viele Säcke?', style: t.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            knopf(Icons.remove, -1, 'weniger'),
            SizedBox(width: 140, child: Text('$_anzahl', key: const Key('anzahl'), textAlign: TextAlign.center, style: t.displayMedium)),
            knopf(Icons.add, 1, 'mehr'),
          ]),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 12, children: [
            for (final n in const [5, 10, 20, 40])
              ChoiceChip(label: Text('$n', style: const TextStyle(fontSize: 18)), selected: _anzahl == n, onSelected: (_) => setState(() => _anzahl = n)),
          ]),
          const SizedBox(height: 32),
          FilledButton(
            key: const Key('buchen'),
            onPressed: _arbeitet ? null : () => _buchen(_anzahl),
            child: Text('$_anzahl ${_anzahl == 1 ? 'Sack' : 'Säcke'} buchen'),
          ),
          if (!mitKamera)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Enter bucht · Pfeil hoch/runter ändert die Anzahl',
                  textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
        ]),
      ),
    );
  }
}

/// Tastenkappe neben dem Lager (Desktop).
class _Taste extends StatelessWidget {
  const _Taste(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );
}

/// Unbekannter Barcode: einmal Sorte und Gewicht erfassen.
class SorteErfassen extends StatefulWidget {
  const SorteErfassen({super.key, required this.barcode, required this.arbeitet, required this.speichern});
  final String barcode;
  final bool arbeitet;
  final Future<void> Function(String bezeichnung, double kg) speichern;
  @override
  State<SorteErfassen> createState() => _SorteErfassenState();
}

class _SorteErfassenState extends State<SorteErfassen> {
  final _name = TextEditingController();
  final _kg = TextEditingController(text: '25');
  String? _hinweis;

  void _los() {
    final name = _name.text.trim();
    final kg = double.tryParse(_kg.text.trim().replaceAll(',', '.'));
    if (name.length < 2) return setState(() => _hinweis = 'Bitte angeben, was auf dem Sack steht.');
    if (kg == null || kg <= 0 || kg > 100) return setState(() => _hinweis = 'Gewicht je Sack in kg, z. B. 25.');
    setState(() => _hinweis = null);
    widget.speichern(name, kg);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(children: [
      Text('Neuer Sack', style: t.headlineSmall),
      const SizedBox(height: 4),
      Text('Diesen Barcode kennt Rosenweg noch nicht. Einmal erfassen – beim nächsten Mal geht es ohne.', style: t.bodyLarge),
      const SizedBox(height: 4),
      Text(widget.barcode, style: t.bodyMedium?.copyWith(fontFamily: 'monospace')),
      const SizedBox(height: 20),
      TextField(
        key: const Key('sorte-name'),
        controller: _name,
        autofocus: !mitKamera,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 20),
        decoration: const InputDecoration(labelText: 'Was steht auf dem Sack?', hintText: 'z. B. Regeneriersalz Tabletten', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      Text('Gewicht je Sack', style: t.titleMedium),
      const SizedBox(height: 8),
      Wrap(spacing: 12, children: [
        for (final g in const ['10', '25'])
          ChoiceChip(label: Text('$g kg', style: const TextStyle(fontSize: 18)), selected: _kg.text == g, onSelected: (_) => setState(() => _kg.text = g)),
        SizedBox(
          width: 120,
          child: TextField(
            key: const Key('sorte-kg'),
            controller: _kg,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _los(),
            decoration: const InputDecoration(suffixText: 'kg', isDense: true),
          ),
        ),
      ]),
      if (_hinweis != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_hinweis!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SizedBox(height: 28),
      FilledButton(key: const Key('sorte-speichern'), onPressed: widget.arbeitet ? null : _los, child: const Text('Speichern und weiter')),
    ]);
  }
}

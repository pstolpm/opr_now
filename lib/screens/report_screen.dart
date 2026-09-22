import 'package:flutter/material.dart';

import '../models/user_position.dart';
import '../models/user_report.dart';
import '../repositories/report_repository.dart';

/// "Melden"-Screen fuer die mobile Geodatenerfassung (PROJECT_BRAIN
/// Abschnitt 9/29, Phase 8).
///
/// Die Koordinate wird automatisch aus dem aktuellen Standort (GPS oder
/// Demo) uebernommen - fuer den MVP kein manuelles Setzen eines Pins auf
/// der Karte (das waere eine sinnvolle spaetere Erweiterung).
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.position});

  /// Aktueller Standort im Moment des Oeffnens. Ohne Standort kann keine
  /// Meldung erfasst werden (Koordinate ist ein Pflichtfeld).
  final UserPosition? position;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _repository = ReportRepository();
  final _commentController = TextEditingController();

  String _category = ReportCategory.sonstiges;
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final position = widget.position;
    if (position == null) return;

    setState(() => _saving = true);
    try {
      await _repository.addReport(
        UserReport(
          category: _category,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      // Lokale SQLite-Speicherung sollte praktisch nie fehlschlagen, aber
      // PROJECT_BRAIN Regel 8 verlangt trotzdem eine verstaendliche
      // Fehlermeldung statt eines Absturzes.
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meldung konnte nicht gespeichert werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.position;

    return Scaffold(
      appBar: AppBar(title: const Text('Melden')),
      body: position == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Kein Standort verfuegbar. Bitte GPS aktivieren oder '
                  'einen Demo-Standort waehlen, um eine Meldung mit '
                  'Koordinate zu erfassen.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Kategorie',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in ReportCategory.all)
                      ChoiceChip(
                        label: Text(ReportCategory.labelFor(category)),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Kommentar (optional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'z. B. genauere Beschreibung...',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Standort',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${position.latitude.toStringAsFixed(5)}, '
                  '${position.longitude.toStringAsFixed(5)}'
                  '${position.isDemo ? " (Demo-Standort)" : ""}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Meldung speichern'),
                  ),
                ),
              ],
            ),
    );
  }
}

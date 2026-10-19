import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/herday_db.dart';
import '../widgets/common.dart';

/// 📤 Backup & Export — copy all of her HerDay data as JSON.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = HerDayDb.instance.exportAllAsJson();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Export 📤')),
      body: AsyncBody<String>(
        future: _future,
        onRetry: () => setState(() => _future = HerDayDb.instance.exportAllAsJson()),
        builder: (json) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '💾 This is a full backup of her HerDay data (tasks, journal, budget, goals, memories, reminders…). '
                    'Copy it and keep it somewhere safe — it can be re-imported into Supabase later.\n\n'
                    '⚠️ It includes the Private Vault, so treat this file like a diary: don\'t share it publicly.',
                    style: TextStyle(height: 1.45),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: json));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup copied to clipboard 💾')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy full backup (JSON)'),
              ),
              const SectionTitle('Preview'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(
                    json.length > 6000 ? '${json.substring(0, 6000)}\n\n… (truncated in preview — Copy gets everything)' : json,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

/// 🔒 Private Vault — notes only visible to the signed-in account (RLS).
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  late Future<List<VaultNote>> _future;

  @override
  void initState() {
    super.initState();
    _future = HerDayDb.instance.fetchVault();
  }

  void _reload() => setState(() => _future = HerDayDb.instance.fetchVault());

  Future<void> _edit({VaultNote? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final content = TextEditingController(text: existing?.content ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Private Note 🔒' : 'Edit Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: content,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Important numbers, private thoughts…',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    if (title.text.trim().isEmpty && content.text.trim().isEmpty) return;
    try {
      await HerDayDb.instance.saveVault(
        id: existing?.id,
        title: title.text.trim(),
        content: content.text.trim(),
      );
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Vault 🔒')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Note'),
      ),
      body: AsyncBody<List<VaultNote>>(
        future: _future,
        onRetry: _reload,
        builder: (notes) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Text('🔐', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Only your account can open these notes — protected by Supabase Row Level Security.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: notes.isEmpty
                    ? const EmptyState(
                        emoji: '🔒',
                        title: 'Vault is empty',
                        subtitle: 'Store important info and private notes here.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: notes.length,
                        itemBuilder: (context, i) {
                          final n = notes[i];
                          return Dismissible(
                            key: ValueKey(n.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                  color: Colors.red.shade300, borderRadius: BorderRadius.circular(20)),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) async {
                              try {
                                await HerDayDb.instance.deleteVault(n.id);
                                _reload();
                              } catch (e) {
                                if (mounted) showError(context, e);
                              }
                            },
                            child: Card(
                              child: ListTile(
                                onTap: () => _edit(existing: n),
                                leading: const Text('📝', style: TextStyle(fontSize: 24)),
                                title: Text(n.title.isEmpty ? 'Untitled' : n.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(n.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

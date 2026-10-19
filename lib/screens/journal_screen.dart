import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late Future<List<JournalEntry>> _future;
  String _query = '';
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _future = HerDayDb.instance.fetchJournal();
  }

  void _reload() => setState(() => _future = HerDayDb.instance.fetchJournal());

  Future<void> _openEditor({JournalEntry? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JournalEditorScreen(existing: existing)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal 📝'),
        actions: [
          IconButton(
            icon: Icon(_favoritesOnly ? Icons.favorite : Icons.favorite_outline),
            tooltip: 'Favorites',
            onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.edit),
        label: const Text('Write'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search entries or #tags…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: AsyncBody<List<JournalEntry>>(
              future: _future,
              onRetry: _reload,
              builder: (all) {
                final entries = all.where((e) {
                  if (_favoritesOnly && !e.isFavorite) return false;
                  if (_query.isEmpty) return true;
                  return e.title.toLowerCase().contains(_query) ||
                      e.content.toLowerCase().contains(_query) ||
                      e.tags.toLowerCase().contains(_query);
                }).toList();
                if (entries.isEmpty) {
                  return const EmptyState(
                    emoji: '📔',
                    title: 'No entries yet',
                    subtitle: 'Write about today — future you will thank you.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        try {
                          await HerDayDb.instance.deleteJournal(e.id);
                          _reload();
                        } catch (err) {
                          if (mounted) showError(context, err);
                        }
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.imageUrl.isNotEmpty)
                              Image.network(
                                e.imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ListTile(
                              onTap: () => _openEditor(existing: e),
                          leading: Text(e.mood, style: const TextStyle(fontSize: 30)),
                          title: Text(
                            e.title.isEmpty ? shortDate(e.entryDate) : e.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            [
                              shortDate(e.entryDate),
                              if (e.content.isNotEmpty)
                                e.content.length > 90 ? '${e.content.substring(0, 90)}…' : e.content,
                              if (e.tags.isNotEmpty) e.tags,
                            ].join('\n'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              e.isFavorite ? Icons.favorite : Icons.favorite_outline,
                              color: e.isFavorite ? Colors.red.shade400 : null,
                            ),
                            onPressed: () async {
                              try {
                                await HerDayDb.instance.setJournalFavorite(e.id, !e.isFavorite);
                                _reload();
                              } catch (err) {
                                if (mounted) showError(context, err);
                              }
                            },
                            ),
                          ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class JournalEditorScreen extends StatefulWidget {
  final JournalEntry? existing;
  const JournalEditorScreen({super.key, this.existing});

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _tags;
  late String _mood;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _content = TextEditingController(text: e?.content ?? '');
    _tags = TextEditingController(text: e?.tags ?? '');
    _mood = e?.mood ?? '🙂';
    _date = e?.entryDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_content.text.trim().isEmpty && _title.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await HerDayDb.instance.saveJournal(
        id: widget.existing?.id,
        title: _title.text.trim(),
        content: _content.text.trim(),
        mood: _mood,
        tags: _tags.text.trim(),
        date: _date,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Entry 📝' : 'Edit Entry'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              Text(shortDate(_date), style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.event_outlined, size: 18),
                label: const Text('Change date'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('How was today?', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: moods.map((m) {
              final selected = _mood == m;
              return GestureDetector(
                onTap: () => setState(() => _mood = m),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: scheme.primary, width: 2) : null,
                  ),
                  child: Text(m, style: TextStyle(fontSize: selected ? 26 : 22)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(hintText: 'Title (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _content,
            maxLines: 12,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Today was…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: '#school #stress #happy',
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 16),
          if (_newImageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(_newImageBytes!, height: 180, width: double.infinity, fit: BoxFit.cover),
            )
          else if (_imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickPhoto,
                icon: const Icon(Icons.photo_outlined),
                label: Text(_newImageBytes != null || _imageUrl.isNotEmpty ? 'Change photo 📸' : 'Add photo 📸'),
              ),
              if (_newImageBytes != null || _imageUrl.isNotEmpty)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                            _newImageBytes = null;
                            _imageUrl = '';
                          }),
                  child: const Text('Remove'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

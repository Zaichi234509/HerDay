import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class _UsData {
  final Profile? profile;
  final List<LoveMessage> messages;
  final List<Memory> memories;
  _UsData(this.profile, this.messages, this.memories);
}

/// 💕 "Us" — days together, love messages, and shared memories.
class UsScreen extends StatefulWidget {
  const UsScreen({super.key});

  @override
  State<UsScreen> createState() => _UsScreenState();
}

class _UsScreenState extends State<UsScreen> {
  late Future<_UsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_UsData> _load() async {
    final r = await Future.wait<dynamic>([
      HerDayDb.instance.fetchProfile(),
      HerDayDb.instance.fetchMessages(),
      HerDayDb.instance.fetchMemories(),
    ]);
    return _UsData(r[0] as Profile?, r[1] as List<LoveMessage>, r[2] as List<Memory>);
  }

  void _reload() => setState(() => _future = _load());

  String _togetherText(DateTime start) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;
    if (days < 0) return 'Counting down to day one 💕';
    if (days < 30) return '$days days together ❤️';
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    final rest = (days % 365) % 30;
    final parts = <String>[
      if (years > 0) '$years Year${years == 1 ? '' : 's'}',
      if (months > 0) '$months Month${months == 1 ? '' : 's'}',
      '$rest Days',
    ];
    return '${parts.join(' · ')} ❤️\n($days days together)';
  }

  Future<void> _addMessage() async {
    final title = TextEditingController(text: '💌 A message for you');
    final body = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave a Message 💌'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(
                controller: body,
                autofocus: true,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: "Don't forget to eat today. I'm proud of you ❤️",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send 💕')),
        ],
      ),
    );
    if (saved != true || body.text.trim().isEmpty) return;
    try {
      await HerDayDb.instance.addMessage(title: title.text.trim(), body: body.text.trim());
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _addMemory() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final image = TextEditingController();
    DateTime date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New Memory 📸'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title (e.g. First Date ❤️)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: desc,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'What happened?'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: image,
                  decoration: const InputDecoration(
                    labelText: 'Photo URL (optional)',
                    hintText: 'https://…',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(shortDate(date)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setLocal(() => date = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true || title.text.trim().isEmpty) return;
    try {
      await HerDayDb.instance.addMemory(
        title: title.text.trim(),
        description: desc.text.trim(),
        imageUrl: image.text.trim(),
        date: date,
      );
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Us 💕')),
      body: AsyncBody<_UsData>(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          final anniversary = data.profile?.anniversary;
          final partner = data.profile?.partnerName ?? '';
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                // Days together
                Card(
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Text('❤️', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(
                          partner.isNotEmpty ? 'You & $partner' : "We've been together",
                          style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          anniversary == null
                              ? 'Set your anniversary in Me → Edit Profile 💕'
                              : _togetherText(anniversary),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Messages
                SectionTitle('💌 Messages', actionLabel: '+ New', onAction: _addMessage),
                if (data.messages.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No messages yet. Leave her a little note 💌'),
                    ),
                  ),
                ...data.messages.map((m) => Card(
                      child: ListTile(
                        onTap: () async {
                          if (!m.isRead) {
                            try {
                              await HerDayDb.instance.markMessageRead(m.id);
                              _reload();
                            } catch (e) {
                              if (mounted) showError(context, e);
                            }
                          }
                        },
                        leading: Text(m.isRead ? '💌' : '💝', style: const TextStyle(fontSize: 26)),
                        title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${m.body}\n${shortDate(m.createdAt)}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            try {
                              await HerDayDb.instance.deleteMessage(m.id);
                              _reload();
                            } catch (e) {
                              if (mounted) showError(context, e);
                            }
                          },
                        ),
                      ),
                    )),

                // Memories
                SectionTitle('📸 Our Memories', actionLabel: '+ Add', onAction: _addMemory),
                if (data.memories.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No memories saved yet. Add your first date, trips, random Tuesdays 😂'),
                    ),
                  ),
                ...data.memories.map((mem) => Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mem.imageUrl.isNotEmpty)
                            Image.network(
                              mem.imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: scheme.primaryContainer,
                                alignment: Alignment.center,
                                child: const Text('📸', style: TextStyle(fontSize: 44)),
                              ),
                            )
                          else
                            Container(
                              height: 110,
                              width: double.infinity,
                              color: scheme.primaryContainer,
                              alignment: Alignment.center,
                              child: const Text('💕', style: TextStyle(fontSize: 44)),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(mem.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 2),
                                      Text(shortDate(mem.memoryDate),
                                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                                      if (mem.description.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(mem.description),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    try {
                                      await HerDayDb.instance.deleteMemory(mem.id);
                                      _reload();
                                    } catch (e) {
                                      if (mounted) showError(context, e);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

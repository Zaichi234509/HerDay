import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'habits_screen.dart';
import 'journal_screen.dart';
import 'meals_screen.dart';
import 'shopping_screen.dart';
import 'vault_screen.dart';

class _MeData {
  final Profile? profile;
  final int tasksDone;
  final int journalCount;
  final int goalsCount;
  _MeData(this.profile, this.tasksDone, this.journalCount, this.goalsCount);
}

/// 👤 Me — profile, themes, stats, settings and shortcuts to everything.
class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  late Future<_MeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MeData> _load() async {
    final db = HerDayDb.instance;
    final r = await Future.wait<dynamic>([
      db.fetchProfile(),
      db.countDoneTasks(),
      db.countJournal(),
      db.fetchGoals(),
    ]);
    return _MeData(
      r[0] as Profile?,
      r[1] as int,
      r[2] as int,
      (r[3] as List<Goal>).length,
    );
  }

  void _reload() => setState(() => _future = _load());

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)).then((_) => _reload());
  }

  Future<void> _editProfile(Profile profile) async {
    final name = TextEditingController(text: profile.displayName);
    final bio = TextEditingController(text: profile.bio);
    final partner = TextEditingController(text: profile.partnerName);
    final budget = TextEditingController(
        text: profile.dailyBudget > 0 ? profile.dailyBudget.toStringAsFixed(0) : '');
    DateTime? anniversary = profile.anniversary;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edit Profile 🌸'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Her name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bio,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Taking life one day at a time.',
                    prefixIcon: Icon(Icons.favorite_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: partner,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Partner's name (for Us 💕)", prefixIcon: Icon(Icons.people_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: budget,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Daily budget', prefixText: '₱ '),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: Text(anniversary == null ? 'Set anniversary ❤️' : shortDate(anniversary!)),
                  subtitle: const Text('Anniversary (for days together)'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: anniversary ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setLocal(() => anniversary = picked);
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
    if (saved != true) return;
    profile.displayName = name.text.trim();
    profile.bio = bio.text.trim();
    profile.partnerName = partner.text.trim();
    profile.dailyBudget = double.tryParse(budget.text.trim()) ?? profile.dailyBudget;
    profile.anniversary = anniversary;
    try {
      await HerDayDb.instance.updateProfile(profile);
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _pickTheme(Profile? profile) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose a Theme 🎨'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: HerDayThemes.options.map((o) {
              return ListTile(
                leading: CircleAvatar(backgroundColor: o.seed, radius: 14),
                title: Text(o.label),
                trailing: themeNotifier.value == o.name ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, o.name),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (picked == null) return;
    themeNotifier.value = picked;
    if (profile != null) {
      profile.theme = picked;
      try {
        await HerDayDb.instance.updateProfile(profile);
        _reload();
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Me 👤')),
      body: AsyncBody<_MeData>(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          final p = data.profile;
          final displayName = (p?.displayName.isNotEmpty ?? false) ? p!.displayName : 'Her';
          final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '🌸';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(initial, style: TextStyle(fontSize: 36, color: scheme.onPrimaryContainer)),
                    ),
                    const SizedBox(height: 12),
                    Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    if ((p?.bio.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 4),
                      Text('"${p!.bio}"', style: TextStyle(color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 2),
                    Text(email, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: p == null ? null : () => _editProfile(p),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(value: '${data.tasksDone}', label: '✅ Tasks done'),
                      _Stat(value: '${data.journalCount}', label: '📔 Journal'),
                      _Stat(value: '${data.goalsCount}', label: '🎯 Goals'),
                    ],
                  ),
                ),
              ),
              const SectionTitle('🌸 HerDay'),
              Card(
                child: Column(
                  children: [
                    _MenuTile(icon: '📝', title: 'Journal', onTap: () => _push(const JournalScreen())),
                    _MenuTile(icon: '💰', title: 'Budget & Expenses', onTap: () => _push(const BudgetScreen())),
                    _MenuTile(icon: '🛒', title: 'Shopping List', onTap: () => _push(const ShoppingScreen())),
                    _MenuTile(icon: '🎯', title: 'Goals', onTap: () => _push(const GoalsScreen())),
                    _MenuTile(icon: '💧', title: 'Self-Care Habits', onTap: () => _push(const HabitsScreen())),
                    _MenuTile(icon: '🍱', title: "Today's Meals", onTap: () => _push(const MealsScreen())),
                    _MenuTile(icon: '🔒', title: 'Private Vault', onTap: () => _push(const VaultScreen())),
                  ],
                ),
              ),
              const SectionTitle('⚙️ Settings'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Text('🎨', style: TextStyle(fontSize: 22)),
                      title: const Text('Theme'),
                      subtitle: Text(HerDayThemes.byName(themeNotifier.value).label),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickTheme(p),
                    ),
                    ListTile(
                      leading: const Text('🌸', style: TextStyle(fontSize: 22)),
                      title: const Text('About HerDay'),
                      subtitle: const Text('Made with ❤️ — Flutter + Supabase'),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'HerDay',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Text('🌸', style: TextStyle(fontSize: 32)),
                        children: const [
                          Text('A personal everyday companion: tasks, calendar, journal, mood, budget, self-care, goals, memories and love notes — all private to her account.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log out?'),
                      content: const Text('Your data stays saved in Supabase — you can log back in anytime.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await Supabase.instance.client.auth.signOut();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

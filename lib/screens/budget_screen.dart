import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class _BudgetData {
  final List<Txn> txns;
  final double budget;
  _BudgetData(this.txns, this.budget);
}

const List<String> _incomeCategories = ['Salary', 'Allowance', 'Gift', 'Business', 'Others'];

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late Future<_BudgetData> _future;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BudgetData> _load() async {
    final r = await Future.wait<dynamic>([
      HerDayDb.instance.fetchTransactions(_month),
      HerDayDb.instance.fetchBudget(_month),
    ]);
    return _BudgetData(r[0] as List<Txn>, r[1] as double);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _addTxn() async {
    final title = TextEditingController();
    final amount = TextEditingController();
    String type = 'expense';
    String category = 'Food';
    DateTime date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Money 💰'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                    ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setLocal(() {
                    type = s.first;
                    category = type == 'expense' ? 'Food' : 'Allowance';
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: '₱ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'What for? (e.g. Lunch, Load)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: (type == 'expense' ? expenseCategories : _incomeCategories)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setLocal(() => category = v ?? category),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(shortDate(date)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
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
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    final value = double.tryParse(amount.text.trim()) ?? 0;
    if (saved != true || value <= 0) return;
    try {
      await HerDayDb.instance.addTransaction(
        title: title.text.trim().isEmpty ? category : title.text.trim(),
        category: category,
        amount: value,
        type: type,
        date: date,
      );
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _setBudget(double current) async {
    final ctrl = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly Budget 💰'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Budget for this month', prefixText: '₱ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    final value = double.tryParse(ctrl.text.trim()) ?? 0;
    if (saved != true) return;
    try {
      await HerDayDb.instance.setBudget(_month, value);
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Budget 💰')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTxn,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: AsyncBody<_BudgetData>(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          final income = data.txns.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
          final spent = data.txns.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
          final remaining = income - spent;
          final target = data.budget > 0 ? data.budget : income;
          final budgetProgress = target <= 0 ? 0.0 : spent / target;

          // Category breakdown (expenses only)
          final byCat = <String, double>{};
          for (final t in data.txns.where((t) => t.type == 'expense')) {
            byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
          }
          final catSorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() => _month = DateTime(_month.year, _month.month - 1));
                        _future = _load();
                      },
                    ),
                    Expanded(
                      child: Text(DateFormat('MMMM yyyy').format(_month),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() => _month = DateTime(_month.year, _month.month + 1));
                        _future = _load();
                      },
                    ),
                  ],
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('💰 This Month', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _setBudget(data.budget),
                              child: Text(data.budget > 0 ? 'Budget: ${peso(data.budget)}' : 'Set budget'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _MoneyRow(label: 'Income', value: income, color: Colors.green.shade600),
                        _MoneyRow(label: 'Spent', value: spent, color: scheme.error),
                        const Divider(height: 20),
                        _MoneyRow(label: 'Remaining', value: remaining, bold: true,
                            color: remaining >= 0 ? scheme.primary : scheme.error),
                        if (target > 0) ...[
                          const SizedBox(height: 12),
                          HerProgress(value: budgetProgress),
                          const SizedBox(height: 6),
                          Text(
                            budgetProgress >= 1
                                ? 'Over budget this month 🙈'
                                : '${(budgetProgress * 100).round()}% of ${peso(target)} used',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (catSorted.isNotEmpty) ...[
                  const SectionTitle('📊 Where it went'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: catSorted.map((e) {
                          final pct = spent <= 0 ? 0.0 : e.value / spent;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('${categoryIcon(e.key)} ${e.key}')),
                                    Text(peso(e.value), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                HerProgress(value: pct, height: 7),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                const SectionTitle('🧾 History'),
                if (data.txns.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No income or expenses logged this month yet.'),
                    ),
                  ),
                ...data.txns.map((t) {
                  final isIncome = t.type == 'income';
                  return Dismissible(
                    key: ValueKey(t.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      try {
                        await HerDayDb.instance.deleteTransaction(t.id);
                        _reload();
                      } catch (e) {
                        if (mounted) showError(context, e);
                      }
                    },
                    child: Card(
                      child: ListTile(
                        leading: Text(isIncome ? '💵' : categoryIcon(t.category),
                            style: const TextStyle(fontSize: 24)),
                        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${t.category} · ${shortDate(t.txnDate)}'),
                        trailing: Text(
                          '${isIncome ? '+' : '−'}${peso(t.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isIncome ? Colors.green.shade600 : scheme.error,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final bool bold;
  const _MoneyRow({required this.label, required this.value, this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(peso(value),
              style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                fontSize: bold ? 17 : 15,
                color: color,
              )),
        ],
      ),
    );
  }
}

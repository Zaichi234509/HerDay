import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  late Future<List<ShoppingItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = HerDayDb.instance.fetchShopping();
  }

  void _reload() => setState(() => _future = HerDayDb.instance.fetchShopping());

  Future<void> _add() async {
    final name = TextEditingController();
    final qty = TextEditingController(text: '1');
    final price = TextEditingController();
    String category = 'Others';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Item 🛒'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Item (e.g. Shampoo)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qty,
                        decoration: const InputDecoration(labelText: 'Qty'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Est. price', prefixText: '₱ '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setLocal(() => category = v ?? category),
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
    if (saved != true || name.text.trim().isEmpty) return;
    try {
      await HerDayDb.instance.addShopping(
        name: name.text.trim(),
        quantity: qty.text.trim().isEmpty ? '1' : qty.text.trim(),
        estimatedPrice: double.tryParse(price.text.trim()) ?? 0,
        category: category,
      );
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping 🛍️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Clear bought items',
            onPressed: () async {
              try {
                await HerDayDb.instance.clearBoughtShopping();
                _reload();
              } catch (e) {
                if (mounted) showError(context, e);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: AsyncBody<List<ShoppingItem>>(
        future: _future,
        onRetry: _reload,
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              emoji: '🛍️',
              title: 'Shopping list is empty',
              subtitle: 'Add shampoo, snacks, skincare — anything she needs.',
            );
          }
          final remaining = items.where((i) => !i.isBought).toList();
          final totalEst = remaining.fold<double>(0, (s, i) => s + i.estimatedPrice);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text('🧾', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${remaining.length} item(s) left to buy',
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text('Estimated total: ${peso(totalEst)}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        try {
                          await HerDayDb.instance.deleteShopping(item.id);
                          _reload();
                        } catch (e) {
                          if (mounted) showError(context, e);
                        }
                      },
                      child: Card(
                        child: CheckboxListTile(
                          value: item.isBought,
                          onChanged: (v) async {
                            try {
                              await HerDayDb.instance.setShoppingBought(item.id, v ?? false);
                              _reload();
                            } catch (e) {
                              if (mounted) showError(context, e);
                            }
                          },
                          title: Text(item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: item.isBought ? TextDecoration.lineThrough : null,
                              )),
                          subtitle: Text('Qty ${item.quantity} · ${item.category}'),
                          secondary: item.estimatedPrice > 0
                              ? Text(peso(item.estimatedPrice),
                                  style: const TextStyle(fontWeight: FontWeight.w700))
                              : null,
                          controlAffinity: ListTileControlAffinity.leading,
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

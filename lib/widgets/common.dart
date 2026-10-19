import 'package:flutter/material.dart';

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red.shade400),
  );
}

String friendlyError(Object e) {
  final s = e.toString();
  if (s.contains('Invalid login credentials')) return 'Wrong email or password.';
  if (s.contains('User already registered')) return 'That email already has an account — try logging in.';
  if (s.contains('Password should be')) return 'Password should be at least 6 characters.';
  if (s.contains('SocketException') || s.contains('Failed host lookup')) {
    return 'No connection. Check your internet and try again.';
  }
  return s.replaceAll('Exception: ', '');
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😔', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(friendlyError(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Thin progress bar used for budget / goals / habits.
class HerProgress extends StatelessWidget {
  final double value; // 0..1
  final double height;
  const HerProgress({super.key, required this.value, this.height = 10});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: height,
        backgroundColor: scheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(scheme.primary),
      ),
    );
  }
}

/// FutureBuilder wrapper with consistent loading / error / refresh states.
class AsyncBody<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;
  const AsyncBody({
    super.key,
    required this.future,
    required this.builder,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
        if (snap.hasError) return ErrorView(error: snap.error!, onRetry: onRetry);
        return builder(snap.data as T);
      },
    );
  }
}

const List<String> taskCategories = ['Home', 'School', 'Work', 'Shopping', 'Personal', 'Self-care'];
const List<String> taskCategoryIcons = ['🏠', '🎓', '💼', '🛍️', '💕', '🧴'];
const List<String> priorities = ['Low', 'Normal', 'High'];
const List<String> expenseCategories = ['Food', 'Shopping', 'Transport', 'School', 'Bills', 'Self-care', 'Others'];
const List<String> expenseCategoryIcons = ['🍔', '🛍️', '🚗', '🎓', '🧾', '🎀', '✨'];
const List<String> moods = ['😭', '😔', '😐', '🙂', '😍'];
const List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
const List<String> mealIcons = ['🍳', '🍗', '🍜', '🍓'];

String categoryIcon(String category) {
  final i = expenseCategories.indexOf(category);
  if (i >= 0) return expenseCategoryIcons[i];
  final j = taskCategories.indexOf(category);
  if (j >= 0) return taskCategoryIcons[j];
  return '✨';
}

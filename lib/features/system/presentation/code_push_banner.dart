import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/code_push_provider.dart';

class CodePushBanner extends ConsumerWidget {
  const CodePushBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: scheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: scheme.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "You're up to date — new improvements were just applied",
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(codePushBannerDismissedProvider.notifier).state =
                      true,
              child: const Text('DISMISS'),
            ),
          ],
        ),
      ),
    );
  }
}

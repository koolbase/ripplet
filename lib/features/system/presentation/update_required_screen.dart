import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/platform_config_providers.dart';

class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final result = ref.watch(versionStatusProvider).valueOrNull;
    final message = (result?.message.isNotEmpty ?? false)
        ? result!.message
        : 'This version is no longer supported.\nPlease update to keep chatting.';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 48,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.download, size: 40, color: scheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Update required',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const Spacer(),
              const FilledButton(onPressed: null, child: Text('Update now')),
              const SizedBox(height: 12),
              Text(
                'v2.4.0 (Build 892)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

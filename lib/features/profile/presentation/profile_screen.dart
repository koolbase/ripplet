import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../system/application/platform_config_providers.dart';
import '../application/delete_account_controller.dart';
import '../application/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final profile = ref.watch(myProfileProvider);

    final displayName =
        profile.valueOrNull?.displayName ??
        session?.displayName ??
        session?.email ??
        '';
    final username = profile.valueOrNull?.username;
    final avatarUrl = profile.valueOrNull?.avatarUrl ?? session?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ripplet'),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (username != null) Center(child: Text('@$username')),
          const SizedBox(height: 12),
          const Center(
            child: OutlinedButton(onPressed: null, child: Text('Edit profile')),
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Appearance'),
            subtitle: Text('System default'),
            trailing: Icon(Icons.chevron_right),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('All alerts enabled'),
            value: true,
            onChanged: (_) {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.science_outlined),
            title: const Row(
              children: [
                Text('Labs'),
                SizedBox(width: 8),
                Chip(label: Text('BETA'), visualDensity: VisualDensity.compact),
              ],
            ),
            subtitle: const Text(
              'Message reactions — controlled by Koolbase Feature Flags',
            ),
            value: ref.watch(reactionsEnabledProvider),
            onChanged: null, // server-controlled; state reflects the flag
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('Version 2.4.0 (Build 892)'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () => ref.read(sessionProvider.notifier).signOut(),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete account',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text('Permanently removes your account and data'),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'This permanently deletes your account. Your profile, photo, and '
        'chat list are removed, and your messages are cleared for everyone. '
        'This cannot be undone.',
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final ok = await ref
      .read(deleteAccountControllerProvider.notifier)
      .deleteAccount();
  if (ok) return;
  final err = ref.read(deleteAccountControllerProvider).error;
  messenger.showSnackBar(
    SnackBar(content: Text('Could not delete account: ${err ?? 'unknown'}')),
  );
}

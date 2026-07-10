import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../profile/application/profile_providers.dart';
import '../../profile/data/profile_repository.dart';
import '../application/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.completeMode = false});

  final bool completeMode;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  File? _avatar;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _avatar = File(picked.path));
  }

  void _fail(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _continue() async {
    final username = _username.text.trim().toLowerCase();
    final displayName = _displayName.text.trim();
    if (username.isEmpty || displayName.isEmpty) {
      _fail('Please fill in display name and username.');
      return;
    }

    final repo = ref.read(profileRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    final avatar = _avatar;
    final email = _email.text.trim();
    final password = _password.text;

    setState(() => _loading = true);
    try {
      if (!widget.completeMode) {
        await session.signUp(email, password);
      }
      final user = ref.read(sessionProvider);
      if (user == null) throw StateError('signup returned no session');

      if (await repo.isUsernameTaken(username, userId: user.id)) {
        // Account exists but handle is taken. The onboarding gate holds
        // the user on /complete-profile until a profile row exists, so
        // this is a retry, not a dead end.
        // TODO(platform idea): public username-availability endpoint so
        // this check can happen BEFORE account creation.
        _fail('@$username is taken — try another username.');
        return;
      }

      final profile = await repo.completeOnboarding(
        userId: user.id,
        username: username,
        displayName: displayName,
        avatar: avatar,
      );
      ref.read(freshProfileOverrideProvider.notifier).state = profile;
      ref.invalidate(myProfileProvider);
    } catch (e, st) {
      debugPrint('onboarding failed: $e\n$st');
      if (mounted) _fail('Sign up failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.completeMode
                  ? 'Finish setting up'
                  : 'Complete your profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              widget.completeMode
                  ? 'Your account needs a profile before you can start.'
                  : 'Set up your identity to start connecting.',
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: scheme.surfaceContainerHighest,
                      backgroundImage: _avatar != null
                          ? FileImage(_avatar!)
                          : null,
                      child: _avatar == null
                          ? const Icon(Icons.person_outline, size: 40)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: scheme.primary,
                        child: const Icon(
                          Icons.photo_camera,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!widget.completeMode) ...[
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText: 'Min. 8 characters',
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _displayName,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'E.g. Alex Rivera',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _username,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@ ',
                hintText: 'alex_ripple',
                helperText: 'Unique handle for your profile.',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _continue,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
            const SizedBox(height: 24),
            if (!widget.completeMode)
              TextButton(
                onPressed: () => context.go('/welcome'),
                child: const Text("Already have an account? Sign In"),
              ),
          ],
        ),
      ),
    );
  }
}

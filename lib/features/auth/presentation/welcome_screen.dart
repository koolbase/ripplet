import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';
import 'package:koolbase_flutter/src/code_push/vm_patch_bindings.dart' as vm;
import 'package:ripple/main.dart';
import '../../../core/constants.dart';
import '../application/auth_controller.dart';

const bool kCodePushProof = bool.fromEnvironment(
  'KOOLBASE_CODEPUSH_PROOF',
  defaultValue: false,
);

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Timer? _tagPoll;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    if (!kCodePushProof) return;
    _tagPoll = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || ++_polls > 15) {
        t.cancel();
        return;
      }
      setState(() {}); // re-run build → re-read rippleBuildTag()
    });
  }

  @override
  void dispose() {
    _tagPoll?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(sessionProvider.notifier)
          .signIn(_email.text.trim(), _password.text);
      // Router redirect handles navigation on session change.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Debug affordance only — the OTA loop is the mechanism. No asset, no apply.
  Future<void> _debugRefresh() async {
    final current = await Koolbase.vmPatch.currentPatch();
    final fresh = Koolbase.vmPatch.appliedThisLaunch;
    String bid = '';
    try {
      bid = vm.koolbaseBuildId();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('patch=$current new=$fresh bid=$bid')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: kCodePushProof
          ? FloatingActionButton.extended(
              onPressed: _debugRefresh,
              label: const Text('REFRESH'),
              icon: const Icon(Icons.refresh),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.primary,
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppConstants.tagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (kCodePushProof) ...[
                const SizedBox(height: 8),
                Text(
                  'build: ${rippleBuildTag()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Builder(
                  builder: (context) {
                    String bid = '';
                    try {
                      bid = vm.koolbaseBuildId();
                    } catch (_) {}
                    return Text(
                      'bid: $bid',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                    );
                  },
                ),
              ],

              const SizedBox(height: 32),
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
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _logIn,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log In'),
              ),

              const Spacer(),
              TextButton(
                onPressed: () => context.go('/signup'),
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

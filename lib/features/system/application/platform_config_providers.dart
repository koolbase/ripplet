import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';

const _sampleInterval = Duration(seconds: 3);

Stream<T> _sampled<T>(T Function() read) async* {
  var last = read();
  yield last;
  await for (final _ in Stream<void>.periodic(_sampleInterval)) {
    final next = read();
    if (next != last) {
      last = next;
      yield next;
    }
  }
}

final flagProvider = StreamProvider.family<bool, String>(
  (ref, key) => _sampled(() => Koolbase.isEnabled(key)),
);

final configStringProvider =
    StreamProvider.family<String, ({String key, String fallback})>(
      (ref, p) =>
          _sampled(() => Koolbase.configString(p.key, fallback: p.fallback)),
    );

// ── Ripplet's own keys ──────────────────────────────────────────────

/// Gates the reactions feature (long-press picker + chips).
final reactionsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(flagProvider('message_reactions')).valueOrNull ?? false;
});

/// Theme accent, dashboard-tunable. Falls back to Ripplet teal.
final accentColorProvider = Provider<Color>((ref) {
  final hex =
      ref
          .watch(
            configStringProvider((key: 'accent_color', fallback: '#0E7C7B')),
          )
          .valueOrNull ??
      '#0E7C7B';
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null || cleaned.length != 6) return const Color(0xFF0E7C7B);
  return Color(0xFF000000 | value);
});

final versionStatusProvider = StreamProvider<VersionCheckResult>(
  (ref) => _sampled(
    () => Koolbase.checkVersion().status,
  ).map((_) => Koolbase.checkVersion()),
);

final updateRequiredProvider = Provider<bool>((ref) {
  return ref.watch(versionStatusProvider).valueOrNull?.status ==
      VersionStatus.forceUpdate;
});

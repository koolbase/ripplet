import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';

final codePushBannerDismissedProvider = StateProvider<bool>((_) => false);

bool _readAppliedThisLaunch() {
  try {
    return (Koolbase.vmPatch as dynamic).appliedThisLaunch as bool;
  } on NoSuchMethodError {
    return false;
  }
}

final _vmPatchAppliedProvider = StreamProvider<bool>((ref) async* {
  yield _readAppliedThisLaunch();
  await for (final _ in Stream<void>.periodic(
    const Duration(seconds: 2),
  ).take(15)) {
    if (_readAppliedThisLaunch()) {
      yield true;
      return; // immutable for the rest of the session — stop sampling
    }
  }
});

final codePushAppliedProvider = Provider<bool>((ref) {
  final applied = ref.watch(_vmPatchAppliedProvider).valueOrNull ?? false;
  final dismissed = ref.watch(codePushBannerDismissedProvider);
  return applied && !dismissed;
});

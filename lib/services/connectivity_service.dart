import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around connectivity_plus. A non-none result means the
/// device *has a network interface up* — it does not guarantee Supabase
/// is actually reachable, so repositories should still treat failed
/// requests as "go offline" regardless of what this reports.
class ConnectivityService {
  Stream<bool> get onStatusChange => Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onStatusChange;
});

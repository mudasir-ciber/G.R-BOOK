import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(supabaseClientProvider),
    ref.watch(secureStorageProvider),
  );
});

/// Emits whenever Supabase's auth state changes (sign in/out/token
/// refresh). Screens/router use this to decide Login vs Dashboard.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  return authState?.session?.user ?? ref.watch(authServiceProvider).currentUser;
});

/// Tracks whether the user has authenticated in the current session.
/// Resets to false whenever the app process starts, ensuring the user must enter
/// their credentials every time the app is reopened to protect student records.
final appUnlockedProvider = StateProvider<bool>((ref) => false);

/// Checks whether the currently logged-in user is Master Admin (Mudasir Ahmed)
final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authServiceProvider).isCurrentUserSuperAdmin();
});



import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'core/theme.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/classes/classes_screen.dart';
import 'features/school/add_school_screen.dart';
import 'providers/repository_providers.dart';
import 'services/sync_coordinator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    // Persists the Supabase session securely on-device so "Remember Me"
    // survives app restarts without re-entering credentials, and so the
    // app can still read locally-cached data if it launches offline.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const ProviderScope(child: GrBookApp()));
}

class GrBookApp extends ConsumerWidget {
  const GrBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'G.R. Book',
      debugShowCheckedModeBanner: false,
      theme: GrBookTheme.themeData,
      home: authState.when(
        data: (state) {
          final session = state.session ?? Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return const SyncCoordinator(child: _SchoolGate());
          }
          return const LoginScreen();
        },
        loading: () => const _SplashScreen(),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Decides where a signed-in user lands, per requirement #37's flow
/// (Login → Add School if needed → Classes/Dashboard):
///  1. If a school is already cached locally, go straight to Classes —
///     works fully offline on every app launch after the first.
///  2. Otherwise (fresh device / fresh account), try to bootstrap from
///     Supabase — this requires connectivity, since there's nothing
///     local yet to fall back to.
///  3. If bootstrap finds no school membership at all, this is a brand
///     new account: send the user to Add School.
class _SchoolGate extends ConsumerStatefulWidget {
  const _SchoolGate();

  @override
  ConsumerState<_SchoolGate> createState() => _SchoolGateState();
}

enum _BootstrapPhase { notStarted, running, done, failed }

class _SchoolGateState extends ConsumerState<_SchoolGate> {
  _BootstrapPhase _phase = _BootstrapPhase.notStarted;
  String? _bootstrapError;

  Future<void> _runBootstrap() async {
    setState(() => _phase = _BootstrapPhase.running);
    try {
      await ref.read(schoolRepositoryProvider).bootstrapFromServer();
      if (mounted) setState(() => _phase = _BootstrapPhase.done);
    } catch (e) {
      if (mounted) {
        setState(() {
          _bootstrapError = e.toString();
          _phase = _BootstrapPhase.failed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return schoolAsync.when(
      loading: () => const _SplashScreen(),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (school) {
        if (school != null) return const ClassesScreen();

        // No local school cached yet. Kick off a one-time bootstrap
        // attempt (scheduled after this build frame — never called
        // synchronously inside build).
        if (_phase == _BootstrapPhase.notStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _runBootstrap());
          return const _SplashScreen();
        }

        if (_phase == _BootstrapPhase.running) {
          return const _SplashScreen();
        }

        if (_phase == _BootstrapPhase.failed) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_bootstrapError ?? 'Something went wrong.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => _phase = _BootstrapPhase.notStarted),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // _phase == done, and the stream still shows no local school:
        // bootstrap genuinely found no membership → brand new account.
        return const AddSchoolScreen();
      },
    );
  }
}

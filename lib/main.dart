import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'bloc/daily_bloc.dart';
import 'bloc/daily_event.dart';
import 'bloc/daily_state.dart';
import 'bloc/settings_bloc.dart';
import 'bloc/settings_event.dart';
import 'bloc/settings_state.dart';
import 'models/daily_model.dart';
import 'models/goal_model.dart';
import 'models/settings_model.dart';
import 'models/recurring_goal.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/goal_complete_screen.dart';
import 'screens/wind_down_screen.dart';
import 'screens/focus_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(DailyAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(RecurringGoalAdapter());

  await NotificationService.instance.initialize();

  runApp(const DoneDailyApp());
}

class DoneDailyApp extends StatefulWidget {
  const DoneDailyApp({super.key});

  @override
  State<DoneDailyApp> createState() => _DoneDailyAppState();
}

class _DoneDailyAppState extends State<DoneDailyApp> {
  final _dailyBloc = DailyBloc();
  final _settingsBloc = SettingsBloc();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _dailyBloc.add(const InitializeDailyEvent());
    _settingsBloc.add(const InitializeSettingsEvent());

    _router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const MainShell(),
        ),
        GoRoute(
          path: '/complete',
          name: 'complete',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return GoalCompleteScreen(
              daily: extra['daily'] as Daily,
              completedGoalTitle: extra['completedGoalTitle'] as String? ?? 'Goal',
            );
          },
        ),
        GoRoute(
          path: '/winddown',
          name: 'winddown',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return WindDownScreen(daily: extra['daily'] as Daily);
          },
        ),
        GoRoute(
          path: '/focus',
          name: 'focus',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return FocusScreen(
              goal: extra['goal'] as Goal,
              daily: extra['daily'] as Daily,
            );
          },
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dailyBloc.close();
    _settingsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DailyBloc>.value(value: _dailyBloc),
        BlocProvider<SettingsBloc>.value(value: _settingsBloc),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final isDark = settingsState is SettingsLoaded && settingsState.settings.isDarkMode;
          return MaterialApp.router(
            title: 'DONE:Daily',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            routerDelegate: _router.routerDelegate,
            routeInformationParser: _router.routeInformationParser,
            routeInformationProvider: _router.routeInformationProvider,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => _GoalCompletionListener(
              router: _router,
              child: child ?? const SizedBox(),
            ),
          );
        },
      ),
    );
  }
}

class _GoalCompletionListener extends StatelessWidget {
  final GoRouter router;
  final Widget child;

  const _GoalCompletionListener({required this.router, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DailyBloc, DailyState>(
      listener: (context, state) {
        if (state is GoalCompleted) {
          final goal = state.daily.goals.firstWhere((g) => g.id == state.completedGoalId);
          router.pushNamed('complete', extra: {
            'daily': state.daily,
            'completedGoalTitle': goal.title,
          });
        }
      },
      child: child,
    );
  }
}

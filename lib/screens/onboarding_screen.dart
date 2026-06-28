import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../models/settings_model.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markSeenAndGo() {
    final bloc = context.read<SettingsBloc>();
    final settings = bloc.state is SettingsLoaded
        ? (bloc.state as SettingsLoaded).settings
        : const AppSettings();
    bloc.add(UpdateSettingsEvent(settings.copyWith(hasSeenOnboarding: true)));
    context.go('/');
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final isLast = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                child: GestureDetector(
                  onTap: _markSeenAndGo,
                  child: Text(
                    'Skip',
                    style: TextStyle(fontSize: 13, color: t.textTertiary, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: const [
                  _WelcomePage(),
                  _TodayPage(),
                  _CalendarPage(),
                  _ReadyPage(),
                ],
              ),
            ),

            // Dots
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? t.accent : t.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  );
                }),
              ),
            ),

            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: GestureDetector(
                onTap: isLast ? _markSeenAndGo : _next,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isLast ? t.accent : t.surface,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                    boxShadow: isLast
                        ? [BoxShadow(color: t.accent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))]
                        : t.buttonShadow,
                  ),
                  child: Center(
                    child: Text(
                      isLast ? "Let's get started" : 'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isLast ? Colors.white : t.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 1 — Welcome ─────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.check_circle_outline_rounded, size: 52, color: t.accent),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'DONE:Daily',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Your day has a finish line.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textSecondary),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Set your goals each morning. Work through them. Then close the app and rest — for real.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: t.textTertiary, height: 1.65),
            ),
          ),
          const SizedBox(height: 32),
          // Three pillars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Pillar(icon: Icons.flag_outlined, label: 'Set goals', t: t),
              const SizedBox(width: 20),
              _Pillar(icon: Icons.timer_outlined, label: 'Focus', t: t),
              const SizedBox(width: 20),
              _Pillar(icon: Icons.nights_stay_outlined, label: 'Rest', t: t),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  final IconData icon;
  final String label;
  final NTheme t;
  const _Pillar({required this.icon, required this.label, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: t.surface,
            shape: BoxShape.circle,
            boxShadow: t.boxShadow,
          ),
          child: Center(child: Icon(icon, size: 24, color: t.accent)),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSecondary)),
      ],
    );
  }
}

// ─── Page 2 — Today tab ───────────────────────────────────────────────────────

class _TodayPage extends StatelessWidget {
  const _TodayPage();

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(Icons.today_rounded, size: 24, color: t.accent)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today tab', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.textPrimary)),
                  Text('Your daily workspace', style: TextStyle(fontSize: 13, color: t.textTertiary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _FeatureRow(
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.success,
            title: 'Add goals',
            subtitle: 'Tap "+ Add Goal" at the bottom to add what you need to finish today.',
            t: t,
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.check_box_outlined,
            color: AppColors.success,
            title: 'Complete them',
            subtitle: 'Tap the checkbox on each goal to mark it done. Long-press to edit.',
            t: t,
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.timer_outlined,
            color: t.accent,
            title: 'Focus mode',
            subtitle: 'Tap the ▶ button on any goal to start a timed focus session.',
            t: t,
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.edit_note_rounded,
            color: t.accent,
            title: 'Daily reflection',
            subtitle: 'Write a short note at the top about how your day is going.',
            t: t,
          ),
        ],
      ),
    );
  }
}

// ─── Page 3 — Calendar tab ────────────────────────────────────────────────────

class _CalendarPage extends StatelessWidget {
  const _CalendarPage();

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(Icons.calendar_month_rounded, size: 24, color: t.accent)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calendar tab', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.textPrimary)),
                  Text('Plan & review', style: TextStyle(fontSize: 13, color: t.textTertiary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _FeatureRow(
            icon: Icons.schedule_outlined,
            color: t.accent,
            title: 'Set work end time',
            subtitle: 'Tell the app when your shift ends — it shows a live countdown on Today.',
            t: t,
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.weekend_outlined,
            color: AppColors.warning,
            title: 'Weekly rest days',
            subtitle: 'Pick which days of the week you always rest (e.g. Sunday).',
            t: t,
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.self_improvement_outlined,
            color: AppColors.accent,
            title: 'Mark holidays in advance',
            subtitle: 'Tap any future date on the calendar to mark it as a rest day.',
            t: t,
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.bar_chart_rounded,
            color: AppColors.success,
            title: 'Review past days',
            subtitle: 'See your completed goals and reflections for any previous date.',
            t: t,
          ),
        ],
      ),
    );
  }
}

// ─── Page 4 — Ready ───────────────────────────────────────────────────────────

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.rocket_launch_outlined, size: 50, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "You're all set.",
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Add your goals, focus on them one by one, and when they\'re done — rest. That\'s it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: t.textTertiary, height: 1.65),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadii.large),
              boxShadow: t.boxShadow,
            ),
            child: Column(
              children: [
                _TipRow(icon: Icons.star_rounded, color: AppColors.warning, text: 'Star a goal to mark it priority — it moves to the top', t: t),
                const SizedBox(height: 12),
                _TipRow(icon: Icons.repeat_rounded, color: t.accent, text: 'Add recurring goals in Settings — they appear every day', t: t),
                const SizedBox(height: 12),
                _TipRow(icon: Icons.notifications_outlined, color: t.accent, text: 'Enable notifications to get a work-end reminder', t: t),
                const SizedBox(height: 12),
                _TipRow(icon: Icons.dark_mode_outlined, color: t.textSecondary, text: 'Switch dark/light mode in Settings anytime', t: t),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final NTheme t;
  const _FeatureRow({required this.icon, required this.color, required this.title, required this.subtitle, required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(icon, size: 20, color: color)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: t.textTertiary, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final NTheme t;
  const _TipRow({required this.icon, required this.color, required this.text, required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: t.textSecondary, height: 1.45)),
        ),
      ],
    );
  }
}

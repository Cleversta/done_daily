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
      duration: const Duration(milliseconds: 300),
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
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
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
                  _GoalsPage(),
                  _FocusPage(),
                  _ReadyPage(),
                ],
              ),
            ),

            // Dots
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? t.textPrimary
                          : t.textTertiary.withValues(alpha: 0.35),
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
                    color: t.surface,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                    boxShadow: t.buttonShadow,
                  ),
                  child: Center(
                    child: Text(
                      isLast ? "Let's go" : 'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
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
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: t.surface,
              shape: BoxShape.circle,
              boxShadow: t.boxShadow,
            ),
            child: Center(
              child: Icon(Icons.check_circle_outline_rounded, size: 48, color: t.accent),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'DONE:Daily',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Your day has a finish line.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              'Set your goals each morning. Complete them. Then close the app and rest — for real.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: t.textTertiary,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2 — Goals ───────────────────────────────────────────────────────────

class _GoalsPage extends StatelessWidget {
  const _GoalsPage();

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your daily goals', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(
            'Add what you want to finish today. Tap the box to complete.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Mock goal tiles
          _MockGoalTile(title: 'Morning walk', completed: true, priority: true),
          const SizedBox(height: 8),
          _MockGoalTile(title: 'Reply to emails', completed: true, priority: false),
          const SizedBox(height: 8),
          _MockGoalTile(title: 'Cook dinner', completed: false, priority: false, showHint: true),
          const SizedBox(height: 8),
          _MockGoalTile(title: 'Call mum', completed: false, priority: false),

          const SizedBox(height: 20),
          // Hint row
          Row(
            children: [
              Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                'Star = priority goal — shown at the top',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.play_arrow_rounded, size: 14, color: t.accent),
              const SizedBox(width: 6),
              Text(
                '▶ starts a focus timer for that goal',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MockGoalTile extends StatelessWidget {
  final String title;
  final bool completed;
  final bool priority;
  final bool showHint;

  const _MockGoalTile({
    required this.title,
    required this.completed,
    required this.priority,
    this.showHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.subtleShadow,
      ),
      child: Row(
        children: [
          // Priority star
          Icon(
            priority ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 18,
            color: priority ? AppColors.warning : t.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: completed ? t.textTertiary : t.textPrimary,
                decoration: completed ? TextDecoration.lineThrough : null,
                decorationColor: t.textTertiary,
              ),
            ),
          ),
          // Play button hint
          if (!completed) ...[
            Icon(Icons.play_arrow_rounded, size: 18, color: t.accent.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
          ],
          // Checkbox
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed ? AppColors.success : t.surface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: completed ? t.insetShadow : t.buttonShadow,
              border: completed
                  ? null
                  : Border.all(color: t.textTertiary.withValues(alpha: 0.35), width: 1.5),
            ),
            child: completed
                ? const Center(child: Icon(Icons.check_rounded, size: 14, color: Colors.white))
                : null,
          ),
          // Tap hint arrow
          if (showHint) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('tap', style: TextStyle(fontSize: 10, color: t.accent, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Page 3 — Focus ───────────────────────────────────────────────────────────

class _FocusPage extends StatelessWidget {
  const _FocusPage();

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Focus on one goal', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Tap ▶ on any goal to start a timed session. No distractions.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Mock focus timer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadii.large),
              boxShadow: t.boxShadow,
            ),
            child: Column(
              children: [
                Text('Study Flutter', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 20),
                // Mock ring
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: 0.6,
                          strokeWidth: 8,
                          backgroundColor: t.textTertiary.withValues(alpha: 0.15),
                          color: t.accent,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('15:00', style: Theme.of(context).textTheme.headlineLarge),
                          Text('min', style: Theme.of(context).textTheme.labelMedium),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MockButton(label: '⏸ Pause', color: t.textSecondary),
                    const SizedBox(width: 12),
                    _MockButton(label: '✓ Mark Done', color: AppColors.success),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DurationChip('5 min', t),
              _DurationChip('15 min', t, active: true),
              _DurationChip('25 min', t),
              _DurationChip('45 min', t),
            ],
          ),
        ],
      ),
    );
  }
}

class _MockButton extends StatelessWidget {
  final String label;
  final Color color;
  const _MockButton({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: t.buttonShadow,
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final NTheme t;
  final bool active;
  const _DurationChip(this.label, this.t, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: active ? t.insetShadow : t.subtleShadow,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: active ? t.accent : t.textTertiary, fontWeight: FontWeight.w600),
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
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: t.surface,
              shape: BoxShape.circle,
              boxShadow: t.boxShadow,
            ),
            child: Center(
              child: Icon(Icons.nights_stay_outlined, size: 42, color: t.accent),
            ),
          ),
          const SizedBox(height: 28),
          Text("You're all set.", style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              'Add your goals for today, focus on them one by one, and when they\'re all done — rest. That\'s it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary, height: 1.6),
            ),
          ),
          const SizedBox(height: 32),
          // Quick tips
          _TipRow(icon: Icons.bar_chart_rounded, text: 'Archive tab — see any past day', t: t),
          const SizedBox(height: 10),
          _TipRow(icon: Icons.repeat_rounded, text: 'Recurring goals — auto habits', t: t),
          const SizedBox(height: 10),
          _TipRow(icon: Icons.edit_note_rounded, text: 'Reflection — daily journal at the top', t: t),
          const SizedBox(height: 10),
          _TipRow(icon: Icons.settings_outlined, text: 'Settings — notifications & dark mode', t: t),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final NTheme t;
  const _TipRow({required this.icon, required this.text, required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: t.subtleShadow,
          ),
          child: Center(child: Icon(icon, size: 16, color: t.accent)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_model.dart';
import '../theme/app_theme.dart';

class GoalCompleteScreen extends StatefulWidget {
  final Daily daily;
  final String completedGoalTitle;

  const GoalCompleteScreen({
    super.key,
    required this.daily,
    required this.completedGoalTitle,
  });

  @override
  State<GoalCompleteScreen> createState() => _GoalCompleteScreenState();
}

class _GoalCompleteScreenState extends State<GoalCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final completed = widget.daily.completedGoalsCount;
    final total = widget.daily.totalGoalsCount;
    final allDone = widget.daily.allGoalsCompleted;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated checkmark
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: t.surface,
                        shape: BoxShape.circle,
                        boxShadow: t.boxShadow,
                      ),
                      child: Center(
                        child: Icon(
                          allDone ? Icons.celebration_outlined : Icons.check_rounded,
                          size: 44,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Goal title
                  Text(
                    widget.completedGoalTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    allDone
                        ? 'All goals complete. Great work!'
                        : _encouragement(completed, total),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: t.textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Progress card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppRadii.large),
                      boxShadow: t.insetShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Today', style: Theme.of(context).textTheme.labelLarge),
                        Row(
                          children: [
                            ...List.generate(total, (i) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < completed
                                      ? AppColors.success
                                      : t.textTertiary.withValues(alpha: 0.3),
                                  boxShadow: i < completed
                                      ? [BoxShadow(color: t.shadowDark, blurRadius: 2, offset: const Offset(1, 1))]
                                      : null,
                                ),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Text(
                              '$completed / $total',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: allDone ? AppColors.success : t.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Continue button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        boxShadow: t.buttonShadow,
                      ),
                      child: Text(
                        allDone ? 'Wrap up the day' : 'Keep going',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _encouragement(int done, int total) {
    final left = total - done;
    if (left == 1) return 'One more to go. You\'ve got this.';
    if (left <= 3) return '$left goals left. Stay focused.';
    return 'Keep it up. $done of $total done.';
  }
}

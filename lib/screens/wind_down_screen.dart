import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../models/daily_model.dart';
import '../theme/app_theme.dart';

class WindDownScreen extends StatefulWidget {
  final Daily daily;

  const WindDownScreen({super.key, required this.daily});

  @override
  State<WindDownScreen> createState() => _WindDownScreenState();
}

class _WindDownScreenState extends State<WindDownScreen>
    with SingleTickerProviderStateMixin {
  static const _totalSeconds = 600;
  int _secondsRemaining = _totalSeconds;
  bool _isPlaying = false;
  Timer? _timer;

  // Breathing animation
  late AnimationController _breathController;
  late Animation<double> _breathAnim;
  bool _breathExpand = true;

  // Phase: 0=timer, 1=notes
  int _phase = 0;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _breathExpand = !_breathExpand);
          _breathController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() => _breathExpand = !_breathExpand);
          _breathController.forward();
        }
      });
    _breathAnim = CurvedAnimation(parent: _breathController, curve: Curves.easeInOut);
    _breathController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isPlaying = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isPlaying = false);
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    context.read<DailyBloc>().add(const CompleteWindDownEvent());
    setState(() => _phase = 1);
  }

  void _skip() {
    _timer?.cancel();
    context.read<DailyBloc>().add(const CompleteWindDownEvent());
    setState(() => _phase = 1);
  }

  void _saveAndExit() {
    if (_notesController.text.trim().isNotEmpty) {
      context.read<DailyBloc>().add(UpdateDailyNotesEvent(_notesController.text.trim()));
    }
    Navigator.pop(context);
  }

  String _fmt(int s) {
    final m = s ~/ 60, sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _formatWorkEndTime() {
    final h = widget.daily.workEndHour;
    final m = widget.daily.workEndMinute;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: _phase == 0 ? _buildTimerPhase(t) : _buildNotesPhase(t),
      ),
    );
  }

  Widget _buildTimerPhase(NTheme t) {
    final progress = _secondsRemaining / _totalSeconds;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: t.surface,
                    shape: BoxShape.circle,
                    boxShadow: t.buttonShadow,
                  ),
                  child: Icon(Icons.arrow_back_rounded, size: 18, color: t.textPrimary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatWorkEndTime(), style: Theme.of(context).textTheme.displayLarge),
                    Text('TIME TO WIND DOWN', style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Breathing circle
          AnimatedBuilder(
            animation: _breathAnim,
            builder: (context, _) {
              final scale = 0.7 + (_breathExpand ? _breathAnim.value : (1 - _breathAnim.value)) * 0.3;
              return Column(
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: t.surface,
                      shape: BoxShape.circle,
                      boxShadow: t.boxShadow,
                    ),
                    child: Center(
                      child: Container(
                        width: 120 * scale,
                        height: 120 * scale,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _breathExpand ? 'Breathe in' : 'Breathe out',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: t.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Wind-down message
          Text(
            'Step away from work.\nClose your laptop.\nBreathe.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.9,
                  color: t.textSecondary,
                ),
          ),
          const SizedBox(height: 36),

          // Timer card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadii.extraLarge),
              boxShadow: t.boxShadow,
            ),
            child: Column(
              children: [
                // Circular progress
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: _CircularProgressPainter(progress: progress, textColor: t.textPrimary, trackColor: t.shadowDark),
                      ),
                      Text(
                        _fmt(_secondsRemaining),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Play/Pause button
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: t.surface,
                      shape: BoxShape.circle,
                      boxShadow: t.buttonShadow,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 28,
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Today stats + skip
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                    boxShadow: t.insetShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Today', style: Theme.of(context).textTheme.labelLarge),
                      Text(
                        '${widget.daily.completedGoalsCount}/${widget.daily.totalGoalsCount} goals',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: widget.daily.allGoalsCompleted ? AppColors.success : t.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _skip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                    boxShadow: t.buttonShadow,
                  ),
                  child: Text('Skip', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesPhase(NTheme t) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: t.surface,
              shape: BoxShape.circle,
              boxShadow: t.boxShadow,
            ),
            child: Center(
              child: Text('✓', style: TextStyle(fontSize: 22, color: AppColors.success)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Wind-down complete', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'You\'ve earned your rest.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 28),
          Text('Reflection (optional)', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadii.large),
                boxShadow: t.insetShadow,
              ),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'How was your day? What went well?',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _saveAndExit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadii.large),
                boxShadow: t.buttonShadow,
              ),
              child: Center(
                child: Text('Done for today', style: Theme.of(context).textTheme.titleSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Circular progress painter ────────────────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color textColor;
  final Color trackColor;
  _CircularProgressPainter({required this.progress, required this.textColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final radius = min(cx, cy) - 8;

    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.1)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = textColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.textColor != textColor;
}

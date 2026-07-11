import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../models/goal_model.dart';
import '../models/daily_model.dart';
import '../theme/app_theme.dart';

class FocusScreen extends StatefulWidget {
  final Goal goal;
  final Daily daily;
  const FocusScreen({super.key, required this.goal, required this.daily});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with SingleTickerProviderStateMixin {
  static const _presets = [5, 15, 25, 45];
  int _selectedMinutes = 25;
  bool _isCustom = false;
  int _phase = 0; // 0=setup, 1=running

  late int _totalSeconds;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _selectedMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _ringController = AnimationController(vsync: this, duration: Duration(minutes: _selectedMinutes));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = 1;
      _totalSeconds = _selectedMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _isRunning = true;
    });
    _ringController.duration = Duration(minutes: _selectedMinutes);
    _ringController.forward(from: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        setState(() { _remainingSeconds = 0; _isRunning = false; });
        _ringController.stop();
        context.read<DailyBloc>().add(AddFocusMinutesEvent(_selectedMinutes));
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _togglePause() {
    setState(() => _isRunning = !_isRunning);
    if (_isRunning) {
      _ringController.forward();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_remainingSeconds <= 1) {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          setState(() { _remainingSeconds = 0; _isRunning = false; });
          _ringController.stop();
        } else {
          setState(() => _remainingSeconds--);
        }
      });
    } else {
      _timer?.cancel();
      _ringController.stop();
    }
  }

  Future<void> _pickCustomTime() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom duration'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'min', hintText: '1–180'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 1 && v <= 180) Navigator.pop(ctx, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) setState(() { _selectedMinutes = result; _isCustom = true; });
  }

  void _markDone() {
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    final elapsed = ((_totalSeconds - _remainingSeconds) / 60).ceil().clamp(0, _selectedMinutes);
    if (_phase == 1 && elapsed > 0) {
      context.read<DailyBloc>().add(AddFocusMinutesEvent(elapsed));
    }
    context.read<DailyBloc>().add(CompleteGoalEvent(widget.goal.id));
    context.pop();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: _phase == 0 ? _buildSetup(context, t) : _buildTimer(context, t),
      ),
    );
  }

  Widget _buildSetup(BuildContext context, NTheme t) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          ),
          const SizedBox(height: 32),
          Text('Focus on', style: TextStyle(fontSize: 14, color: t.textSecondary)),
          const SizedBox(height: 6),
          Text(
            widget.goal.title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: t.textPrimary),
          ),
          const Spacer(),
          Text('Set timer duration', style: TextStyle(fontSize: 13, color: t.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              ..._presets.map((min) {
                final selected = !_isCustom && min == _selectedMinutes;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() { _selectedMinutes = min; _isCustom = false; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(AppRadii.large),
                          boxShadow: selected ? t.insetShadow : t.buttonShadow,
                        ),
                        child: Column(children: [
                          Text(
                            '$min',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: selected ? t.accent : t.textPrimary),
                          ),
                          Text('min', style: TextStyle(fontSize: 11, color: t.textTertiary)),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
              Expanded(
                child: GestureDetector(
                  onTap: _pickCustomTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppRadii.large),
                      boxShadow: _isCustom ? t.insetShadow : t.buttonShadow,
                    ),
                    child: Column(children: [
                      _isCustom
                          ? Text('$_selectedMinutes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.accent))
                          : Icon(Icons.edit_outlined, size: 22, color: t.textTertiary),
                      Text('min', style: TextStyle(fontSize: 11, color: t.textTertiary)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _start,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadii.large),
                boxShadow: t.buttonShadow,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.play_arrow_rounded, color: t.textPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Start Focus',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textPrimary),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimer(BuildContext context, NTheme t) {
    final progress = _totalSeconds > 0
        ? (_totalSeconds - _remainingSeconds) / _totalSeconds
        : 1.0;
    final done = _remainingSeconds == 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
            ),
          ),
          const Spacer(),
          Text(
            widget.goal.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary),
          ),
          const SizedBox(height: 40),
          // Ring
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _FocusRingPainter(
                progress: progress.clamp(0.0, 1.0),
                color: t.accent,
                bg: t.shadowDark,
              ),
              child: Center(
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w300,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          if (!done)
            GestureDetector(
              onTap: _togglePause,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: t.buttonShadow,
                ),
                child: Icon(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 28,
                  color: t.textPrimary,
                ),
              ),
            ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _markDone,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: t.buttonShadow,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_rounded, size: 18, color: t.success),
                const SizedBox(width: 6),
                Text(
                  'Mark Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.textPrimary),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.pop(),
            child: Text(
              done ? 'Back' : 'Skip',
              style: TextStyle(fontSize: 13, color: t.textTertiary),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;
  const _FocusRingPainter({required this.progress, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final bgPaint = Paint()
      ..color = bg.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) => old.progress != progress;
}

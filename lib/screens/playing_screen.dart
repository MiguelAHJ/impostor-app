import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cancel_game_button.dart';

const _roundSeconds = 300; // 5 minutes

class PlayingScreen extends StatefulWidget {
  const PlayingScreen({super.key});

  @override
  State<PlayingScreen> createState() => _PlayingScreenState();
}

class _PlayingScreenState extends State<PlayingScreen> {
  int _timeLeft = _roundSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _roundSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft <= 1) {
          _timeLeft = 0;
          timer.cancel();
          context.read<GameProvider>().startVoting();
        } else {
          _timeLeft--;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final players = game.players;
    final alivePlayers = game.alivePlayers;

    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;
    final progress = _timeLeft / _roundSeconds;
    final isLow = _timeLeft < 60;

    // Build speaking order
    final originalOrder = <({String name, int originalIndex})>[];
    for (var i = 0; i < players.length; i++) {
      if (players[i].alive) {
        originalOrder.add((name: players[i].name, originalIndex: i));
      }
    }

    var speakerStart = 0;
    for (var i = 0; i < originalOrder.length; i++) {
      if (originalOrder[i].originalIndex >= game.firstSpeakerIndex) {
        speakerStart = i;
        break;
      }
    }

    final orderedPlayers = [
      ...originalOrder.sublist(speakerStart),
      ...originalOrder.sublist(0, speakerStart),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Text(
            'Ronda ${game.roundNumber}',
            style: AppTheme.bodyStyle(
                fontSize: 13, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),

          // Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1F30), Color(0xFF18192A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Timer circle
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _TimerPainter(progress: progress, isLow: isLow),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 18,
                            color: isLow ? AppColors.accent : AppColors.primary,
                          ),
                          Text(
                            '$minutes:${seconds.toString().padLeft(2, '0')}',
                            style: AppTheme.displayStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: isLow
                                  ? AppColors.accent
                                  : AppColors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Speaking order
                Row(
                  children: [
                    const Icon(Icons.mic, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Orden de habla',
                      style: AppTheme.displayStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(orderedPlayers.length, (i) {
                  final p = orderedPlayers[i];
                  final isFirst = i == 0;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isFirst
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.transparent,
                      border: isFirst
                          ? Border.all(
                              color: AppColors.primary.withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${i + 1}',
                            style: AppTheme.displayStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isFirst
                                  ? AppColors.primary
                                  : AppColors.mutedForeground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          p.name,
                          style: AppTheme.bodyStyle(
                            fontSize: 14,
                            color: isFirst
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                          ),
                        ),
                        if (isFirst) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Primero',
                              style: AppTheme.displayStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // End round button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _timer?.cancel();
                      context.read<GameProvider>().startVoting();
                    },
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: const Text('Finalizar Ronda'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.accentForeground,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people,
                  size: 14, color: AppColors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                '${alivePlayers.length} jugadores vivos',
                style: AppTheme.bodyStyle(
                    fontSize: 12, color: AppColors.mutedForeground),
              ),
            ],
          ),
          const CancelGameButton(),
        ],
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final bool isLow;

  _TimerPainter({required this.progress, required this.isLow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = isLow ? AppColors.accent : AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isLow != isLow;
  }
}

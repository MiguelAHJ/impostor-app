import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cancel_game_button.dart';

const _countdownSeconds = 4;

class EliminationRevealScreen extends StatefulWidget {
  const EliminationRevealScreen({super.key});

  @override
  State<EliminationRevealScreen> createState() =>
      _EliminationRevealScreenState();
}

class _EliminationRevealScreenState extends State<EliminationRevealScreen>
    with SingleTickerProviderStateMixin {
  int _timeLeft = _countdownSeconds;
  bool _revealed = false;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft <= 1) {
          _timeLeft = 0;
          timer.cancel();
          _revealed = true;
          _pulseController.repeat(reverse: true);
        } else {
          _timeLeft--;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final eliminatedIndex = game.lastEliminatedIndex;

    if (eliminatedIndex < 0 || eliminatedIndex >= game.players.length) {
      return const SizedBox.shrink();
    }

    final player = game.players[eliminatedIndex];
    final isImpostor = player.role == Role.impostor;
    final roleColor = isImpostor ? AppColors.impostor : AppColors.primary;
    final roleLabel = isImpostor ? 'IMPOSTOR' : 'CIVIL';
    final roleIcon = isImpostor ? Icons.dangerous : Icons.shield;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_revealed) ...[
              // ── FASE SUSPENSO ──────────────────────────────────────────
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
                        value: _timeLeft / _countdownSeconds,
                        strokeWidth: 7,
                        backgroundColor: AppColors.secondary,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      '$_timeLeft',
                      style: AppTheme.displayStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Text(
                player.name,
                style: AppTheme.displayStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ha sido eliminado',
                style: AppTheme.bodyStyle(
                  fontSize: 15,
                  color: AppColors.mutedForeground,
                ),
              ),

              const SizedBox(height: 40),

              // Mystery box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  color: AppColors.secondary,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.question_mark_rounded,
                      size: 48,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¿Civil o Impostor?',
                      style: AppTheme.displayStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const CancelGameButton(),
            ] else ...[
              // ── FASE REVELACIÓN ────────────────────────────────────────
              Text(
                player.name,
                style: AppTheme.displayStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'era...',
                style: AppTheme.bodyStyle(
                  fontSize: 15,
                  color: AppColors.mutedForeground,
                ),
              ),

              const SizedBox(height: 32),

              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor, width: 2),
                    color: roleColor.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(roleIcon, size: 52, color: roleColor),
                      const SizedBox(height: 12),
                      Text(
                        roleLabel,
                        style: AppTheme.displayStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: roleColor,
                        ),
                      ),
                      if (isImpostor) ...[
                        const SizedBox(height: 8),
                        Text(
                          '¡Era el impostor!',
                          style: AppTheme.bodyStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.read<GameProvider>().confirmElimination(),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Continuar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const CancelGameButton(),
            ],
          ],
        ),
      ),
    );
  }
}

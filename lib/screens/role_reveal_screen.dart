import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cancel_game_button.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key});

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  bool _revealed = false;

  void _handleNext() {
    setState(() => _revealed = false);
    context.read<GameProvider>().nextReveal();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final players = game.players;
    final index = game.currentRevealIndex;

    // All players revealed
    if (index >= players.length) {
      return _buildAllReady(context, game);
    }

    final player = players[index];
    final isImpostor = player.role == Role.impostor;
    final hasClue = !isImpostor || game.impostorHasClue;
    final word = isImpostor
        ? (game.impostorHasClue ? game.impostorClue : '')
        : game.currentWord?.palabraReal ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          // Progress
          Text(
            'Jugador ${index + 1} de ${players.length}',
            style: AppTheme.bodyStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (index + 1) / players.length,
              backgroundColor: AppColors.secondary,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),

          // Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
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
                Text(
                  player.name,
                  style: AppTheme.displayStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pasa el dispositivo a ',
                  style: AppTheme.bodyStyle(fontSize: 13, color: AppColors.mutedForeground),
                ),
                Text(
                  player.name,
                  style: AppTheme.bodyStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 20),

                if (!_revealed)
                  // Hidden - tap to reveal
                  GestureDetector(
                    onTap: () => setState(() => _revealed = true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.visibility_off,
                            size: 40,
                            color: AppColors.mutedForeground,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Toca para revelar tu rol',
                            style: AppTheme.bodyStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Revealed
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isImpostor ? AppColors.impostor : AppColors.primary,
                        width: 2,
                      ),
                      color: isImpostor
                          ? AppColors.impostor.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: (isImpostor ? AppColors.impostor : AppColors.primary)
                              .withOpacity(0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 20,
                              color: isImpostor ? AppColors.impostor : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isImpostor ? 'IMPOSTOR' : 'CIVIL',
                              style: AppTheme.displayStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isImpostor ? AppColors.impostor : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (isImpostor && !hasClue) ...[
                          // No-clue mode
                          const Icon(
                            Icons.block,
                            size: 36,
                            color: AppColors.mutedForeground,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin pista',
                            style: AppTheme.displayStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'No tienes pista. Escucha a los demás con atención y trata de encajar sin delatarte.',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyStyle(
                                fontSize: 13,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Normal word / clue
                          Text(
                            word,
                            style: AppTheme.displayStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (isImpostor) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Esta es tu pista. Intenta encajar.',
                              style: AppTheme.bodyStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                if (_revealed) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleNext,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Siguiente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.foreground,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const CancelGameButton(),
        ],
      ),
    );
  }

  Widget _buildAllReady(BuildContext context, GameProvider game) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
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
            Text(
              '¡Todos listos!',
              style: AppTheme.displayStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(
              'Todos han visto su rol. Es hora de jugar.',
              style: AppTheme.bodyStyle(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: game.startPlaying,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Comenzar Ronda'),
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
        ),
      ),
    );
  }
}

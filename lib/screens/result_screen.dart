import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final players = game.players;

    final aliveImpostors =
        players.where((p) => p.alive && p.role == Role.impostor).length;
    final civilsWin = aliveImpostors == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          // Trophy / skull icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: child,
            ),
            child: Icon(
              civilsWin ? Icons.emoji_events : Icons.dangerous,
              size: 56,
              color: civilsWin ? AppColors.primary : AppColors.impostor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            civilsWin ? '¡Civiles ganan!' : '¡Impostores ganan!',
            style: AppTheme.displayStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: civilsWin ? AppColors.primary : AppColors.impostor,
            ),
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
                // Word reveal
                Text(
                  'La palabra era',
                  style: AppTheme.bodyStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  game.currentWord?.palabraReal ?? '',
                  style: AppTheme.displayStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTheme.bodyStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                    children: [
                      const TextSpan(text: 'Pista del impostor: '),
                      TextSpan(
                        text: game.impostorClue,
                        style: AppTheme.bodyStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),

                // Player list
                ...List.generate(players.length, (i) {
                  final p = players[i];
                  final isImpostor = p.role == Role.impostor;
                  return Opacity(
                    opacity: p.alive ? 1.0 : 0.4,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isImpostor ? Icons.dangerous : Icons.shield,
                            size: 16,
                            color: isImpostor
                                ? AppColors.impostor
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            p.name,
                            style: AppTheme.bodyStyle(
                              fontSize: 14,
                              color: AppColors.foreground,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isImpostor
                                  ? AppColors.impostor.withOpacity(0.15)
                                  : AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isImpostor ? 'Impostor' : 'Civil',
                              style: AppTheme.displayStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isImpostor
                                    ? AppColors.impostor
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          if (!p.alive) ...[
                            const SizedBox(width: 8),
                            Text(
                              '✕',
                              style: AppTheme.bodyStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // New game button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<GameProvider>().resetGame(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Nueva Partida'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTheme.displayStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

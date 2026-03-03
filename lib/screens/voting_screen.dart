import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cancel_game_button.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  int? _selected;
  bool _confirmed = false;

  void _handleEliminate() {
    if (_selected == null) return;
    setState(() => _confirmed = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      context.read<GameProvider>().eliminatePlayer(_selected!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final players = game.players;

    final alivePlayers = <({int index, String name})>[];
    for (var i = 0; i < players.length; i++) {
      if (players[i].alive) {
        alivePlayers.add((index: i, name: players[i].name));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          // Header
          const Icon(Icons.how_to_vote, size: 32, color: AppColors.accent),
          const SizedBox(height: 8),
          Text(
            'Votación',
            style: AppTheme.displayStyle(
                fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona al jugador a eliminar',
            style: AppTheme.bodyStyle(
                fontSize: 13, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),

          // Player list
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
              children: alivePlayers.map((p) {
                final isSelected = _selected == p.index;
                return GestureDetector(
                  onTap: _confirmed
                      ? null
                      : () => setState(() => _selected = p.index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.15)
                          : AppColors.secondary,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.accent : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.2),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_remove,
                          size: 18,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.mutedForeground,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          p.name,
                          style: AppTheme.bodyStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Confirm button
          if (_selected != null && !_confirmed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleEliminate,
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: Text('Eliminar a ${players[_selected!].name}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.impostor,
                  foregroundColor: AppColors.impostorForeground,
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

          // Eliminating feedback
          if (_confirmed) ...[
            const SizedBox(height: 24),
            Text(
              'Eliminando...',
              style: AppTheme.displayStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
          if (!_confirmed) const CancelGameButton(),
        ],
      ),
    );
  }
}

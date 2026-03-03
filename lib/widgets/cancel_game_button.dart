import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

/// Small "Cancelar partida" text button that shows a confirmation dialog
/// before returning to the setup screen. Safe to use in any game phase.
class CancelGameButton extends StatelessWidget {
  const CancelGameButton({super.key});

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancelar partida',
          style: AppTheme.displayStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '¿Seguro que quieres volver al menú? Los participantes y ajustes quedarán guardados.',
          style: AppTheme.bodyStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Seguir jugando',
              style: AppTheme.bodyStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cancelar partida',
              style: AppTheme.bodyStyle(
                fontSize: 14,
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<GameProvider>().resetGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _confirm(context),
      icon: const Icon(Icons.exit_to_app,
          size: 16, color: AppColors.mutedForeground),
      label: Text(
        'Cancelar partida',
        style: AppTheme.bodyStyle(
          fontSize: 13,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

const _kRevealSeconds = 4;
const _kResultSeconds = 5;

class OnlineEliminationRevealScreen extends StatefulWidget {
  const OnlineEliminationRevealScreen({super.key});

  @override
  State<OnlineEliminationRevealScreen> createState() =>
      _OnlineEliminationRevealScreenState();
}

class _OnlineEliminationRevealScreenState
    extends State<OnlineEliminationRevealScreen> with TickerProviderStateMixin {
  // Phase 0: suspense (4s), Phase 1: role revealed (5s)
  int _phase = 0;
  double _progress = 1.0;
  int _displaySeconds = _kRevealSeconds;
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

    _startPhase(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPhase(int phase) {
    _timer?.cancel();
    final totalSeconds = phase == 0 ? _kRevealSeconds : _kResultSeconds;
    setState(() {
      _phase = phase;
      _progress = 1.0;
      _displaySeconds = totalSeconds;
    });

    if (phase == 1) {
      _pulseController.repeat(reverse: true);
    }

    int elapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      elapsed++;
      setState(() {
        _displaySeconds = totalSeconds - elapsed;
        _progress = _displaySeconds / totalSeconds;
      });
      if (elapsed >= totalSeconds) {
        t.cancel();
        if (phase == 0) {
          _startPhase(1);
        } else {
          context.read<GameProvider>().resolveOnlineElimination();
        }
      }
    });
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
    final roleColor = isImpostor ? const Color(0xFFE53935) : AppColors.blue;
    final avatarColor =
        AppColors.avatarColors[eliminatedIndex % AppColors.avatarColors.length];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.lightBg1, AppColors.lightBg2, AppColors.lightBg3],
        ),
      ),
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Veredicto',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'ELIMINACIÓN',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: game.showRoleOnElimination
                    ? (_phase == 0
                        ? _buildSuspense(player, avatarColor)
                        : _buildRevealed(player, isImpostor, roleColor, avatarColor, game))
                    : _buildNoReveal(player, avatarColor),
              ),
            ),
          ),

          // Auto countdown bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCountdownBar(
              _phase == 0
                  ? AppColors.blue
                  : (_phase == 1 && game.showRoleOnElimination ? roleColor : Colors.grey.shade500),
            ),
          ),

          // Tags
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTag(Icons.people_outline,
                  '${game.alivePlayers.length} Jugadores'),
              const SizedBox(width: 12),
              _buildTag(
                Icons.person_off_outlined,
                '${game.impostorCount} ${game.impostorCount == 1 ? "Impostor" : "Impostores"}',
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildCountdownBar(Color color) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          FractionallySizedBox(
            widthFactor: _progress,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Center(
            child: Text(
              _displaySeconds > 0 ? '$_displaySeconds s' : '',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspense(Player player, Color avatarColor) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: avatarColor.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: avatarColor, width: 3),
          ),
          child: Icon(Icons.person, color: avatarColor, size: 52),
        ),

        const SizedBox(height: 16),

        Text(
          player.name,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        Text(
          'ha sido eliminado',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),

        const SizedBox(height: 36),

        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.blue,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$_displaySeconds',
                style: GoogleFonts.outfit(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        Text(
          '¿Civil o Impostor?',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildRevealed(Player player, bool isImpostor, Color roleColor,
      Color avatarColor, GameProvider game) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: avatarColor.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: avatarColor, width: 3),
          ),
          child: Icon(Icons.person, color: avatarColor, size: 52),
        ),

        const SizedBox(height: 16),

        Text(
          player.name,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text(
                  isImpostor ? '¡ERA EL IMPOSTOR!' : 'ERA INOCENTE',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: roleColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isImpostor
                      ? 'Han eliminado a un impostor'
                      : 'Han eliminado a un civil...',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: roleColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoReveal(Player player, Color avatarColor) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: avatarColor.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: avatarColor, width: 3),
          ),
          child: Icon(Icons.person, color: avatarColor, size: 52),
        ),

        const SizedBox(height: 16),

        Text(
          player.name,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'ha sido eliminado',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: Colors.grey.shade500,
          ),
        ),

        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_off_outlined,
                  size: 18, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                'Su rol permanece oculto',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

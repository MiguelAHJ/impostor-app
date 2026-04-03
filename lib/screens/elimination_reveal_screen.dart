import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

const _countdownSeconds = 4;

class EliminationRevealScreen extends StatefulWidget {
  const EliminationRevealScreen({super.key});

  @override
  State<EliminationRevealScreen> createState() =>
      _EliminationRevealScreenState();
}

class _EliminationRevealScreenState extends State<EliminationRevealScreen>
    with TickerProviderStateMixin {
  bool _revealed = false;
  double _progress = 1.0;
  int _displaySeconds = _countdownSeconds;

  late final AnimationController _ticker;
  final Stopwatch _stopwatch = Stopwatch();

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

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _ticker.addListener(_onTick);
    _stopwatch.start();
  }

  void _onTick() {
    if (_revealed) return;
    final elapsed = _stopwatch.elapsedMilliseconds / 1000.0;
    final remaining = _countdownSeconds - elapsed;

    if (remaining <= 0) {
      _stopwatch.stop();
      _ticker.stop();
      setState(() {
        _progress = 0;
        _displaySeconds = 0;
        _revealed = true;
      });
      _pulseController.repeat(reverse: true);
    } else {
      setState(() {
        _progress = remaining / _countdownSeconds;
        _displaySeconds = remaining.ceil();
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancelar partida',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        content: Text(
          '¿Seguro que quieres volver al menú? Los participantes y ajustes quedarán guardados.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Seguir',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cancelar partida',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<GameProvider>().resetGame();
    }
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
    final roleColor =
        isImpostor ? const Color(0xFFE53935) : AppColors.blue;
    final roleLabel = isImpostor ? 'IMPOSTOR' : 'CIVIL';
    final avatarIndex =
        eliminatedIndex % AppColors.avatarColors.length;
    final avatarColor = AppColors.avatarColors[avatarIndex];

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
          // ── App Bar ────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Row(
              children: [
                _appBarButton(Icons.close, onTap: _showCancelDialog),
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

          // ── Content ────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: game.showRoleOnElimination
                    ? (_revealed
                        ? _buildRevealed(player, isImpostor, roleColor,
                            roleLabel, avatarColor, game.roundNumber - 1,
                            _getSpeakingPosition(game, eliminatedIndex))
                        : _buildSuspense(player, avatarColor))
                    : _buildNoReveal(player, avatarColor),
              ),
            ),
          ),

          // ── Bottom ─────────────────────────────────────────────────
          if (_revealed || !game.showRoleOnElimination) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () =>
                      context.read<GameProvider>().confirmElimination(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.blue.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONTINUAR',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 20, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Tags ───────────────────────────────────────────────────
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

  // ── Suspense phase ──────────────────────────────────────────────────────

  Widget _buildSuspense(Player player, Color avatarColor) {
    return Column(
      children: [
        // Player avatar
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

        // Countdown
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

  // ── Revealed phase ──────────────────────────────────────────────────────

  int _getSpeakingPosition(GameProvider game, int playerIndex) {
    final players = game.players;
    final aliveIndices = <int>[];
    for (var i = 0; i < players.length; i++) {
      if (players[i].alive || i == playerIndex) {
        aliveIndices.add(i);
      }
    }
    var start = 0;
    for (var i = 0; i < aliveIndices.length; i++) {
      if (aliveIndices[i] >= game.firstSpeakerIndex) {
        start = i;
        break;
      }
    }
    final ordered = [
      ...aliveIndices.sublist(start),
      ...aliveIndices.sublist(0, start),
    ];
    return ordered.indexOf(playerIndex) + 1;
  }

  Widget _buildRevealed(Player player, bool isImpostor, Color roleColor,
      String roleLabel, Color avatarColor, int roundsSurvived,
      int speakingPosition) {
    return Column(
      children: [
        // Avatar (same default as rest of the app)
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

        // Name
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

        // Role reveal
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

        const SizedBox(height: 28),

        // Stats
        _buildStatRow(
          Icons.shield_outlined,
          'Sobrevivió ',
          '$roundsSurvived ${roundsSurvived == 1 ? 'ronda' : 'rondas'}',
        ),
        const SizedBox(height: 8),
        _buildStatRow(
          Icons.record_voice_over_outlined,
          'Posición de habla: ',
          '#$speakingPosition',
        ),
      ],
    );
  }

  // ── No-reveal phase (role hidden) ─────────────────────────────────────

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

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Container(
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
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _appBarButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.darkText, size: 20),
      ),
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

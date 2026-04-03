import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

const _roundSeconds = 300; // 5 minutes

class PlayingScreen extends StatefulWidget {
  const PlayingScreen({super.key});

  @override
  State<PlayingScreen> createState() => _PlayingScreenState();
}

class _PlayingScreenState extends State<PlayingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  double _progress = 1.0;
  bool _finished = false;
  int _elapsedOffset = 0;

  @override
  void initState() {
    super.initState();
    // Restore elapsed time if returning from voting
    final savedElapsed = context.read<GameProvider>().elapsedSeconds;

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _ticker.addListener(_onTick);
    _stopwatch.start();
    if (savedElapsed > 0) {
      // Fast-forward the stopwatch to the saved position
      _elapsedOffset = savedElapsed;
    }
  }

  void _onTick() {
    if (_finished) return;
    final elapsed = _elapsedOffset + _stopwatch.elapsedMilliseconds / 1000.0;
    final remaining = _roundSeconds - elapsed;
    if (remaining <= 0) {
      _finished = true;
      _stopwatch.stop();
      setState(() => _progress = 0);
      context.read<GameProvider>().startVoting(timerExpired: true);
    } else {
      setState(() => _progress = remaining / _roundSeconds);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
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

  void _showInstructions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.blue, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Fase de Discusión',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Text(
                  'Cada jugador habla en el orden indicado diciendo '
                  'algo relacionado con la palabra secreta.\n\n'
                  'Civiles: Den pistas suficientes para demostrar que '
                  'conocen la palabra, pero sin ser tan obvios.\n\n'
                  'Impostores: Escuchen y sean ambiguos. ¡No se delaten!\n\n'
                  'Al terminar el tiempo (o antes si lo deciden), '
                  'se pasa a la votación.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: const Color(0xFF4A4A5A),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final players = game.players;

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
              bottom: 8,
            ),
            child: Row(
              children: [
                _appBarButton(Icons.close, onTap: _showCancelDialog),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Ronda ${game.roundNumber}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'FASE DE DISCUSIÓN',
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
                _appBarButton(Icons.info_outline,
                    onTap: _showInstructions, highlight: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Timer (fixed) ──────────────────────────────────────────
          Builder(
            builder: (context) {
              final remaining = _progress * _roundSeconds;
              final minutes = remaining ~/ 60;
              final seconds = (remaining % 60).toInt();
              final isLow = remaining < 60;

              return SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _SmoothTimerPainter(
                    progress: _progress,
                    isLow: isLow,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: isLow
                                ? const Color(0xFFE53935)
                                : AppColors.darkText,
                          ),
                        ),
                        Text(
                          'RESTANTE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Speaking Order header (fixed) ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Orden de habla',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orderedPlayers.length} Jugadores',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Player list (scrollable) ───────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: orderedPlayers.length,
              itemBuilder: (ctx, i) {
                final p = orderedPlayers[i];
                final color = AppColors
                    .avatarColors[i % AppColors.avatarColors.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                        child:
                            Icon(Icons.person, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Vote button ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  _finished = true;
                  _stopwatch.stop();
                  _ticker.stop();
                  final elapsed = _elapsedOffset + _stopwatch.elapsedMilliseconds ~/ 1000;
                  context.read<GameProvider>().startVoting(elapsedSeconds: elapsed);
                },
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
                    const Icon(Icons.how_to_vote_outlined,
                        size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'PASAR A VOTACIÓN',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

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

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _appBarButton(IconData icon,
      {required VoidCallback onTap, bool highlight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: highlight
              ? Border.all(color: AppColors.blue.withValues(alpha: 0.3))
              : null,
        ),
        child: Icon(
          icon,
          color: highlight ? AppColors.blue : AppColors.darkText,
          size: 20,
        ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Smooth circular timer painter
// ═══════════════════════════════════════════════════════════════════════════

class _SmoothTimerPainter extends CustomPainter {
  final double progress;
  final bool isLow;

  _SmoothTimerPainter({required this.progress, required this.isLow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background track
    final bgPaint = Paint()
      ..color = const Color(0xFFE8E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final color = isLow ? const Color(0xFFE53935) : AppColors.blue;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
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
  bool shouldRepaint(covariant _SmoothTimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isLow != isLow;
  }
}

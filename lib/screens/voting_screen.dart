import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

const _roundSeconds = 300;

class _VotingScreenState extends State<VotingScreen>
    with SingleTickerProviderStateMixin {
  int? _selected;
  bool _confirmed = false;

  // Live countdown from discussion phase
  late final AnimationController _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  late int _elapsedOffset;
  int _remainingSeconds = 0;
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();
    final game = context.read<GameProvider>();
    _timerDone = game.timerExpired;
    _elapsedOffset = game.elapsedSeconds;

    if (!_timerDone) {
      final initialRemaining = _roundSeconds - _elapsedOffset;
      _remainingSeconds = initialRemaining.clamp(0, _roundSeconds);
      _ticker = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat();
      _ticker.addListener(_onTick);
      _stopwatch.start();
    } else {
      _ticker = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      );
      _remainingSeconds = 0;
    }
  }

  void _onTick() {
    if (_timerDone) return;
    final totalElapsed =
        _elapsedOffset + _stopwatch.elapsedMilliseconds / 1000.0;
    final remaining = (_roundSeconds - totalElapsed).round();
    if (remaining <= 0) {
      _timerDone = true;
      _stopwatch.stop();
      _ticker.stop();
      setState(() => _remainingSeconds = 0);
    } else if (remaining != _remainingSeconds) {
      setState(() => _remainingSeconds = remaining);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  void _handleEliminate() {
    if (_selected == null) return;
    setState(() => _confirmed = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      context.read<GameProvider>().eliminatePlayer(_selected!);
    });
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
          maxHeight: MediaQuery.of(ctx).size.height * 0.5,
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
                    'Votación',
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
                  'Selecciona al jugador que crees que es el impostor '
                  'y confirma tu voto.\n\n'
                  'El jugador con más votos será eliminado de la partida.',
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
    final canGoBack = !_timerDone;

    final alivePlayers = <({int index, String name})>[];
    for (var i = 0; i < players.length; i++) {
      if (players[i].alive) {
        alivePlayers.add((index: i, name: players[i].name));
      }
    }

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
                        '¿Quién es el impostor?',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'FASE DE VOTACIÓN',
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

          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Selecciona al jugador a eliminar',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 12),

          // ── Back to discussion (live timer) ─────────────────────────
          if (canGoBack && !_confirmed)
            Padding(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, bottom: 12),
              child: GestureDetector(
                onTap: () {
                  final elapsed = _elapsedOffset +
                      _stopwatch.elapsedMilliseconds ~/ 1000;
                  context
                      .read<GameProvider>()
                      .startVoting(elapsedSeconds: elapsed);
                  context.read<GameProvider>().backToPlaying();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        'Volver a discusión',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lightBg3,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Player grid ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: alivePlayers.map((p) {
                  final isSelected = _selected == p.index;
                  final avatarIndex = p.index % AppColors.avatarColors.length;
                  final color = AppColors.avatarColors[avatarIndex];

                  return GestureDetector(
                    onTap: _confirmed
                        ? null
                        : () => setState(() {
                              _selected = isSelected ? null : p.index;
                            }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: (MediaQuery.of(context).size.width - 52) / 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.blue.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: isSelected ? 16 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: color, width: 2.5),
                                ),
                                child: Icon(Icons.person,
                                    color: color, size: 30),
                              ),
                              if (isSelected)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: AppColors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Name
                          Text(
                            p.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Confirm button ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_selected != null && !_confirmed) ? _handleEliminate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  disabledBackgroundColor: AppColors.blue.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppColors.blue.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _selected != null && !_confirmed ? 4 : 0,
                  shadowColor: AppColors.blue.withValues(alpha: 0.3),
                ),
                child: _confirmed
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Eliminando...',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _selected != null
                            ? 'Eliminar a ${players[_selected!].name}'
                            : 'Selecciona un jugador',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
                  '${alivePlayers.length} Jugadores'),
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

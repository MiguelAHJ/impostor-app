import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key});

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _springAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
    );
    _springController.addListener(() {
      setState(() => _dragOffset = _springAnimation.value);
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      if (_dragOffset > 0) _dragOffset = 0;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    _springAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic,
    ));
    _springController.forward(from: 0);
  }

  void _handleNext() {
    setState(() => _dragOffset = 0);
    _springController.stop();
    context.read<GameProvider>().nextReveal();
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
      builder: (ctx) => const _InstructionsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final players = game.players;
    final index = game.currentRevealIndex;

    if (index >= players.length) {
      return _buildAllReady(context, game);
    }

    final player = players[index];
    final isImpostor = player.role == Role.impostor;
    final hasClue = !isImpostor || game.impostorHasClue;
    final word = isImpostor
        ? (game.impostorHasClue ? game.impostorClue : '')
        : game.currentWord?.palabraReal ?? '';

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
          // ── App Bar ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Row(
              children: [
                // Cancel
                _appBarButton(
                  Icons.close,
                  onTap: _showCancelDialog,
                ),
                Expanded(
                  child: Text(
                    player.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                // Info
                _appBarButton(
                  Icons.info_outline,
                  onTap: _showInstructions,
                  highlight: true,
                ),
              ],
            ),
          ),

          // ── Progress ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (index + 1) / players.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.blue),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jugador ${index + 1} de ${players.length}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Main area: role info + cover ──────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Role info underneath
                    Positioned.fill(
                      child: _buildRoleInfo(
                          player, isImpostor, hasClue, word),
                    ),
                    // Draggable cover on top
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0, _dragOffset),
                        child: GestureDetector(
                          onVerticalDragUpdate: _onDragUpdate,
                          onVerticalDragEnd: _onDragEnd,
                          child: _buildCoverCard(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Pass button ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleNext,
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
                      'PASAR AL SIGUIENTE',
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

          // ── Tags ─────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTag(Icons.people_outline,
                  '${game.players.length} Jugadores'),
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
              ? Border.all(
                  color: AppColors.blue.withValues(alpha: 0.3))
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

  // ── Role info (revealed underneath cover) ───────────────────────────────

  Widget _buildRoleInfo(
      Player player, bool isImpostor, bool hasClue, String word) {
    final roleColor =
        isImpostor ? const Color(0xFFE53935) : const Color(0xFF2E7D32);
    final bgGradient = isImpostor
        ? [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)]
        : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgGradient,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Role label - big and bold
          Text(
            isImpostor ? 'IMPOSTOR' : 'CIVIL',
            style: GoogleFonts.outfit(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: roleColor,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          // Divider line
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Word / clue
          if (isImpostor && !hasClue) ...[
            Text(
              'SIN PISTA',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: roleColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Escucha a los demás y finge que sabes',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: roleColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ] else ...[
            Text(
              isImpostor ? 'Tu pista' : 'La palabra',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: roleColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              word,
              style: GoogleFonts.outfit(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: roleColor,
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }


  // ── Cover card (on top, drag to reveal) ─────────────────────────────────

  Widget _buildCoverCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3460).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.2),
                    AppColors.teal.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Decorative ring
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Central icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 40,
                  color: AppColors.teal.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Cuál es tu rol?',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(flex: 2),
              // Swipe hint (animated bounce)
              const _BouncingChevron(),
              const SizedBox(height: 4),
              Text(
                'DESLIZA HACIA ARRIBA\nPARA REVELAR TU ROL',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  // ── All Ready screen ────────────────────────────────────────────────────

  Widget _buildAllReady(BuildContext context, GameProvider game) {
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
          SizedBox(height: MediaQuery.of(context).padding.top + 40),
          const Spacer(),

          // Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 40, color: AppColors.blue),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¡Todos listos!',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todos han visto su rol.\nEs hora de jugar.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: game.startPlaying,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor:
                            AppColors.blue.withValues(alpha: 0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'COMENZAR RONDA',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.play_arrow_rounded,
                              size: 22, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Cancel
          TextButton(
            onPressed: _showCancelDialog,
            child: Text(
              'Cancelar partida',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Instructions Modal
// ═══════════════════════════════════════════════════════════════════════════

class _InstructionsModal extends StatelessWidget {
  const _InstructionsModal();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.blue, size: 22),
                const SizedBox(width: 8),
                Text(
                  '¿Cómo se juega?',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(
                    'El Juego',
                    'Un grupo de jugadores recibe una palabra secreta, '
                        'pero entre ellos se esconde un impostor que NO '
                        'conoce la palabra (o recibe solo una pista vaga).',
                  ),
                  _section(
                    'Los Roles',
                    '• Civil: Conoce la palabra secreta. Su objetivo es '
                        'descubrir quién es el impostor.\n'
                        '• Impostor: NO conoce la palabra. Debe escuchar y '
                        'fingir que la sabe.',
                  ),
                  _section(
                    'La Ronda de Discusión',
                    'Cada jugador, en orden, dice algo relacionado con la '
                        'palabra. Por ejemplo:\n\n'
                        'Palabra secreta: "Playa"\n'
                        '• Civil: "Me gusta ir en verano"\n'
                        '• Civil: "Hay que llevar protector solar"\n'
                        '• Impostor: "Es un lugar muy relajante"\n\n'
                        'La clave es dar pistas suficientes para demostrar '
                        'que sabes la palabra, pero sin ser tan obvio que '
                        'el impostor la adivine.',
                  ),
                  _section(
                    'La Votación',
                    'Al terminar la ronda, todos votan para eliminar al '
                        'jugador que creen que es el impostor.',
                  ),
                  _section(
                    '¿Quién gana?',
                    '• Civiles ganan si eliminan a todos los impostores.\n'
                        '• Impostores ganan si logran igualar o superar en '
                        'número a los civiles.',
                  ),
                  _section(
                    'Consejos',
                    'Civiles: No seas demasiado específico o el impostor '
                        'descubrirá la palabra.\n'
                        'Impostor: Escucha atentamente las pistas de los '
                        'demás y sé ambiguo. ¡No te delates!',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: const Color(0xFF4A4A5A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Bouncing Chevron
// ═══════════════════════════════════════════════════════════════════════════

class _BouncingChevron extends StatefulWidget {
  const _BouncingChevron();

  @override
  State<_BouncingChevron> createState() => _BouncingChevronState();
}

class _BouncingChevronState extends State<_BouncingChevron>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = Curves.easeInOut.transform(_controller.value) * -8;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: Icon(
        Icons.keyboard_arrow_up_rounded,
        size: 32,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}

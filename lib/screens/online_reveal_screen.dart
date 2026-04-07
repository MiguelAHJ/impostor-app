import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

const _revealSeconds = 10;

class OnlineRevealScreen extends StatefulWidget {
  const OnlineRevealScreen({super.key});

  @override
  State<OnlineRevealScreen> createState() => _OnlineRevealScreenState();
}

class _OnlineRevealScreenState extends State<OnlineRevealScreen>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _hasRevealed = false;
  int _secondsLeft = _revealSeconds;
  Timer? _countdownTimer;

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
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      if (_dragOffset > 0) _dragOffset = 0;
      if (_dragOffset <= -150 && !_hasRevealed) {
        _hasRevealed = true;
        _startCountdown();
      }
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

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 0;
          t.cancel();
          // Discussion transition triggered by backend's discussion_started event
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final localName = game.localPlayerName;
    final player = game.players.firstWhere(
      (p) => p.name == localName,
      orElse: () => game.players.first,
    );
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
                        'Tu Rol',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'MODO ONLINE',
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

          const SizedBox(height: 8),

          // Main card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildRoleInfo(player, isImpostor, hasClue, word),
                    ),
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0, _dragOffset),
                        child: GestureDetector(
                          onVerticalDragUpdate: _onDragUpdate,
                          onVerticalDragEnd: _onDragEnd,
                          child: _buildCoverCard(localName),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bottom: countdown or swipe hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: _hasRevealed
                  ? _buildCountdownBar()
                  : _buildSwipeHintBar(),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildSwipeHintBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe_up_rounded, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            'DESLIZA PARA VER TU ROL',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBar() {
    final frac = _secondsLeft / _revealSeconds;
    final color = _secondsLeft <= 3 ? const Color(0xFFE53935) : AppColors.blue;

    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Progress fill
        FractionallySizedBox(
          widthFactor: frac,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Label
        Center(
          child: Text(
            _secondsLeft > 0
                ? 'Memoriza tu rol — $_secondsLeft s'
                : 'Esperando a los demás...',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

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
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
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

  Widget _buildCoverCard(String playerName) {
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
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
                'Es el turno de',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                playerName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(flex: 2),
              _BouncingChevron(),
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
}

class _BouncingChevron extends StatefulWidget {
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

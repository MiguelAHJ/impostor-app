import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final winColor =
        civilsWin ? AppColors.blue : const Color(0xFFE53935);

    // Sort: alive players first, then eliminated
    final sorted = List.generate(players.length, (i) => (index: i, player: players[i]));
    sorted.sort((a, b) {
      if (a.player.alive == b.player.alive) return 0;
      return a.player.alive ? -1 : 1;
    });
    final sortedPlayers = sorted;

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
          SizedBox(height: MediaQuery.of(context).padding.top + 16),

          // ── Header ─────────────────────────────────────────────────
          // Icon with elastic animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: child,
            ),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: winColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                civilsWin ? Icons.emoji_events_outlined : Icons.whatshot,
                size: 34,
                color: winColor,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            civilsWin ? '¡Civiles ganan!' : '¡Impostores ganan!',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: winColor,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            civilsWin
                ? 'El impostor fue descubierto'
                : 'Los impostores se salieron con la suya',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 20),

          // ── Word & Clue ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Secret word
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                  child: Column(
                    children: [
                      Text(
                        'LA PALABRA SECRETA',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.currentWord?.palabraReal ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Impostor clue
                if (game.impostorHasClue)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    child: Column(
                      children: [
                        Text(
                          'PISTA DEL IMPOSTOR',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.impostorClue,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Player Roles header ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Roles de jugadores',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Player list (scrollable, alive first) ─────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sortedPlayers.length,
              itemBuilder: (ctx, i) {
                final entry = sortedPlayers[i];
                final p = entry.player;
                final isImpostor = p.role == Role.impostor;
                final roleColor = isImpostor
                    ? const Color(0xFFE53935)
                    : AppColors.blue;
                final avatarColor =
                    AppColors.avatarColors[entry.index % AppColors.avatarColors.length];

                return Opacity(
                  opacity: p.alive ? 1.0 : 0.5,
                  child: Container(
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
                        // Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: avatarColor.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: avatarColor, width: 2),
                          ),
                          child: Icon(Icons.person,
                              color: avatarColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        // Name & role
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isImpostor ? 'IMPOSTOR' : 'CIVIL',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: roleColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status icon
                        if (!p.alive)
                          Icon(Icons.cancel_outlined,
                              size: 20, color: Colors.grey.shade400)
                        else
                          Icon(Icons.check_circle_outlined,
                              size: 20, color: roleColor),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── New Game button ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.read<GameProvider>().resetGame(),
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
                      'NUEVA PARTIDA',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.refresh_rounded,
                        size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

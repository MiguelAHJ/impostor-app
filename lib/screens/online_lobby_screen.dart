import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';

class OnlineLobbyScreen extends StatelessWidget {
  const OnlineLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final countdown = game.countdown;
    final isCountingDown = countdown != null && countdown > 0;

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
                _appBarButton(Icons.arrow_back_rounded, onTap: () {
                  game.backToOnlineName();
                }),
                Expanded(
                  child: Text(
                    'Sala de Espera',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Room code card
                  _RoomCodeCard(code: game.roomCode),
                  const SizedBox(height: 20),

                  // Players list
                  _PlayersCard(
                    players: game.lobbyPlayers,
                    localPlayerName: game.localPlayerName,
                  ),
                  const SizedBox(height: 20),

                  // Settings (host only)
                  if (game.isHost)
                    _SettingsCard(
                      impostorCount: game.impostorCount,
                      maxImpostors: _maxImpostors(game.lobbyPlayers.length),
                      showRoleOnElimination: game.showRoleOnElimination,
                      impostorHasClue: game.impostorHasClue,
                      enabled: !isCountingDown,
                      onChanged: (impostors, showRole, hasClue) {
                        game.updateLobbySettings(
                          impostors: impostors,
                          showRole: showRole,
                          hasClue: hasClue,
                        );
                      },
                    )
                  else
                    _GuestSettingsCard(
                      impostorCount: game.impostorCount,
                      showRoleOnElimination: game.showRoleOnElimination,
                      impostorHasClue: game.impostorHasClue,
                    ),

                  const SizedBox(height: 24),

                  // Countdown overlay
                  if (isCountingDown)
                    _CountdownBanner(seconds: countdown)
                  else if (countdown == 0)
                    _CountdownBanner(seconds: 0)
                  else ...[
                    // Ready button
                    _ReadyButton(
                      isReady: _isLocalReady(game),
                      onTap: () => game.toggleReady(),
                    ),

                    if (game.lobbyPlayers.length < 3) ...[
                      const SizedBox(height: 12),
                      Text(
                        'MÍNIMO 3 JUGADORES PARA INICIAR',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isLocalReady(GameProvider game) {
    final me = game.lobbyPlayers.where((p) => p.name == game.localPlayerName);
    return me.isNotEmpty && me.first.ready;
  }

  int _maxImpostors(int playerCount) {
    return ((playerCount - 1) / 2).floor().clamp(1, 10);
  }

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
}

// ── Room Code Card ──────────────────────────────────────────────────────────

class _RoomCodeCard extends StatelessWidget {
  final String code;
  const _RoomCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Código de Sala',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitleText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Código copiado', style: GoogleFonts.spaceGrotesk()),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy_rounded, size: 18, color: AppColors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Comparte este código con los demás jugadores',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.subtitleText),
          ),
        ],
      ),
    );
  }
}

// ── Players Card ────────────────────────────────────────────────────────────

class _PlayersCard extends StatelessWidget {
  final List<LobbyPlayer> players;
  final String localPlayerName;
  const _PlayersCard({required this.players, required this.localPlayerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_rounded, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(
                'Jugadores (${players.length})',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...players.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final color = AppColors.avatarColors[index % AppColors.avatarColors.length];
            final isMe = player.name == localPlayerName;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withValues(alpha: 0.25),
                    child: Icon(Icons.person_rounded, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          player.name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.darkText,
                          ),
                        ),
                        if (isMe)
                          Text(
                            ' (tú)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: AppColors.subtitleText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (player.isHost)
                    _badge('Anfitrión', AppColors.blue),
                  if (player.ready)
                    Padding(
                      padding: EdgeInsets.only(left: player.isHost ? 6 : 0),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Settings Card (host) ────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final int impostorCount;
  final int maxImpostors;
  final bool showRoleOnElimination;
  final bool impostorHasClue;
  final bool enabled;
  final void Function(int? impostors, bool? showRole, bool? hasClue) onChanged;

  const _SettingsCard({
    required this.impostorCount,
    required this.maxImpostors,
    required this.showRoleOnElimination,
    required this.impostorHasClue,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 18, color: AppColors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Configuración',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _impostorRow(),
              const SizedBox(height: 14),
              _toggleRow(
                label: 'Mostrar rol al eliminar',
                value: showRoleOnElimination,
                onChanged: (v) => onChanged(null, v, null),
              ),
              const SizedBox(height: 10),
              _toggleRow(
                label: 'Impostor tiene pista',
                value: impostorHasClue,
                onChanged: (v) => onChanged(null, null, v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _impostorRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Impostores',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightInputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _counterBtn(Icons.remove, enabled: impostorCount > 1, onTap: () {
                onChanged(impostorCount - 1, null, null);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$impostorCount',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              _counterBtn(Icons.add, enabled: impostorCount < maxImpostors, onTap: () {
                onChanged(impostorCount + 1, null, null);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _counterBtn(IconData icon, {required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: enabled ? AppColors.darkText : AppColors.lightBorder),
      ),
    );
  }

  Widget _toggleRow({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText)),
        ),
        SizedBox(
          height: 28,
          child: Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.blue),
        ),
      ],
    );
  }
}

// ── Guest Settings Card (read-only) ─────────────────────────────────────────

class _GuestSettingsCard extends StatelessWidget {
  final int impostorCount;
  final bool showRoleOnElimination;
  final bool impostorHasClue;

  const _GuestSettingsCard({
    required this.impostorCount,
    required this.showRoleOnElimination,
    required this.impostorHasClue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 18, color: AppColors.subtitleText),
              const SizedBox(width: 8),
              Text(
                'Configuración',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              Text(
                'Solo el anfitrión puede editar',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.subtitleText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow('Impostores', '$impostorCount'),
          const SizedBox(height: 8),
          _infoRow('Mostrar rol al eliminar', showRoleOnElimination ? 'Sí' : 'No'),
          const SizedBox(height: 8),
          _infoRow('Impostor tiene pista', impostorHasClue ? 'Sí' : 'No'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 14, color: AppColors.darkText)),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.blue),
        ),
      ],
    );
  }
}

// ── Ready Button ────────────────────────────────────────────────────────────

class _ReadyButton extends StatelessWidget {
  final bool isReady;
  final VoidCallback onTap;
  const _ReadyButton({required this.isReady, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          isReady ? Icons.close_rounded : Icons.check_rounded,
          size: 20,
        ),
        label: Text(
          isReady ? 'Cancelar Listo' : 'Estoy Listo',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isReady ? AppColors.subtitleText : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Countdown Banner ────────────────────────────────────────────────────────

class _CountdownBanner extends StatelessWidget {
  final int seconds;
  const _CountdownBanner({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            seconds > 0 ? 'La partida inicia en' : 'Iniciando...',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.blue,
            ),
          ),
          if (seconds > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$seconds',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.blue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

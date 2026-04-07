import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<String> _playerNames = [];
  int _impostorCount = 1;
  bool _showRoleOnElimination = false;
  bool _impostorHasClue = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    GameProvider.loadLastSession().then((session) {
      if (session == null || !mounted) return;
      setState(() {
        _playerNames
          ..clear()
          ..addAll(session.names);
        _impostorCount = session.impostors;
        _showRoleOnElimination = session.showRole;
        _impostorHasClue = session.impostorHasClue;
      });
    });
  }

  int get _maxImpostors {
    final count = _playerNames.length;
    return ((count - 1) / 2).floor().clamp(1, 10);
  }

  void _openPlayersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlayersModal(
        names: List.from(_playerNames),
        onSave: (names) {
          setState(() {
            _playerNames
              ..clear()
              ..addAll(names);
            if (_impostorCount > _maxImpostors) {
              _impostorCount = _maxImpostors;
            }
          });
        },
      ),
    );
  }

  void _handleStart() {
    if (_playerNames.length < 3) {
      setState(() => _error = 'Se necesitan al menos 3 jugadores');
      return;
    }
    if (_playerNames.toSet().length != _playerNames.length) {
      setState(() => _error = 'Los nombres deben ser únicos');
      return;
    }
    final civils = _playerNames.length - _impostorCount;
    if (_impostorCount >= civils) {
      setState(() => _error = 'Los impostores deben ser menos que los civiles');
      return;
    }

    setState(() => _error = '');
    context.read<GameProvider>().startGame(
          _playerNames,
          _impostorCount,
          showRoleOnElimination: _showRoleOnElimination,
          impostorHasClue: _impostorHasClue,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lightBg1,
            AppColors.lightBg2,
            AppColors.lightBg3,
          ],
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
                  context.read<GameProvider>().backToModeSelection();
                }),
                Expanded(
                  child: Text(
                    'Game Setup',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                _appBarButton(Icons.settings, onTap: () {}),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildPlayersCard(),
                  const SizedBox(height: 16),
                  _buildGameRulesCard(),
                  const SizedBox(height: 24),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  _buildStartButton(),
                  const SizedBox(height: 12),
                  Text(
                    _playerNames.length < 3
                        ? 'MÍNIMO 3 JUGADORES REQUERIDOS'
                        : '${_playerNames.length} JUGADORES LISTOS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBarButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.darkText, size: 20),
      ),
    );
  }

  // ── Players Card ──────────────────────────────────────────────────────

  Widget _buildPlayersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Jugadores',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Input area → opens modal
          GestureDetector(
            onTap: _openPlayersModal,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.lightInputBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Gestionar jugadores...',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.person_add_outlined,
                            color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Player avatars (horizontal scroll)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _playerNames.length + 1,
              itemBuilder: (ctx, i) {
                if (i < _playerNames.length) {
                  return _buildPlayerAvatar(i);
                }
                return _buildEmptySlot();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar(int index) {
    final name = _playerNames[index];
    final color = AppColors.avatarColors[index % AppColors.avatarColors.length];

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
            ),
            child: Icon(Icons.person, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 58,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Icon(Icons.add, color: Colors.grey.shade300, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'Vacío',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Game Rules Card ───────────────────────────────────────────────────

  Widget _buildGameRulesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.blue, size: 22),
              const SizedBox(width: 8),
              Text(
                'Configuración',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Impostor count header
          Row(
            children: [
              Text(
                'Cantidad de Impostores',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_impostorCount',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Slider
          if (_maxImpostors > 1) ...[
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.blue,
                inactiveTrackColor: Colors.grey.shade200,
                thumbColor: AppColors.blue,
                overlayColor: AppColors.blue.withValues(alpha:0.1),
                trackHeight: 6,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: _impostorCount.toDouble(),
                min: 1,
                max: _maxImpostors.toDouble(),
                divisions: _maxImpostors - 1,
                onChanged: (val) =>
                    setState(() => _impostorCount = val.round()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_maxImpostors, (i) {
                  return Text(
                    '${i + 1}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Agrega más jugadores para poder ajustar',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 16),

          // Toggle: Show role on elimination
          _buildToggleRow(
            icon: Icons.visibility_outlined,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF4CAF50),
            title: 'Mostrar rol al eliminar',
            subtitle: _showRoleOnElimination
                ? 'Se mostrará el rol del eliminado'
                : 'El rol del eliminado permanece oculto',
            value: _showRoleOnElimination,
            onChanged: (val) => setState(() => _showRoleOnElimination = val),
          ),

          const SizedBox(height: 16),

          // Toggle: Impostor clue
          _buildToggleRow(
            icon: Icons.lightbulb_outline,
            iconBgColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFFF9800),
            title: 'Pista para el impostor',
            subtitle: _impostorHasClue
                ? 'El impostor recibe una pista relacionada'
                : 'El impostor no recibe ninguna pista',
            value: _impostorHasClue,
            onChanged: (val) => setState(() => _impostorHasClue = val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        _AnimatedSwitch(value: value, onChanged: onChanged),
      ],
    );
  }

  // ── Start Button ──────────────────────────────────────────────────────

  Widget _buildStartButton() {
    final canStart = _playerNames.length >= 3;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canStart ? _handleStart : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          disabledBackgroundColor: AppColors.blue.withValues(alpha:0.4),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha:0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canStart ? 4 : 0,
          shadowColor: AppColors.blue.withValues(alpha:0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'INICIAR PARTIDA',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: canStart ? Colors.white : Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Players Modal (Bottom Sheet)
// ═══════════════════════════════════════════════════════════════════════════

class _PlayersModal extends StatefulWidget {
  final List<String> names;
  final ValueChanged<List<String>> onSave;

  const _PlayersModal({
    required this.names,
    required this.onSave,
  });

  @override
  State<_PlayersModal> createState() => _PlayersModalState();
}

class _PlayersModalState extends State<_PlayersModal> {
  late final List<_PlayerEntry> _entries;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _entries = widget.names.map((n) => _PlayerEntry(_nextId++, n)).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    if (_entries.any((e) => e.name == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Este nombre ya existe'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() {
      _entries.add(_PlayerEntry(_nextId++, name));
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  void _removePlayer(int index) {
    setState(() => _entries.removeAt(index));
  }

  void _save() {
    widget.onSave(_entries.map((e) => e.name).toList());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  'Jugadores',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    'Listo',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Add player input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.darkText,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nombre del jugador...',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: AppColors.lightInputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addPlayer,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Player count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${_entries.length} jugadores',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                if (_entries.isNotEmpty)
                  Text(
                    'Mantén ≡ para reordenar',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Player list
          Flexible(
            child: _entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Agrega jugadores para empezar',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    buildDefaultDragHandles: false,
                    itemCount: _entries.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final entry = _entries.removeAt(oldIndex);
                        _entries.insert(newIndex, entry);
                      });
                    },
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 8,
                        color: Colors.transparent,
                        shadowColor: AppColors.blue.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      );
                    },
                    itemBuilder: (ctx, i) {
                      final entry = _entries[i];
                      final color = AppColors
                          .avatarColors[i % AppColors.avatarColors.length];

                      return Container(
                        key: ValueKey(entry.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha:0.25),
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Icon(Icons.person,
                                  color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            // Name
                            Expanded(
                              child: Text(
                                entry.name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ),
                            // Delete
                            GestureDetector(
                              onTap: () => _removePlayer(i),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close,
                                    size: 18, color: Colors.grey.shade400),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Drag handle
                            ReorderableDragStartListener(
                              index: i,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.drag_handle,
                                    size: 20, color: Colors.grey.shade400),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// Simple data class for stable keys in ReorderableListView
class _PlayerEntry {
  final int id;
  final String name;
  _PlayerEntry(this.id, this.name);
}

// ═══════════════════════════════════════════════════════════════════════════
// Custom Animated Switch
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AnimatedSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? AppColors.teal : const Color(0xFFD5D5DC),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x29000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

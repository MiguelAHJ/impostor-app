import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _impostors = 1;
  bool _showRoleOnElimination = false;
  bool _impostorHasClue = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    GameProvider.loadLastSession().then((session) {
      if (session == null || !mounted) return;
      setState(() {
        for (final c in _controllers) {
          c.dispose();
        }
        _controllers
          ..clear()
          ..addAll(session.names.map((n) => TextEditingController(text: n)));
        _impostors = session.impostors;
        _showRoleOnElimination = session.showRole;
        _impostorHasClue = session.impostorHasClue;
      });
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removePlayer(int index) {
    if (_controllers.length <= 2) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  int get _maxImpostors {
    final validCount =
        _controllers.where((c) => c.text.trim().isNotEmpty).length;
    return ((validCount - 1) / 2).floor().clamp(1, 10);
  }

  void _handleStart() {
    final names = _controllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (names.length < 3) {
      setState(() => _error = 'Se necesitan al menos 3 jugadores');
      return;
    }
    if (names.toSet().length != names.length) {
      setState(() => _error = 'Los nombres deben ser únicos');
      return;
    }
    final civils = names.length - _impostors;
    if (_impostors >= civils) {
      setState(() => _error = 'Los impostores deben ser menos que los civiles');
      return;
    }

    setState(() => _error = '');
    context.read<GameProvider>().startGame(
          names,
          _impostors,
          showRoleOnElimination: _showRoleOnElimination,
          impostorHasClue: _impostorHasClue,
        );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          // Title
          Text(
            'IMPOSTOR',
            style: AppTheme.displayStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Quién es el impostor entre nosotros?',
            style: AppTheme.bodyStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 32),

          // Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1F30), Color(0xFF18192A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Players header
                Row(
                  children: [
                    const Icon(Icons.people,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Jugadores',
                      style: AppTheme.displayStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Player inputs
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final controller = _controllers.removeAt(oldIndex);
                      _controllers.insert(newIndex, controller);
                    });
                  },
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Material(
                          elevation: 10 * animation.value,
                          color: Colors.transparent,
                          shadowColor: AppColors.primary.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                  children: List.generate(_controllers.length, (i) {
                    return _PlayerShakeRow(
                      key: ValueKey(_controllers[i]),
                      index: i,
                      controller: _controllers[i],
                      canRemove: _controllers.length > 2,
                      onRemove: () => _removePlayer(i),
                      onChanged: () => setState(() {}),
                    );
                  }),
                ),

                // Add player button
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _addPlayer,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add,
                            size: 16, color: AppColors.mutedForeground),
                        const SizedBox(width: 8),
                        Text(
                          'Añadir jugador',
                          style: AppTheme.bodyStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Impostors
                Row(
                  children: [
                    const Icon(Icons.dangerous,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Impostores',
                      style: AppTheme.displayStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(_maxImpostors, (i) {
                    final n = i + 1;
                    final isSelected = _impostors == n;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _impostors = n),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.secondary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color:
                                            AppColors.accent.withOpacity(0.3),
                                        blurRadius: 20)
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$n',
                            style: AppTheme.displayStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.accentForeground
                                  : AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // Show role on elimination toggle
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.visibility,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mostrar rol al eliminar',
                        style: AppTheme.displayStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _showRoleOnElimination,
                      onChanged: (val) =>
                          setState(() => _showRoleOnElimination = val),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                Text(
                  _showRoleOnElimination
                      ? 'Al eliminar un jugador se mostrará su rol'
                      : 'El rol del eliminado permanece oculto',
                  style: AppTheme.bodyStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),

                // Impostor clue toggle
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pista para el impostor',
                        style: AppTheme.displayStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _impostorHasClue,
                      onChanged: (val) =>
                          setState(() => _impostorHasClue = val),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                Text(
                  _impostorHasClue
                      ? 'El impostor recibe una pista relacionada'
                      : 'El impostor no recibe ninguna pista',
                  style: AppTheme.bodyStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),

                // Error
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error,
                    style: AppTheme.bodyStyle(
                        fontSize: 13, color: AppColors.accent),
                  ),
                ],

                const SizedBox(height: 20),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleStart,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Iniciar Partida'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ).copyWith(
                      shadowColor: WidgetStateProperty.all(
                          AppColors.primary.withOpacity(0.3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerShakeRow extends StatefulWidget {
  final int index;
  final TextEditingController controller;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _PlayerShakeRow({
    required super.key,
    required this.index,
    required this.controller,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_PlayerShakeRow> createState() => _PlayerShakeRowState();
}

class _PlayerShakeRowState extends State<_PlayerShakeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;
  final FocusNode _focusNode = FocusNode();
  Timer? _holdTimer;
  bool _isHeld = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeController);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    _holdTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _isHeld = true);
      _shakeController.forward(from: 0).then((_) {
        if (mounted) setState(() => _isHeld = false);
      });
    });
  }

  void _onPointerUp(PointerUpEvent _) {
    _holdTimer?.cancel();
    if (mounted && _isHeld) setState(() => _isHeld = false);
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _holdTimer?.cancel();
    if (mounted && _isHeld) setState(() => _isHeld = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _isHeld
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: _isHeld
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                )
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // TextField no recibe toques directamente
                  TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    style: AppTheme.bodyStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Jugador ${widget.index + 1}',
                    ),
                    onChanged: (_) => widget.onChanged(),
                  ),
                  // Capa invisible encima que intercepta todos los toques
                  Positioned.fill(
                    child: Listener(
                      onPointerDown: _onPointerDown,
                      onPointerUp: _onPointerUp,
                      onPointerCancel: _onPointerCancel,
                      behavior: HitTestBehavior.opaque,
                      child: ReorderableDelayedDragStartListener(
                        index: widget.index,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // Toque rápido → enfoca el TextField manualmente
                          onTap: () => _focusNode.requestFocus(),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.canRemove) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      builder: (context, child) {
        final shake = math.sin(_shakeAnim.value * math.pi * 7) * 2.5;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class OnlineNameScreen extends StatefulWidget {
  const OnlineNameScreen({super.key});

  @override
  State<OnlineNameScreen> createState() => _OnlineNameScreenState();
}

class _OnlineNameScreenState extends State<OnlineNameScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _showJoinField = false;
  String _error = '';

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _trimmedName => _nameController.text.trim();
  String get _trimmedCode => _codeController.text.trim().toUpperCase();

  void _handleCreate() {
    if (_trimmedName.isEmpty) {
      setState(() => _error = 'Ingresa tu nombre');
      return;
    }
    setState(() => _error = '');
    context.read<GameProvider>().createRoom(_trimmedName);
  }

  void _handleJoin() {
    if (_trimmedName.isEmpty) {
      setState(() => _error = 'Ingresa tu nombre');
      return;
    }
    if (_trimmedCode.length < 5) {
      setState(() => _error = 'El código debe tener 5 caracteres');
      return;
    }
    setState(() => _error = '');
    context.read<GameProvider>().clearRoomError();
    context.read<GameProvider>().joinRoom(_trimmedName, _trimmedCode);
  }


  @override
  Widget build(BuildContext context) {
    // React to room errors from the server
    final roomError = context.select<GameProvider, String?>((g) => g.roomError);
    if (roomError != null && _error.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _error = roomError);
        context.read<GameProvider>().clearRoomError();
      });
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
                    'Partida Online',
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
                  const SizedBox(height: 24),

                  // Name field
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Tu nombre'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _nameController,
                          hint: 'Ej: Miguel',
                          icon: Icons.person_rounded,
                          maxLength: 12,
                          onChanged: (_) => setState(() => _error = ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create room button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _handleCreate,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        'Crear Sala',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.lightBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'o',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: AppColors.subtitleText,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.lightBorder)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Join room
                  if (!_showJoinField)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _showJoinField = true),
                        icon: const Icon(Icons.login_rounded, size: 20),
                        label: Text(
                          'Unirse a una Sala',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkText,
                          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Código de sala'),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _codeController,
                            hint: 'Ej: ABC12',
                            icon: Icons.tag_rounded,
                            maxLength: 5,
                            capitalize: true,
                            onChanged: (_) => setState(() => _error = ''),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _handleJoin,
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: Text(
                                'Unirse',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

  Widget _buildCard({required Widget child}) {
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
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLength,
    bool capitalize = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      textCapitalization: capitalize ? TextCapitalization.characters : TextCapitalization.words,
      onChanged: onChanged,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          color: AppColors.subtitleText,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppColors.subtitleText),
        counterText: '',
        filled: true,
        fillColor: AppColors.lightInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.darkText, size: 20),
      ),
    );
  }
}

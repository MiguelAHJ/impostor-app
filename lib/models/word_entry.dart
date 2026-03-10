enum Difficulty { facil, medio, dificil }

class WordEntry {
  final int id;
  final Difficulty dificultad;
  final String palabraReal;
  final List<String> pistaImpostor;

  const WordEntry({
    required this.id,
    required this.dificultad,
    required this.palabraReal,
    required this.pistaImpostor,
  });

  /// Construye un WordEntry a partir de la respuesta JSON del backend.
  factory WordEntry.fromJson(Map<String, dynamic> json) {
    final difficultyMap = {
      'facil': Difficulty.facil,
      'medio': Difficulty.medio,
      'dificil': Difficulty.dificil,
    };

    return WordEntry(
      id: int.tryParse(json['id'].toString()) ?? 0,
      dificultad: difficultyMap[json['difficulty']] ?? Difficulty.facil,
      palabraReal: json['text'] as String,
      pistaImpostor: List<String>.from(json['impostorHints'] as List),
    );
  }
}

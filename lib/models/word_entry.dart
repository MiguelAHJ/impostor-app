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
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word_entry.dart';

const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://secret-word-social-backend.vercel.app/api/v1',
);

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  /// Obtiene una palabra aleatoria del backend.
  /// Lanza una excepción si el servidor no responde o devuelve error.
  Future<WordEntry> fetchRandomWord(
      {String? category, String? difficulty}) async {
    final uri = Uri.parse('$_baseUrl/words/random').replace(
      queryParameters: {
        if (category != null) 'category': category,
        if (difficulty != null) 'difficulty': difficulty,
      },
    );

    final response = await _client.get(uri).timeout(
          const Duration(seconds: 30),
          onTimeout: () =>
              throw Exception('El servidor tardó demasiado en responder.'),
        );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return WordEntry.fromJson(json);
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  }
}

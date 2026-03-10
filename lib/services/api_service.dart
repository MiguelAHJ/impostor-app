import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word_entry.dart';

/// IP de tu PC en la red local WiFi.
/// Cámbialo si cambias de red (corre `ipconfig` y busca el adaptador WiFi).
/// Si usas emulador Android en vez de teléfono real, usa: 10.0.2.2
const String _baseUrl = 'http://192.168.1.101:3000/api/v1';

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

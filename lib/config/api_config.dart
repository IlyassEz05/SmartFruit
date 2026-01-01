import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration de l'API d'IA
///
/// ⚠️ SÉCURITÉ IMPORTANTE ⚠️
/// - Ne hardcodez JAMAIS une clé API dans le code
/// - Mettez la clé dans un fichier `.env` (non commité) via flutter_dotenv
/// - Pour production: utilisez un backend (ex: Firebase Functions) comme proxy

class ApiConfig {
  // Choisir le service à utiliser (Gemini activé)
  static const bool useGemini = true; // true pour Gemini, false pour OpenAI

  // OpenAI
  static String get openAiApiKey => (dotenv.env['OPENAI_API_KEY'] ?? '').trim();
  static String get openAiModel => (dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini').trim();

  // Gemini (utilisé actuellement)
  static String get geminiApiKey => (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
  static String get geminiModel => 'gemini-2.5-flash-lite'; // Modèle Gemini à utiliser

  static String get activeApiKey => useGemini ? geminiApiKey : openAiApiKey;
  static String get activeModel => useGemini ? geminiModel : openAiModel;

  static bool get isApiKeyConfigured {
    if (useGemini) {
      final key = geminiApiKey;
      return key.isNotEmpty && key.length > 10;
    }
    final key = openAiApiKey;
    return key.isNotEmpty &&
        key.length > 20 &&
        (key.startsWith('sk-') || key.startsWith('sk-proj-'));
  }
}

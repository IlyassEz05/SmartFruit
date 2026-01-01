import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:smart_fruit/config/api_config.dart';

/// Service pour interagir avec l'API OpenAI
/// 
/// IMPORTANT SÉCURITÉ:
/// - La clé API doit venir de `.env` via flutter_dotenv (voir `ApiConfig`)
/// - Pour la production: proxy via Firebase Functions (recommandé)
/// - Ne JAMAIS hardcoder ou commiter une clé API
class AIService {
  // OpenAI modern endpoint (chat completions)
  static const String _openAiChatUrl = 'https://api.openai.com/v1/chat/completions';
  
  String _apiKey = '';
  String _model = 'gpt-4o-mini';
  bool _useGemini = false;
  
  // Verrou pour empêcher les doubles envois
  bool _requestInFlight = false;
  
  AIService() {
    // Utiliser la configuration depuis api_config.dart
    _apiKey = ApiConfig.activeApiKey.trim();
    _useGemini = ApiConfig.useGemini;
    if (!_useGemini) {
      _model = ApiConfig.openAiModel;
    }
    
    debugPrint('🔧 AIService initialisé');
    debugPrint('   - Modèle: $_model');
    debugPrint('   - Clé API configurée: ${ApiConfig.isApiKeyConfigured}');
  }

  /// Envoyer une requête à l'API d'IA
  /// 
  /// Retourne null en cas d'erreur critique
  /// Retourne un Map avec 'text' et 'imageUrl' en cas de succès
  Future<Map<String, dynamic>?> sendMessage(String userMessage) async {
    // CRITIQUE: Empêcher les doubles envois
    if (_requestInFlight) {
      debugPrint('⚠️ AI: Requête déjà en cours, ignorée');
      return {
        'text': 'Une requête est déjà en cours. Veuillez patienter...',
        'imageUrl': null,
      };
    }
    
    // Mettre à jour la clé API depuis la config
    _apiKey = ApiConfig.activeApiKey.trim();
    _useGemini = ApiConfig.useGemini;
    _model = ApiConfig.activeModel;
    
    // Vérifier que la clé est valide
    if (_useGemini) {
      if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY' || _apiKey.length < 10) {
        debugPrint('❌ AI: Clé API Gemini invalide');
        return {
          'text': 'Erreur: Clé API Gemini non configurée.\n\nConfigurez votre clé dans lib/config/api_config.dart',
          'imageUrl': null,
        };
      }
    } else {
      final key = _apiKey.trim();
      if (key.isEmpty || key.length < 20 || (!key.startsWith('sk-') && !key.startsWith('sk-proj-'))) {
        debugPrint('❌ AI: Clé API OpenAI invalide (longueur: ${key.length})');
        return {
          'text': 'Erreur: Clé API OpenAI non configurée ou invalide.\n\nVérifiez lib/config/api_config.dart',
          'imageUrl': null,
        };
      }
    }

    _requestInFlight = true;
    try {
      if (_useGemini) {
        return await _sendToGemini(userMessage);
      }
      return await _sendToOpenAI(userMessage);
    } catch (e) {
      debugPrint('❌ AI: Exception lors de l\'appel API: $e');
      return {
        'text': 'Erreur: impossible de contacter l’assistant. Vérifiez votre connexion Internet, puis réessayez.',
        'imageUrl': null,
      };
    } finally {
      _requestInFlight = false;
    }
  }

  /// OpenAI Chat Completions API (modern endpoint)
  Future<Map<String, dynamic>> _sendToOpenAI(String userMessage, {int retryCount = 0}) async {
    final model = _model.isNotEmpty ? _model : 'gpt-4o-mini';
    debugPrint('🚀 AI: OpenAI chat/completions (model: $model)');

    // Quick DNS/network preflight (common issue on emulators)
    try {
      await InternetAddress.lookup('api.openai.com')
          .timeout(const Duration(seconds: 4));
    } on SocketException catch (e) {
      debugPrint('❌ AI: DNS/network error (lookup api.openai.com): $e');
      return {
        'text':
            'Erreur réseau: impossible de joindre OpenAI (DNS/Internet).\n\nSur émulateur Android: ouvrez Chrome pour vérifier Internet, puis faites un “Cold Boot” de l’AVD si besoin.',
        'imageUrl': null,
      };
    } on TimeoutException catch (e) {
      debugPrint('❌ AI: DNS lookup timeout: $e');
      return {
        'text':
            'Erreur réseau: DNS trop lent/inaccessible (api.openai.com).\n\nVérifiez la connexion Internet de l\'émulateur.',
        'imageUrl': null,
      };
    } catch (e) {
      debugPrint('❌ AI: DNS preflight unexpected error: $e');
    }

    try {
      final response = await http
          .post(
            Uri.parse(_openAiChatUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Tu es un assistant vocal intelligent pour une application de classification de fruits. Réponds en français, de manière concise et utile.',
                },
                {
                  'role': 'user',
                  'content': userMessage,
                }
              ],
              'max_tokens': 500,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String;
        return {'text': text.trim(), 'imageUrl': null};
      }

      if (response.statusCode == 401) {
        return {
          'text':
              'Erreur 401: clé API invalide. Vérifiez OPENAI_API_KEY dans votre fichier .env.',
          'imageUrl': null,
        };
      }

      if (response.statusCode == 429) {
        if (retryCount < 2) {
          final delay = Duration(milliseconds: 800 * (1 << retryCount));
          debugPrint('⚠️ AI: 429 (retry $retryCount/2) backoff ${delay.inMilliseconds}ms');
          await Future.delayed(delay);
          return _sendToOpenAI(userMessage, retryCount: retryCount + 1);
        }
        return {
          'text':
              'Erreur 429: trop de requêtes / quota atteint. Attendez 30–60s puis réessayez, ou vérifiez votre quota sur https://platform.openai.com/usage',
          'imageUrl': null,
        };
      }

      if (response.statusCode == 400) {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMsg = errorBody['error']?['message'] ?? 'Requête invalide';
          return {
            'text': 'Erreur 400: $errorMsg. Vérifiez votre clé API OpenAI.',
            'imageUrl': null,
          };
        } catch (e) {
          return {
            'text': 'Erreur 400: Requête invalide. Vérifiez votre clé API OpenAI dans .env',
            'imageUrl': null,
          };
        }
      }

      final body =
          response.body.length > 300 ? '${response.body.substring(0, 300)}…' : response.body;
      return {
        'text': 'Erreur ${response.statusCode}: $body',
        'imageUrl': null,
      };
    } on TimeoutException {
      return {
        'text':
            'Timeout: l\'API ne répond pas. Vérifiez la connexion internet de l\'appareil et réessayez.',
        'imageUrl': null,
      };
    } on http.ClientException catch (e) {
      // Often wraps SocketException like "Failed host lookup"
      debugPrint('❌ AI: ClientException: $e');
      return {
        'text':
            'Erreur réseau: impossible de contacter OpenAI. Vérifiez Internet (et DNS) sur l’appareil/émulateur puis réessayez.',
        'imageUrl': null,
      };
    } on SocketException catch (e) {
      debugPrint('❌ AI: SocketException: $e');
      return {
        'text':
            'Erreur réseau: impossible de contacter OpenAI. Test rapide: ouvrez Chrome dans l’émulateur.\n\nSi Chrome ne charge rien: faites “Cold Boot” puis “Wipe Data” de l’AVD.',
        'imageUrl': null,
      };
    } catch (e) {
      debugPrint('❌ AI: Exception lors de l\'appel OpenAI: $e');
      return {
        'text': 'Erreur réseau: impossible de contacter OpenAI. Vérifiez votre connexion puis réessayez.',
        'imageUrl': null,
      };
    }
  }

  /// Envoyer une requête à Google Gemini (gemini-2.5-flash-lite)
  Future<Map<String, dynamic>> _sendToGemini(String userMessage) async {
    final model = ApiConfig.geminiModel;
    debugPrint('🚀 AI: Envoi requête à Gemini ($model)');
    
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Tu es un assistant vocal intelligent pour une application de classification de fruits. Réponds de manière concise et amicale en français.\n\n$userMessage',
                },
              ],
            },
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        debugPrint('✅ AI: Réponse Gemini reçue');
        return {
          'text': text.trim(),
          'imageUrl': null,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('❌ AI Gemini: Erreur ${response.statusCode} - Clé API invalide');
        return {
          'text': 'Erreur d\'authentification (${response.statusCode}). Vérifiez votre clé API Gemini dans le fichier .env.',
          'imageUrl': null,
        };
      } else if (response.statusCode == 429) {
        debugPrint('❌ AI Gemini: Erreur 429 - Rate limit exceeded');
        return {
          'text': 'Trop de requêtes (429). Attendez quelques instants puis réessayez.',
          'imageUrl': null,
        };
      } else {
        debugPrint('❌ AI Gemini: Erreur ${response.statusCode}');
        final errorBody = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        return {
          'text': 'Erreur ${response.statusCode}: $errorBody',
          'imageUrl': null,
        };
      }
    } on TimeoutException {
      return {
        'text': 'Délai d\'attente dépassé. Vérifiez votre connexion internet.',
        'imageUrl': null,
      };
    } on SocketException catch (e) {
      debugPrint('❌ AI Gemini: Erreur réseau: $e');
      return {
        'text': 'Erreur réseau: impossible de contacter l\'API Gemini. Vérifiez votre connexion internet.',
        'imageUrl': null,
      };
    } catch (e) {
      debugPrint('❌ AI Gemini: Exception: $e');
      return {
        'text': 'Erreur lors de l\'appel à Gemini. Vérifiez votre clé API et votre connexion internet.',
        'imageUrl': null,
      };
    }
  }
  
  /// Vérifier si une requête est en cours
  bool get isRequestInFlight => _requestInFlight;
}

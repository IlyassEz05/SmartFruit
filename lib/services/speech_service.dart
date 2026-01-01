import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';

/// Service pour la reconnaissance vocale (Speech-to-Text)
/// 
/// IMPORTANT: Ne traite QUE les résultats finaux (finalResult == true)
/// Les résultats partiels sont ignorés pour éviter les envois multiples à l'API
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  Function(String)? _onErrorCallback;
  
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  /// Initialiser le service de reconnaissance vocale
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🔊 STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (error) {
          final errorMsg = error.errorMsg ?? 'Erreur inconnue';
          debugPrint('❌ STT Erreur: $errorMsg (permanent: ${error.permanent})');
          
          // Si l'erreur est permanente (comme timeout sur émulateur), arrêter l'écoute
          if (error.permanent) {
            _isListening = false;
            // Notifier l'erreur via le callback si fourni
            if (_onErrorCallback != null) {
              if (errorMsg.contains('timeout')) {
                _onErrorCallback!('Timeout: Les émulateurs Android n\'ont pas de microphone réel.');
              } else {
                _onErrorCallback!(errorMsg);
              }
            }
          }
        },
      );
      
      if (_isAvailable) {
        debugPrint('✅ STT Service initialisé avec succès');
      } else {
        debugPrint('⚠️ STT Service non disponible sur cet appareil');
      }
      
      return _isAvailable;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de STT: $e');
      return false;
    }
  }

  /// Démarrer l'écoute
  /// 
  /// IMPORTANT: Le callback onResult n'est appelé QUE pour les résultats finaux (finalResult == true)
  /// Les résultats partiels sont ignorés pour éviter les doubles envois à l'API
  Future<String?> startListening({
    required Function(String) onResult,
    String localeId = 'fr_FR',
    Function(String)? onError,
  }) async {
    _onErrorCallback = onError;
    
    if (!_isAvailable) {
      debugPrint('❌ STT: Service non disponible');
      if (onError != null) {
        onError('Reconnaissance vocale non disponible sur cet appareil.');
      }
      return null;
    }
    
    if (_isListening) {
      debugPrint('⚠️ STT: Écoute déjà en cours');
      return null;
    }
    
    try {
      debugPrint('🎤 STT: Démarrage de l\'écoute (locale: $localeId)');
      
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords.trim();
          final isFinal = result.finalResult;
          
          debugPrint('📢 STT Résultat: "$text" (final: $isFinal)');
          
          // CRITIQUE: Ne traiter QUE les résultats finaux
          // Ignorer complètement les résultats partiels pour éviter les doubles envois
          if (isFinal && text.isNotEmpty) {
            debugPrint('✅ STT: Résultat final reçu, arrêt de l\'écoute');
            _isListening = false;
            onResult(text);
          } else if (isFinal && text.isEmpty) {
            debugPrint('⚠️ STT: Résultat final vide, arrêt de l\'écoute');
            _isListening = false;
          } else {
            // Résultat partiel - IGNORER (ne pas appeler onResult)
            debugPrint('⏳ STT: Résultat partiel ignoré (en attente du résultat final)');
          }
        },
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false, // Ne pas annuler sur erreur mineure
        partialResults: false, // DÉSACTIVER les résultats partiels pour éviter les doubles envois
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      
      _isListening = true;
      debugPrint('✅ STT: Écoute démarrée');
      return null;
    } catch (e) {
      debugPrint('❌ STT: Erreur lors de l\'écoute: $e');
      _isListening = false;
      if (onError != null) {
        onError('Erreur lors du démarrage de l\'écoute: $e');
      }
      return null;
    }
  }

  /// Arrêter l'écoute
  Future<void> stopListening() async {
    if (_isListening) {
      debugPrint('🛑 STT: Arrêt de l\'écoute');
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Annuler l'écoute
  Future<void> cancelListening() async {
    if (_isListening) {
      debugPrint('❌ STT: Annulation de l\'écoute');
      await _speech.cancel();
      _isListening = false;
    }
  }

  /// Obtenir les locales disponibles
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isAvailable) {
      return [];
    }
    return await _speech.locales();
  }
}

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';

/// Service pour la synthèse vocale (Text-to-Speech)
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Initialiser le service TTS
  Future<bool> initialize() async {
    try {
      // Configuration de la langue (français par défaut)
      await _flutterTts.setLanguage("fr-FR");
      
      // Configuration de la vitesse de lecture (0.0 à 1.0)
      await _flutterTts.setSpeechRate(0.5);
      
      // Configuration du volume (0.0 à 1.0)
      await _flutterTts.setVolume(1.0);
      
      // Configuration de la hauteur (0.5 à 2.0)
      await _flutterTts.setPitch(1.0);

      // Callbacks pour suivre l'état
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🔊 TTS: Parole démarrée');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('✅ TTS: Parole terminée');
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('🛑 TTS: Parole annulée');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('❌ TTS: Erreur - $msg');
      });

      _isInitialized = true;
      debugPrint('✅ TTS Service initialisé');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de TTS: $e');
      return false;
    }
  }

  /// Lire un texte à haute voix
  Future<void> speak(String text) async {
    if (text.isEmpty) {
      debugPrint('⚠️ TTS: Texte vide, ignoré');
      return;
    }
    
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ TTS: Impossible d\'initialiser');
        return;
      }
    }

    try {
      // Arrêter toute parole en cours avant de commencer
      if (_isSpeaking) {
        debugPrint('🛑 TTS: Arrêt de la parole en cours');
        await stop();
        // Attendre un peu pour que l'arrêt soit effectif
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      debugPrint('🔊 TTS: Démarrage de la lecture (${text.length} caractères)');
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('❌ TTS: Erreur lors de la lecture: $e');
      _isSpeaking = false;
    }
  }

  /// Arrêter la lecture
  Future<void> stop() async {
    if (_isSpeaking) {
      try {
        debugPrint('🛑 TTS: Arrêt demandé');
        await _flutterTts.stop();
        _isSpeaking = false;
      } catch (e) {
        debugPrint('❌ TTS: Erreur lors de l\'arrêt: $e');
        _isSpeaking = false;
      }
    }
  }

  /// Mettre en pause
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      debugPrint('⏸️ TTS: Pause');
    } catch (e) {
      debugPrint('❌ TTS: Erreur lors de la pause: $e');
    }
  }

  /// Définir la langue
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      debugPrint('🌐 TTS: Langue changée vers $language');
    } catch (e) {
      debugPrint('❌ TTS: Erreur lors du changement de langue: $e');
    }
  }
}

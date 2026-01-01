import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_fruit/services/speech_service.dart';
import 'package:smart_fruit/services/ai_service.dart';
import 'package:smart_fruit/services/tts_service.dart';
import 'package:smart_fruit/config/api_config.dart';

/// Modèle de message pour la conversation
class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Écran de l'assistant vocal avec interface de chat
class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final SpeechService _speechService = SpeechService();
  final AIService _aiService = AIService();
  final TTSService _ttsService = TTSService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  
  // États de l'application
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  
  // Verrou pour empêcher les doubles envois
  bool _requestLock = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    // Message de bienvenue
    _messages.add(Message(
      text: 'Bonjour ! Je suis votre assistant vocal. Comment puis-je vous aider ?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _initializeServices() async {
    try {
      // Initialiser la reconnaissance vocale
      final speechInitialized = await _speechService.initialize();
      
      // Initialiser la synthèse vocale
      await _ttsService.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = speechInitialized;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur d\'initialisation: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Envoyer un message texte
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    
    // Vérifications de sécurité
    if (text.isEmpty) {
      return;
    }
    
    if (_requestLock || _isProcessing || _isListening) {
      debugPrint('⚠️ Envoi bloqué: requête en cours');
      return;
    }
    
    // Activer le verrou
    _requestLock = true;

    // Ajouter le message utilisateur
    setState(() {
      _messages.add(Message(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _textController.clear();
      _isProcessing = true;
    });

    _scrollToBottom();

    // Traiter le message
    await _processUserMessage(text);
    
    // Libérer le verrou
    _requestLock = false;
  }

  /// Démarrer l'écoute vocale
  Future<void> _startListening() async {
    // Vérifications de sécurité
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reconnaissance vocale non disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_requestLock || _isProcessing || _isListening || _isSpeaking) {
      debugPrint('⚠️ Écoute bloquée: requête en cours');
      return;
    }

    setState(() {
      _isListening = true;
    });

    try {
      await _speechService.startListening(
        localeId: 'fr_FR',
        onResult: (text) async {
          // CRITIQUE: Ce callback n'est appelé QUE pour les résultats finaux
          debugPrint('✅ STT Résultat final reçu: "$text"');
          
          if (text.isNotEmpty && !_requestLock) {
            setState(() {
              _isListening = false;
            });
            
            // Activer le verrou pour éviter double envoi
            _requestLock = true;
            
            // Ajouter le message utilisateur
            setState(() {
              _messages.add(Message(
                text: text,
                isUser: true,
                timestamp: DateTime.now(),
              ));
              _isProcessing = true;
            });
            
            _scrollToBottom();
            
            // Envoyer à l'API
            await _processUserMessage(text);
            
            // Libérer le verrou
            _requestLock = false;
          } else {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (errorMsg) {
          debugPrint('❌ STT Erreur: $errorMsg');
          setState(() {
            _isListening = false;
          });
          
          // Afficher un message informatif si c'est un timeout (émulateur)
          if (errorMsg.contains('timeout') || errorMsg.contains('émulateur')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note: Les émulateurs n\'ont pas de microphone. Utilisez le champ de texte.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Erreur lors du démarrage de l\'écoute: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  /// Arrêter l'écoute
  Future<void> _stopListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
    }
  }

  /// Traiter le message utilisateur et obtenir la réponse de l'IA
  Future<void> _processUserMessage(String message) async {
    try {
      debugPrint('🚀 Traitement du message: "${message.substring(0, message.length > 50 ? 50 : message.length)}..."');
      
      final response = await _aiService.sendMessage(message);

      if (mounted) {
        final responseText = response?['text'] ?? 'Désolé, je n\'ai pas pu obtenir de réponse.';
        
        setState(() {
          _messages.add(Message(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isProcessing = false;
        });

        _scrollToBottom();

        // Lire la réponse à haute voix (seulement si pas d'erreur)
        if (responseText.isNotEmpty && 
            !responseText.contains('Erreur') && 
            !responseText.contains('Désolé')) {
          setState(() {
            _isSpeaking = true;
          });
          
          await _ttsService.speak(responseText);
          
          // Attendre que la lecture se termine
          while (_ttsService.isSpeaking) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
          setState(() {
            _isSpeaking = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement: $e');
      if (mounted) {
        setState(() {
          _messages.add(Message(
            // Ne jamais afficher les erreurs techniques (URL, stack trace, etc.) à l'utilisateur
            text: 'Erreur: impossible de contacter l’assistant. Vérifiez votre connexion Internet (ou le DNS de l’émulateur) puis réessayez.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isProcessing = false;
        });
        _scrollToBottom();
      }
    } finally {
      // Safety: never leave the UI stuck in "processing..."
      if (mounted && _isProcessing) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Arrêter la synthèse vocale
  Future<void> _stopSpeaking() async {
    await _ttsService.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _ttsService.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Désactiver toutes les interactions pendant le traitement ou la lecture
    final bool isBusy = _isProcessing || _isSpeaking || _requestLock;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Vocal'),
        centerTitle: true,
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.volume_off),
              onPressed: _stopSpeaking,
              tooltip: 'Arrêter la lecture',
            ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages (chat)
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Commencez une conversation...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // Indicateurs d'état
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('L\'assistant réfléchit...'),
                ],
              ),
            ),
          if (_isSpeaking && !_isProcessing)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Réponse vocale...'),
                ],
              ),
            ),
          if (_isListening && !_isProcessing)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Écoute...'),
                ],
              ),
            ),
          
          // Zone de saisie
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // Bouton microphone (désactivé si occupé)
                    IconButton(
                      onPressed: isBusy
                          ? null
                          : (_isListening ? _stopListening : _startListening),
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : (isBusy ? Colors.grey : null),
                      ),
                      tooltip: _isListening ? 'Arrêter l\'enregistrement' : 'Parler',
                    ),
                    
                    // Champ de texte (désactivé si occupé)
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: isBusy ? 'En attente...' : 'Tapez votre message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isBusy ? Colors.grey[100] : Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !isBusy && !_isListening,
                        onSubmitted: isBusy ? null : (_) => _sendMessage(),
                        onChanged: (value) {
                          setState(() {}); // Mettre à jour l'état pour le bouton d'envoi
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Bouton d'envoi (désactivé si occupé ou texte vide)
                    IconButton(
                      onPressed: (isBusy || _textController.text.trim().isEmpty)
                          ? null
                          : _sendMessage,
                      icon: Icon(
                        Icons.send,
                        color: (isBusy || _textController.text.trim().isEmpty)
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Envoyer',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white70
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

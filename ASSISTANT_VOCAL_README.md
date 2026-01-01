# Assistant Vocal - Guide de Configuration

L'assistant vocal de SmartFruit est maintenant implémenté et fonctionnel ! 🎉

## Fonctionnalités

✅ **Reconnaissance vocale** (Speech-to-Text)
✅ **Appel API d'IA** (OpenAI GPT ou Google Gemini)
✅ **Synthèse vocale** (Text-to-Speech)
✅ **Affichage texte et image**

## Configuration requise

### 1. Configuration de la clé API

Pour que l'assistant vocal fonctionne, vous devez configurer une clé API d'IA.

#### Option A : OpenAI GPT (recommandé)

1. Créez un compte sur [OpenAI Platform](https://platform.openai.com/)
2. Obtenez votre clé API sur [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
3. Ouvrez le fichier `lib/config/api_config.dart`
4. Remplacez `YOUR_OPENAI_API_KEY` par votre clé API :

```dart
static const String openAiApiKey = 'sk-...votre-clé-api-ici...';
```

#### Option B : Google Gemini

1. Créez un compte Google
2. Obtenez votre clé API sur [https://makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)
3. Ouvrez le fichier `lib/config/api_config.dart`
4. Remplacez `YOUR_GEMINI_API_KEY` par votre clé API
5. Décommentez `useGemini = true` :

```dart
static const String geminiApiKey = 'votre-clé-api-gemini-ici';
static const bool useGemini = true; // Passer à true pour utiliser Gemini
```

### 2. Installation des dépendances

Les dépendances suivantes ont été ajoutées au `pubspec.yaml` :

- `speech_to_text: ^6.6.0` - Reconnaissance vocale
- `flutter_tts: ^4.1.0` - Synthèse vocale
- `http: ^1.2.0` - Appels API

Pour installer, exécutez :
```bash
flutter pub get
```

### 3. Permissions Android

Les permissions suivantes ont été ajoutées dans `AndroidManifest.xml` :

- `RECORD_AUDIO` - Pour la reconnaissance vocale
- `INTERNET` - Pour les appels API

Ces permissions sont déjà configurées automatiquement.

## Utilisation

1. **Lancez l'application**
2. **Connectez-vous** avec votre compte Firebase
3. **Accédez à l'onglet "Assistant"** dans le menu principal
4. **Appuyez sur le bouton "Parler"**
5. **Parlez votre question** (en français)
6. **L'assistant répondra** :
   - En texte affiché
   - En voix (synthèse vocale)

## Structure du code

```
lib/
├── config/
│   └── api_config.dart          # Configuration des clés API
├── services/
│   ├── speech_service.dart      # Reconnaissance vocale
│   ├── ai_service.dart          # Appels API GPT/Gemini
│   └── tts_service.dart         # Synthèse vocale
└── screens/
    └── main/
        └── voice_assistant_screen.dart  # Écran de l'assistant vocal
```

## Notes importantes

⚠️ **Sécurité** : Ne commitez jamais votre clé API dans un dépôt public Git !
- Ajoutez `lib/config/api_config.dart` dans `.gitignore` si vous utilisez Git
- Ou utilisez des variables d'environnement pour la production

📱 **Permissions** : Lors du premier lancement, l'application demandera la permission d'accéder au microphone. Acceptez-la pour utiliser la reconnaissance vocale.

🌍 **Langue** : L'assistant est configuré pour le français (`fr_FR`). Vous pouvez modifier cela dans `voice_assistant_screen.dart` si nécessaire.

## Dépannage

### L'assistant ne répond pas

1. Vérifiez que votre clé API est correctement configurée dans `api_config.dart`
2. Vérifiez votre connexion internet
3. Vérifiez les logs dans la console pour voir les erreurs éventuelles

### La reconnaissance vocale ne fonctionne pas

1. Vérifiez que vous avez accordé la permission au microphone
2. Vérifiez que votre appareil/émulateur supporte la reconnaissance vocale
3. Essayez de redémarrer l'application

### Erreur "Clé API non configurée"

Cela signifie que vous devez configurer votre clé API dans `lib/config/api_config.dart`. Suivez les instructions ci-dessus.

## Support

Si vous rencontrez des problèmes, vérifiez :
- Les logs de l'application (Console Flutter)
- Que toutes les dépendances sont installées (`flutter pub get`)
- Que les permissions sont correctement configurées dans `AndroidManifest.xml`


# Dossier Models

## Emplacement du modèle TFLite

Placez votre modèle CNN au format TensorFlow Lite (.tflite) dans ce dossier.

### Exemple de structure :
```
assets/models/
  └── model.tflite          # Votre modèle CNN converti en TFLite
```

### Nom du fichier
- Par défaut, le code cherche un fichier nommé `model.tflite`
- Si votre fichier a un nom différent, modifiez la constante `MODEL_PATH` dans `lib/services/tflite_service.dart`

### Format attendu
- Format : `.tflite` (TensorFlow Lite)
- Le modèle doit être entraîné pour classifier des images de fruits
- Les dimensions d'entrée seront configurées dans le service TFLite

### Comment ajouter votre modèle

1. Copiez votre fichier `.tflite` dans ce dossier (`assets/models/`)
2. Assurez-vous que le fichier `pubspec.yaml` contient bien :
   ```yaml
   flutter:
     assets:
       - assets/models/
   ```
3. Relancez l'application avec `flutter pub get` puis `flutter run`


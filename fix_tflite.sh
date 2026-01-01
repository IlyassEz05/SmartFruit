#!/bin/bash
# Script de correction définitive pour tflite_flutter 0.10.4

TFLITE_FILE="$HOME/.pub-cache/hosted/pub.dev/tflite_flutter-0.10.4/lib/src/tensor.dart"

if [ ! -f "$TFLITE_FILE" ]; then
    echo "❌ Fichier non trouvé: $TFLITE_FILE"
    echo "Exécutez d'abord: flutter pub get"
    exit 1
fi

echo "🔧 Correction du fichier tensor.dart..."

# Créer une sauvegarde
cp "$TFLITE_FILE" "${TFLITE_FILE}.bak"

# La solution: retourner directement le Uint8List sans wrapper
# car asTypedList retourne déjà un Uint8List
sed -i '' 's/return UnmodifiableListView<Uint8List>(/return /g' "$TFLITE_FILE"
sed -i '' 's/data.asTypedList(tfliteBinding.TfLiteTensorByteSize(_tensor)));/data.asTypedList(tfliteBinding.TfLiteTensorByteSize(_tensor));/g' "$TFLITE_FILE"

echo "✅ Correction appliquée!"
echo "💾 Backup: ${TFLITE_FILE}.bak"
echo ""
echo "🚀 Vous pouvez maintenant lancer: flutter run"

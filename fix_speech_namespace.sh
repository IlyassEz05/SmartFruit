#!/bin/bash
# Script pour ajouter le namespace manquant à speech_to_text

echo "🔧 Recherche du plugin speech_to_text..."

# Trouver le dossier du plugin
PLUGIN_DIR=$(find ~/.pub-cache/hosted/pub.dev -name "speech_to_text-*" -type d | head -1)

if [ -z "$PLUGIN_DIR" ]; then
    echo "❌ Plugin speech_to_text non trouvé. Exécutez d'abord: flutter pub get"
    exit 1
fi

GRADLE_FILE="$PLUGIN_DIR/android/build.gradle"

if [ ! -f "$GRADLE_FILE" ]; then
    echo "❌ Fichier build.gradle non trouvé: $GRADLE_FILE"
    exit 1
fi

echo "✅ Fichier trouvé: $GRADLE_FILE"

# Vérifier si le namespace existe déjà
if grep -q "namespace" "$GRADLE_FILE"; then
    echo "✅ Namespace déjà présent dans le fichier"
    exit 0
fi

echo "🔧 Ajout du namespace..."

# Créer une sauvegarde
cp "$GRADLE_FILE" "$GRADLE_FILE.bak"

# Ajouter le namespace après android {
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' '/^android {/a\
    namespace = "com.csdcorp.speech_to_text"
' "$GRADLE_FILE"
else
    # Linux
    sed -i '/^android {/a\    namespace = "com.csdcorp.speech_to_text"' "$GRADLE_FILE"
fi

# Vérifier que le namespace a été ajouté
if grep -q "namespace" "$GRADLE_FILE"; then
    echo "✅ Namespace ajouté avec succès!"
    echo "📝 Fichier modifié: $GRADLE_FILE"
    echo "💾 Sauvegarde créée: $GRADLE_FILE.bak"
else
    echo "❌ Échec de l'ajout du namespace. Restauration de la sauvegarde..."
    mv "$GRADLE_FILE.bak" "$GRADLE_FILE"
    exit 1
fi

# 🎯 Entraînement du Modèle CNN

## 📋 Prérequis

1. **Python 3.8+** installé sur votre machine
2. **TensorFlow 2.10+** et les dépendances

## 🚀 Installation

1. **Installer les dépendances :**
   ```bash
   pip install -r requirements.txt
   ```

   Ou manuellement :
   ```bash
   pip install tensorflow pillow numpy
   ```

## 🏃 Exécution

1. **Exécuter le script d'entraînement :**
   ```bash
   python train_model.py
   ```

2. **Le script va :**
   - Charger les images depuis `/Users/ilyassez/Downloads/images`
   - Préparer les données (train/validation split)
   - Créer et entraîner un modèle CNN
   - Convertir le modèle en TFLite
   - Sauvegarder dans `assets/models/fruit_classifier.tflite`

## ⏱️ Temps d'entraînement

L'entraînement prend généralement **15-30 minutes** selon votre machine :
- CPU: ~30-60 minutes
- GPU (NVIDIA): ~5-15 minutes

Le script s'arrêtera automatiquement si la validation n'améliore plus (Early Stopping).

## 📊 Résultats

Après l'entraînement, vous obtiendrez :
- ✅ `assets/models/fruit_classifier.tflite` - Le modèle à utiliser dans Flutter
- ✅ `assets/models/class_names.txt` - L'ordre des classes
- ✅ `best_model.h5` - Le meilleur modèle Keras (peut être supprimé après)

## 🔧 Configuration

Vous pouvez modifier dans `train_model.py` :
- `INPUT_SIZE = 224` - Taille des images (224x224 par défaut)
- `EPOCHS = 50` - Nombre maximum d'époques
- `BATCH_SIZE = 32` - Taille des batches
- `VALIDATION_SPLIT = 0.2` - 20% des données pour la validation

## ✅ Vérification

Après l'entraînement, vérifiez que :
1. Le fichier `assets/models/fruit_classifier.tflite` existe
2. La taille du fichier est raisonnable (quelques MB)
3. Les classes sont correctes dans `class_names.txt`

## 🐛 Problèmes courants

**Erreur "No module named 'tensorflow'"**
```bash
pip install tensorflow
```

**Erreur "CUDA out of memory"**
- Réduisez `BATCH_SIZE` à 16 ou 8
- Fermez les autres applications utilisant le GPU

**Dataset non trouvé**
- Vérifiez que le chemin `DATASET_PATH` dans le script correspond à votre dossier d'images


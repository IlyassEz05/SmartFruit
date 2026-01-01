"""
Script pour entraîner un modèle CNN de classification de fruits et le convertir en TFLite
Dataset: /Users/ilyassez/Downloads/images
"""

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import numpy as np
from PIL import Image
import os
from pathlib import Path
import shutil

# Configuration
DATASET_PATH = "/Users/ilyassez/Downloads/images"
OUTPUT_PATH = "assets/models/fruit_classifier.tflite"
INPUT_SIZE = 224  # Taille d'entrée du modèle (224x224)
BATCH_SIZE = 32
EPOCHS = 50
VALIDATION_SPLIT = 0.2

print("=" * 60)
print("ENTRAÎNEMENT DU MODÈLE CNN POUR CLASSIFICATION DE FRUITS")
print("=" * 60)

# 1. Préparer le dataset
print("\n📁 Préparation du dataset...")

# Liste des classes (dossiers de fruits)
fruit_classes = sorted([d for d in os.listdir(DATASET_PATH) 
                       if os.path.isdir(os.path.join(DATASET_PATH, d))])

print(f"✅ Classes trouvées: {len(fruit_classes)}")
for i, cls in enumerate(fruit_classes):
    class_path = os.path.join(DATASET_PATH, cls)
    num_images = len([f for f in os.listdir(class_path) 
                     if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
    print(f"  {i}: {cls} ({num_images} images)")

# 2. Créer les générateurs de données
print("\n🔄 Création des générateurs de données...")

train_datagen = keras.preprocessing.image.ImageDataGenerator(
    rescale=1./255,  # Normalisation entre 0 et 1
    validation_split=VALIDATION_SPLIT,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    horizontal_flip=True,
    zoom_range=0.2,
    fill_mode='nearest'
)

test_datagen = keras.preprocessing.image.ImageDataGenerator(
    rescale=1./255,  # Normalisation entre 0 et 1
    validation_split=VALIDATION_SPLIT
)

train_generator = train_datagen.flow_from_directory(
    DATASET_PATH,
    target_size=(INPUT_SIZE, INPUT_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='training',
    shuffle=True
)

validation_generator = test_datagen.flow_from_directory(
    DATASET_PATH,
    target_size=(INPUT_SIZE, INPUT_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='validation',
    shuffle=False
)

num_classes = len(train_generator.class_indices)
print(f"✅ {num_classes} classes détectées")
print(f"✅ {train_generator.samples} images d'entraînement")
print(f"✅ {validation_generator.samples} images de validation")

# Créer le mapping des classes
class_names = sorted(train_generator.class_indices.keys())
print(f"\n📋 Ordre des classes:")
for i, name in enumerate(class_names):
    print(f"  {i}: {name}")

# 3. Créer le modèle CNN
print("\n🏗️  Création du modèle CNN...")

model = keras.Sequential([
    # Première couche de convolution
    layers.Conv2D(32, (3, 3), activation='relu', input_shape=(INPUT_SIZE, INPUT_SIZE, 3)),
    layers.MaxPooling2D(2, 2),
    
    # Deuxième couche de convolution
    layers.Conv2D(64, (3, 3), activation='relu'),
    layers.MaxPooling2D(2, 2),
    
    # Troisième couche de convolution
    layers.Conv2D(128, (3, 3), activation='relu'),
    layers.MaxPooling2D(2, 2),
    
    # Quatrième couche de convolution
    layers.Conv2D(128, (3, 3), activation='relu'),
    layers.MaxPooling2D(2, 2),
    
    # Aplatir et couches denses
    layers.Flatten(),
    layers.Dropout(0.5),
    layers.Dense(512, activation='relu'),
    layers.Dense(num_classes, activation='softmax')  # Softmax pour classification multi-classes
])

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.001),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

print("✅ Modèle créé:")
model.summary()

# 4. Callbacks pour améliorer l'entraînement
print("\n⚙️  Configuration des callbacks...")

callbacks = [
    keras.callbacks.EarlyStopping(
        monitor='val_loss',
        patience=10,
        restore_best_weights=True,
        verbose=1
    ),
    keras.callbacks.ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=5,
        min_lr=0.00001,
        verbose=1
    ),
    keras.callbacks.ModelCheckpoint(
        'best_model.h5',
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    )
]

# 5. Entraîner le modèle
print("\n🚀 Démarrage de l'entraînement...")
print(f"   Époques: {EPOCHS}")
print(f"   Batch size: {BATCH_SIZE}")
print("   Cela peut prendre plusieurs minutes...\n")

history = model.fit(
    train_generator,
    steps_per_epoch=train_generator.samples // BATCH_SIZE,
    epochs=EPOCHS,
    validation_data=validation_generator,
    validation_steps=validation_generator.samples // BATCH_SIZE,
    callbacks=callbacks,
    verbose=1
)

print("\n✅ Entraînement terminé!")
print(f"   Meilleure précision d'entraînement: {max(history.history['accuracy']):.4f}")
print(f"   Meilleure précision de validation: {max(history.history['val_accuracy']):.4f}")

# 6. Charger le meilleur modèle
print("\n📦 Chargement du meilleur modèle...")
if os.path.exists('best_model.h5'):
    model = keras.models.load_model('best_model.h5')
    print("✅ Meilleur modèle chargé")

# 7. Convertir en TFLite
print("\n🔄 Conversion en TFLite...")

# Créer le convertisseur
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Optimisations (optionnel mais recommandé)
converter.optimizations = [tf.lite.Optimize.DEFAULT]

# Convertir
tflite_model = converter.convert()

# 8. Sauvegarder le modèle TFLite
print(f"\n💾 Sauvegarde du modèle dans {OUTPUT_PATH}...")

# Créer le dossier si nécessaire
os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

# Sauvegarder
with open(OUTPUT_PATH, 'wb') as f:
    f.write(tflite_model)

file_size = os.path.getsize(OUTPUT_PATH) / (1024 * 1024)  # MB
print(f"✅ Modèle TFLite sauvegardé! Taille: {file_size:.2f} MB")

# 9. Sauvegarder l'ordre des classes
classes_file = "assets/models/class_names.txt"
with open(classes_file, 'w') as f:
    for name in class_names:
        f.write(f"{name}\n")
print(f"✅ Ordre des classes sauvegardé dans {classes_file}")

print("\n" + "=" * 60)
print("✅ MODÈLE CRÉÉ AVEC SUCCÈS!")
print("=" * 60)
print(f"\n📁 Modèle TFLite: {OUTPUT_PATH}")
print(f"📋 Classes ({num_classes}): {', '.join(class_names)}")
print(f"📐 Taille d'entrée: {INPUT_SIZE}x{INPUT_SIZE}")
print("\n💡 Le modèle est prêt à être utilisé dans votre application Flutter!")
print("=" * 60)


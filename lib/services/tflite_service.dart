import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  // Configuration du modèle
  static const String MODEL_PATH = 'assets/models/fruits_model15.tflite';
  
  // Dimensions détectées automatiquement au chargement
  int? _inputSize;
  int? _numClasses;
  
  // IMPORTANT: Normaliser les valeurs entre 0 et 1 (le modèle attend des valeurs normalisées via rescale=1./255)
  static const bool USE_NORMALIZATION = false ;
  
  // Labels des fruits dans l'ordre exact de l'entraînement (15 fruits)
  // Ordre alphabétique strict des dossiers utilisés par flow_from_directory dans Keras
  static const List<String> LABELS = [
    'Apple Golden 2',     // 0
    'Apple Red 3',        // 1
    'Avocado',            // 2
    'Banana',             // 3
    'Banana Lady Finger', // 4
    'Cherry 1',           // 5
    'Kiwi',               // 6
    'Mango',              // 7
    'Mango Red',          // 8
    'Orange',             // 9
    'Peach',              // 10
    'Peach 2',            // 11
    'Pineapple',          // 12
    'Strawberry',         // 13
    'Watermelon',         // 14
  ];

  /// Charger le modèle TFLite et détecter automatiquement les dimensions
  Future<bool> loadModel() async {
    if (_isLoaded) {
      return true;
    }

    try {
      // Charger le modèle depuis les assets
      final ByteData data = await rootBundle.load(MODEL_PATH);
      final Uint8List bytes = data.buffer.asUint8List();

      // Créer l'interpréteur
      _interpreter = Interpreter.fromBuffer(bytes);
      _interpreter!.allocateTensors();

      // Détecter automatiquement les dimensions
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;
      
      // Extraire la taille d'entrée [1, height, width, 3]
      if (inputShape.length == 4) {
        _inputSize = inputShape[1]; // height (supposé carré)
      }
      
      // Extraire le nombre de classes depuis la shape de sortie [1, num_classes]
      if (outputShape.length >= 2) {
        _numClasses = outputShape.last;
      }
      
      print('✅ Modèle TFLite chargé avec succès');
      print('📊 Dimensions détectées: Input=${inputShape}, Output=${outputShape}');
      print('📊 Input size: $_inputSize, Num classes: $_numClasses');
      
      _isLoaded = true;
      return true;
    } catch (e) {
      print('❌ Erreur lors du chargement du modèle: $e');
      print('Assurez-vous que le fichier fruits_model15.tflite existe dans assets/models/');
      _isLoaded = false;
      return false;
    }
  }

  /// Prédire la classe d'une image
  Future<Map<String, dynamic>?> predict(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      final loaded = await loadModel();
      if (!loaded) {
        print('ERREUR: Impossible de charger le modèle');
        return null;
      }
    }

    try {
      print('📸 Début de la prédiction...');
      
      // Charger et prétraiter l'image
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        print('❌ Impossible de décoder l\'image');
        return null;
      }

      print('✅ Image décodée: ${image.width}x${image.height}');

      // Obtenir les tensors (déjà alloués au chargement)
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;
      
      print('📊 Shape d\'entrée attendue: $inputShape');
      print('📊 Shape de sortie attendue: $outputShape');
      
      // Extraire la taille d'entrée depuis la shape [1, height, width, 3]
      final inputSize = inputShape.length == 4 ? inputShape[1] : 100;
      print('📊 Taille d\'entrée détectée: ${inputSize}x$inputSize');
      
      // Redimensionner l'image à la taille attendue par le modèle
      final img.Image finalImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );
      
      print('✅ Image redimensionnée: ${finalImage.width}x${finalImage.height}');
      
      // Convertir l'image en Float32List avec la taille détectée
      final inputFlat = _imageToByteListFloat32(finalImage, inputSize);
      final expectedInputSize = inputShape.reduce((a, b) => a * b);
      
      print('✅ Input créé: ${inputFlat.length} éléments (attendu: $expectedInputSize)');
      
      if (inputFlat.length != expectedInputSize) {
        print('❌ ERREUR: Taille d\'input incorrecte!');
        return null;
      }
      
      // SOLUTION DÉFINITIVE: Copier directement les données Float32 dans le buffer du tensor
      // Utiliser le buffer Uint8List du tensor et y copier les bytes du Float32List
      print('🔧 Copie des données dans le buffer du tensor...');
      
      // Convertir Float32List en Uint8List en utilisant le buffer directement
      // Float32List.buffer.asUint8List() avec offset correct
      final inputBytes = inputFlat.buffer.asUint8List(
        inputFlat.offsetInBytes,
        inputFlat.lengthInBytes,
      );
      
      // Vérifier que la taille correspond
      final tensorByteSize = inputTensor.numBytes();
      if (inputBytes.length != tensorByteSize) {
        print('❌ ERREUR: Taille de bytes incorrecte! Tensor: $tensorByteSize, Input: ${inputBytes.length}');
        return null;
      }
      
      // Copier les bytes directement dans le tensor
      inputTensor.data = inputBytes;
      print('✅ ${inputFlat.length} valeurs Float32 (${inputBytes.length} bytes) copiées dans le tensor');
      
      // Préparer le buffer de sortie
      final outputSize = outputShape.reduce((a, b) => a * b);
      var outputBuffer = Float32List(outputSize);
      
      print('🚀 Exécution de l\'inférence avec invoke()...');
      
      // Exécuter l'inférence en utilisant invoke() directement (méthode native)
      try {
        _interpreter!.invoke();
        print('✅ Inférence exécutée avec invoke()');
        
        // Copier les résultats depuis le tensor de sortie
        final outputBytes = outputTensor.data;
        // Convertir Uint8List en Float32List (4 bytes par float32)
        final outputFloat32 = Float32List.view(outputBytes.buffer);
        outputBuffer = outputFloat32.sublist(0, outputSize);
        print('✅ Résultats copiés depuis le tensor de sortie');
      } catch (e, stackTrace) {
        print('❌ ERREUR lors de l\'inférence: $e');
        print('❌ Stack trace: $stackTrace');
        return null;
      }
      
      // Récupérer les résultats
      final output = outputBuffer;
      print('✅ Inférence terminée. Taille de la sortie: ${output.length}');
      
      // Afficher toutes les valeurs de sortie pour debug
      print('📊 Toutes les valeurs de sortie:');
      for (int i = 0; i < output.length; i++) {
        final label = i < LABELS.length ? LABELS[i] : 'Classe $i';
        print('  [$i] $label: ${output[i].toStringAsFixed(6)}');
      }

      // Trouver l'index de la classe avec la plus haute probabilité
      int maxIndex = 0;
      double maxValue = output[0].toDouble();
      for (int i = 1; i < output.length; i++) {
        final value = output[i].toDouble();
        if (value > maxValue) {
          maxValue = value;
          maxIndex = i;
        }
      }

      // Détecter si les valeurs sont déjà des probabilités (softmax appliqué) ou des logits
      // Les probabilités sont entre 0 et 1, et leur somme ≈ 1
      double sum = 0.0;
      bool hasNegative = false;
      bool hasGreaterThanOne = false;
      
      for (int i = 0; i < output.length; i++) {
        final val = output[i].toDouble();
        sum += val;
        if (val < -0.1) hasNegative = true;
        if (val > 1.1) hasGreaterThanOne = true;
      }
      
      // Si toutes les valeurs sont entre 0 et 1 et la somme est proche de 1, ce sont des probabilités
      final areProbabilities = !hasNegative && !hasGreaterThanOne && (sum - 1.0).abs() < 0.5;
      
      print('📊 Somme des valeurs: ${sum.toStringAsFixed(4)}, Type: ${areProbabilities ? "Probabilités" : "Logits"}');
      print('🏆 Classe prédite: Index=$maxIndex, Valeur=$maxValue, Label=${maxIndex < LABELS.length ? LABELS[maxIndex] : "Inconnu"}');
      
      double confidence;
      if (areProbabilities) {
        // Les valeurs sont déjà des probabilités (softmax déjà appliqué dans le modèle)
        confidence = (maxValue * 100.0).clamp(0.0, 100.0);
        print('📊 Utilisation directe des probabilités du modèle');
      } else {
        // Les valeurs sont des logits, appliquer softmax numériquement stable
        double maxLogit = maxValue;
        for (int i = 0; i < output.length; i++) {
          if (output[i] > maxLogit) {
            maxLogit = output[i];
          }
        }
        
        double sumExp = 0.0;
        for (int i = 0; i < output.length; i++) {
          sumExp += math.exp(output[i] - maxLogit);
        }
        
        final probability = math.exp(maxValue - maxLogit) / sumExp;
        confidence = (probability * 100.0).clamp(0.0, 100.0);
        print('📊 Probabilité calculée avec softmax: ${probability.toStringAsFixed(4)}');
      }

      // Obtenir le label (avec gestion d'erreur si l'index est hors limites)
      // Utiliser le nombre de classes détecté ou les labels disponibles
      final numClasses = _numClasses ?? LABELS.length;
      final label = (maxIndex < LABELS.length && maxIndex >= 0)
          ? LABELS[maxIndex]
          : 'Classe $maxIndex';

      print('✅ Prédiction finale: $label (${confidence.toStringAsFixed(2)}%)');

      return {
        'label': label,
        'confidence': confidence,
        'index': maxIndex,
        'allPredictions': output.map((e) => e.toDouble()).toList(),
      };
    } catch (e, stackTrace) {
      print('❌ ERREUR lors de la prédiction: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Convertir une image en Float32List pour TensorFlow Lite
  /// Format: [batch=1, height=100, width=100, channels=3] -> liste plate de 1*100*100*3 éléments
  /// L'ordre des pixels suit le format HWC (Height, Width, Channels)
  Float32List _imageToByteListFloat32(img.Image image, int inputSize) {
    // Créer un Float32List de taille 1 * inputSize * inputSize * 3 = 30000 éléments
    final convertedBytes = Float32List(inputSize * inputSize * 3);
    
    int pixelIndex = 0;
    
    // Parcourir l'image ligne par ligne (height) puis colonne par colonne (width)
    // Format attendu: [batch, height, width, channels] -> pour batch=1, on a [height, width, channels]
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        
        // Normaliser ou non selon la configuration
        // Ordre: R, G, B pour chaque pixel (format RGB standard)
        if (USE_NORMALIZATION) {
          // Normaliser entre 0 et 1 (pour modèle SANS preprocessing Rescaling)
          convertedBytes[pixelIndex++] = pixel.r / 255.0;
          convertedBytes[pixelIndex++] = pixel.g / 255.0;
          convertedBytes[pixelIndex++] = pixel.b / 255.0;
        } else {
          // Utiliser les valeurs brutes 0-255 (pour modèle AVEC preprocessing Rescaling inclus)
          convertedBytes[pixelIndex++] = pixel.r.toDouble();
          convertedBytes[pixelIndex++] = pixel.g.toDouble();
          convertedBytes[pixelIndex++] = pixel.b.toDouble();
        }
      }
    }

    print('🔧 Conversion image->tensor: ${convertedBytes.length} éléments créés');
    print('🔧 Premiers pixels: R=${convertedBytes[0]}, G=${convertedBytes[1]}, B=${convertedBytes[2]} (${USE_NORMALIZATION ? "normalisés 0-1" : "bruts 0-255"})');

    return convertedBytes;
  }

  /// Libérer les ressources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }

  bool get isLoaded => _isLoaded;
}



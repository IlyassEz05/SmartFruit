import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_fruit/services/image_service.dart';
import 'package:smart_fruit/services/tflite_service.dart';
import 'classification_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImageService _imageService = ImageService();
  final TFLiteService _tfliteService = TFLiteService();
  bool _isLoading = false;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
    });

    final loaded = await _tfliteService.loadModel();
    
    if (mounted) {
      setState(() {
        _modelLoaded = loaded;
        _isLoading = false;
      });

      if (!loaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erreur: Modèle TFLite non trouvé. Assurez-vous que model.tflite est dans assets/models/',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imageService.takePhoto();
    
    if (image != null && mounted) {
      final File? file = await _imageService.convertToFile(image);
      if (file != null) {
        await _classifyImage(file);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _imageService.pickImageFromGallery();
    
    if (image != null && mounted) {
      final File? file = await _imageService.convertToFile(image);
      if (file != null) {
        await _classifyImage(file);
      }
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    if (!_modelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le modèle n\'est pas chargé. Veuillez patienter...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _tfliteService.predict(imageFile);

      if (!mounted) return;

      if (result != null) {
        // Naviguer vers l'écran de résultats
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassificationResultScreen(
              imageFile: imageFile,
              label: result['label'] as String,
              confidence: result['confidence'] as double,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la classification. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartFruit'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Icons.lunch_dining,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Classification de Fruits',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Prenez une photo ou sélectionnez une image depuis la galerie pour identifier le fruit',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Camera button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _takePhoto,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt, size: 28),
                label: Text(
                  _isLoading ? 'Traitement...' : 'Prendre une photo',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
              const SizedBox(height: 16),
              // Gallery button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickFromGallery,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library, size: 28),
                label: Text(
                  _isLoading ? 'Traitement...' : 'Choisir depuis la galerie',
                  style: const TextStyle(fontSize: 18),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
              const SizedBox(height: 48),
              // Model status
              Card(
                color: _modelLoaded 
                    ? Colors.green.shade50 
                    : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _modelLoaded ? Icons.check_circle : Icons.warning,
                        color: _modelLoaded 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _modelLoaded
                              ? 'Modèle CNN chargé et prêt'
                              : 'Chargement du modèle en cours...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Utilisez un modèle CNN entraîné pour identifier les fruits avec précision',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


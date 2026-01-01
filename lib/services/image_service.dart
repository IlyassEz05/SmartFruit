import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Prendre une photo avec la caméra
  Future<XFile?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image;
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  /// Sélectionner une image depuis la galerie
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image;
    } catch (e) {
      print('Erreur lors de la sélection d\'image: $e');
      return null;
    }
  }

  /// Convertir XFile en File
  Future<File?> convertToFile(XFile xFile) async {
    try {
      return File(xFile.path);
    } catch (e) {
      print('Erreur lors de la conversion en File: $e');
      return null;
    }
  }
}


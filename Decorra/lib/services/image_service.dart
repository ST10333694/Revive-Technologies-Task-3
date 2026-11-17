import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config.dart';

class ImageUploadException implements Exception {
  ImageUploadException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A photo the person just picked, held in memory until it is uploaded.
class PickedPhoto {
  PickedPhoto({required this.bytes, required this.fileName});
  final Uint8List bytes;
  final String fileName;
}

/// Picks photos and uploads them to Cloudinary, which hands back a public
/// https link. That link is what gets saved in Firestore, so every device
/// shows the same photo. (The Android app saved a file path that only existed
/// on one phone, which is why photos kept going missing.)
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Opens the gallery. The picker shrinks the photo and applies its EXIF
  /// rotation for us. Returns null if the person cancels.
  Future<PickedPhoto?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedPhoto(
      bytes: bytes,
      fileName: file.name.isEmpty ? 'photo.jpg' : file.name,
    );
  }

  /// Uploads [photo] and returns its public https link.
  /// [folder] keeps things tidy in Cloudinary, e.g. "themes" or "items".
  Future<String> upload(PickedPhoto photo, {required String folder}) async {
    if (!AppConfig.cloudinaryConfigured) {
      throw ImageUploadException(
        'Image uploads are not set up yet. Fill in lib/config.dart (README step 4).',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          photo.bytes,
          filename: photo.fileName,
        ),
      );

    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (streamed.statusCode != 200) {
        final error = (json['error'] as Map<String, dynamic>?)?['message'];
        throw ImageUploadException(
          error is String
              ? 'Upload failed: $error'
              : 'Upload failed (${streamed.statusCode}).',
        );
      }
      final url = json['secure_url'] as String?;
      if (url == null) {
        throw ImageUploadException('Upload failed: no link came back.');
      }
      return url;
    } on TimeoutException {
      throw ImageUploadException(
        'The upload took too long. Check your connection and try again.',
      );
    } on http.ClientException {
      throw ImageUploadException(
        'No connection. Check your internet and try again.',
      );
    } on FormatException {
      throw ImageUploadException(
        'Upload failed: unexpected reply from the image server.',
      );
    }
  }
}

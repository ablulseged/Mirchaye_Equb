import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String cloudinaryUrl = 'cloudinary://992945872898888:t9kRIPORIezV3xZzndvEw0c6Z8Y@deg68e6rs';
  
  // Parse credentials from URL
  static String get cloudName => 'deg68e6rs';
  static String get apiKey => '992945872898888';
  static String get apiSecret => 't9kRIPORIezV3xZzndvEw0c6Z8Y';
  static String get baseUrl => 'https://api.cloudinary.com/v1_1/$cloudName';

  /// Upload an image file to Cloudinary
  /// 
  /// [filePath] - Local path to the image file
  /// [folder] - Optional folder name in Cloudinary (e.g., 'profile_pictures')
  /// [publicId] - Optional public ID for the image
  /// 
  /// Returns the secure URL of the uploaded image
  static Future<String> uploadImage({
    required String filePath,
    String? folder,
    String? publicId,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Generate timestamp and signature for authentication
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final params = <String, String>{
        'timestamp': timestamp,
        if (folder != null) 'folder': folder,
        if (publicId != null) 'public_id': publicId,
      };
      
      // Create signature
      final signature = _generateSignature(params);
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/image/upload'));
      
      // Add fields
      request.fields['timestamp'] = timestamp;
      request.fields['api_key'] = apiKey;
      request.fields['signature'] = signature;
      if (folder != null) request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;
      
      // Add file
      final file = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(file);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        return jsonResponse['secure_url'] ?? jsonResponse['url'];
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading image to Cloudinary: $e');
    }
  }

  /// Upload an image from bytes to Cloudinary
  /// 
  /// [imageBytes] - Image as bytes
  /// [fileName] - Name for the file (optional)
  /// [folder] - Optional folder name in Cloudinary
  /// 
  /// Returns the secure URL of the uploaded image
  static Future<String> uploadImageBytes({
    required List<int> imageBytes,
    String? fileName,
    String? folder,
  }) async {
    try {
      final Uri uploadUrl = Uri.parse('$baseUrl/image/upload');
      
      // Generate timestamp and signature
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final params = Map<String, String>.from({
        'timestamp': timestamp,
        if (folder != null) 'folder': folder,
      });
      
      // Create signature
      final signature = _generateSignature(params);
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uploadUrl);
      
      // Add fields
      request.fields['timestamp'] = timestamp;
      request.fields['api_key'] = apiKey;
      request.fields['signature'] = signature;
      if (folder != null) request.fields['folder'] = folder;
      
      // Add bytes file
      final file = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName ?? 'image.jpg',
      );
      request.files.add(file);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['secure_url'] ?? jsonResponse['url'];
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading image to Cloudinary: $e');
    }
  }

  /// Delete an image from Cloudinary
  /// 
  /// [publicId] - The public ID of the image to delete
  /// Returns true if successful
  static Future<bool> deleteImage({required String publicId}) async {
    try {
      final Uri deleteUrl = Uri.parse('$baseUrl/image/destroy');
      
      // Generate timestamp and signature
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final params = {
        'public_id': publicId,
        'timestamp': timestamp,
      };
      
      final signature = _generateSignature(params);
      
      final response = await http.post(
        deleteUrl,
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': apiKey,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] == 'ok';
      } else {
        throw Exception('Failed to delete image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting image from Cloudinary: $e');
    }
  }

  /// Generate Cloudinary signature for authentication
  static String _generateSignature(Map<String, String> params) {
    // Sort params by key
    final sortedKeys = params.keys.toList()..sort();
    
    // Create query string
    final queryString = sortedKeys.map((key) => '$key=${params[key]}').join('&');
    
    // Append api_secret
    final signatureString = '$queryString$apiSecret';
    
    // Generate SHA-1 hash
    final bytes = utf8.encode(signatureString);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Extract public ID from Cloudinary URL
  static String? extractPublicIdFromUrl(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      
      // Cloudinary URL format: https://res.cloudinary.com/{cloud_name}/image/upload/{folder}/{public_id}.{ext}
      if (pathSegments.contains('upload')) {
        final uploadIndex = pathSegments.indexOf('upload');
        if (uploadIndex < pathSegments.length - 1) {
          // Get everything after 'upload' and before the file extension
          final publicIdParts = pathSegments.sublist(uploadIndex + 1);
          return publicIdParts.join('/');
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Progress callback for upload progress
typedef ProgressCallback = void Function(int sent, int total);


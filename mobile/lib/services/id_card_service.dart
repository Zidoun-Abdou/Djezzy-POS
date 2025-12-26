import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class IDCardService {
  static const String _keyUserData = 'user_id_card_data';
  static const String _keyFaceImagePath = 'user_face_image_path';
  static const String _keySignaturePath = 'user_signature_path';
  static const String _keyIsVerified = 'user_is_verified';
  static const String _keyVerificationDate = 'user_verification_date';

  // Save complete user data after NFC reading and face matching
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    // Extract and save main data
    final dataToSave = {
      'personal': {
        'firstName': userData['firstName'] ?? '',
        'firstNameAr': userData['firstNameAr'] ?? '',
        'lastName': userData['lastName'] ?? '',
        'lastNameAr': userData['lastNameAr'] ?? '',
        'birthDate': userData['birthDate'] ?? '',
        'birthPlace': userData['birthPlace'] ?? '',
        'birthPlaceAr': userData['birthPlaceAr'] ?? '',
        'sex': userData['sex'] ?? '',
        'bloodType': userData['bloodType'] ?? '',
        'nin': userData['nin'] ?? '',
      },
      'document': {
        'idNumber': userData['idNumber'] ?? '',
        'daira': userData['daira'] ?? '',
        'baladia': userData['baladia'] ?? '',
        'baladiaAr': userData['baladiaAr'] ?? '',
        'issueDate': userData['issueDate'] ?? '',
        'expiryDate': userData['expiryDate'] ?? '',
      },
      'biometric': {
        'faceImage': userData['faceImage'] ?? '',
        'signature': userData['signature'] ?? '',
      },
      'verification': {
        'isVerified': userData['isVerified'] ?? false,
        'confidence': userData['confidence'] ?? 0.0,
        'verificationDate': DateTime.now().toIso8601String(),
      }
    };

    await prefs.setString(_keyUserData, jsonEncode(dataToSave));
    await prefs.setBool(_keyIsVerified, userData['isVerified'] ?? false);
    await prefs.setString(_keyVerificationDate, DateTime.now().toIso8601String());

    if (userData['faceImagePath'] != null) {
      await prefs.setString(_keyFaceImagePath, userData['faceImagePath']);
    }
    if (userData['signaturePath'] != null) {
      await prefs.setString(_keySignaturePath, userData['signaturePath']);
    }
  }

  // Get complete user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_keyUserData);

    if (dataString != null) {
      try {
        final data = jsonDecode(dataString) as Map<String, dynamic>;

        // Add paths if they exist
        final faceImagePath = prefs.getString(_keyFaceImagePath);
        final signaturePath = prefs.getString(_keySignaturePath);

        if (faceImagePath != null) {
          data['faceImagePath'] = faceImagePath;
        }
        if (signaturePath != null) {
          data['signaturePath'] = signaturePath;
        }

        return data;
      } catch (e) {
        print('Error loading user data: $e');
        return null;
      }
    }
    return null;
  }

  // Check if user is verified
  static Future<bool> isUserVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsVerified) ?? false;
  }

  // Get verification date
  static Future<String?> getVerificationDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVerificationDate);
  }

  // Clear all user data
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyFaceImagePath);
    await prefs.remove(_keySignaturePath);
    await prefs.remove(_keyIsVerified);
    await prefs.remove(_keyVerificationDate);
  }

  // Save partial data from MRZ scanning
  static Future<void> saveMRZData(String idNumber, String birthDate, String expiryDate) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing data or create new
    final existingData = await getUserData() ?? {
      'personal': {},
      'document': {},
      'biometric': {},
      'verification': {},
    };

    // Update document data
    existingData['document']['idNumber'] = idNumber;
    existingData['document']['expiryDate'] = expiryDate;
    existingData['personal']['birthDate'] = birthDate;

    await prefs.setString(_keyUserData, jsonEncode(existingData));
  }

  // Save NFC decoded data
  static Future<void> saveNFCData(Map<String, dynamic> nfcData) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing data or create new
    final existingData = await getUserData() ?? {
      'personal': {},
      'document': {},
      'biometric': {},
      'verification': {},
    };

    // Update with NFC data
    if (nfcData['dg11'] != null) {
      final dg11 = nfcData['dg11'];
      existingData['personal']['firstName'] = dg11['name_latin'] ?? '';
      existingData['personal']['firstNameAr'] = dg11['name_arabic'] ?? '';
      existingData['personal']['lastName'] = dg11['surname_latin'] ?? '';
      existingData['personal']['lastNameAr'] = dg11['surname_arabic'] ?? '';
      existingData['personal']['birthDate'] = dg11['birth_date'] ?? '';
      existingData['personal']['birthPlace'] = dg11['birthplace_latin'] ?? '';
      existingData['personal']['birthPlaceAr'] = dg11['birthplace_arabic'] ?? '';
      existingData['personal']['sex'] = dg11['sex_latin'] ?? '';
      existingData['personal']['bloodType'] = dg11['blood_type'] ?? '';
      existingData['personal']['nin'] = dg11['nin'] ?? '';
    }

    if (nfcData['dg12'] != null) {
      final dg12 = nfcData['dg12'];
      existingData['document']['daira'] = dg12['daira'] ?? '';
      existingData['document']['baladia'] = dg12['baladia_latin'] ?? '';
      existingData['document']['baladiaAr'] = dg12['baladia_arabic'] ?? '';
      existingData['document']['issueDate'] = dg12['delivery_date'] ?? '';
      existingData['document']['expiryDate'] = dg12['expiry_date'] ?? '';
    }

    if (nfcData['dg2'] != null) {
      existingData['biometric']['faceImage'] = nfcData['dg2']['face'] ?? '';
    }

    if (nfcData['dg7'] != null) {
      existingData['biometric']['signature'] = nfcData['dg7']['signature'] ?? '';
    }

    await prefs.setString(_keyUserData, jsonEncode(existingData));
  }

  // Mark user as verified after face matching
  static Future<void> markAsVerified(double confidence) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing data
    final existingData = await getUserData() ?? {
      'personal': {},
      'document': {},
      'biometric': {},
      'verification': {},
    };

    // Update verification status
    existingData['verification']['isVerified'] = true;
    existingData['verification']['confidence'] = confidence;
    existingData['verification']['verificationDate'] = DateTime.now().toIso8601String();

    await prefs.setString(_keyUserData, jsonEncode(existingData));
    await prefs.setBool(_keyIsVerified, true);
    await prefs.setString(_keyVerificationDate, DateTime.now().toIso8601String());
  }

  // Get formatted display data
  static Future<Map<String, String>> getFormattedUserData() async {
    final data = await getUserData();
    if (data == null) return {};

    final personal = data['personal'] as Map<String, dynamic>? ?? {};
    final document = data['document'] as Map<String, dynamic>? ?? {};

    return {
      'fullName': '${personal['firstName']} ${personal['lastName']}',
      'fullNameAr': '${personal['firstNameAr']} ${personal['lastNameAr']}',
      'idNumber': document['idNumber'] ?? '',
      'birthDate': personal['birthDate'] ?? '',
      'birthPlace': personal['birthPlace'] ?? '',
      'sex': personal['sex'] ?? '',
      'bloodType': personal['bloodType'] ?? '',
      'nin': personal['nin'] ?? '',
      'issueDate': document['issueDate'] ?? '',
      'expiryDate': document['expiryDate'] ?? '',
      'daira': document['daira'] ?? '',
      'baladia': document['baladia'] ?? '',
    };
  }
}
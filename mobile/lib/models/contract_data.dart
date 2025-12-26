import 'dart:typed_data';
import '../services/api_service.dart';

/// Contract data that flows through the entire workflow
class ContractData {
  final OfferData selectedOffer;
  final PhoneNumberData selectedPhoneNumber;
  final Map<String, dynamic>? userData;
  final Uint8List? signatureImage;
  final DateTime contractDate;
  final String contractId;

  ContractData({
    required this.selectedOffer,
    required this.selectedPhoneNumber,
    this.userData,
    this.signatureImage,
    DateTime? contractDate,
    String? contractId,
  })  : contractDate = contractDate ?? DateTime.now(),
        contractId = contractId ?? _generateContractId();

  /// Generate unique contract ID: DJ-YYYYMMDD-XXXX
  static String _generateContractId() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomStr = now.millisecondsSinceEpoch.toString().substring(7);
    return 'DJ-$dateStr-$randomStr';
  }

  /// Create a copy with updated fields
  ContractData copyWith({
    OfferData? selectedOffer,
    PhoneNumberData? selectedPhoneNumber,
    Map<String, dynamic>? userData,
    Uint8List? signatureImage,
    DateTime? contractDate,
    String? contractId,
  }) {
    return ContractData(
      selectedOffer: selectedOffer ?? this.selectedOffer,
      selectedPhoneNumber: selectedPhoneNumber ?? this.selectedPhoneNumber,
      userData: userData ?? this.userData,
      signatureImage: signatureImage ?? this.signatureImage,
      contractDate: contractDate ?? this.contractDate,
      contractId: contractId ?? this.contractId,
    );
  }

  /// Get formatted contract date
  String get formattedDate {
    return '${contractDate.day.toString().padLeft(2, '0')}/${contractDate.month.toString().padLeft(2, '0')}/${contractDate.year}';
  }

  /// Get formatted phone number (0770 12 34 56)
  String get formattedPhoneNumber {
    return selectedPhoneNumber.formattedNumber;
  }

  /// Get raw phone number
  String get phoneNumberRaw {
    return selectedPhoneNumber.number;
  }

  /// Get customer full name from userData
  String get customerFullName {
    if (userData == null) return '';
    final personal = userData!['personal'] as Map<String, dynamic>?;
    if (personal == null) return '';
    final firstName = personal['firstName'] ?? '';
    final lastName = personal['lastName'] ?? '';
    return '$firstName $lastName'.trim();
  }

  /// Get customer full name in Arabic from userData
  String get customerFullNameArabic {
    if (userData == null) return '';
    final personal = userData!['personal'] as Map<String, dynamic>?;
    if (personal == null) return '';
    final firstName = personal['firstNameAr'] ?? '';
    final lastName = personal['lastNameAr'] ?? '';
    return '$firstName $lastName'.trim();
  }

  /// Get NIN from userData
  String get customerNIN {
    if (userData == null) return '';
    final personal = userData!['personal'] as Map<String, dynamic>?;
    return personal?['nin'] ?? '';
  }

  /// Get ID card number from userData
  String get idCardNumber {
    if (userData == null) return '';
    final document = userData!['document'] as Map<String, dynamic>?;
    return document?['idNumber'] ?? '';
  }

  /// Get birth date from userData
  String get birthDate {
    if (userData == null) return '';
    final personal = userData!['personal'] as Map<String, dynamic>?;
    return personal?['birthDate'] ?? '';
  }

  /// Get birth place from userData
  String get birthPlace {
    if (userData == null) return '';
    final personal = userData!['personal'] as Map<String, dynamic>?;
    return personal?['birthPlace'] ?? '';
  }

  /// Get face image (base64) from userData
  String? get faceImageBase64 {
    if (userData == null) return null;
    final biometric = userData!['biometric'] as Map<String, dynamic>?;
    return biometric?['faceImage'];
  }

  /// Check if contract has all required data
  bool get isComplete {
    return userData != null &&
           signatureImage != null &&
           customerFullName.isNotEmpty &&
           idCardNumber.isNotEmpty;
  }
}

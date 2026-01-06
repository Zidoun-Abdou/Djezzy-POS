import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// API service for fetching offers and phone numbers
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final AuthService _authService = AuthService();

  /// Fetch active offers with their phone numbers
  Future<List<OfferData>> fetchActiveOffers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.activeOffersEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle paginated response
        final results = data is List ? data : (data['results'] ?? []);
        return (results as List)
            .map((json) => OfferData.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load offers: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  /// Fetch available phone numbers for a specific offer
  Future<List<PhoneNumberData>> fetchAvailableNumbers({int? offerId}) async {
    try {
      var url = '${ApiConfig.baseUrl}${ApiConfig.availableNumbersEndpoint}';
      if (offerId != null) {
        url += '?offer=$offerId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle paginated response
        final results = data is List ? data : (data['results'] ?? []);
        return (results as List)
            .map((json) => PhoneNumberData.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load phone numbers: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  /// Convert date to YYYY-MM-DD for Django API
  /// Handles multiple input formats: MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, YYMMDD
  String _convertToIsoDate(String? date) {
    if (date == null || date.isEmpty) return '';

    // Already in ISO format YYYY-MM-DD
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      return date;
    }

    // MRZ format YYMMDD (6 digits)
    if (RegExp(r'^\d{6}$').hasMatch(date)) {
      final yy = date.substring(0, 2);
      final mm = date.substring(2, 4);
      final dd = date.substring(4, 6);
      final year = int.parse(yy) < 30 ? '20$yy' : '19$yy';
      return '$year-$mm-$dd';
    }

    // Format with slashes: MM/DD/YYYY or DD/MM/YYYY
    final parts = date.split('/');
    if (parts.length == 3) {
      // Check if first part is year (YYYY/MM/DD)
      if (parts[0].length == 4) {
        return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
      }
      // Assume MM/DD/YYYY format
      return '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
    }

    // Format with dashes but wrong order
    final dashParts = date.split('-');
    if (dashParts.length == 3) {
      // Check if first part is year
      if (dashParts[0].length == 4) {
        return date; // Already correct
      }
      // Try to parse and reorder: assume DD-MM-YYYY or MM-YYYY-DD
      // If middle part is 4 digits, it's MM-YYYY-DD -> YYYY-MM-DD
      if (dashParts[1].length == 4) {
        return '${dashParts[1]}-${dashParts[0].padLeft(2, '0')}-${dashParts[2].padLeft(2, '0')}';
      }
    }

    return date; // Return as-is if can't parse
  }

  /// Create a new contract with full customer data
  Future<ContractResult> submitContract({
    required int offerId,
    required int phoneNumberId,
    required Map<String, dynamic> customerData,
    String? signatureBase64,
    String? photoBase64,
    String? customerPhone,
    String? customerEmail,
    String? customerAddress,
  }) async {
    try {
      final personal = customerData['personal'] as Map<String, dynamic>? ?? {};
      final document = customerData['document'] as Map<String, dynamic>? ?? {};

      final body = {
        'offer': offerId,
        'phone_number': phoneNumberId,
        'customer_first_name': personal['firstName'] ?? '',
        'customer_last_name': personal['lastName'] ?? '',
        'customer_first_name_ar': personal['firstNameAr'] ?? '',
        'customer_last_name_ar': personal['lastNameAr'] ?? '',
        'customer_birth_date': _convertToIsoDate(personal['birthDate']),
        'customer_birth_place': personal['birthPlace'] ?? '',
        'customer_sex': personal['sex'] ?? '',
        'customer_nin': personal['nin'] ?? '',
        'customer_id_number': document['idNumber'] ?? '',
        'customer_id_expiry': _convertToIsoDate(document['expiryDate']),
        'customer_daira': document['daira'] ?? '',
        'customer_baladia': document['baladia'] ?? '',
        if (signatureBase64 != null) 'signature_base64': signatureBase64,
        if (photoBase64 != null) 'customer_photo_base64': photoBase64,
        if (customerPhone != null && customerPhone.isNotEmpty) 'customer_phone': customerPhone,
        if (customerEmail != null && customerEmail.isNotEmpty) 'customer_email': customerEmail,
        if (customerAddress != null && customerAddress.isNotEmpty) 'customer_address': customerAddress,
      };

      print('Contract API Request: $body');

      final response = await _authService.authenticatedPost(
        ApiConfig.contractsEndpoint,
        body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ContractResult.success(
          data['id'],
          contractNumber: data['contract_number'],
        );
      } else {
        print('Contract API Error: ${response.statusCode} - ${response.body}');
        final error = jsonDecode(response.body);
        // DRF returns field errors as {field_name: [errors]} or detail for non-field errors
        String errorMsg = 'Erreur lors de la creation du contrat';
        if (error is Map) {
          if (error.containsKey('detail')) {
            errorMsg = error['detail'].toString();
          } else {
            // Get first field error
            final firstError = error.entries.first;
            final fieldErrors = firstError.value;
            if (fieldErrors is List && fieldErrors.isNotEmpty) {
              errorMsg = '${firstError.key}: ${fieldErrors.first}';
            }
          }
        }
        return ContractResult.error(errorMsg);
      }
    } catch (e) {
      return ContractResult.error('Impossible de creer le contrat: $e');
    }
  }

  /// Fetch agent's contracts (my sales)
  Future<List<ContractListItem>> fetchMyContracts() async {
    try {
      final response = await _authService.authenticatedGet(
        '${ApiConfig.contractsEndpoint}my-contracts/',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        return (results as List)
            .map((json) => ContractListItem.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load contracts: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch contracts: $e');
    }
  }

  /// Fetch agent's statistics
  Future<MyStats> fetchMyStats() async {
    try {
      final response = await _authService.authenticatedGet(
        '${ApiConfig.contractsEndpoint}my-stats/',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MyStats.fromJson(data);
      }
      throw Exception('Failed to load stats: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch stats: $e');
    }
  }
}

/// Offer data model
class OfferData {
  final int id;
  final String name;
  final String code;
  final String? description;
  final double price;
  final String currency;
  final int dataAllowanceMb;
  final int voiceMinutes;
  final int smsCount;
  final int validityDays;
  final List<String> features;
  final bool isActive;
  final bool isFeatured;
  final String formattedPrice;
  final List<PhoneNumberData> availablePhoneNumbers;
  final int availableCount;

  OfferData({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.price,
    required this.currency,
    required this.dataAllowanceMb,
    required this.voiceMinutes,
    required this.smsCount,
    required this.validityDays,
    required this.features,
    required this.isActive,
    required this.isFeatured,
    required this.formattedPrice,
    required this.availablePhoneNumbers,
    required this.availableCount,
  });

  factory OfferData.fromJson(Map<String, dynamic> json) {
    return OfferData(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      price: double.parse(json['price'].toString()),
      currency: json['currency'] ?? 'DZD',
      dataAllowanceMb: json['data_allowance_mb'] ?? 0,
      voiceMinutes: json['voice_minutes'] ?? 0,
      smsCount: json['sms_count'] ?? 0,
      validityDays: json['validity_days'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      formattedPrice: json['formatted_price'] ?? '${json['price']} DZD',
      availablePhoneNumbers: (json['available_phone_numbers'] as List? ?? [])
          .map((pn) => PhoneNumberData.fromJson(pn))
          .toList(),
      availableCount: json['available_count'] ?? 0,
    );
  }

  /// Get data in GB
  double get dataGB => dataAllowanceMb / 1024;

  /// Formatted data display
  String get formattedData {
    if (dataGB >= 1) {
      return '${dataGB.toStringAsFixed(0)} Go';
    }
    return '$dataAllowanceMb Mo';
  }

  /// Formatted validity
  String get formattedValidity {
    if (validityDays == 1) return '1 jour';
    if (validityDays < 30) return '$validityDays jours';
    final months = validityDays ~/ 30;
    return months == 1 ? '1 mois' : '$months mois';
  }
}

/// Phone number data model
class PhoneNumberData {
  final int id;
  final String number;
  final String formattedNumber;
  final String status;

  PhoneNumberData({
    required this.id,
    required this.number,
    required this.formattedNumber,
    required this.status,
  });

  factory PhoneNumberData.fromJson(Map<String, dynamic> json) {
    return PhoneNumberData(
      id: json['id'],
      number: json['number'] ?? '',
      formattedNumber: json['formatted_number'] ?? json['number'] ?? '',
      status: json['status'] ?? 'available',
    );
  }
}

/// Contract creation result
class ContractResult {
  final bool success;
  final int? contractId;
  final String? contractNumber;
  final String? error;

  ContractResult.success(this.contractId, {this.contractNumber})
      : success = true,
        error = null;
  ContractResult.error(this.error)
      : success = false,
        contractId = null,
        contractNumber = null;
}

/// Contract list item for my sales
class ContractListItem {
  final int id;
  final String contractNumber;
  final String status;
  final String statusDisplay;
  final String customerFirstName;
  final String customerLastName;
  final String phoneNumber;
  final String offerName;
  final String createdAt;

  ContractListItem({
    required this.id,
    required this.contractNumber,
    required this.status,
    required this.statusDisplay,
    required this.customerFirstName,
    required this.customerLastName,
    required this.phoneNumber,
    required this.offerName,
    required this.createdAt,
  });

  String get customerFullName => '$customerFirstName $customerLastName'.trim();

  factory ContractListItem.fromJson(Map<String, dynamic> json) {
    final phoneDetail = json['phone_number_detail'] as Map<String, dynamic>?;
    final offerDetail = json['offer_detail'] as Map<String, dynamic>?;

    return ContractListItem(
      id: json['id'],
      contractNumber: json['contract_number'] ?? '',
      status: json['status'] ?? 'draft',
      statusDisplay: json['status_display'] ?? 'Brouillon',
      customerFirstName: json['customer_first_name'] ?? '',
      customerLastName: json['customer_last_name'] ?? '',
      phoneNumber: phoneDetail?['formatted_number'] ?? phoneDetail?['number'] ?? '',
      offerName: offerDetail?['name'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

/// Agent statistics
class MyStats {
  final int total;
  final int today;
  final int thisMonth;
  final Map<String, int> byStatus;

  MyStats({
    required this.total,
    required this.today,
    required this.thisMonth,
    required this.byStatus,
  });

  factory MyStats.fromJson(Map<String, dynamic> json) {
    return MyStats(
      total: json['total'] ?? 0,
      today: json['today'] ?? 0,
      thisMonth: json['this_month'] ?? 0,
      byStatus: Map<String, int>.from(json['by_status'] ?? {}),
    );
  }
}

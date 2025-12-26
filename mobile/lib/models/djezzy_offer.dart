/// Djezzy offer model representing available mobile plans
class DjezzyOffer {
  final String id;
  final String name;
  final int price;
  final String currency;
  final int dataGB;
  final int validityDays;
  final List<String> features;

  const DjezzyOffer({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'DA',
    required this.dataGB,
    required this.validityDays,
    required this.features,
  });

  /// Format price with currency
  String get formattedPrice => '$price $currency';

  /// Format data allowance
  String get formattedData => '$dataGB Go';

  /// Format validity
  String get formattedValidity {
    if (validityDays == 1) return '1 jour';
    return '$validityDays jours';
  }

  /// Predefined Djezzy offers
  static const List<DjezzyOffer> offers = [
    DjezzyOffer(
      id: 'legend_1500',
      name: 'LEGEND 1500',
      price: 1500,
      dataGB: 50,
      validityDays: 30,
      features: [
        '50 Go Internet',
        'Appels illimités vers Djezzy',
        'SMS illimités',
      ],
    ),
    DjezzyOffer(
      id: 'legend_1000',
      name: 'LEGEND 1000',
      price: 1000,
      dataGB: 30,
      validityDays: 30,
      features: [
        '30 Go Internet',
        'Appels illimités vers Djezzy',
        'SMS illimités',
      ],
    ),
    DjezzyOffer(
      id: 'legend_150',
      name: 'LEGEND 150',
      price: 150,
      dataGB: 5,
      validityDays: 7,
      features: [
        '5 Go Internet',
        'Appels vers Djezzy',
        'SMS inclus',
      ],
    ),
    DjezzyOffer(
      id: 'legend_100',
      name: 'LEGEND 100',
      price: 100,
      dataGB: 3,
      validityDays: 3,
      features: [
        '3 Go Internet',
        'Appels vers Djezzy',
        'SMS inclus',
      ],
    ),
    DjezzyOffer(
      id: 'legend_50',
      name: 'LEGEND 50',
      price: 50,
      dataGB: 1,
      validityDays: 1,
      features: [
        '1 Go Internet',
        'Appels vers Djezzy',
        'SMS inclus',
      ],
    ),
  ];

  /// Available phone numbers (hardcoded for MVP)
  static const List<String> availablePhoneNumbers = [
    '0770123456',
    '0771234567',
    '0772345678',
    '0773456789',
    '0774567890',
  ];

  /// Format phone number for display (07 XX XX XX XX)
  static String formatPhoneNumber(String number) {
    if (number.length != 10) return number;
    return '${number.substring(0, 2)} ${number.substring(2, 4)} ${number.substring(4, 6)} ${number.substring(6, 8)} ${number.substring(8, 10)}';
  }
}

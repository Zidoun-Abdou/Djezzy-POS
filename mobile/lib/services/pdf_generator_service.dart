import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/contract_data.dart';
import '../config/api_config.dart';

class PDFGeneratorService {
  static Future<Uint8List> generateContract(ContractData contractData) async {
    final pdf = pw.Document();

    // Load Djezzy logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/djezzy_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Could not load logo: $e');
    }

    // Load Arabic font for RTL text
    pw.Font? arabicFont;
    try {
      final arabicFontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      arabicFont = pw.Font.ttf(arabicFontData);
    } catch (e) {
      print('Could not load Arabic font: $e');
    }

    // Load face image from base64
    pw.MemoryImage? faceImage;
    if (contractData.faceImageBase64 != null) {
      try {
        final faceBytes = base64Decode(contractData.faceImageBase64!);
        faceImage = pw.MemoryImage(faceBytes);
      } catch (e) {
        print('Could not decode face image: $e');
      }
    }

    // Get user data
    final userData = contractData.userData;
    final personal = userData?['personal'] as Map<String, dynamic>? ?? {};
    final document = userData?['document'] as Map<String, dynamic>? ?? {};

    // Debug print offer data
    final offer = contractData.selectedOffer;
    print('PDF Generator - Offer name: ${offer.name}');
    print('PDF Generator - Offer price: ${offer.formattedPrice}');
    print('PDF Generator - Phone: ${contractData.formattedPhoneNumber}');
    print('PDF Generator - Signature bytes: ${contractData.signatureImage?.length ?? 0}');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header with logo
            _buildHeader(logoImage, contractData),
            pw.SizedBox(height: 30),

            // Client Information Section with Face Photo
            _buildSectionTitle('INFORMATIONS CLIENT'),
            pw.SizedBox(height: 10),
            _buildClientInfoWithPhoto(personal, document, faceImage, arabicFont),
            pw.SizedBox(height: 15),

            // Contact Information Section
            _buildSectionTitle('COORDONNEES'),
            pw.SizedBox(height: 10),
            _buildContactInfoSection(contractData),
            pw.SizedBox(height: 25),

            // Offer Details Section
            _buildSectionTitle('OFFRE SELECTIONNEE'),
            pw.SizedBox(height: 10),
            _buildOfferTable(contractData),
            pw.SizedBox(height: 25),

            // Terms Section
            _buildSectionTitle('CONDITIONS GENERALES'),
            pw.SizedBox(height: 10),
            _buildTermsText(),
            pw.SizedBox(height: 30),

            // Signature Section
            _buildSignatureSection(contractData),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      pw.MemoryImage? logoImage, ContractData contractData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#ED1C24'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Image(logoImage, width: 120, height: 40)
              else
                pw.Text(
                  'DJEZZY',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              pw.SizedBox(height: 8),
              pw.Text(
                'CONTRAT D\'ABONNEMENT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'N: ${contractData.contractId}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Date: ${contractData.formattedDate}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#ED1C24'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildClientInfoWithPhoto(
      Map<String, dynamic> personal,
      Map<String, dynamic> document,
      pw.MemoryImage? faceImage,
      pw.Font? arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#CCCCCC')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Face Photo
          if (faceImage != null)
            pw.Container(
              width: 80,
              height: 100,
              margin: const pw.EdgeInsets.only(right: 16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#ED1C24'), width: 2),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.Image(faceImage, fit: pw.BoxFit.cover),
              ),
            )
          else
            pw.Container(
              width: 80,
              height: 100,
              margin: const pw.EdgeInsets.only(right: 16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F0F0F0'),
                border: pw.Border.all(color: PdfColor.fromHex('#CCCCCC')),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Photo',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ),
          // Client Info
          pw.Expanded(
            child: pw.Column(
              children: [
                _buildInfoRow('Nom', personal['lastName'] ?? '-'),
                _buildInfoRow('Prenom', personal['firstName'] ?? '-'),
                _buildInfoRowArabic('Nom (Arabe)', personal['lastNameAr'] ?? '-', arabicFont),
                _buildInfoRowArabic('Prenom (Arabe)', personal['firstNameAr'] ?? '-', arabicFont),
                pw.Divider(color: PdfColor.fromHex('#EEEEEE')),
                _buildInfoRow('Date de naissance', personal['birthDate'] ?? '-'),
                _buildInfoRow('Lieu de naissance', personal['birthPlace'] ?? '-'),
                _buildInfoRowArabic('Lieu de naissance (Arabe)', personal['birthPlaceAr'] ?? '-', arabicFont),
                _buildInfoRow('Sexe', personal['sex'] ?? '-'),
                _buildInfoRow('Groupe sanguin', personal['bloodType'] ?? '-'),
                pw.Divider(color: PdfColor.fromHex('#EEEEEE')),
                _buildInfoRow('N Carte d\'identite', document['idNumber'] ?? '-'),
                _buildInfoRow('NIN', personal['nin'] ?? '-'),
                _buildInfoRow('Daira', document['daira'] ?? '-'),
                _buildInfoRow('Baladia', document['baladia'] ?? '-'),
                _buildInfoRow('Date d\'expiration CNI', document['expiryDate'] ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#666666'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRowArabic(String label, String value, pw.Font? arabicFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#666666'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
                font: arabicFont,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildContactInfoSection(ContractData contractData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#CCCCCC')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildInfoRow('Telephone', contractData.customerPhone ?? '-'),
          _buildInfoRow('Email', contractData.customerEmail ?? '-'),
          _buildInfoRow('Adresse', contractData.customerAddress ?? '-'),
        ],
      ),
    );
  }

  static pw.Widget _buildOfferTable(ContractData contractData) {
    final offer = contractData.selectedOffer;
    final formattedNumber = contractData.formattedPhoneNumber;

    // Use fallbacks if data is empty
    final offerName = offer.name.isNotEmpty ? offer.name : 'Offre non specifiee';
    final offerPrice = offer.formattedPrice.isNotEmpty ? offer.formattedPrice : '${offer.price} DZD';
    final phoneNumber = formattedNumber.isNotEmpty ? formattedNumber : 'Non attribue';
    final dataInfo = offer.formattedData.isNotEmpty ? offer.formattedData : '${offer.dataAllowanceMb} Mo';
    final validityInfo = offer.formattedValidity.isNotEmpty ? offer.formattedValidity : '${offer.validityDays} jours';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF5F5'),
        border: pw.Border.all(color: PdfColor.fromHex('#ED1C24')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                offerName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#ED1C24'),
                ),
              ),
              pw.Text(
                offerPrice,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#ED1C24'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          _buildOfferInfoRow('Numero attribue', phoneNumber),
          _buildOfferInfoRow('Internet', dataInfo),
          _buildOfferInfoRow('Validite', validityInfo),
          if (offer.voiceMinutes > 0)
            _buildOfferInfoRow('Appels', '${offer.voiceMinutes} min'),
          if (offer.smsCount > 0)
            _buildOfferInfoRow('SMS', '${offer.smsCount} SMS'),
          if (offer.features.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColor.fromHex('#FFCCCC')),
            pw.SizedBox(height: 10),
            pw.Text(
              'Avantages inclus:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            ...offer.features.map((f) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 5,
                        height: 5,
                        margin: const pw.EdgeInsets.only(top: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#ED1C24'),
                          borderRadius: pw.BorderRadius.circular(2.5),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(f, style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildOfferInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTermsText() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'En signant ce contrat, le client accepte les conditions generales d\'utilisation '
        'des services Djezzy. Le client certifie que les informations fournies sont '
        'exactes et s\'engage a respecter les termes du contrat. Djezzy se reserve le '
        'droit de suspendre ou resilier le service en cas de non-respect des conditions. '
        'Pour toute reclamation, veuillez contacter le service client au 777.',
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey700,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  static pw.Widget _buildSignatureSection(ContractData contractData) {
    // Generate QR code URL for public PDF download
    final qrUrl = '${ApiConfig.baseUrl}/api/contracts/public/${contractData.contractId}/pdf/';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#CCCCCC')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SIGNATURE DU CLIENT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Signature image
              pw.Container(
                width: 160,
                height: 65,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#CCCCCC')),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.white,
                ),
                child: contractData.signatureImage != null
                    ? pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Image(
                          pw.MemoryImage(contractData.signatureImage!),
                          fit: pw.BoxFit.contain,
                        ),
                      )
                    : pw.Center(
                        child: pw.Text(
                          '[Signature]',
                          style: const pw.TextStyle(color: PdfColors.grey),
                        ),
                      ),
              ),
              pw.SizedBox(width: 15),
              // Customer info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      contractData.customerFullName.isNotEmpty
                          ? contractData.customerFullName
                          : 'Client',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: ${contractData.formattedDate}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E8F5E9'),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'Je confirme que c\'est ma carte d\'identite nationale',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.green800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              // QR Code
              pw.Column(
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrUrl,
                    width: 60,
                    height: 60,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Scanner pour\ntelecharger',
                    style: const pw.TextStyle(
                      fontSize: 6,
                      color: PdfColors.grey700,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/contract_data.dart';
import '../models/djezzy_offer.dart';

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

    // Get user data
    final userData = contractData.userData;
    final personal = userData?['personal'] as Map<String, dynamic>? ?? {};
    final document = userData?['document'] as Map<String, dynamic>? ?? {};

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo
              _buildHeader(logoImage, contractData),
              pw.SizedBox(height: 30),

              // Client Information Section
              _buildSectionTitle('INFORMATIONS CLIENT'),
              pw.SizedBox(height: 10),
              _buildClientInfoTable(personal, document),
              pw.SizedBox(height: 25),

              // Offer Details Section
              _buildSectionTitle('OFFRE SÉLECTIONNÉE'),
              pw.SizedBox(height: 10),
              _buildOfferTable(contractData),
              pw.SizedBox(height: 25),

              // Terms Section
              _buildSectionTitle('CONDITIONS GÉNÉRALES'),
              pw.SizedBox(height: 10),
              _buildTermsText(),
              pw.SizedBox(height: 30),

              // Signature Section
              _buildSignatureSection(contractData),
            ],
          );
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
                'N°: ${contractData.contractId}',
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
        color: PdfColor.fromHex('#1A1A2E'),
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

  static pw.Widget _buildClientInfoTable(
      Map<String, dynamic> personal, Map<String, dynamic> document) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#CCCCCC')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildInfoRow('Nom', personal['lastName'] ?? ''),
          _buildInfoRow('Prénom', personal['firstName'] ?? ''),
          _buildInfoRow('Nom (Arabe)', personal['lastNameAr'] ?? ''),
          _buildInfoRow('Prénom (Arabe)', personal['firstNameAr'] ?? ''),
          pw.Divider(color: PdfColor.fromHex('#EEEEEE')),
          _buildInfoRow('Date de naissance', personal['birthDate'] ?? ''),
          _buildInfoRow('Lieu de naissance', personal['birthPlace'] ?? ''),
          _buildInfoRow('Sexe', personal['sex'] ?? ''),
          _buildInfoRow('Groupe sanguin', personal['bloodType'] ?? ''),
          pw.Divider(color: PdfColor.fromHex('#EEEEEE')),
          _buildInfoRow('N° Carte d\'identité', document['idNumber'] ?? ''),
          _buildInfoRow('NIN', personal['nin'] ?? ''),
          _buildInfoRow('Daïra', document['daira'] ?? ''),
          _buildInfoRow('Baladia', document['baladia'] ?? ''),
          _buildInfoRow('Date d\'expiration CNI', document['expiryDate'] ?? ''),
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
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#666666'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOfferTable(ContractData contractData) {
    final offer = contractData.selectedOffer;
    final formattedNumber =
        DjezzyOffer.formatPhoneNumber(contractData.selectedPhoneNumber);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF5F5'),
        border: pw.Border.all(color: PdfColor.fromHex('#ED1C24')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                offer.name,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#ED1C24'),
                ),
              ),
              pw.Text(
                offer.formattedPrice,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#ED1C24'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _buildOfferInfoRow('Numéro attribué', formattedNumber),
          _buildOfferInfoRow('Internet', offer.formattedData),
          _buildOfferInfoRow('Validité', offer.formattedValidity),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColor.fromHex('#FFCCCC')),
          pw.SizedBox(height: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Avantages inclus:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              ...offer.features.map((f) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 6,
                          height: 6,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#ED1C24'),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(f, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOfferInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
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
        'En signant ce contrat, le client accepte les conditions générales d\'utilisation '
        'des services Djezzy. Le client certifie que les informations fournies sont '
        'exactes et s\'engage à respecter les termes du contrat. Djezzy se réserve le '
        'droit de suspendre ou résilier le service en cas de non-respect des conditions. '
        'Pour toute réclamation, veuillez contacter le service client au 777.',
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey700,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  static pw.Widget _buildSignatureSection(ContractData contractData) {
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
                width: 200,
                height: 80,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#EEEEEE')),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: contractData.signatureImage != null
                    ? pw.Image(
                        pw.MemoryImage(contractData.signatureImage!),
                        fit: pw.BoxFit.contain,
                      )
                    : pw.Center(
                        child: pw.Text(
                          '[Signature]',
                          style: const pw.TextStyle(color: PdfColors.grey),
                        ),
                      ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      contractData.customerFullName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: ${contractData.formattedDate}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E8F5E9'),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        '✓ Je confirme que c\'est ma carte d\'identité nationale',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.green800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

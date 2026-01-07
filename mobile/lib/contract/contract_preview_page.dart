import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../models/contract_data.dart';
import '../services/pdf_generator_service.dart';
import '../services/api_service.dart';
import 'offer_selection_page.dart';

class ContractPreviewPage extends StatefulWidget {
  final ContractData contractData;
  final List<CameraDescription> cameras;

  const ContractPreviewPage({
    super.key,
    required this.contractData,
    required this.cameras,
  });

  @override
  State<ContractPreviewPage> createState() => _ContractPreviewPageState();
}

class _ContractPreviewPageState extends State<ContractPreviewPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final ApiService _apiService = ApiService();

  Uint8List? _pdfBytes;
  bool _isGenerating = true;
  String? _error;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _serverContractNumber;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _generatePdf();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    try {
      final pdfBytes =
          await PDFGeneratorService.generateContract(widget.contractData);
      if (mounted) {
        setState(() {
          _pdfBytes = pdfBytes;
          _isGenerating = false;
        });
        _fadeController.forward();

        // Submit contract to backend after PDF is ready
        _submitContractToServer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _submitContractToServer() async {
    if (_isSubmitting || _isSubmitted) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get signature as base64
      String? signatureBase64;
      if (widget.contractData.signatureImage != null) {
        signatureBase64 = base64Encode(widget.contractData.signatureImage!);
      }

      // Get face image (already base64 from NFC)
      final photoBase64 = widget.contractData.faceImageBase64;

      // Get PDF as base64
      String? pdfBase64;
      if (_pdfBytes != null) {
        pdfBase64 = base64Encode(_pdfBytes!);
      }

      final result = await _apiService.submitContract(
        offerId: widget.contractData.selectedOffer.id,
        phoneNumberId: widget.contractData.selectedPhoneNumber.id,
        customerData: widget.contractData.userData ?? {},
        signatureBase64: signatureBase64,
        photoBase64: photoBase64,
        customerPhone: widget.contractData.customerPhone,
        customerEmail: widget.contractData.customerEmail,
        customerAddress: widget.contractData.customerAddress,
        pdfBase64: pdfBase64,
        contractId: widget.contractData.contractId,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = result.success;
          _serverContractNumber = result.contractNumber;
        });

        if (!result.success) {
          // Show error snackbar but don't block the flow
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Erreur de synchronisation'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: _submitContractToServer,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;

    await Printing.sharePdf(
      bytes: _pdfBytes!,
      filename: 'contrat_djezzy_${widget.contractData.contractId}.pdf',
    );
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => _pdfBytes!,
    );
  }

  void _startNewContract() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OfferSelectionPage(cameras: widget.cameras),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contrat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share),
              tooltip: 'Partager',
            ),
            IconButton(
              onPressed: _printPdf,
              icon: const Icon(Icons.print),
              tooltip: 'Imprimer',
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _isGenerating
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : _buildPdfPreview(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated document icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFED1C24).withOpacity(0.3),
                        const Color(0xFFC41820).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Color(0xFFED1C24),
                    size: 50,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFED1C24)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Génération du contrat...',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez patienter',
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erreur de génération',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Une erreur est survenue',
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isGenerating = true;
                  _error = null;
                });
                _generatePdf();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED1C24),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Contract info header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFED1C24).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFED1C24).withOpacity(0.3),
                        const Color(0xFFC41820).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.article,
                    color: Color(0xFFED1C24),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contrat d\'abonnement',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'N° ${widget.contractData.contractId}',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isSubmitting
                        ? Colors.orange.withOpacity(0.2)
                        : _isSubmitted
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        )
                      else
                        Icon(
                          _isSubmitted ? Icons.cloud_done : Icons.cloud_upload,
                          color: _isSubmitted ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _isSubmitting
                            ? 'Sync...'
                            : _isSubmitted
                                ? 'Synchro'
                                : 'En attente',
                        style: TextStyle(
                          color: _isSubmitting
                              ? Colors.orange
                              : _isSubmitted
                                  ? Colors.green
                                  : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PDF Preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PdfPreview(
                  build: (format) async => _pdfBytes!,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName:
                      'contrat_djezzy_${widget.contractData.contractId}.pdf',
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFED1C24)),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Quick actions row
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.share,
                        label: 'Partager',
                        onTap: _sharePdf,
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.print,
                        label: 'Imprimer',
                        onTap: _printPdf,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // New contract button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFED1C24), Color(0xFFC41820)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFED1C24).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _startNewContract,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(
                      'Nouveau contrat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFFED1C24)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : const Color(0xFFED1C24).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFFED1C24),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:signature/signature.dart';
import '../models/contract_data.dart';
import 'contract_preview_page.dart';

class SignaturePage extends StatefulWidget {
  final ContractData contractData;
  final List<CameraDescription> cameras;

  const SignaturePage({
    super.key,
    required this.contractData,
    required this.cameras,
  });

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage>
    with TickerProviderStateMixin {
  late SignatureController _signatureController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isConfirmed = false;
  bool _hasSigned = false;

  @override
  void initState() {
    super.initState();

    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
      exportPenColor: Colors.black,
      onDrawStart: () {
        setState(() {
          _hasSigned = true;
        });
      },
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _hasSigned = false;
    });
  }

  bool get _canProceed => _hasSigned && _isConfirmed;

  Future<void> _proceedToContract() async {
    if (!_canProceed) return;

    // Export signature as PNG bytes
    final signatureBytes = await _signatureController.toPngBytes();

    if (signatureBytes != null) {
      final updatedContractData = widget.contractData.copyWith(
        signatureImage: signatureBytes,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ContractPreviewPage(
              contractData: updatedContractData,
              cameras: widget.cameras,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Signature'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Info Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFED1C24).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Photo
                      if (widget.contractData.faceImageBase64 != null)
                        Container(
                          width: 60,
                          height: 70,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFED1C24).withOpacity(0.2),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(
                                  widget.contractData.faceImageBase64!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.contractData.customerFullName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CNI: ${widget.contractData.idCardNumber}',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'NIN: ${widget.contractData.customerNIN}',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Signature Section Title
                Row(
                  children: [
                    const Icon(
                      Icons.draw,
                      color: Color(0xFFED1C24),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Signez ci-dessous',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_hasSigned)
                      TextButton.icon(
                        onPressed: _clearSignature,
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: Color(0xFFFF6B6B),
                        ),
                        label: const Text(
                          'Effacer',
                          style: TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Signature Pad
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasSigned
                            ? const Color(0xFFED1C24)
                            : Colors.grey.withOpacity(0.3),
                        width: _hasSigned ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.white,
                          ),
                          if (!_hasSigned)
                            Center(
                              child: Text(
                                'Signez ici',
                                style: TextStyle(
                                  color: Colors.grey.withOpacity(0.3),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Confirmation Checkbox
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isConfirmed = !_isConfirmed;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isConfirmed
                          ? const Color(0xFFED1C24).withOpacity(0.1)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isConfirmed
                            ? const Color(0xFFED1C24)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isConfirmed
                                  ? const Color(0xFFED1C24)
                                  : Colors.black.withOpacity(0.3),
                              width: 2,
                            ),
                            color: _isConfirmed
                                ? const Color(0xFFED1C24)
                                : Colors.transparent,
                          ),
                          child: _isConfirmed
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Je confirme que c\'est ma carte d\'identité nationale',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Continue Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: _canProceed
                        ? const LinearGradient(
                            colors: [Color(0xFFED1C24), Color(0xFFC41820)],
                          )
                        : null,
                    color: _canProceed ? null : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _canProceed
                        ? [
                            BoxShadow(
                              color: const Color(0xFFED1C24).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _canProceed ? _proceedToContract : null,
                    icon: const Icon(Icons.article),
                    label: const Text(
                      'Générer le contrat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white54,
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
        ),
      ),
    );
  }
}

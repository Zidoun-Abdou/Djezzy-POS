import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/djezzy_offer.dart';
import '../models/contract_data.dart';
import 'scan_intro_page.dart';

class NumberSelectionPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final DjezzyOffer selectedOffer;

  const NumberSelectionPage({
    super.key,
    required this.cameras,
    required this.selectedOffer,
  });

  @override
  State<NumberSelectionPage> createState() => _NumberSelectionPageState();
}

class _NumberSelectionPageState extends State<NumberSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  String? _selectedNumber;

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

    _cardControllers = List.generate(
      DjezzyOffer.availablePhoneNumbers.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 80)),
        vsync: this,
      ),
    );

    _cardAnimations = _cardControllers
        .map((controller) => CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            ))
        .toList();

    _fadeController.forward();
    for (var controller in _cardControllers) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectNumber(String number) {
    setState(() {
      _selectedNumber = number;
    });
  }

  void _continueToScan() {
    if (_selectedNumber == null) return;

    final contractData = ContractData(
      selectedOffer: widget.selectedOffer,
      selectedPhoneNumber: _selectedNumber!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanIntroPage(
          cameras: widget.cameras,
          contractData: contractData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choisir un numéro'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Selected Offer Summary
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFED1C24), Color(0xFFC41820)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFED1C24).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedOffer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.selectedOffer.formattedData} - ${widget.selectedOffer.formattedValidity}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      widget.selectedOffer.formattedPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_android,
                      color: Color(0xFFED1C24),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Numéros disponibles',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Phone Numbers List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: DjezzyOffer.availablePhoneNumbers.length,
                  itemBuilder: (context, index) {
                    final number = DjezzyOffer.availablePhoneNumbers[index];
                    final isSelected = _selectedNumber == number;
                    final formattedNumber =
                        DjezzyOffer.formatPhoneNumber(number);

                    return ScaleTransition(
                      scale: _cardAnimations[index],
                      child: GestureDetector(
                        onTap: () => _selectNumber(number),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xFFED1C24).withOpacity(0.1),
                                      const Color(0xFFC41820).withOpacity(0.05),
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFED1C24)
                                  : Colors.black.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Phone Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFED1C24),
                                            Color(0xFFC41820)
                                          ],
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : const Color(0xFFED1C24)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.sim_card,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFED1C24),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Phone Number
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formattedNumber,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 20,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Djezzy',
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.4),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection Radio
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFED1C24)
                                        : Colors.black.withOpacity(0.2),
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? const Color(0xFFED1C24)
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: _selectedNumber != null
                        ? const LinearGradient(
                            colors: [Color(0xFFED1C24), Color(0xFFC41820)],
                          )
                        : null,
                    color: _selectedNumber != null
                        ? null
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedNumber != null
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFFED1C24).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed:
                        _selectedNumber != null ? _continueToScan : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

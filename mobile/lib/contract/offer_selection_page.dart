import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../auth/login_page.dart';
import 'number_selection_page.dart';

class OfferSelectionPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const OfferSelectionPage({
    super.key,
    required this.cameras,
  });

  @override
  State<OfferSelectionPage> createState() => _OfferSelectionPageState();
}

class _OfferSelectionPageState extends State<OfferSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  List<AnimationController> _cardControllers = [];
  List<Animation<double>> _cardAnimations = [];

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<OfferData> _offers = [];
  OfferData? _selectedOffer;
  bool _isLoading = true;
  String? _errorMessage;

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

    _fadeController.forward();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final offers = await _apiService.fetchActiveOffers();
      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoading = false;
        });
        _initializeCardAnimations();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement des offres';
          _isLoading = false;
        });
      }
    }
  }

  void _initializeCardAnimations() {
    // Dispose old controllers
    for (var controller in _cardControllers) {
      controller.dispose();
    }

    _cardControllers = List.generate(
      _offers.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _cardAnimations = _cardControllers
        .map((controller) => CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            ))
        .toList();

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

  void _selectOffer(OfferData offer) {
    setState(() {
      _selectedOffer = offer;
    });
  }

  void _continueToNumberSelection() {
    if (_selectedOffer == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NumberSelectionPage(
          cameras: widget.cameras,
          selectedOffer: _selectedOffer!,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deconnexion'),
        content: const Text('Voulez-vous vraiment vous deconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginPage(cameras: widget.cameras),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFED1C24),
                                    Color(0xFFFF6B6B)
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Djezzy POS',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choisissez une offre',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          color: Colors.black54,
                          tooltip: 'Deconnexion',
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFED1C24), Color(0xFFFF6B6B)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.sim_card,
                              color: Color(0xFFED1C24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFED1C24),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadOffers,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reessayer'),
                                ),
                              ],
                            ),
                          )
                        : _offers.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucune offre disponible',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _offers.length,
                                itemBuilder: (context, index) {
                                  final offer = _offers[index];
                                  final isSelected =
                                      _selectedOffer?.id == offer.id;

                                  return ScaleTransition(
                                    scale: index < _cardAnimations.length
                                        ? _cardAnimations[index]
                                        : const AlwaysStoppedAnimation(1.0),
                                    child: GestureDetector(
                                      onTap: () => _selectOffer(offer),
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
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
                                              : const Color(0xFFF5F5F5),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.transparent
                                                : const Color(0xFFED1C24)
                                                    .withOpacity(0.2),
                                            width: 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFFED1C24)
                                                            .withOpacity(0.4),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            children: [
                                              // Offer Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            offer.name,
                                                            style: TextStyle(
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black87,
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: isSelected
                                                                ? Colors.white
                                                                    .withOpacity(
                                                                        0.2)
                                                                : const Color(
                                                                        0xFFED1C24)
                                                                    .withOpacity(
                                                                        0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Text(
                                                            '${offer.availableCount} numeros',
                                                            style: TextStyle(
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFFED1C24),
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${offer.formattedData} - ${offer.formattedValidity}',
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? Colors.white
                                                                .withOpacity(
                                                                    0.8)
                                                            : Colors.black
                                                                .withOpacity(
                                                                    0.6),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (offer.features
                                                        .isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 8,
                                                        children: offer.features
                                                            .take(2)
                                                            .map((f) =>
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 2,
                                                                  ),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: isSelected
                                                                        ? Colors
                                                                            .white
                                                                            .withOpacity(
                                                                                0.2)
                                                                        : const Color(0xFFED1C24)
                                                                            .withOpacity(0.1),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8),
                                                                  ),
                                                                  child: Text(
                                                                    f,
                                                                    style:
                                                                        TextStyle(
                                                                      color: isSelected
                                                                          ? Colors.white.withOpacity(
                                                                              0.9)
                                                                          : const Color(
                                                                              0xFFED1C24),
                                                                      fontSize:
                                                                          10,
                                                                    ),
                                                                  ),
                                                                ))
                                                            .toList(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),

                                              // Price
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${offer.price.toInt()}',
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFFED1C24),
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    offer.currency,
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                              .withOpacity(0.7)
                                                          : Colors.black
                                                              .withOpacity(0.5),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Selection Indicator
                                              const SizedBox(width: 12),
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.black
                                                            .withOpacity(0.2),
                                                    width: 2,
                                                  ),
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                ),
                                                child: isSelected
                                                    ? const Icon(
                                                        Icons.check,
                                                        color:
                                                            Color(0xFFED1C24),
                                                        size: 16,
                                                      )
                                                    : null,
                                              ),
                                            ],
                                          ),
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
                    gradient: _selectedOffer != null
                        ? const LinearGradient(
                            colors: [Color(0xFFED1C24), Color(0xFFC41820)],
                          )
                        : null,
                    color: _selectedOffer != null
                        ? null
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedOffer != null
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
                    onPressed: _selectedOffer != null
                        ? _continueToNumberSelection
                        : null,
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

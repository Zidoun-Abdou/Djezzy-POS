import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../idcard/mrz_scanner_page.dart';
import '../idcard/user_profile_page.dart';
import '../services/id_card_service.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage({
    super.key,
    required this.cameras,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();

    // Main fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Card animations - only 1 card now
    _cardControllers = List.generate(1, (index) =>
        AnimationController(
          duration: Duration(milliseconds: 600 + (index * 100)),
          vsync: this,
        )
    );

    _cardAnimations = _cardControllers.map((controller) =>
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        )
    ).toList();

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

  Future<void> _navigateToFeature() async {
    // ID Card - Check if user has saved data
    final isVerified = await IDCardService.isUserVerified();
    final userData = await IDCardService.getUserData();

    if (isVerified && userData != null && mounted) {
      // Show user profile page with all their info
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfilePage(
            userData: userData,
            cameras: widget.cameras,
          ),
        ),
      );
    } else if (mounted) {
      // Start MRZ scanning process
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MrzScannerPage(cameras: widget.cameras),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Carte d\'Identité',
        'subtitle': 'Scanner et lire votre CNI',
        'icon': '🆔',
        'gradient': const [Color(0xFFED1C24), Color(0xFFC41820)],
        'enabled': true,
      },
    ];

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFFED1C24), Color(0xFFFF6B6B)],
                                ).createShader(bounds),
                                child: const Text(
                                  'Djezzy POS',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Votre identité numérique sécurisée',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                              Icons.fingerprint,
                              color: Color(0xFFED1C24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Feature Grid
                      Expanded(
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: features.length,
                          itemBuilder: (context, index) {
                            final feature = features[index];
                            final isEnabled = feature['enabled'] as bool;
                            final gradient = feature['gradient'] as List<Color>;

                            return ScaleTransition(
                              scale: _cardAnimations[index],
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _navigateToFeature(),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isEnabled
                                            ? gradient
                                            : [
                                          Colors.grey[300]!,
                                          Colors.grey[400]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isEnabled
                                              ? gradient[0].withOpacity(0.3)
                                              : Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Background pattern
                                        Positioned(
                                          right: -20,
                                          bottom: -20,
                                          child: Icon(
                                            Icons.circle,
                                            size: 100,
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        // Content
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    feature['icon'] as String,
                                                    style: const TextStyle(fontSize: 40),
                                                  ),
                                                  if (index == 0)
                                                    FutureBuilder<bool>(
                                                      future: IDCardService.isUserVerified(),
                                                      builder: (context, snapshot) {
                                                        if (snapshot.data == true) {
                                                          return Container(
                                                            padding: const EdgeInsets.all(6),
                                                            decoration: const BoxDecoration(
                                                              color: Color(0xFFED1C24),
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: const Icon(
                                                              Icons.check,
                                                              color: Colors.white,
                                                              size: 16,
                                                            ),
                                                          );
                                                        }
                                                        return const SizedBox();
                                                      },
                                                    ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    feature['title'] as String,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    feature['subtitle'] as String,
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.9),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Lock icon for disabled features
                                        if (!isEnabled)
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.3),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.lock,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
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

                      const SizedBox(height: 20),

                      // Bottom info card
                      Container(
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFED1C24), Color(0xFFC41820)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sécurité garantie',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Vos données sont protégées et chiffrées',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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

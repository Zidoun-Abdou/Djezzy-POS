import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import '../services/id_card_service.dart';
import 'mrz_scanner_page.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<CameraDescription> cameras;

  const UserProfilePage({
    super.key,
    required this.userData,
    required this.cameras,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateIDCard() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mettre à jour', style: TextStyle(color: Colors.black87)),
        content: Text(
          'Voulez-vous rescanner votre carte d\'identité?',
          style: TextStyle(color: Colors.black.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.black.withOpacity(0.7))),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFED1C24), Color(0xFFC41820)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                // Clear old data and restart scanning process
                await IDCardService.clearUserData();

                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MrzScannerPage(cameras: widget.cameras),
                    ),
                  );
                }
              },
              child: const Text('Scanner', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    if (value.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFED1C24).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFED1C24).withOpacity(0.2),
                  const Color(0xFFFF6B6B).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFED1C24), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTab() {
    final personal = widget.userData['personal'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFED1C24), Color(0xFFC41820)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.person, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Informations Personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoTile('Prénom', personal['firstName'] ?? '', Icons.person_outline),
          _buildInfoTile('Nom', personal['lastName'] ?? '', Icons.person_outline),
          _buildInfoTile('Prénom (Arabe)', personal['firstNameAr'] ?? '', Icons.translate),
          _buildInfoTile('Nom (Arabe)', personal['lastNameAr'] ?? '', Icons.translate),
          _buildInfoTile('Date de naissance', personal['birthDate'] ?? '', Icons.cake),
          _buildInfoTile('Lieu de naissance', personal['birthPlace'] ?? '', Icons.location_on),
          _buildInfoTile('Lieu de naissance (Arabe)', personal['birthPlaceAr'] ?? '', Icons.location_on),
          _buildInfoTile('Sexe', personal['sex'] ?? '', Icons.wc),
          _buildInfoTile('Groupe sanguin', personal['bloodType'] ?? '', Icons.bloodtype),
          _buildInfoTile('NIN', personal['nin'] ?? '', Icons.fingerprint),
        ],
      ),
    );
  }

  Widget _buildDocumentTab() {
    final document = widget.userData['document'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.credit_card, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Informations du Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoTile('Numéro de carte', document['idNumber'] ?? '', Icons.numbers),
          _buildInfoTile('Daïra', document['daira'] ?? '', Icons.business),
          _buildInfoTile('Baladia', document['baladia'] ?? '', Icons.location_city),
          _buildInfoTile('Baladia (Arabe)', document['baladiaAr'] ?? '', Icons.location_city),
          _buildInfoTile('Date d\'émission', document['issueDate'] ?? '', Icons.calendar_today),
          _buildInfoTile('Date d\'expiration', document['expiryDate'] ?? '', Icons.event),

          // Check if card is expired or expiring soon
          if (document['expiryDate'] != null && document['expiryDate'].toString().isNotEmpty)
            _buildExpiryWarning(document['expiryDate'].toString()),
        ],
      ),
    );
  }

  Widget _buildExpiryWarning(String expiryDate) {
    try {
      // Parse date in various formats
      DateTime? expiry;
      if (expiryDate.contains('/')) {
        final parts = expiryDate.split('/');
        if (parts.length == 3) {
          // Check if it's YYYY/MM/DD or MM/DD/YYYY or DD/MM/YYYY
          int year, month, day;

          // Check if first part is year (4 digits)
          if (parts[0].length == 4) {
            // YYYY/MM/DD format
            year = int.parse(parts[0]);
            month = int.parse(parts[1]);
            day = int.parse(parts[2]);
          } else if (parts[2].length == 4) {
            // Could be MM/DD/YYYY or DD/MM/YYYY
            year = int.parse(parts[2]);
            // Assume MM/DD/YYYY for US format (from MRZ scanner)
            month = int.parse(parts[0]);
            day = int.parse(parts[1]);
          } else {
            return const SizedBox();
          }

          expiry = DateTime(year, month, day);
        }
      } else if (expiryDate.contains('-')) {
        // YYYY-MM-DD format
        expiry = DateTime.parse(expiryDate);
      }

      if (expiry != null) {
        final now = DateTime.now();
        final difference = expiry.difference(now).inDays;

        if (difference < 0) {
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF6B6B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Color(0xFFFF6B6B)),
                const SizedBox(width: 12),
                const Text(
                  'Carte expirée',
                  style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        } else if (difference < 90) {
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Expire dans $difference jours',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Error parsing expiry date: $e');
    }

    return const SizedBox();
  }

  Widget _buildBiometricTab() {
    final biometric = widget.userData['biometric'] as Map<String, dynamic>? ?? {};
    final verification = widget.userData['verification'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verification Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFED1C24), Color(0xFFC41820)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.verified_user, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Identité Vérifiée',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (verification['confidence'] != null) ...[
                  const SizedBox(height: 8),

                ],
                if (verification['verificationDate'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Vérifié le: ${_formatDate(verification['verificationDate'])}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Face Image
          if (biometric['faceImage'] != null && biometric['faceImage'].toString().isNotEmpty)
            Card(
              color: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.face, color: Color(0xFFED1C24)),
                        SizedBox(width: 12),
                        Text(
                          'Photo d\'identité',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFED1C24).withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImageFromBase64(biometric['faceImage'] as String),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Signature
          if (biometric['signature'] != null && biometric['signature'].toString().isNotEmpty)
            Card(
              color: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.draw, color: Color(0xFFED1C24)),
                        SizedBox(width: 12),
                        Text(
                          'Signature',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 150, maxWidth: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFED1C24).withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImageFromBase64(biometric['signature'] as String),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Erreur d\'affichage',
              style: TextStyle(color: Colors.black.withOpacity(0.5)),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Image non disponible',
          style: TextStyle(color: Colors.black.withOpacity(0.5)),
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final personal = widget.userData['personal'] as Map<String, dynamic>? ?? {};
    final fullName = '${personal['firstName'] ?? ''} ${personal['lastName'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFFED1C24)),
                        onPressed: _updateIDCard,
                        tooltip: 'Mettre à jour',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Profile Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFED1C24), Color(0xFFC41820)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFED1C24).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName.isNotEmpty ? fullName : 'Utilisateur',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (personal['nin'] != null && personal['nin'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED1C24).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NIN: ${personal['nin']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFFED1C24),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFED1C24),
                indicatorWeight: 3,
                labelColor: const Color(0xFFED1C24),
                unselectedLabelColor: Colors.black.withOpacity(0.5),
                tabs: const [
                  Tab(text: 'Personnel', icon: Icon(Icons.person, size: 18)),
                  Tab(text: 'Document', icon: Icon(Icons.credit_card, size: 18)),
                  Tab(text: 'Biométrie', icon: Icon(Icons.fingerprint, size: 18)),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalTab(),
                  _buildDocumentTab(),
                  _buildBiometricTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

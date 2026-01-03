import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dmrtd/dmrtd.dart';
import 'package:dmrtd/extensions.dart';
import 'package:logging/logging.dart';
import 'package:camera/camera.dart';
import '../services/id_card_service.dart';
import '../services/datagroup_decoder.dart';
import '../models/contract_data.dart';
import '../contract/signature_page.dart';
import 'user_profile_page.dart';

class MrtdData {
  EfDG2? dg2;
  EfDG7? dg7;
  EfDG11? dg11;
  EfDG12? dg12;
}

class ReadNfcPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String idNumber;
  final String dob;
  final String doe;
  final ContractData? contractData;

  const ReadNfcPage({
    super.key,
    required this.cameras,
    required this.idNumber,
    required this.dob,
    required this.doe,
    this.contractData,
  });

  @override
  State<ReadNfcPage> createState() => _ReadNfcPageState();
}

class _ReadNfcPageState extends State<ReadNfcPage> with SingleTickerProviderStateMixin {
  final _log = Logger('djezzypos.nfc');
  final _nfc = NfcProvider();
  bool _reading = false;
  String _status = '';
  MrtdData? _data;
  Map<String, dynamic>? _decoded;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkNfcAndScan() async {
    final status = await NfcProvider.nfcStatus;
    if (status != NfcStatus.enabled && mounted) {
      setState(() => _status = '⚠️ NFC est désactivé. Veuillez l\'activer et réessayer.');
      return;
    }
    await _readMRTD();
  }

  Future<void> _readMRTD() async {
    setState(() {
      _reading = true;
      _status = '📱 Approchez la carte d\'identité du téléphone…';
      _data = null;
      _decoded = null;
    });

    try {
      await _nfc.connect();
      final passport = Passport(_nfc);

      setState(() => _status = '🔐 Démarrage de la session sécurisée…');

      final dob = DateTime.parse(widget.dob);
      final doe = DateTime.parse(widget.doe);
      final bac = DBAKeys(widget.idNumber, dob, doe);

      await passport.startSession(bac);

      final out = MrtdData();

      Future<T?> tryRead<T>(Future<T> Function() reader) async {
        try {
          return await reader();
        } catch (e) {
          _log.warning('Erreur lors de la lecture du groupe de données: $e');
          return null;
        }
      }

      setState(() => _status = '📖 Lecture des groupes de données…');

      out.dg2 = await tryRead(() => passport.readEfDG2());
      out.dg7 = await tryRead(() => passport.readEfDG7());
      out.dg11 = await tryRead(() => passport.readEfDG11());
      out.dg12 = await tryRead(() => passport.readEfDG12());

      setState(() {
        _data = out;
        _status = '✅ Terminé. Décodage des données…';
      });

      await _decodeLocally();

    } catch (e, st) {
      _log.warning('Échec de la lecture: $e\n$st');
      setState(() {
        _status = '❌ Erreur de lecture: ${e.toString()}';
      });
    } finally {
      try {
        await _nfc.disconnect(iosAlertMessage: 'Terminé');
      } catch (_) {}
      setState(() {
        _reading = false;
      });
    }
  }

  Future<void> _decodeLocally() async {
    if (_data == null) return;

    setState(() {
      _status = '🔄 Décodage des données localement…';
    });

    Uint8List? getBytes(dynamic dg) {
      try {
        if (dg == null) return null;
        return (dg as dynamic).toBytes() as Uint8List;
      } catch (e) {
        _log.warning('Erreur de conversion DG en bytes: $e');
        return null;
      }
    }

    try {
      // Decode locally using DatagroupDecoder
      final data = DatagroupDecoder.decodeAll(
        dg2Bytes: getBytes(_data!.dg2),
        dg7Bytes: getBytes(_data!.dg7),
        dg11Bytes: getBytes(_data!.dg11),
        dg12Bytes: getBytes(_data!.dg12),
      );

      // Save NFC data to persistent storage
      await IDCardService.saveNFCData(data);

      // Mark as verified (1.0 confidence for NFC verification)
      await IDCardService.markAsVerified(1.0);

      setState(() {
        _decoded = data;
        _status = '✅ Décodé avec succès!';
      });

      // Get the saved user data and navigate appropriately
      final userData = await IDCardService.getUserData();
      if (mounted && userData != null) {
        // If contract flow, navigate to SignaturePage
        if (widget.contractData != null) {
          final updatedContractData = widget.contractData!.copyWith(
            userData: userData,
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SignaturePage(
                contractData: updatedContractData,
                cameras: widget.cameras,
              ),
            ),
          );
        } else {
          // Standard flow: navigate to UserProfilePage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => UserProfilePage(
                userData: userData,
                cameras: widget.cameras,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _status = '❌ Erreur de décodage: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lecture NFC'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NFC Animation and Status
            if (!(_data != null && _decoded != null)) ...[
              const SizedBox(height: 20),
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _reading ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: _reading
                              ? const LinearGradient(
                            colors: [Color(0xFFED1C24), Color(0xFFC41820)],
                          )
                              : null,
                          color: _reading ? null : Colors.grey.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: _reading ? [
                            BoxShadow(
                              color: const Color(0xFFED1C24).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ] : [],
                        ),
                        child: Icon(
                          Icons.nfc,
                          size: 60,
                          color: _reading ? Colors.white : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _reading
                      ? const Color(0xFFED1C24).withOpacity(0.1)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _reading
                        ? const Color(0xFFED1C24).withOpacity(0.5)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  _status.isEmpty ? 'Prêt à scanner' : _status,
                  style: TextStyle(
                    fontSize: 14,
                    color: _reading ? Colors.black87 : Colors.black.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Start/Restart Button
            Container(
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
                onPressed: _reading ? null : _checkNfcAndScan,
                icon: Icon(_reading ? Icons.hourglass_empty : Icons.nfc),
                label: Text(_reading ? 'Lecture en cours…' : 'Commencer la lecture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Results
            Expanded(
              child: ListView(
                children: [
                  if (_data != null) ...[
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
                                Icon(Icons.storage, color: Color(0xFFED1C24)),
                                SizedBox(width: 12),
                                Text(
                                  'Données brutes lues',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _dgTile('DG2 - Image du visage', _data!.dg2),
                            _dgTile('DG7 - Signature', _data!.dg7),
                            _dgTile('DG11 - Données personnelles', _data!.dg11),
                            _dgTile('DG12 - Données du document', _data!.dg12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_decoded != null) ...[
                    _decodedSection(_decoded!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dgTile(String name, Object? dg) {
    final ok = dg != null;
    int? len;
    if (ok) {
      try {
        len = ((dg as dynamic).toBytes() as Uint8List).length;
      } catch (_) {}
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? const Color(0xFFED1C24) : const Color(0xFFFF6B6B),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: Colors.black.withOpacity(0.9)),
            ),
          ),
          if (ok && len != null)
            Text(
              '$len octets',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _decodedSection(Map<String, dynamic> data) {
    List<Widget> tiles = [];

    // DG11 Personal Data
    final dg11 = data['dg11'] as Map<String, dynamic>?;
    if (dg11 != null && dg11['result'] == 'True') {
      tiles.add(Card(
        color: const Color(0xFFF5F5F5),
        elevation: 2,
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
                  Icon(Icons.person, color: Color(0xFFED1C24)),
                  SizedBox(width: 12),
                  Text(
                    'Informations personnelles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('👤 Prénom (Latin)', dg11['name_latin'] ?? ''),
              _infoRow('👤 Prénom (Arabe)', dg11['name_arabic'] ?? ''),
              _infoRow('👥 Nom (Latin)', dg11['surname_latin'] ?? ''),
              _infoRow('👥 Nom (Arabe)', dg11['surname_arabic'] ?? ''),
              _infoRow('🎂 Date de naissance', dg11['birth_date'] ?? ''),
              _infoRow('📍 Lieu de naissance (Latin)', dg11['birthplace_latin'] ?? ''),
              _infoRow('📍 Lieu de naissance (Arabe)', dg11['birthplace_arabic'] ?? ''),
              _infoRow('⚧ Sexe', dg11['sex_latin'] ?? ''),
              _infoRow('🩸 Groupe sanguin', dg11['blood_type'] ?? ''),
              _infoRow('🆔 NIN', dg11['nin'] ?? ''),
            ],
          ),
        ),
      ));
    }

    // DG12 Document Data
    final dg12 = data['dg12'] as Map<String, dynamic>?;
    if (dg12 != null && dg12['result'] == 'True') {
      tiles.add(Card(
        color: const Color(0xFFF5F5F5),
        elevation: 2,
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
                  Icon(Icons.credit_card, color: Color(0xFFED1C24)),
                  SizedBox(width: 12),
                  Text(
                    'Informations du document',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('🏛 Daïra', dg12['daira'] ?? ''),
              _infoRow('🏘 Baladia (Latin)', dg12['baladia_latin'] ?? ''),
              _infoRow('🏘 Baladia (Arabe)', dg12['baladia_arabic'] ?? ''),
              _infoRow('📅 Date d\'émission', dg12['delivery_date'] ?? ''),
              _infoRow('⏰ Date d\'expiration', dg12['expiry_date'] ?? ''),
            ],
          ),
        ),
      ));
    }

    // DG2 Face Image
    final dg2 = data['dg2'] as Map<String, dynamic>?;
    if (dg2 != null && dg2['result'] == 'True') {
      tiles.add(Card(
        color: const Color(0xFFF5F5F5),
        elevation: 2,
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
                  Icon(Icons.photo_camera, color: Color(0xFFED1C24)),
                  SizedBox(width: 12),
                  Text(
                    'Photo d\'identité',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildImageFromBase64(dg2['face'] as String?, 'Photo d\'identité'),
            ],
          ),
        ),
      ));
    }

    // DG7 Signature
    final dg7 = data['dg7'] as Map<String, dynamic>?;
    if (dg7 != null && dg7['result'] == 'True') {
      tiles.add(Card(
        color: const Color(0xFFF5F5F5),
        elevation: 2,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildImageFromBase64(dg7['signature'] as String?, 'Signature'),
            ],
          ),
        ),
      ));
    }

    return Column(children: tiles);
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String? base64String, String fallbackText) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        final bytes = base64Decode(base64String);
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFED1C24).withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Erreur d\'affichage de $fallbackText',
                      style: TextStyle(color: Colors.black.withOpacity(0.5)),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      } catch (e) {
        return Text(
          'Erreur de décodage de $fallbackText: $e',
          style: TextStyle(color: Colors.black.withOpacity(0.5)),
        );
      }
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            '$fallbackText non disponible',
            style: TextStyle(color: Colors.black.withOpacity(0.5)),
          ),
        ),
      );
    }
  }
}

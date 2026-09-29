import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String creatorName = 'MUDASIR AHMED GHANGHRO';
  static const String creatorWhatsApp = '923368456907';
  static const String creatorFormattedPhone = '+92 336 8456907';

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent('Assalam-o-Alaikum Mudasir Bhai, G.R BOOK App ke hawale se rabta kiya hai.');
    final uris = [
      Uri.parse('whatsapp://send?phone=$creatorWhatsApp&text=$message'),
      Uri.parse('https://api.whatsapp.com/send?phone=$creatorWhatsApp&text=$message'),
      Uri.parse('https://wa.me/$creatorWhatsApp?text=$message'),
    ];

    bool launched = false;
    for (final uri in uris) {
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) break;
        }
      } catch (_) {}
    }

    if (!launched) {
      try {
        launched = await launchUrl(
          Uri.parse('https://wa.me/$creatorWhatsApp?text=$message'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp: $creatorFormattedPhone')),
      );
    }
  }

  Future<void> _callPhone(BuildContext context) async {
    final uri = Uri.parse('tel:+$creatorWhatsApp');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call: $creatorFormattedPhone')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone: $creatorFormattedPhone')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(
        title: const Text('About G.R BOOK'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: GrBookTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.menu_book_rounded, size: 44, color: GrBookTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'G.R BOOK',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: GrBookTheme.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Digital School Record System',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: GrBookTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: GrBookTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GrBookTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Version 1.0.0 • Offline-First Edition',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: GrBookTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // CREATOR & LEAD ARCHITECT CARD (MUDASIR AHMED GHANGHRO)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F5132), Color(0xFF0A3622)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'FOUNDER & LEAD ARCHITECT',
                                  style: TextStyle(
                                    color: Color(0xFFFFE066),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar with verified badge
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/creator_face.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF0F5132),
                                child: const Center(
                                  child: Icon(Icons.person_rounded, size: 48, color: Color(0xFFFFD700)),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_rounded, size: 22, color: Color(0xFF198754)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        creatorName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Creator & Software Architect',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD1E7DD),
                        ),
                      ),

                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Text(
                          'A passionate innovator and visionary in educational software. Mudasir Ahmed Ghanghro has masterminded and crafted G.R BOOK to eliminate manual register paperwork and bring complete digital empowerment to schools. With a steadfast commitment to offline-first speed, biometric privacy, and flawless register tracking, his vision sets the benchmark for modern school management applications in Pakistan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: Color(0xFFF8F9FA),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Direct Contact Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                              label: const Text(
                                'WhatsApp',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () => _openWhatsApp(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F5132),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.phone_rounded, size: 18),
                              label: const Text(
                                'Call Creator',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () => _callPhone(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Direct Contact: $creatorFormattedPhone',
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Application Features Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GrBookTheme.borderColor),
                  boxShadow: const [
                    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.stars_rounded, color: GrBookTheme.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Core Highlights',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildFeatureRow(Icons.offline_pin_rounded, 'Fully Independent Offline-First Architecture'),
                      _buildFeatureRow(Icons.folder_special_rounded, 'Persistent Phone Storage in GR BOOK Folder'),
                      _buildFeatureRow(Icons.fingerprint_rounded, 'Biometric Fingerprint Lock & Instant Login'),
                      _buildFeatureRow(Icons.picture_as_pdf_rounded, 'A4 Student Profile & Certificates (PDF & JPG)'),
                      _buildFeatureRow(Icons.cloud_sync_rounded, 'Seamless Background Cloud Synchronization'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  '© ${DateTime.now().year} G.R BOOK. All rights reserved.\nCrafted with pride by Mudasir Ahmed Ghanghro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: GrBookTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: GrBookTheme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

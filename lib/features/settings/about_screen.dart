import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String creatorName = 'Mudasir Ahmed Ghanghro';
  static const String creatorTitle = 'Founder & Software Architect';
  static const String creatorWhatsApp = '923368456907';
  static const String creatorFormattedPhone = '+92 336 8456907';

  static const String ideatorName = 'Sir Asif Ali Ghanghro';
  static const String ideatorTitle = 'Head Master, GBPS Mehar Ghanghro';
  static const String ideatorRole = 'Concept & Educational Ideation';

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent('Assalam-o-Alaikum Mudasir Bhai, G.R. Book App ke hawale se rabta kiya hai.');
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
    final isDark = GrBookTheme.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      appBar: AppBar(
        title: const Text('About G.R. Book App'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. App Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: GrBookTheme.getCardBackground(context),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: GrBookTheme.primary.withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.menu_book_rounded, size: 48, color: GrBookTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'G.R. Book App',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: GrBookTheme.getTextPrimary(context),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Digital School Record Management Application',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: GrBookTheme.getTextSecondary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2E24) : GrBookTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GrBookTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Version 1.0.0 • Offline-First System',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 2. "About the G.R. Book App" Overview Card
              Container(
                decoration: BoxDecoration(
                  color: GrBookTheme.getCardBackground(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GrBookTheme.getBorderColor(context)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2E24) : GrBookTheme.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: GrBookTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'About the G.R. Book App',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : GrBookTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'G.R. Book App is a digital school record management application designed to make student records more organized, secure, and easier to manage. It brings essential school records into one simple digital system, reducing paperwork and helping schools manage student information efficiently.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: GrBookTheme.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Founder, Vision & Dedication Card (Emerald Gradient)
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                            'FOUNDER & SOFTWARE ARCHITECT',
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
                    const SizedBox(height: 16),

                    // Avatar with verified badge
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
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
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/creator_face.png',
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF0F5132),
                                child: const Center(
                                  child: Icon(Icons.person_rounded, size: 48, color: Color(0xFFFFD700)),
                                ),
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
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      creatorTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD1E7DD),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Vision Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD700), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Vision & Purpose',
                                style: TextStyle(
                                  color: Color(0xFFFFE066),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The G.R. Book App was created by Mudasir Ahmed Ghanghro, Founder & Software Architect, with a vision to build practical technology that solves real problems in schools and communities and contributes to a more digital, connected, and technology-driven Sindh.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: Color(0xFFF8F9FA),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Dedication to Teachers Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school_rounded, color: Color(0xFF68D391), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Dedicated to Teachers',
                                style: TextStyle(
                                  color: Color(0xFF68D391),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The app is inspired by the dedication of teachers, who work every day to educate, guide, and support their communities. G.R. Book App aims to make school record management simpler and more efficient for them.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: Color(0xFFF8F9FA),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Inspiring Quote Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD700), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'G.R. Book App is just the beginning.',
                            style: TextStyle(
                              color: Color(0xFFFFE066),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
                              'Call Founder',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () => _callPhone(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Direct Contact: $creatorFormattedPhone',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3b. Concept, Ideation & Educational Vision Card (Royal Sapphire Gradient)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF60A5FA), width: 1.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_rounded, color: Color(0xFF93C5FD), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'CONCEPT & IDEATION',
                            style: TextStyle(
                              color: Color(0xFFDBEAFE),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Avatar with educational badge
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF60A5FA), width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/asif_ali_ghanghro.jpg',
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF1E3A8A),
                                child: const Center(
                                  child: Icon(Icons.person_rounded, size: 48, color: Color(0xFF93C5FD)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded, size: 20, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      ideatorName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      ideatorTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBFDBFE),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Primary School Teacher (PST) — Sindh Education Dept.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Concept & Origin Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology_rounded, color: Color(0xFF93C5FD), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'The Concept & Origin',
                                style: TextStyle(
                                  color: Color(0xFFDBEAFE),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The vision of transforming the traditional, physical General Register into a smart digital tool was conceived by Sir Asif Ali Ghanghro, Head Master of GBPS Mehar Ghanghro. Having experienced the day-to-day challenges of student records, struck-off tracing, and certificate generation firsthand in government primary schools, he formulated the core requirements and inspired the development of this offline-first solution.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: Color(0xFFF8F9FA),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Appreciation Note Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Color(0xFF93C5FD), size: 16),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Special gratitude for inspiring the digitalization of primary school records in Sindh.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFDBEAFE),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Core Features Highlights Card
              Container(
                decoration: BoxDecoration(
                  color: GrBookTheme.getCardBackground(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GrBookTheme.getBorderColor(context)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: GrBookTheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Key System Highlights',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildFeatureRow(context, Icons.offline_pin_rounded, 'Fully Independent Offline-First Architecture'),
                    _buildFeatureRow(context, Icons.folder_special_rounded, 'Persistent Phone Storage in GR BOOK Folder'),
                    _buildFeatureRow(context, Icons.fingerprint_rounded, 'Biometric Fingerprint Lock & Instant Login'),
                    _buildFeatureRow(context, Icons.picture_as_pdf_rounded, 'A4 Student Profile & Certificates (PDF & JPG)'),
                    _buildFeatureRow(context, Icons.edit_note_rounded, 'Teacher-Editable Certificate Context & Custom Notes'),
                    _buildFeatureRow(context, Icons.cake_rounded, 'Live Dynamic Age Auto-Sync with Real Date of Birth'),
                    _buildFeatureRow(context, Icons.cloud_sync_rounded, 'Seamless Background Cloud Synchronization'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. Footer & Copyright
              Center(
                child: Text(
                  '© ${DateTime.now().year} G.R. Book App. All rights reserved.\nCreated & Architected by Mudasir Ahmed Ghanghro\nConcept & Ideation by Sir Asif Ali Ghanghro (Head Master, GBPS Mehar Ghanghro)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: GrBookTheme.getTextSecondary(context), height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: GrBookTheme.isDark(context) ? const Color(0xFF1E2E24) : GrBookTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: GrBookTheme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: GrBookTheme.getTextPrimary(context), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

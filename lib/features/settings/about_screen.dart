import 'package:flutter/material.dart';

import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('About G.R. Book')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Icon(Icons.menu_book_rounded, size: 64, color: GrBookTheme.primary),
              const SizedBox(height: 12),
              Text('G.R. Book', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Text('Digital School Record System'),
              const SizedBox(height: 4),
              Text('Version 1.0.0', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'G.R. Book digitizes the General Register for government primary '
                    'schools — student records, promotions, pass-outs, and struck-off '
                    'history — working fully offline and syncing automatically when '
                    'connectivity returns.',
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

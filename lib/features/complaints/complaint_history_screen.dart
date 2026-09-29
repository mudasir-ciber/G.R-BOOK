import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/student.dart';
import '../../repositories/complaint_repository.dart';
import '../../widgets/gr_book_ui_components.dart';

class ComplaintHistoryScreen extends ConsumerWidget {
  const ComplaintHistoryScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(studentComplaintsStreamProvider(student.id));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GrBookTopBar(showBack: true),
              GrBookPageHeader(
                title: 'Complaint History',
                subtitle: student.studentName,
              ),
              Expanded(
                child: complaintsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading history: $e')),
                  data: (complaints) {
                    if (complaints.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notes_rounded, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No complaint or notice history for this student.',
                              style: TextStyle(color: GrBookTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        final c = complaints[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: GrBookTheme.borderColor),
                            boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: GrBookTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateFormat.format(c.createdAt),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GrBookTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.communicationMethod.contains('WhatsApp')
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      c.communicationMethod,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: c.communicationMethod.contains('WhatsApp')
                                            ? Colors.green.shade800
                                            : Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                c.complaintText,
                                style: const TextStyle(fontSize: 14, color: GrBookTheme.textPrimary, height: 1.3),
                              ),
                              if (c.localPhotoPath != null && c.localPhotoPath!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(c.localPhotoPath!),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/school.dart';
import '../../providers/repository_providers.dart';

/// Requirement #6: manage classes through Settings. Scoped to what's
/// safe without risking the promotion chain: rename, edit age rules,
/// toggle active/inactive. See README for what's intentionally out of
/// scope (adding a brand-new class, reordering the chain).
class ManageClassesScreen extends ConsumerWidget {
  const ManageClassesScreen({super.key, required this.schoolId});

  final String schoolId;

  Future<void> _editClass(BuildContext context, WidgetRef ref, SchoolClass schoolClass) async {
    final nameController = TextEditingController(text: schoolClass.displayName);
    final admissionController =
        TextEditingController(text: schoolClass.minAdmissionAgeMonths?.toString() ?? '');
    final promotionController =
        TextEditingController(text: schoolClass.minPromotionAgeMonths?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${schoolClass.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Display Name')),
              const SizedBox(height: 12),
              TextField(
                controller: admissionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min. Admission Age (months)',
                  hintText: 'Leave blank for no rule',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promotionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min. Promotion Age (months)',
                  hintText: 'e.g. 61 for 5 years 1 month',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final updated = SchoolClass(
      id: schoolClass.id,
      schoolId: schoolClass.schoolId,
      classCode: schoolClass.classCode,
      displayName: nameController.text.trim().isEmpty ? schoolClass.displayName : nameController.text.trim(),
      sortOrder: schoolClass.sortOrder,
      minAdmissionAgeMonths: int.tryParse(admissionController.text.trim()),
      minPromotionAgeMonths: int.tryParse(promotionController.text.trim()),
      promotesToClassId: schoolClass.promotesToClassId,
      isTerminal: schoolClass.isTerminal,
      isActive: schoolClass.isActive,
    );
    await ref.read(classRepositoryProvider).updateClass(updated);
  }

  Future<void> _toggleActive(WidgetRef ref, SchoolClass schoolClass, bool active) async {
    final updated = SchoolClass(
      id: schoolClass.id,
      schoolId: schoolClass.schoolId,
      classCode: schoolClass.classCode,
      displayName: schoolClass.displayName,
      sortOrder: schoolClass.sortOrder,
      minAdmissionAgeMonths: schoolClass.minAdmissionAgeMonths,
      minPromotionAgeMonths: schoolClass.minPromotionAgeMonths,
      promotesToClassId: schoolClass.promotesToClassId,
      isTerminal: schoolClass.isTerminal,
      isActive: active,
    );
    await ref.read(classRepositoryProvider).updateClass(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(allClassesStreamProvider(schoolId));
    final isDark = GrBookTheme.isDark(context);
    final cardBg = GrBookTheme.getCardBackground(context);
    final borderColor = GrBookTheme.getBorderColor(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);
    final textSecondary = GrBookTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      appBar: AppBar(title: const Text('Manage Classes')),
      body: SafeArea(
        child: classesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: textPrimary))),
          data: (classes) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = classes[index];
                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: (c.isActive ? GrBookTheme.primary : Colors.grey).withOpacity(0.12),
                      child: Text(
                        c.classCode,
                        style: TextStyle(
                          color: c.isActive ? (isDark ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark) : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(c.displayName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                    subtitle: Text(
                      [
                        if (c.minAdmissionAgeMonths != null) 'Min admission: ${c.minAdmissionAgeMonths}mo',
                        if (c.minPromotionAgeMonths != null) 'Min promotion: ${c.minPromotionAgeMonths}mo',
                        if (!c.isActive) 'Inactive',
                      ].join('  •  '),
                      style: TextStyle(fontSize: 12, color: c.isActive ? textSecondary : Colors.redAccent),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: textSecondary),
                          onPressed: () => _editClass(context, ref, c),
                        ),
                        Switch(
                          value: c.isActive,
                          activeColor: GrBookTheme.primary,
                          onChanged: (v) => _toggleActive(ref, c, v),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

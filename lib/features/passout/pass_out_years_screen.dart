import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/pass_out_providers.dart';
import '../../widgets/gr_book_ui_components.dart';
import 'pass_out_students_screen.dart';

/// Screen 6: Pass Out Years Page matching reference UI image 6 exactly.
class PassOutYearsScreen extends ConsumerWidget {
  const PassOutYearsScreen({super.key, required this.schoolId});

  final String schoolId;

  Future<void> _addYear(BuildContext context, WidgetRef ref, List<int> existingYears) async {
    final controller = TextEditingController(text: '${DateTime.now().year}');
    final year = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Year'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Year', hintText: 'e.g. 2031'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GrBookTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < 2000 || parsed > 2100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid 4-digit year.')),
                );
                return;
              }
              if (existingYears.contains(parsed)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('That year already exists.')),
                );
                return;
              }
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (year != null) {
      await ref.read(passOutRepositoryProvider).addYear(schoolId: schoolId, year: year);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(passOutYearsProvider(schoolId));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GrBookTopBar(),
              const GrBookPageHeader(
                title: 'Pass Out Years',
                subtitle: 'Manage pass out years',
              ),
              Expanded(
                child: yearsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (years) {
                    if (years.isEmpty) {
                      return const Center(child: Text('No pass-out years yet. Tap below to add one.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: years.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final year = years[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PassOutStudentsScreen(
                                      schoolId: schoolId,
                                      initialYear: year,
                                      availableYears: years,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                child: Row(
                                  children: [
                                    const GrBookIconBadge(icon: Icons.school_rounded),
                                    const SizedBox(width: 16),
                                    Text(
                                      '$year',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: GrBookTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: GrBookTheme.primary,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom Button: + Add New Year
              yearsAsync.maybeWhen(
                data: (years) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: GrBookGradientButton(
                    text: 'Add New Year',
                    icon: Icons.add_circle_outline_rounded,
                    trailingIcon: null,
                    onPressed: () => _addYear(context, ref, years),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

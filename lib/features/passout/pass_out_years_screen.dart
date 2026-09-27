import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/pass_out_providers.dart';
import 'pass_out_students_screen.dart';

class PassOutYearsScreen extends ConsumerWidget {
  const PassOutYearsScreen({super.key, required this.schoolId});

  final String schoolId;

  Future<void> _addYear(BuildContext context, WidgetRef ref, List<int> existingYears) async {
    final controller = TextEditingController(text: '${DateTime.now().year}');
    final year = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
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
            style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
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
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Pass Out Years')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: yearsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (years) {
                  if (years.isEmpty) {
                    return const Center(child: Text('No pass-out years yet. Add one to get started.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: years.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final year = years[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                            child: const Icon(Icons.school, color: GrBookTheme.primaryDark),
                          ),
                          title: Text('$year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PassOutStudentsScreen(schoolId: schoolId, initialYear: year, availableYears: years),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: GrBookTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _addYear(context, ref, yearsAsync.valueOrNull ?? []),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add New Year'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

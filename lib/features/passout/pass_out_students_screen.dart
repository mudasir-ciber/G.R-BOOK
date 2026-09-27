import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/pass_out_providers.dart';

class PassOutStudentsScreen extends ConsumerStatefulWidget {
  const PassOutStudentsScreen({
    super.key,
    required this.schoolId,
    required this.initialYear,
    required this.availableYears,
  });

  final String schoolId;
  final int initialYear;
  final List<int> availableYears;

  @override
  ConsumerState<PassOutStudentsScreen> createState() => _PassOutStudentsScreenState();
}

class _PassOutStudentsScreenState extends ConsumerState<PassOutStudentsScreen> {
  late int _selectedYear;
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(
      passOutStudentsForYearProvider((schoolId: widget.schoolId, year: _selectedYear)),
    );

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Pass Out Students')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, color: GrBookTheme.primaryDark),
                    const SizedBox(width: 10),
                    const Text('Year:', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: DropdownButton<int>(
                        value: widget.availableYears.contains(_selectedYear) ? _selectedYear : null,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        items: widget.availableYears
                            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                            .toList(),
                        onChanged: (y) {
                          if (y != null) setState(() => _selectedYear = y);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Search student name or GR No...', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _searchText = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: studentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (students) {
                  final filtered = students
                      .where((s) =>
                          _searchText.isEmpty ||
                          s.studentName.toLowerCase().contains(_searchText.toLowerCase()) ||
                          s.grNumber.toLowerCase().contains(_searchText.toLowerCase()))
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text('No students passed out in $_selectedYear.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                          child: Text(s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?'),
                        ),
                        title: Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('GR: ${s.grNumber}  •  Sr. No: ${s.serialNumber ?? "-"}'),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: GrBookTheme.primaryDark),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pass Out Students', style: TextStyle(color: Colors.grey)),
                          Text(
                            '${studentsAsync.valueOrNull?.length ?? 0} Students',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

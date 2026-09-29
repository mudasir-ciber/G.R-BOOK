import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/pass_out_providers.dart';
import '../../widgets/gr_book_ui_components.dart';

/// Screen 10: Pass Out Students Page matching reference UI image 10 exactly.
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

    final totalCount = studentsAsync.valueOrNull?.length ?? 0;

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
              GrBookPageHeader(
                title: 'Pass Out Students',
                subtitle: 'Students who have passed out in $_selectedYear',
              ),

              // Year Selector Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const GrBookIconBadge(icon: Icons.school_rounded, size: 36, iconSize: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Year:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GrBookTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<int>(
                          value: widget.availableYears.contains(_selectedYear) ? _selectedYear : null,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: GrBookTheme.primary),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: GrBookTheme.textPrimary,
                          ),
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

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search student name or GR No...',
                    prefixIcon: Icon(Icons.search, color: GrBookTheme.primary, size: 20),
                  ),
                  onChanged: (v) => setState(() => _searchText = v),
                ),
              ),

              // Table Header Row ("Sr. No. | G.R No. | Student Name")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF2E4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          'Sr. No.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'G.R No.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          'Student Name',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Student List
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
                      return Center(
                        child: Text('No students passed out in $_selectedYear.'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: GrBookTheme.borderColor, width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '${index + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F8F4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s.grNumber,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: GrBookTheme.primaryDark),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: GrBookTheme.primaryLight,
                                  child: Text(
                                    s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    s.studentName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: GrBookTheme.primary, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom Summary Card (Total Pass Out Students)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const GrBookIconBadge(icon: Icons.school_rounded, size: 44, iconSize: 24),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Pass Out Students',
                            style: TextStyle(fontSize: 12, color: GrBookTheme.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalCount Students',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: GrBookTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/localization_provider.dart';

class QuizFiltersBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required LocalizationProvider localization,
    required String selectedCategory,
    required String selectedQuizStatus,
    required List<String> allCategories,
    required List<String> quizStatuses,
    required Function(String) onCategoryChanged,
    required Function(String) onStatusChanged,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: _Content(
            localization: localization,
            selectedCategory: selectedCategory,
            selectedQuizStatus: selectedQuizStatus,
            allCategories: allCategories,
            quizStatuses: quizStatuses,
            onCategoryChanged: onCategoryChanged,
            onStatusChanged: onStatusChanged,
          ),
        );
      },
    );
  }
}

class _Content extends StatefulWidget {
  final LocalizationProvider localization;
  final String selectedCategory;
  final String selectedQuizStatus;
  final List<String> allCategories;
  final List<String> quizStatuses;
  final Function(String) onCategoryChanged;
  final Function(String) onStatusChanged;

  const _Content({
    required this.localization,
    required this.selectedCategory,
    required this.selectedQuizStatus,
    required this.allCategories,
    required this.quizStatuses,
    required this.onCategoryChanged,
    required this.onStatusChanged,
  });

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  late String categoryValue;
  late String statusValue;

  @override
  void initState() {
    super.initState();
    categoryValue = widget.selectedCategory;
    statusValue = widget.selectedQuizStatus;
  }

  @override
  Widget build(BuildContext context) {
    final localization = widget.localization;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          localization.translate('Filters'),
          style: GoogleFonts.sniglet(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        // CATEGORY
        Text(
          localization.translate('filterByCategory'),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: categoryValue,
          decoration: const InputDecoration(
            isDense: true,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black54),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black87, width: 1.5),
            ),
          ),
          items:
              ['All Categories', ...widget.allCategories].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: (v) {
            setState(() => categoryValue = v ?? 'All Categories');
          },
        ),

        const SizedBox(height: 20),

        // STATUS
        Text(
          localization.translate('status'),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: statusValue,
          decoration: const InputDecoration(
            isDense: true,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black54),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black87, width: 1.5),
            ),
          ),
          items:
              widget.quizStatuses.map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: (v) {
            setState(() => statusValue = v ?? 'All');
          },
        ),

        const SizedBox(height: 30),

        Row(
          children: [
            // RESET
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  widget.onCategoryChanged('All Categories');
                  widget.onStatusChanged('All');
                  Navigator.pop(context);
                },
                child: Text(localization.translate('reset')),
              ),
            ),
            const SizedBox(width: 12),

            // APPLY
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD93D),
                ),
                onPressed: () {
                  widget.onCategoryChanged(categoryValue);
                  widget.onStatusChanged(statusValue);
                  Navigator.pop(context);
                },
                child: Text(localization.translate('apply')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

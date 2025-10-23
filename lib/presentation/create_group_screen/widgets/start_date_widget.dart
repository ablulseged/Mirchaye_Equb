import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class StartDateWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const StartDateWidget({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'event',
                  color: colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Start Date',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'calendar_today',
                      color: colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'First Contribution Date',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _formatDate(selectedDate),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomIconWidget(
                      iconName: 'arrow_drop_down',
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 6.w,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Date suggestions
            Text(
              'Quick Select',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _getDateSuggestions().map((suggestion) {
                final isSelected = _isSameDate(
                  selectedDate,
                  suggestion['date'] as DateTime,
                );
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onDateChanged(suggestion['date'] as DateTime);
                    }
                  },
                  label: Text(
                    suggestion['label'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: isSelected
                      ? colorScheme.primary
                      : colorScheme.surface,
                  selectedColor: colorScheme.primary,
                  checkmarkColor: colorScheme.onPrimary,
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: 1,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<Map<String, dynamic>> _getDateSuggestions() {
    final now = DateTime.now();
    return [
      {'label': 'Next Monday', 'date': _getNextWeekday(now, DateTime.monday)},
      {'label': 'Next Friday', 'date': _getNextWeekday(now, DateTime.friday)},
      {
        'label': 'First of Month',
        'date': DateTime(
          now.month == 12 ? now.year + 1 : now.year,
          now.month == 12 ? 1 : now.month + 1,
          1,
        ),
      },
      {
        'label': '15th of Month',
        'date': DateTime(
          now.month == 12 ? now.year + 1 : now.year,
          now.month == 12 ? 1 : now.month + 1,
          15,
        ),
      },
    ];
  }

  DateTime _getNextWeekday(DateTime date, int weekday) {
    final daysUntilWeekday = (weekday - date.weekday) % 7;
    final targetDate = date.add(
      Duration(days: daysUntilWeekday == 0 ? 7 : daysUntilWeekday),
    );
    return DateTime(targetDate.year, targetDate.month, targetDate.day);
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

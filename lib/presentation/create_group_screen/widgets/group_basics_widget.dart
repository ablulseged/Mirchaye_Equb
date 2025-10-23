import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class GroupBasicsWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const GroupBasicsWidget({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final categories = [
      {'value': 'family', 'label': 'Family', 'icon': 'family_restroom'},
      {'value': 'friends', 'label': 'Friends', 'icon': 'people'},
      {'value': 'community', 'label': 'Community', 'icon': 'location_city'},
      {'value': 'workplace', 'label': 'Workplace', 'icon': 'business'},
    ];

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
                  iconName: 'info_outline',
                  color: colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Group Basics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Group Name Field
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Group Name *',
                hintText: 'Enter a memorable name for your Equb',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'groups',
                    color: colorScheme.primary,
                    size: 5.w,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Group name is required';
                }
                if (value.trim().length < 3) {
                  return 'Group name must be at least 3 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 3.h),

            // Description Field
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Describe the purpose and goals of your Equb group',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'description',
                    color: colorScheme.primary,
                    size: 5.w,
                  ),
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value != null && value.length > 200) {
                  return 'Description must be less than 200 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 3.h),

            // Category Selection
            Text(
              'Category *',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: categories.map((category) {
                final isSelected = selectedCategory == category['value'];
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onCategoryChanged(category['value'] as String);
                    }
                  },
                  avatar: CustomIconWidget(
                    iconName: category['icon'] as String,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                    size: 4.w,
                  ),
                  label: Text(
                    category['label'] as String,
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
}

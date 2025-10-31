// appearance_section_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../main.dart'; // access MyApp.themeNotifier

class AppearanceSectionWidget extends StatefulWidget {
  const AppearanceSectionWidget({Key? key}) : super(key: key);

  @override
  State<AppearanceSectionWidget> createState() =>
      _AppearanceSectionWidgetState();
}

class _AppearanceSectionWidgetState extends State<AppearanceSectionWidget> {
  ThemeMode _currentMode = MyApp.themeNotifier.value;

  String _getThemeTitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
      default:
        return 'System Default';
    }
  }

  String _getThemeSubtitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
      default:
        return 'Follow system settings';
    }
  }

  void _onThemeChanged(ThemeMode mode) {
    HapticFeedback.selectionClick();
    setState(() => _currentMode = mode);
    MyApp.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _currentMode == ThemeMode.dark;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Appearance',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.01,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Dark Mode Box
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Toggle between light and dark theme',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (value) {
                      _onThemeChanged(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // Theme Mode radios
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Preference',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.01,
                  ),
                ),
                SizedBox(height: 1.h),
                ...ThemeMode.values.map(
                  (mode) => RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _getThemeTitle(mode),
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _getThemeSubtitle(mode),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: mode,
                    groupValue: _currentMode,
                    onChanged: (value) {
                      if (value != null) _onThemeChanged(value);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

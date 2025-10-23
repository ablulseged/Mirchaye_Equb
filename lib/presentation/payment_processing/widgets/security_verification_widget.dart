import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SecurityVerificationWidget extends StatefulWidget {
  final Function(String) onPinEntered;
  final VoidCallback? onBiometricAuth;
  final bool isBiometricAvailable;
  final bool isLoading;

  const SecurityVerificationWidget({
    Key? key,
    required this.onPinEntered,
    this.onBiometricAuth,
    this.isBiometricAvailable = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<SecurityVerificationWidget> createState() =>
      _SecurityVerificationWidgetState();
}

class _SecurityVerificationWidgetState
    extends State<SecurityVerificationWidget> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: 'security',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                'Security Verification',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          Text(
            'Enter your PIN to confirm this payment',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),

          TextFormField(
            controller: _pinController,
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: 'PIN',
              hintText: 'Enter 4-digit PIN',
              counterText: '',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePin = !_obscurePin;
                  });
                },
                icon: CustomIconWidget(
                  iconName: _obscurePin ? 'visibility' : 'visibility_off',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.length == 4) {
                widget.onPinEntered(value);
              }
            },
          ),

          if (widget.isBiometricAvailable) ...[
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppTheme.lightTheme.colorScheme.outline,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    'OR',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppTheme.lightTheme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            Center(
              child: OutlinedButton.icon(
                onPressed: widget.isLoading ? null : widget.onBiometricAuth,
                icon: CustomIconWidget(
                  iconName: 'fingerprint',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                label: Text('Use Biometric Authentication'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

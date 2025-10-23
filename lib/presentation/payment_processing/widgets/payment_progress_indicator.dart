import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

enum PaymentStage { verification, processing, confirmation }

class PaymentProgressIndicator extends StatelessWidget {
  final PaymentStage currentStage;
  final bool isCompleted;

  const PaymentProgressIndicator({
    Key? key,
    required this.currentStage,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 4.w),
      child: Column(
        children: [
          Row(
            children: [
              _buildStageIndicator(
                stage: PaymentStage.verification,
                title: 'Verification',
                isActive:
                    currentStage == PaymentStage.verification && !isCompleted,
                isCompleted: _isStageCompleted(PaymentStage.verification),
              ),
              _buildConnector(_isStageCompleted(PaymentStage.verification)),
              _buildStageIndicator(
                stage: PaymentStage.processing,
                title: 'Processing',
                isActive:
                    currentStage == PaymentStage.processing && !isCompleted,
                isCompleted: _isStageCompleted(PaymentStage.processing),
              ),
              _buildConnector(_isStageCompleted(PaymentStage.processing)),
              _buildStageIndicator(
                stage: PaymentStage.confirmation,
                title: 'Confirmation',
                isActive:
                    currentStage == PaymentStage.confirmation && !isCompleted,
                isCompleted: isCompleted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isStageCompleted(PaymentStage stage) {
    if (isCompleted) return true;

    switch (stage) {
      case PaymentStage.verification:
        return currentStage == PaymentStage.processing ||
            currentStage == PaymentStage.confirmation;
      case PaymentStage.processing:
        return currentStage == PaymentStage.confirmation;
      case PaymentStage.confirmation:
        return isCompleted;
    }
  }

  Widget _buildStageIndicator({
    required PaymentStage stage,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color indicatorColor;
    Color textColor;
    IconData? iconData;

    if (isCompleted) {
      indicatorColor = AppTheme.getSuccessColor(true);
      textColor = AppTheme.getSuccessColor(true);
      iconData = Icons.check;
    } else if (isActive) {
      indicatorColor = AppTheme.lightTheme.colorScheme.primary;
      textColor = AppTheme.lightTheme.colorScheme.primary;
    } else {
      indicatorColor = AppTheme.lightTheme.colorScheme.outline;
      textColor = AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(iconData, color: Colors.white, size: 20)
                  : isActive
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: isActive || isCompleted
                  ? FontWeight.w500
                  : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppTheme.getSuccessColor(true)
              : AppTheme.lightTheme.colorScheme.outline,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

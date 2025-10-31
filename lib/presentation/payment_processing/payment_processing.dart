import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/amount_display_card.dart';
import './widgets/payment_method_card.dart';
import './widgets/payment_progress_indicator.dart';
import 'package:robot/presentation/payment_processing/widgets/security_verification_widget.dart';

class PaymentProcessing extends StatefulWidget {
  const PaymentProcessing({Key? key}) : super(key: key);

  @override
  State<PaymentProcessing> createState() => _PaymentProcessingState();
}

class _PaymentProcessingState extends State<PaymentProcessing>
    with TickerProviderStateMixin {
  PaymentStage currentStage = PaymentStage.verification;
  String? selectedPaymentMethod;
  bool isLoading = false;
  bool isPaymentCompleted = false;

  // Mock payment data
  final Map<String, dynamic> paymentData = {
    "groupName": "Computer Science Students Equb",
    "cycleInfo": "Round 3 of 12 • Due: Nov 5, 2025",
    "amount": "4,166.67",
    "currency": "ETB",
    "convertedAmount": "74.29",
    "convertedCurrency": "USD",
    "adminName": "Almaz Tadesse",
    "adminPhone": "+251-911-234567",
    "accountNumber": "1000012345678",
  };

  final List<Map<String, String>> paymentMethods = [
    {
      "name": "Telebirr",
      "icon": "phone_android",
      "time": "Instant",
      "fee": "Free",
    },
    {
      "name": "M-Birr",
      "icon": "account_balance_wallet",
      "time": "1-3 minutes",
      "fee": "5.00 ETB",
    },
    {
      "name": "Bank Transfer",
      "icon": "account_balance",
      "time": "5-10 minutes",
      "fee": "12.00 ETB",
    },
    {
      "name": "Cash Deposit",
      "icon": "local_atm",
      "time": "Manual verification",
      "fee": "15.00 ETB",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Get payment context from route arguments if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        // Update payment data with actual values from navigation
        setState(() {
          // Update with real data if provided
        });
      }
    });
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      selectedPaymentMethod = method;
    });
  }

  void _handlePinVerification(String pin) {
    if (pin.length == 4) {
      _processPayment();
    }
  }

  void _handleBiometricAuth() {
    // Simulate biometric authentication
    _processPayment();
  }

  void _processPayment() async {
    if (selectedPaymentMethod == null) {
      _showErrorMessage('Please select a payment method');
      return;
    }

    setState(() {
      isLoading = true;
      currentStage = PaymentStage.processing;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      currentStage = PaymentStage.confirmation;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isPaymentCompleted = true;
      isLoading = false;
    });

    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ethiopian celebration animation placeholder
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: AppTheme.getSuccessColorFromContext(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 40),
                ),
                SizedBox(height: 3.h),

                Text(
                  'Payment Successful!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getSuccessColorFromContext(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),

                Text(
                  'Your contribution has been processed successfully.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),

                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Transaction Reference',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                              color: AppTheme
                                  .lightTheme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'TXN${DateTime.now().millisecondsSinceEpoch}',
                        style: AppTheme.getMonospaceStyle(
                          isLight: true,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _generateReceipt();
                        },
                        child: Text('Download Receipt'),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pop(); // Return to previous screen
                        },
                        child: Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _generateReceipt() {
    // Implement receipt generation with QR code
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt generated successfully'),
        backgroundColor: AppTheme.getSuccessColorFromContext(context),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.getErrorColorFromContext(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Payment Processing',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Progress Indicator
            PaymentProgressIndicator(
              currentStage: currentStage,
              isCompleted: isPaymentCompleted,
            ),

            // Amount Display Card
            AmountDisplayCard(
              amount: paymentData["amount"],
              currency: paymentData["currency"],
              convertedAmount: paymentData["convertedAmount"],
              convertedCurrency: paymentData["convertedCurrency"],
              groupName: paymentData["groupName"],
              cycleInfo: paymentData["cycleInfo"],
            ),

            // Payment Method Selection
            if (currentStage == PaymentStage.verification &&
                !isPaymentCompleted) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Payment Method',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2.h),
                    ...paymentMethods.map(
                      (method) => PaymentMethodCard(
                        methodName: method["name"]!,
                        iconName: method["icon"]!,
                        processingTime: method["time"]!,
                        fee: method["fee"]!,
                        isSelected: selectedPaymentMethod == method["name"],
                        onTap: () => _selectPaymentMethod(method["name"]!),
                      ),
                    ),
                  ],
                ),
              ),

              // Recipient Details
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipient Details',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'person',
                          color:
                              theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          paymentData["adminName"],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'phone',
                          color:
                              theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          paymentData["adminPhone"],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'account_balance',
                          color:
                              theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          paymentData["accountNumber"],
                          style: AppTheme.getMonospaceStyle(
                            isLight: true,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Security Verification
              SecurityVerificationWidget(
                onPinEntered: _handlePinVerification,
                onBiometricAuth: _handleBiometricAuth,
                isBiometricAvailable: true,
                isLoading: isLoading,
              ),
            ],

            // Processing Status
            if (currentStage == PaymentStage.processing ||
                currentStage == PaymentStage.confirmation) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                child: Column(
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 4.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      currentStage == PaymentStage.processing
                          ? 'Processing Payment...'
                          : 'Confirming Transaction...',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Please wait while we process your contribution.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}

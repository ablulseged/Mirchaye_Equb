import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import './widgets/amount_display_card.dart';
import './widgets/payment_method_card.dart';
import './widgets/payment_progress_indicator.dart';
import './widgets/security_verification_widget.dart';
import '../../services/equb_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentProcessing extends StatefulWidget {
  const PaymentProcessing({Key? key}) : super(key: key);

  @override
  State<PaymentProcessing> createState() => _PaymentProcessingState();
}

class _PaymentProcessingState extends State<PaymentProcessing>
    with TickerProviderStateMixin {
  PaymentStage currentStage = PaymentStage.verification;
  String? selectedPaymentMethod;
  String? selectedScreenshotName;
  String? selectedBank;
  String? equbId;
  final TextEditingController _bankController = TextEditingController();
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

  // Common Ethiopian banks (sample for Chapa channels)
  final List<String> chapaBanks = const [
    'Commercial Bank of Ethiopia (CBE)',
    'Dashen Bank',
    'Awash Bank',
    'Bank of Abyssinia',
    'Hibret Bank',
    'Wegagen Bank',
    'Nib Bank',
  ];

  @override
  void initState() {
    super.initState();
    // Get payment context from route arguments if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          equbId = args['equbId'] as String?;
          // Preselect method if provided
          final method = args['method'] as String?;
          if (method != null && method.isNotEmpty) {
            selectedPaymentMethod = method;
          }
          // Update group context for display
          final equbName = args['equbName'] as String?;
          if (equbName != null && equbName.isNotEmpty) {
            paymentData["groupName"] = equbName;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bankController.dispose();
    super.dispose();
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      selectedPaymentMethod = method;
      selectedScreenshotName = null;
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

    // Validate method-specific requirements
    if (selectedPaymentMethod == 'Chapa' && (selectedBank == null || selectedBank!.isEmpty)) {
      _showErrorMessage('Please select a bank for Chapa');
      return;
    }
    if (selectedPaymentMethod == 'Screenshot' && (selectedScreenshotName == null)) {
      _showErrorMessage('Please select a screenshot to upload');
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

    // Build receipt and persist
    final String ref = 'TXN' + DateTime.now().millisecondsSinceEpoch.toString();
    final String? chapaRef = selectedPaymentMethod == 'Chapa'
        ? ('CHP' + DateTime.now().millisecondsSinceEpoch.toString())
        : null;
    try {
      final double amount = double.tryParse((paymentData['amount'] as String).replaceAll(',', '')) ?? 0.0;
      final String currency = (paymentData['currency'] as String?) ?? 'ETB';
      if (equbId != null) {
        await EqubService().recordPayment(
          equbId: equbId!,
          equbName: (paymentData['groupName'] as String?),
          amount: amount,
          currency: currency,
          method: selectedPaymentMethod ?? 'Unknown',
          bankName: selectedPaymentMethod == 'Chapa' ? selectedBank : null,
          screenshotName: selectedPaymentMethod == 'Screenshot' ? selectedScreenshotName : null,
          reference: ref,
          chapaReferenceId: chapaRef,
        );
      }
    } catch (_) {
      // Ignore persistence errors
    }

    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      isPaymentCompleted = true;
      isLoading = false;
    });

    // Show success dialog
    _showSuccessDialogWithRef(ref, chapaRef: chapaRef);
  }

  Future<void> _pickScreenshot() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        setState(() {
          selectedScreenshotName = file.name;
        });
      }
    } catch (_) {
      _showErrorMessage('Failed to open files');
    }
  }

  Future<void> _pickScreenshotFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          selectedScreenshotName = image.name;
        });
      }
    } catch (_) {
      _showErrorMessage('Failed to open gallery');
    }
  }

  Future<void> _openChapaReceipt(String chapaRef) async {
    final Uri url = Uri.parse('https://chapa.link/payment-receipt/' + chapaRef);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showErrorMessage('Could not open Chapa receipt');
    }
  }

  void _showSuccessDialogWithRef(String reference, {String? chapaRef}) {
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
                        reference,
                        style: AppTheme.getMonospaceStyle(
                          isLight: true,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (chapaRef != null) ...[
                        SizedBox(height: 1.h),
                        Text(
                          'Chapa Reference',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        InkWell(
                          onTap: () => _openChapaReceipt(chapaRef),
                          child: Text(
                            'chapa.link/payment-receipt/' + chapaRef,
                            style: AppTheme.getMonospaceStyle(
                              isLight: true,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ).copyWith(color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
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
                SizedBox(height: 1.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, AppRoutes.paymentHistory, arguments: {
                        'equbId': equbId,
                      });
                    },
                    child: const Text('View in History'),
                  ),
                ),
                if (chapaRef != null)
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openChapaReceipt(chapaRef),
                        child: const Text('Open Chapa Receipt'),
                      ),
                    ),
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

            // Payment Method Selection (only when method not preselected)
            if (currentStage == PaymentStage.verification &&
                !isPaymentCompleted &&
                selectedPaymentMethod == null) ...[
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

              if (selectedPaymentMethod != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text('Method: ' + (selectedPaymentMethod ?? '')),
                    ),
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

            // If method is preselected, show method-specific UI
            if (currentStage == PaymentStage.verification &&
                !isPaymentCompleted &&
                selectedPaymentMethod == 'Chapa') ...[
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
                      'Choose Bank',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 1.5.h),
                    ...chapaBanks.map((bank) => RadioListTile<String>(
                          title: Text(bank),
                          value: bank,
                          groupValue: selectedBank,
                          onChanged: (v) => setState(() => selectedBank = v),
                          dense: true,
                        )),
                  ],
                ),
              ),
              // Receipt preview
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
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
                    Text('Receipt Preview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: 1.h),
                    Text('Group: ' + (paymentData['groupName'] as String)),
                    Text('Amount: ' + (paymentData['amount'] as String) + ' ' + (paymentData['currency'] as String)),
                    Text('Method: Chapa'),
                    Text('Bank: ' + (_bankController.text.isEmpty ? '—' : _bankController.text)),
                  ],
                ),
              ),
              // Password/PIN verification for Chapa
              SecurityVerificationWidget(
                onPinEntered: _handlePinVerification,
                onBiometricAuth: _handleBiometricAuth,
                isBiometricAvailable: true,
                isLoading: isLoading,
              ),
            ],

            if (currentStage == PaymentStage.verification &&
                !isPaymentCompleted &&
                selectedPaymentMethod == 'Screenshot') ...[
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
                      'Upload Payment Screenshot',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 1.5.h),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickScreenshot,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Files'),
                        ),
                        SizedBox(width: 2.w),
                        OutlinedButton.icon(
                          onPressed: _pickScreenshotFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                        SizedBox(width: 3.w),
                        if (selectedScreenshotName != null)
                          Flexible(
                            child: Chip(
                              label: Text(selectedScreenshotName!),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _processPayment(),
                        child: const Text('Submit Screenshot'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

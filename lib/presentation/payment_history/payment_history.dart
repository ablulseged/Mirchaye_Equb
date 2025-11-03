import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/equb_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/payment_local_store.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = EqubService();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? equbId = args != null ? args['equbId'] as String? : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Payment History',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
      body: StreamBuilder(
        stream: service.streamPaymentsByUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allDocs = (snapshot.data as dynamic)?.docs ?? [];
          final docs = equbId == null
              ? allDocs
              : allDocs.where((d) => (d.data()['equbId'] as String?) == equbId).toList();

          if (docs.isEmpty) {
            // Fallback to local store
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: PaymentLocalStore.getPayments(),
              builder: (context, localSnap) {
                if (localSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var local = localSnap.data ?? const [];
                if (equbId != null) {
                  local = local.where((m) => (m['equbId'] as String?) == equbId).toList();
                }
                if (local.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(6.w),
                      child: Text(
                        'No payments yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return _buildLocalList(theme, local);
              },
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final method = (data['method'] as String?) ?? 'Unknown';
              final currency = (data['currency'] as String?) ?? 'ETB';
              final reference = (data['reference'] as String?) ?? '';
              final chapaRef = (data['chapaReferenceId'] as String?) ?? '';
              final groupName = (data['equbName'] as String?) ?? '';
              final groupId = (data['equbId'] as String?) ?? '';
              final createdAt = data['createdAt'];
              final createdStr = createdAt != null
                  ? (createdAt.toDate() as DateTime).toLocal().toString()
                  : '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.receipt_long, color: Colors.white),
                ),
                title: Text(
                  amount.toStringAsFixed(2) + ' ' + currency,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Method: ' + method),
                    if (groupName.isNotEmpty || groupId.isNotEmpty)
                      Text('Group: ' + (groupName.isNotEmpty ? groupName : groupId)),
                    if ((data['bankName'] as String?) != null && (data['bankName'] as String).isNotEmpty)
                      Text('Bank: ' + (data['bankName'] as String)),
                    Text('Ref: ' + reference),
                    if (chapaRef.isNotEmpty)
                      InkWell(
                        onTap: () => _openChapaReceipt(chapaRef),
                        child: Text('Chapa Receipt: chapa.link/payment-receipt/' + chapaRef,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                      ),
                    if (createdStr.isNotEmpty) Text(createdStr, style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openChapaReceipt(String chapaRef) async {
    final Uri url = Uri.parse('https://chapa.link/payment-receipt/' + chapaRef);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // ignore errors silently
    }
  }

  Widget _buildLocalList(ThemeData theme, List<Map<String, dynamic>> items) {
    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final data = items[index];
        final amount = (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0;
        final method = (data['method'] as String?) ?? 'Unknown';
        final currency = (data['currency'] as String?) ?? 'ETB';
        final reference = (data['reference'] as String?) ?? '';
        final chapaRef = (data['chapaReferenceId'] as String?) ?? '';
        final groupName = (data['equbName'] as String?) ?? '';
        final groupId = (data['equbId'] as String?) ?? '';
        final createdStr = '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.receipt_long, color: Colors.white),
          ),
          title: Text(
            amount.toStringAsFixed(2) + ' ' + currency,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Method: ' + method),
              if (groupName.isNotEmpty || groupId.isNotEmpty)
                Text('Group: ' + (groupName.isNotEmpty ? groupName : groupId)),
              if ((data['bankName'] as String?) != null && (data['bankName'] as String).isNotEmpty)
                Text('Bank: ' + (data['bankName'] as String)),
              Text('Ref: ' + reference),
              if (chapaRef.isNotEmpty)
                InkWell(
                  onTap: () => _openChapaReceipt(chapaRef),
                  child: Text('Chapa Receipt: chapa.link/payment-receipt/' + chapaRef,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                ),
              if (createdStr.isNotEmpty) Text(createdStr, style: theme.textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}



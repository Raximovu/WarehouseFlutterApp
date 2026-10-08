import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/transaction_model.dart';
import '../../../services/partner_service.dart';

class TransactionDetailDialog extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailDialog({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailDialog> createState() => _TransactionDetailDialogState();
}

class _TransactionDetailDialogState extends State<TransactionDetailDialog> {
  final _partnerService = PartnerService();
  final _numberFormat = NumberFormat('#,##0.00', 'uz');

  String _partnerName = 'Noma\'lum';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartnerInfo();
  }

  Future<void> _loadPartnerInfo() async {
    if (widget.transaction.partnerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final partners = await _partnerService.getAllPartners();
      final partner = partners.firstWhere((p) => p.id == widget.transaction.partnerId);
      setState(() {
        _partnerName = partner.name;
      });
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isKirim = tx.type == 'kirim';
    final isSotuv = tx.type == 'sotuv';

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(tx.typeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sana va Vaqt
                _DetailRow(
                  label: 'Sana va Vaqt:',
                  value: formatAppDate(tx.date),
                  icon: Icons.date_range_outlined,
                ),
                const Divider(),
                
                // Kontragent (Agar mavjud bo'lsa)
                if (isKirim || isSotuv) ...[
                  _DetailRow(
                    label: isKirim ? 'Ta\'minotchi (Kimdan olindi):' : 'Mijoz (Kimga sotildi):',
                    value: _isLoading ? 'Yuklanmoqda...' : _partnerName,
                    icon: Icons.business_outlined,
                  ),
                  const Divider(),
                ],

                // Mahsulot Nomi
                _DetailRow(
                  label: 'Mahsulot / Xomashyo Nomi:',
                  value: tx.name,
                  icon: Icons.inventory_2_outlined,
                ),
                const Divider(),

                // Miqdori va Narxi
                Row(
                  children: [
                    Expanded(
                      child: _DetailRow(
                        label: 'Miqdori:',
                        value: _numberFormat.format(tx.amount),
                        icon: Icons.scale_outlined,
                      ),
                    ),
                    Expanded(
                      child: _DetailRow(
                        label: 'Bir Birlik Narxi:',
                        value: '${_numberFormat.format(tx.price)} So\'m',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Jami Summa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jami Summa:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_numberFormat.format(tx.totalSum)} So\'m',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Izoh
                if (tx.notes != null && tx.notes!.isNotEmpty)
                  _DetailRow(
                    label: 'Izoh / Eslatma:',
                    value: tx.notes!,
                    icon: Icons.notes_outlined,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

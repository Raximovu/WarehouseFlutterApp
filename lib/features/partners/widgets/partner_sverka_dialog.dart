import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/partner_balance_model.dart';
import '../../../models/sverka_item_model.dart';
import '../../../services/excel_service.dart';
import '../../../services/partner_service.dart';
import '../../../services/payment_service.dart';
import '../../../services/transaction_service.dart';

class PartnerSverkaDialog extends StatefulWidget {
  final PartnerBalanceModel partner;

  const PartnerSverkaDialog({
    super.key,
    required this.partner,
  });

  @override
  State<PartnerSverkaDialog> createState() => _PartnerSverkaDialogState();
}

class _PartnerSverkaDialogState extends State<PartnerSverkaDialog> {
  final _partnerService = PartnerService();
  final _paymentService = PaymentService();
  final _transactionService = TransactionService();
  final _excelService = ExcelService();
  final _numberFormat = NumberFormat('#,##0.00', 'uz');

  List<SverkaItemModel> _sverkaItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSverkaHistory();
  }

  Future<void> _loadSverkaHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _partnerService.getPartnerSverkaHistory(widget.partner.id);
      setState(() {
        _sverkaItems = history;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sverka xatosi: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSverkaItem(SverkaItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text('Siz rostdan ham "${item.title}" yozuvini Sverka aktidan o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Yo\'q'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final isPayment = item.type.contains('tolov');
        if (isPayment) {
          await _paymentService.deletePayment(item.id);
        } else {
          await _transactionService.deleteTransaction(item.id);
        }
        _loadSverkaHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yozuv o\'chirildi'), backgroundColor: AppTheme.primaryColor));
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('O\'chirish mumkin emas!', style: TextStyle(color: AppTheme.errorColor)),
              content: Text(e.toString().replaceAll('Exception: ', '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tushundim'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _exportToExcel() async {
    if (_sverkaItems.isEmpty) return;

    try {
      final success = await _excelService.exportSverkaToExcel(widget.partner, _sverkaItems);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sverka Akti Excel formatida saqlandi!'), backgroundColor: AppTheme.primaryColor));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excelga saqlashda xato yuz berdi: $e'), backgroundColor: AppTheme.errorColor));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClient = widget.partner.type == 'mijoz';
    final currentDebt = isClient ? widget.partner.clientBalance : widget.partner.supplierBalance;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('Sverka Akti - ${widget.partner.name}')),
          
          // Excelga yuklash tugmasi
          if (!_isLoading && _sverkaItems.isNotEmpty)
            OutlinedButton.icon(
              onPressed: _exportToExcel,
              icon: const Icon(Icons.table_view_outlined, color: Colors.green, size: 18),
              label: const Text('Excelga Saqlash'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          const SizedBox(width: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: currentDebt > 0 ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: currentDebt > 0 ? AppTheme.errorColor : AppTheme.primaryColor),
            ),
            child: Text(
              'Joriy Qarz: ${_numberFormat.format(currentDebt.abs())} So\'m',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: currentDebt > 0 ? AppTheme.errorColor : AppTheme.primaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 850,
        height: 500,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sverkaItems.isEmpty
                ? const Center(
                    child: Text('Ushbu kontragent bo\'yicha hali harakatlar va to\'lovlar bajarilmagan.'),
                  )
                : Column(
                    children: [
                      // Header Qatori
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        color: AppTheme.tableHeaderBg(context),
                        child: const Row(
                          children: [
                            SizedBox(width: 35, child: Text('№', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Sana', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Harakat Turi', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text('Nomi / Tafsilot', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Summasi (So\'m)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 60, child: Text('Amal', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),

                      // Data Rows
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _sverkaItems.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.dividerColor(context)),
                          itemBuilder: (context, index) {
                            final item = _sverkaItems[index];
                            final isPayment = item.type.contains('tolov');

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(width: 35, child: Text('${index + 1}', style: const TextStyle(color: Colors.grey))),
                                  Expanded(flex: 2, child: Text(formatAppDate(item.date), style: const TextStyle(fontSize: 13))),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      isPayment ? 'To\'lov' : 'Tovar / Qop',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPayment ? AppTheme.primaryColor : Colors.blue,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${_numberFormat.format(item.amount)} So\'m',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPayment ? AppTheme.primaryColor : AppTheme.errorColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _deleteSverkaItem(item),
                                      tooltip: 'Ushbu yozuvni o\'chirish',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Yopish'),
        ),
      ],
    );
  }
}

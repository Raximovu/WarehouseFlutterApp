import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/partner_balance_model.dart';
import '../../../models/payment_model.dart';
import '../../../services/payment_service.dart';
import '../../../widgets/simple_date_picker.dart';

class AddPaymentDialog extends StatefulWidget {
  final List<PartnerBalanceModel> partners;
  final PartnerBalanceModel? initialPartner;

  const AddPaymentDialog({
    super.key,
    required this.partners,
    this.initialPartner,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentService = PaymentService();

  PartnerBalanceModel? _selectedPartner;
  PartnerBalanceModel? _recipientPartner; // Perekidka uchun Qabul qiluvchi
  String _operationType = 'kirim'; // 'kirim', 'chiqim', 'perekidka'
  String _paymentType = 'naqd'; // 'naqd', 'karta', 'bank'
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPartner != null) {
      _selectedPartner = widget.initialPartner;
    } else if (widget.partners.isNotEmpty) {
      _selectedPartner = widget.partners.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _currentBalance {
    if (_selectedPartner == null) return 0.0;
    final isClient = _selectedPartner!.type == 'mijoz';
    return isClient ? _selectedPartner!.clientBalance : _selectedPartner!.supplierBalance;
  }

  double get _maxAllowedAmount {
    if (_selectedPartner == null) return double.infinity;
    final isClient = _selectedPartner!.type == 'mijoz';
    final bal = _currentBalance;

    if (_operationType == 'kirim') {
      if (isClient) return double.infinity; 
      // Ta'minotchidan kirim: Faqat Haqdorligimiz bo'lsagina
      return bal < 0 ? bal.abs() : 0.0;
    } else if (_operationType == 'chiqim') {
      if (!isClient) return double.infinity;
      // Mijozga chiqim: Faqat Haqdorligi bo'lsagina
      return bal < 0 ? bal.abs() : 0.0;
    } else if (_operationType == 'perekidka') {
      // Perekidka: Faqat o'zida bor summa (Qarz yoki Haqdorlik) doirasida o'tkaza oladi.
      return bal != 0 ? bal.abs() : 0.0;
    }
    return double.infinity;
  }

  Future<void> _savePayment() async {
    if (_isSaving) return; // Prevent double-click spam

    if (_selectedPartner == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, kontragentni tanlang!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    if (_operationType == 'perekidka' && _recipientPartner == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perekidka uchun qabul qiluvchini tanlang!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    if (_operationType == 'perekidka' && _selectedPartner?.id == _recipientPartner?.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yuboruvchi va qabul qiluvchi bir xil shaxs bo\'lishi mumkin emas!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, to\'g\'ri summani kiriting!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    final maxLimit = _maxAllowedAmount;
    if (amount > maxLimit && maxLimit != double.infinity) {
      final formatter = NumberFormat('#,##0.00', 'uz');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Xatolik! Ruxsat etilgan maksimal summa: ${formatter.format(maxLimit)} So\'m'), 
        backgroundColor: AppTheme.errorColor,
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final fullDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, now.hour, now.minute, now.second);
      final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(fullDate);

      if (_operationType == 'perekidka') {
        final isSenderOwes = _currentBalance > 0;
        
        final senderTx = PaymentModel(
          date: dateStr,
          partnerId: _selectedPartner!.id,
          amount: amount,
          paymentType: 'perekidka', 
          isIncoming: isSenderOwes ? 1 : 0, 
          notes: 'Perekidka: ${_recipientPartner!.name} ga o\'tkazildi',
        );

        final receiverTx = PaymentModel(
          date: dateStr,
          partnerId: _recipientPartner!.id,
          amount: amount,
          paymentType: 'perekidka', 
          isIncoming: isSenderOwes ? 0 : 1, 
          notes: 'Perekidka: ${_selectedPartner!.name} dan qabul qilindi',
        );

        await _paymentService.addPayment(senderTx);
        await _paymentService.addPayment(receiverTx);

      } else {
        // Oddiy Kirim yoki Chiqim
        final isIncoming = _operationType == 'kirim' ? 1 : 0;
        final payment = PaymentModel(
          date: dateStr,
          partnerId: _selectedPartner!.id,
          amount: amount,
          paymentType: _paymentType,
          isIncoming: isIncoming,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await _paymentService.addPayment(payment);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saqlashda xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'uz');
    final bal = _currentBalance;

    String balanceText = '0.00 So\'m';
    Color balanceColor = Colors.grey;

    if (bal > 0) {
      balanceText = '${formatter.format(bal)} So\'m (Qarzdor)';
      balanceColor = AppTheme.errorColor;
    } else if (bal < 0) {
      balanceText = '${formatter.format(bal.abs())} So\'m (Haqdor)';
      balanceColor = AppTheme.primaryColor;
    }

    return AlertDialog(
      title: const Text('Kassa Operatsiyalari (To\'lov / Perekidka)'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Operatsiya Sanasi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SimpleDatePicker(
                  selectedDate: _selectedDate,
                  onChanged: (newDate) => setState(() => _selectedDate = newDate),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Operatsiya Turi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _operationType,
                isExpanded: true,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                items: const [
                  DropdownMenuItem(value: 'kirim', child: Text('📥 Kirim (Pul qabul qilish)')),
                  DropdownMenuItem(value: 'chiqim', child: Text('📤 Chiqim (Pul to\'lash / qaytarish)')),
                  DropdownMenuItem(value: 'perekidka', child: Text('🔄 O\'zaro O\'tkazma (Perekidka)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _operationType = val);
                },
              ),
              const SizedBox(height: 16),

              const Text('Kontragent (Asosiy Shaxs):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<PartnerBalanceModel>(
                value: _selectedPartner,
                isExpanded: true,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                items: widget.partners.map((p) {
                  return DropdownMenuItem<PartnerBalanceModel>(
                    value: p,
                    child: Text(
                      '${p.name} (${p.type == 'mijoz' ? 'Mijoz' : 'Ta\'minotchi'})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPartner = val);
                },
              ),
              
              if (_selectedPartner != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Joriy Balansi:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(balanceText, style: TextStyle(color: balanceColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              if (_operationType == 'perekidka') ...[
                const Text('Qabul Qiluvchi (Pul / Qarz o\'tkaziluvchi shaxs):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                DropdownButtonFormField<PartnerBalanceModel>(
                  value: _recipientPartner,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
                  ),
                  items: widget.partners.map((p) {
                    return DropdownMenuItem<PartnerBalanceModel>(
                      value: p,
                      child: Text(
                        '${p.name} (${p.type == 'mijoz' ? 'Mijoz' : 'Ta\'minotchi'})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _recipientPartner = val);
                  },
                ),
                const SizedBox(height: 16),
              ],

              const Text('Summa (So\'mda):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Masalan: 5000000'),
              ),
              if (_maxAllowedAmount != double.infinity && _selectedPartner != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Maksimal ruxsat: ${formatter.format(_maxAllowedAmount)} So\'m', 
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ],
              const SizedBox(height: 16),
              
              if (_operationType != 'perekidka') ...[
                const Text('To\'lov Shakli:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _paymentType,
                  isExpanded: true,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  items: const [
                    DropdownMenuItem(value: 'naqd', child: Text('Naqd Pul')),
                    DropdownMenuItem(value: 'karta', child: Text('Plastik Karta (Perechisleniye)')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank Hisob Raqami')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentType = val);
                  },
                ),
                const SizedBox(height: 16),
              ],

              const Text('Izoh (Ixtiyoriy):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(hintText: 'Nima uchun kiritilayotgani haqida izoh...'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Bekor qilish', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePayment,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Saqlash'),
        ),
      ],
    );
  }
}

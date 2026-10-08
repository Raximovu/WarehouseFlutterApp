import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/material_model.dart';
import '../../../models/partner_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/material_service.dart';
import '../../../services/partner_service.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/simple_date_picker.dart';

class PrixodDialog extends StatefulWidget {
  const PrixodDialog({super.key});

  @override
  State<PrixodDialog> createState() => _PrixodDialogState();
}

class _PrixodDialogState extends State<PrixodDialog> {
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  final _materialService = MaterialService();
  final _partnerService = PartnerService();
  final _transactionService = TransactionService();

  List<MaterialModel> _materials = [];
  List<PartnerModel> _partners = [];

  MaterialModel? _selectedMaterial;
  PartnerModel? _selectedPartner;
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  bool _isLoading = true;
  bool _isSaving = false;
  double _totalSum = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final materials = await _materialService.getAllMaterials();
      final partners = await _partnerService.getAllPartners(type: 'taminotchi'); // Faqat Ta'minotchilar

      setState(() {
        _materials = materials;
        _partners = partners;

        if (materials.isNotEmpty) {
          _selectedMaterial = materials.first;
        }

        if (partners.isNotEmpty) {
          _selectedPartner = partners.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _recalculateTotal() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    setState(() {
      _totalSum = amount * price;
    });
  }

  Future<void> _saveTransaction() async {
    if (_selectedMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, xomashyo yoki mahsulotni tanlang!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    final amountText = _amountController.text.trim();
    final priceText = _priceController.text.trim();

    final amount = double.tryParse(amountText);
    final price = double.tryParse(priceText) ?? 0.0;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('To\'g\'ri miqdorni kiriting!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDate);

      // Agar xomashyo bo'lsa 'kirim', tayyor mahsulot (qop) bo'lsa 'tayyor_kirim'
      final isReadyProduct = _selectedMaterial!.categoryName?.toLowerCase().contains('qop') ?? false;
      final txType = isReadyProduct ? 'tayyor_kirim' : 'kirim';

      final transaction = TransactionModel(
        date: dateStr,
        type: txType,
        partnerId: _selectedPartner?.id, // Kirim asosan Ta'minotchidan bo'ladi
        categoryId: _selectedMaterial!.categoryId,
        name: _selectedMaterial!.name,
        amount: amount,
        unitId: _selectedMaterial!.unitId,
        price: price,
        totalSum: amount * price,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await _transactionService.addTransaction(transaction);

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
    return AlertDialog(
      title: const Text('Omborga Kirim (Prixod)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: _isLoading
          ? const SizedBox(width: 500, height: 200, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sana:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SimpleDatePicker(
                          selectedDate: _selectedDate,
                          onChanged: (newDate) => setState(() => _selectedDate = newDate),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Ta\'minotchi (Kimdan olib kelindi):', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<PartnerModel>(
                        isExpanded: true,
                        value: _selectedPartner,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        items: _partners.map((p) {
                          return DropdownMenuItem<PartnerModel>(
                            value: p,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPartner = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text('Xomashyo / Mahsulot:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<MaterialModel>(
                        isExpanded: true,
                        value: _selectedMaterial,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        items: _materials.map((m) {
                          return DropdownMenuItem<MaterialModel>(
                            value: m,
                            child: Text(m.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMaterial = val);
                        },
                      ),
                      if (_selectedMaterial != null) ...[
                        const SizedBox(height: 6),
                        Text('O\'lchov Birligi: ${_selectedMaterial!.unitName ?? 'Noma\'lum'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Miqdori (${_selectedMaterial?.unitName ?? ''}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: '0.00'),
                                  onChanged: (_) => _recalculateTotal(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kelish Narxi (So\'m):', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: '0.00'),
                                  onChanged: (_) => _recalculateTotal(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Jami Summa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('${_totalSum.toStringAsFixed(2)} So\'m', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Izoh (Ixtiyoriy):', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(hintText: 'Mashina raqami, haydovchi ismi va h.k...'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Bekor qilish', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveTransaction,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Saqlash'),
        ),
      ],
    );
  }
}

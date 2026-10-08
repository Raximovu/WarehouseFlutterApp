import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/material_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/material_service.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/simple_date_picker.dart';

class AddInitialBalanceDialog extends StatefulWidget {
  final TransactionModel? initialTransaction; 

  const AddInitialBalanceDialog({
    super.key,
    this.initialTransaction,
  });

  @override
  State<AddInitialBalanceDialog> createState() => _AddInitialBalanceDialogState();
}

class _AddInitialBalanceDialogState extends State<AddInitialBalanceDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;

  final _materialService = MaterialService();
  final _transactionService = TransactionService();

  List<MaterialModel> _materials = [];
  MaterialModel? _selectedMaterial;
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  bool _isLoading = true;
  bool _isSaving = false;
  double _totalSum = 0.0;

  @override
  void initState() {
    super.initState();
    final initTx = widget.initialTransaction;

    _amountController = TextEditingController(text: initTx != null ? initTx.amount.toString() : '');
    _priceController = TextEditingController(text: initTx != null ? initTx.price.toString() : '');
    _notesController = TextEditingController(text: initTx?.notes ?? '');

    if (initTx != null) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(initTx.date.split(' ')[0]);
      } catch (_) {
        final now = DateTime.now();
        _selectedDate = DateTime(now.year, now.month, now.day);
      }
      _totalSum = initTx.totalSum;
    }

    _loadMaterials();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);
    try {
      final materials = await _materialService.getAllMaterials();
      setState(() {
        _materials = materials;
        if (materials.isNotEmpty) {
          if (widget.initialTransaction != null) {
            _selectedMaterial = materials.firstWhere(
              (m) => m.categoryId == widget.initialTransaction!.categoryId && m.name == widget.initialTransaction!.name,
              orElse: () => materials.first,
            );
          } else {
            _selectedMaterial = materials.first;
          }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, xomashyo/mahsulotni tanlang!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    final amountText = _amountController.text.trim();
    final priceText = _priceController.text.trim();

    final amount = double.tryParse(amountText);
    final price = double.tryParse(priceText) ?? 0.0; 

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, to\'g\'ri miqdorni kiriting!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDate);

      final transaction = TransactionModel(
        id: widget.initialTransaction?.id,
        date: dateStr,
        type: 'boshlangich_qoldiq', 
        partnerId: null, 
        categoryId: _selectedMaterial!.categoryId,
        name: _selectedMaterial!.name,
        amount: amount,
        unitId: _selectedMaterial!.unitId,
        price: price,
        totalSum: amount * price,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (widget.initialTransaction != null) {
        await _transactionService.updateTransaction(transaction);
      } else {
        await _transactionService.addTransaction(transaction);
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
    final isEdit = widget.initialTransaction != null;

    return AlertDialog(
      title: Text(isEdit ? 'Boshlang\'ich Qoldiqni Tahrirlash' : 'Boshlang\'ich Qoldiq Kiritish', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: _isLoading
          ? const SizedBox(width: 450, height: 200, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Qoldiq Sanasi:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SimpleDatePicker(
                          selectedDate: _selectedDate,
                          onChanged: (newDate) => setState(() => _selectedDate = newDate),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Xomashyo yoki Mahsulot:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                Text('Qoldiq Miqdori (${_selectedMaterial?.unitName ?? ''}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Masalan: 100'),
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
                                const Text('Bir Birlik Narxi (So\'m):', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Masalan: 50000'),
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
                            const Text('Jami Qoldiq Summasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('${_totalSum.toStringAsFixed(2)} So\'m', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Izoh (Ixtiyoriy):', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(hintText: 'Qo\'shimcha ma\'lumot yoki omborchi ismi...'),
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
              : Text(isEdit ? 'O\'zgarishlarni Saqlash' : 'Saqlash'),
        ),
      ],
    );
  }
}

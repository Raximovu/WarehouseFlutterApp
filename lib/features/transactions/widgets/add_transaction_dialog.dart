import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/material_model.dart';
import '../../../models/partner_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/inventory_service.dart';
import '../../../services/material_service.dart';
import '../../../services/partner_service.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/simple_date_picker.dart';

class AddTransactionDialog extends StatefulWidget {
  final String transactionType; 
  final TransactionModel? initialTransaction; 

  const AddTransactionDialog({
    super.key,
    required this.transactionType,
    this.initialTransaction,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;

  final _materialService = MaterialService();
  final _partnerService = PartnerService();
  final _transactionService = TransactionService();
  final _inventoryService = InventoryService();
  final _numberFormat = NumberFormat('#,##0.00', 'uz');

  List<MaterialModel> _materials = [];
  List<PartnerModel> _partners = [];
  Map<String, double> _stockMap = {}; // Mahsulot nomi bo'yicha joriy qoldiq

  MaterialModel? _selectedMaterial;
  PartnerModel? _selectedPartner;
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  bool _isLoading = true;
  bool _isSaving = false;
  double _totalSum = 0.0;

  bool get _isChiqim => 
      widget.transactionType == 'chiqim_sex' || 
      widget.transactionType == 'sotuv' || 
      widget.transactionType == 'brak';

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
      var allMaterials = await _materialService.getAllMaterials();
      
      // Sklad qoldiqlarini yuklash
      final balances = await _inventoryService.getInventoryBalances();
      final Map<String, double> stockMap = {};
      for (var b in balances) {
        final name = b['name'].toString();
        final amount = (b['current_amount'] as num).toDouble();
        stockMap[name] = amount;
      }

      // Chiqim bo'lsa: Faqat omborda joriy qoldig'i 0 dan baland bo'lgan mahsulotlar ko'rinsin
      if (_isChiqim && widget.initialTransaction == null) {
        allMaterials = allMaterials.where((m) {
          final stock = stockMap[m.name] ?? 0.0;
          return stock > 0;
        }).toList();
      }

      String? partnerType;
      if (widget.transactionType == 'kirim') partnerType = 'taminotchi';
      if (widget.transactionType == 'sotuv') partnerType = 'mijoz';

      final partners = partnerType != null
          ? await _partnerService.getAllPartners(type: partnerType)
          : <PartnerModel>[];

      setState(() {
        _stockMap = stockMap;
        _materials = allMaterials;
        _partners = partners;

        if (allMaterials.isNotEmpty) {
          if (widget.initialTransaction != null) {
            _selectedMaterial = allMaterials.firstWhere(
              (m) => m.categoryId == widget.initialTransaction!.categoryId && m.name == widget.initialTransaction!.name,
              orElse: () => allMaterials.first,
            );
          } else {
            _selectedMaterial = allMaterials.first;
          }
        }

        if (partners.isNotEmpty) {
          if (widget.initialTransaction != null && widget.initialTransaction!.partnerId != null) {
            _selectedPartner = partners.firstWhere(
              (p) => p.id == widget.initialTransaction!.partnerId,
              orElse: () => partners.first,
            );
          } else {
            _selectedPartner = partners.first;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ma\'lumotlarni yuklashda xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _currentStock {
    if (_selectedMaterial == null) return 0.0;
    return _stockMap[_selectedMaterial!.name] ?? 0.0;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, mahsulotni tanlang!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('To\'g\'ri miqdorni kiriting!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    // Chiqim uchun qoldiqni tekshirish (Tahrirlashda emas, faqat yangi chiqimda)
    if (_isChiqim && widget.initialTransaction == null) {
      if (amount > _currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Xatolik! Kiritilgan miqdor (${_numberFormat.format(amount)}) ombordagi joriy qoldiqdan (${_numberFormat.format(_currentStock)}) oshib ketdi!'), 
          backgroundColor: AppTheme.errorColor,
        ));
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final transaction = TransactionModel(
        id: widget.initialTransaction?.id,
        date: dateStr,
        type: widget.transactionType,
        partnerId: _selectedPartner?.id,
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

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saqlashda xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String get _titleText {
    final isEdit = widget.initialTransaction != null;
    if (isEdit) return 'Operatsiyani Tahrirlash';

    switch (widget.transactionType) {
      case 'kirim': return 'Xomashyo Kirimi';
      case 'chiqim_sex': return 'Ishlab chiqarishga Chiqim';
      case 'tayyor_kirim': return 'Tayyor Qop Kirimi';
      case 'sotuv': return 'Sotuv (Mijozga)';
      case 'brak': return 'Brak (Yaroqsiz)';
      default: return 'Ombor Operatsiyasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialTransaction != null;

    return AlertDialog(
      title: Text(_titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

                      if (widget.transactionType == 'kirim' || widget.transactionType == 'sotuv') ...[
                        Text(widget.transactionType == 'kirim' ? 'Ta\'minotchi (Kimdan olindi):' : 'Mijoz (Kimga sotildi):', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<PartnerModel>(
                          isExpanded: true,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                          value: _selectedPartner,
                          items: _partners.map((p) => DropdownMenuItem<PartnerModel>(
                            value: p, 
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPartner = val);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text('Xomashyo / Mahsulotni Tanlang:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_materials.isEmpty && _isChiqim) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(child: Text('Omborda chiqim qilish uchun birorta ham tayyor mahsulot yoki xomashyo qolmagan!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))),
                            ],
                          ),
                        ),
                      ] else ...[
                        DropdownButtonFormField<MaterialModel>(
                          isExpanded: true,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                          value: _selectedMaterial,
                          items: _materials.map((m) => DropdownMenuItem<MaterialModel>(
                            value: m, 
                            child: Text(m.name, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMaterial = val);
                          },
                        ),
                      ],

                      if (_selectedMaterial != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('O\'lchov Birligi: ${_selectedMaterial!.unitName ?? 'Noma\'lum'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            if (_isChiqim)
                              Text(
                                'Joriy Qoldiq: ${_numberFormat.format(_currentStock)} ${_selectedMaterial!.unitName ?? ''}', 
                                style: TextStyle(
                                  color: _currentStock > 0 ? AppTheme.primaryColor : Colors.red, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
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
                                const Text('Bir Birlik Narxi (So\'m):', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
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
                      TextField(controller: _notesController, decoration: const InputDecoration(hintText: 'Qo\'shimcha eslatma yoki mashina raqami')),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(false), child: const Text('Bekor qilish', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: (_isSaving || (_isChiqim && _materials.isEmpty)) ? null : _saveTransaction,
          child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEdit ? 'O\'zgarishlarni Saqlash' : 'Saqlash'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/material_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/inventory_service.dart';
import '../../../services/material_service.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/simple_date_picker.dart';

class BrakDialog extends StatefulWidget {
  const BrakDialog({super.key});

  @override
  State<BrakDialog> createState() => _BrakDialogState();
}

class _BrakDialogState extends State<BrakDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final _materialService = MaterialService();
  final _inventoryService = InventoryService();
  final _transactionService = TransactionService();

  List<MaterialModel> _materials = [];
  MaterialModel? _selectedMaterial;
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  double _currentStock = 0.0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    _amountController.dispose();
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
          _selectedMaterial = materials.first;
          _loadCurrentStock(_selectedMaterial!);
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

  Future<void> _loadCurrentStock(MaterialModel material) async {
    try {
      final balances = await _inventoryService.getInventoryBalances();
      final item = balances.cast<Map<String, dynamic>?>().firstWhere(
            (b) => b!['material_id'] == material.id,
            orElse: () => null,
          );

      setState(() {
        _currentStock = item != null ? (item['current_amount'] as num).toDouble() : 0.0;
      });
    } catch (_) {
      setState(() {
        _currentStock = 0.0;
      });
    }
  }

  Future<void> _saveBrak() async {
    if (_selectedMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, mahsulotni tanlang!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('To\'g\'ri miqdorni kiriting!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    if (amount > _currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiritilgan brak miqdori ombordagi qoldiqdan oshib ketdi!'), backgroundColor: AppTheme.errorColor));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDate);

      final transaction = TransactionModel(
        date: dateStr,
        type: 'brak', 
        partnerId: null, 
        categoryId: _selectedMaterial!.categoryId,
        name: _selectedMaterial!.name,
        amount: amount,
        unitId: _selectedMaterial!.unitId,
        price: 0, 
        totalSum: 0, 
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
      title: const Text('Brak (Yaroqsiz Mahsulot) Chiqim Qilish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

                      const Text('Yaroqsiz Chiqqan Mahsulot:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          if (val != null) {
                            setState(() {
                              _selectedMaterial = val;
                              _loadCurrentStock(val);
                            });
                          }
                        },
                      ),
                      if (_selectedMaterial != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('O\'lchov Birligi: ${_selectedMaterial!.unitName ?? 'Noma\'lum'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('Joriy Qoldiq: $_currentStock', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      const Text('Brak Miqdori:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Masalan: 10'),
                      ),
                      const SizedBox(height: 16),

                      const Text('Sabab / Izoh (Ixtiyoriy):', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(hintText: 'Nima sababdan brak qilingani haqida...'),
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
          onPressed: _isSaving ? null : _saveBrak,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Brak Qilish'),
        ),
      ],
    );
  }
}

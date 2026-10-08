import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/excel_service.dart';
import '../../services/inventory_service.dart';
import '../transactions/widgets/add_transaction_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _inventoryService = InventoryService();
  final _excelService = ExcelService();
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat('#,##0.00', 'uz');

  List<Map<String, dynamic>> _balances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final balances = await _inventoryService.getInventoryBalances();
      setState(() {
        _balances = balances;
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

  Future<void> _openAddTransactionDialog(String type) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddTransactionDialog(transactionType: type),
    );

    if (result == true) {
      _loadInventory();
    }
  }

  Future<void> _exportToExcel() async {
    if (_filteredBalances.isEmpty) return;

    try {
      final success = await _excelService.exportInventoryToExcel(_filteredBalances);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel hisoboti saqlandi!'), backgroundColor: AppTheme.primaryColor));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excelga saqlashda xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredBalances {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _balances;
    return _balances.where((item) {
      final name = item['name'].toString().toLowerCase();
      final category = item['category_name'].toString().toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  double get _totalInventorySum {
    return _filteredBalances.fold(0.0, (sum, item) => sum + (item['current_total_sum'] as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBalances;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Qidiruv maydoni, Kirim, Chiqim va Excel tugmalari
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Mahsulot nomi yoki toifasi bo\'yicha qidirish...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // KIRIM TUGMASI (Xomashyo, Tayyor Mahsulot, Brak Kirimi)
                      PopupMenuButton<String>(
                        tooltip: 'Kirim Operatsiyalari',
                        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadius),
                        onSelected: (type) => _openAddTransactionDialog(type),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem(
                            value: 'kirim',
                            child: ListTile(
                              leading: Icon(Icons.add_shopping_cart, color: AppTheme.primaryColor),
                              title: Text('Xomashyo Kirimi'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'tayyor_kirim',
                            child: ListTile(
                              leading: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
                              title: Text('Tayyor Mahsulot Kirimi'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'brak_kirim',
                            child: ListTile(
                              leading: Icon(Icons.warning_amber_rounded, color: Colors.amber),
                              title: Text('Brak Kirimi (Sexdan)'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        child: ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.add_box_outlined, size: 18),
                          label: const Text('Kirim'),
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: AppTheme.primaryColor,
                            disabledForegroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // CHIQIM TUGMASI (Ishlab chiqarishga, Sotuv, Brak Chiqimi)
                      PopupMenuButton<String>(
                        tooltip: 'Chiqim Operatsiyalari',
                        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadius),
                        onSelected: (type) => _openAddTransactionDialog(type),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem(
                            value: 'chiqim_sex',
                            child: ListTile(
                              leading: Icon(Icons.factory_outlined, color: Colors.orange),
                              title: Text('Ishlab chiqarishga Chiqim'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'sotuv',
                            child: ListTile(
                              leading: Icon(Icons.shopping_cart_checkout, color: Colors.blue),
                              title: Text('Sotuv (Mijozga)'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'brak',
                            child: ListTile(
                              leading: Icon(Icons.warning_amber_outlined, color: Colors.red),
                              title: Text('Brak Chiqimi / Sotuvi'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.unarchive_outlined, size: 18),
                          label: const Text('Chiqim'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // EXCELGA SAQLASH
                      OutlinedButton.icon(
                        onPressed: _exportToExcel,
                        icon: const Icon(Icons.table_view_outlined, color: Colors.green, size: 18),
                        label: const Text('Excelga Saqlash'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sklad Qoldiqlari Soft Flat Jadvali
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Container(
                          decoration: AppTheme.cardDecoration(context),
                          child: const Center(
                            child: Text('Omborda ma\'lumotlar topilmadi.'),
                          ),
                        )
                      : Container(
                          decoration: AppTheme.cardDecoration(context),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                color: AppTheme.tableHeaderBg(context),
                                child: const Row(
                                  children: [
                                    SizedBox(width: 40, child: Text('№', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    Expanded(flex: 3, child: Text('Mahsulot Nomi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    Expanded(flex: 2, child: Text('Toifasi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    Expanded(flex: 2, child: Text('Miqdori', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    SizedBox(width: 80, child: Text('Birligi', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    Expanded(flex: 2, child: Text('Jami Summa', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                  ],
                                ),
                              ),

                              // Data Rows
                              Expanded(
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) => Container(
                                    height: 1,
                                    color: AppTheme.dividerColor(context),
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    final amount = (item['current_amount'] as num).toDouble();
                                    final totalSum = (item['current_total_sum'] ?? 0 as num).toDouble();

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 40, child: Text('${index + 1}', style: const TextStyle(color: Colors.grey))),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              item['name'].toString(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2, 
                                            child: Text(
                                              item['category_name'].toString(), 
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              _numberFormat.format(amount),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 80, 
                                            child: Text(
                                              item['unit_name'].toString(), 
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${_numberFormat.format(totalSum)} So\'m',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                fontSize: 13,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Bottom Total Row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                color: AppTheme.tableHeaderBg(context),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 40, child: Text('JAMI', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 3, child: Text('${filtered.length} xil mahsulot', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    const Expanded(flex: 2, child: SizedBox()),
                                    const Expanded(flex: 2, child: SizedBox()),
                                    const SizedBox(width: 80),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${_numberFormat.format(_totalInventorySum)} So\'m',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

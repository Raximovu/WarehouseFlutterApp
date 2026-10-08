import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/transaction_model.dart';
import '../../services/excel_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/simple_date_picker.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/transaction_detail_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _transactionService = TransactionService();
  final _excelService = ExcelService();
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat('#,##0.00', 'uz');

  String _selectedTab = 'all'; // 'all', 'kirim', 'chiqim_sex', 'tayyor_kirim', 'sotuv', 'brak'
  bool _isLoading = true;

  DateTime _fromDate = DateTime(2020, 1, 1);
  DateTime _toDate = DateTime.now();

  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedTab == 'all') {
        final recent = await _transactionService.getRecentTransactions(limit: 500);
        setState(() => _transactions = recent);
      } else {
        final filtered = await _transactionService.getTransactionsByType(_selectedTab);
        setState(() => _transactions = filtered);
      }
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

  Future<void> _openTransactionDetailDialog(TransactionModel transaction) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TransactionDetailDialog(transaction: transaction),
    );

    if (result == true) {
      _loadTransactions();
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text('Siz rostdan ham "${transaction.name}" bo\'yicha ushbu operatsiyani o\'chirmoqchimisiz?'),
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
        await _transactionService.deleteTransaction(transaction.id!);
        _loadTransactions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Muvaffaqiyatli o\'chirildi'), backgroundColor: AppTheme.primaryColor));
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
    if (_filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saqlash uchun ma\'lumot yo\'q!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    try {
      final success = await _excelService.exportTransactionsToExcel(_filteredTransactions);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel hisoboti saqlandi!'), backgroundColor: AppTheme.primaryColor));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excelga saqlashda xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    }
  }

  List<TransactionModel> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();
    
    final start = DateTime(_fromDate.year, _fromDate.month, _fromDate.day, 0, 0, 0);
    final end = DateTime(_toDate.year, _toDate.month, _toDate.day, 23, 59, 59);

    return _transactions.where((t) {
      bool matchesSearch = true;
      if (query.isNotEmpty) {
        matchesSearch = t.name.toLowerCase().contains(query);
      }

      bool matchesDate = true;
      try {
        final dateOnlyStr = t.date.split(' ')[0];
        final txDate = DateFormat('yyyy-MM-dd').parse(dateOnlyStr);
        matchesDate = txDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                      txDate.isBefore(end.add(const Duration(seconds: 1)));
      } catch (_) {}

      return matchesSearch && matchesDate;
    }).toList();
  }

  double get _totalSum {
    return _filteredTransactions.fold(0.0, (sum, item) => sum + item.totalSum);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Operatsiya Tablari
            Row(
              children: [
                Expanded(child: _buildTabButton('all', 'Barcha Harakatlar')),
                const SizedBox(width: 8),
                Expanded(child: _buildTabButton('kirim', 'Xomashyo Kirimi')),
                const SizedBox(width: 8),
                Expanded(child: _buildTabButton('chiqim_sex', 'Ishlab chiqarishga Chiqim')),
                const SizedBox(width: 8),
                Expanded(child: _buildTabButton('tayyor_kirim', 'Tayyor Kirim')),
                const SizedBox(width: 8),
                Expanded(child: _buildTabButton('sotuv', 'Sotuvlar')),
                const SizedBox(width: 8),
                Expanded(child: _buildTabButton('brak', 'Braklar')),
              ],
            ),
            const SizedBox(height: 16),

            // Sana filtri va Excelga saqlash
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppTheme.cardDecoration(context),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SimpleDatePicker(
                      selectedDate: _fromDate,
                      onChanged: (newDate) => setState(() => _fromDate = newDate),
                    ),
                    const SizedBox(width: 12),
                    const Text('dan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 12),
                    SimpleDatePicker(
                      selectedDate: _toDate,
                      onChanged: (newDate) => setState(() => _toDate = newDate),
                    ),
                    const SizedBox(width: 12),
                    const Text('gacha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 24),

                    // Yashil fonli [Hammasi] tugmasi
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _fromDate = DateTime(2020, 1, 1);
                          _toDate = DateTime.now();
                        });
                      },
                      child: const Text('Hammasi'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _exportToExcel,
                      icon: const Icon(Icons.table_view_outlined, color: Colors.green, size: 18),
                      label: const Text('Excelga Saqlash'),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Nomi bo\'yicha qidirish...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tushunarli Ustunli Jadval
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Container(
                          decoration: AppTheme.cardDecoration(context),
                          child: const Center(
                            child: Text('Tanlangan oraliqda ombor harakatlari topilmadi.'),
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
                                    Expanded(flex: 2, child: Text('Sana', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    Expanded(flex: 2, child: Text('Operatsiya Turi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    Expanded(flex: 3, child: Text('Mahsulot Nomi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    Expanded(flex: 2, child: Text('Miqdori', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    Expanded(flex: 2, child: Text('Narxi', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    Expanded(flex: 2, child: Text('Jami Summa', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    SizedBox(width: 140, child: Text('Amallar', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                  ],
                                ),
                              ),

                              // Data
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
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 40, child: Text('${index + 1}', style: const TextStyle(color: Colors.grey))),
                                          Expanded(flex: 2, child: Text(formatAppDate(item.date), style: const TextStyle(fontSize: 13, color: Colors.grey))),
                                          Expanded(flex: 2, child: Text(item.typeLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                          Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              _numberFormat.format(item.amount),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              _numberFormat.format(item.price),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${_numberFormat.format(item.totalSum)} So\'m',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 140,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                                  onPressed: () => _openTransactionDetailDialog(item),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                                                  onPressed: () async {
                                                    final result = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AddTransactionDialog(
                                                        transactionType: item.type,
                                                        initialTransaction: item,
                                                      ),
                                                    );
                                                    if (result == true) _loadTransactions();
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                  onPressed: () => _deleteTransaction(item),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Total
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                color: AppTheme.tableHeaderBg(context),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 40, child: Text('JAMI', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const Expanded(flex: 2, child: SizedBox()),
                                    const Expanded(flex: 2, child: SizedBox()),
                                    Expanded(flex: 3, child: Text('${filtered.length} ta operatsiya', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    const Expanded(flex: 2, child: SizedBox()),
                                    const Expanded(flex: 2, child: SizedBox()),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${_numberFormat.format(_totalSum)} So\'m',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
                                      ),
                                    ),
                                    const SizedBox(width: 140),
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

  Widget _buildTabButton(String tabKey, String label) {
    final isSelected = _selectedTab == tabKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.darkSurface : Colors.white),
        foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        side: isSelected ? BorderSide.none : BorderSide(color: AppTheme.dividerColor(context)),
      ),
      onPressed: () {
        setState(() => _selectedTab = tabKey);
        _loadTransactions();
      },
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

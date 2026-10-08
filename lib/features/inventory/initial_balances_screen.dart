import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import 'widgets/add_initial_balance_dialog.dart';

class InitialBalancesScreen extends StatefulWidget {
  const InitialBalancesScreen({super.key});

  @override
  State<InitialBalancesScreen> createState() => _InitialBalancesScreenState();
}

class _InitialBalancesScreenState extends State<InitialBalancesScreen> {
  final _transactionService = TransactionService();
  final _numberFormat = NumberFormat('#,##0.00', 'uz');

  List<TransactionModel> _initialBalances = [];
  bool _isLoading = true;

  // Saralash (Sort) holatlari (Sana, Nomi, Miqdori, Narxi va Summa bo'yicha)
  String _sortColumn = 'date'; 
  bool _sortAscending = false; // Odatiy holda eng yangi sanalar tepada bo'ladi

  @override
  void initState() {
    super.initState();
    _loadInitialBalances();
  }

  Future<void> _loadInitialBalances() async {
    setState(() => _isLoading = true);
    try {
      final list = await _transactionService.getInitialBalances();
      setState(() {
        _initialBalances = list;
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

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending; // Yo'nalishni o'zgartirish (Tepadan pastga / Pastdan tepaga)
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  List<TransactionModel> get _sortedBalances {
    final list = List<TransactionModel>.from(_initialBalances);
    list.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'name':
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'totalSum':
          comparison = a.totalSum.compareTo(b.totalSum);
          break;
        default:
          comparison = 0;
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    return list;
  }

  Future<void> _openAddInitialBalanceDialog({TransactionModel? item}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddInitialBalanceDialog(initialTransaction: item),
    );

    if (result == true) {
      _loadInitialBalances();
    }
  }

  Future<void> _deleteInitialBalance(TransactionModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text('Siz rostdan ham "${item.name}" boshlang\'ich qoldig\'ini o\'chirmoqchimisiz?'),
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
        await _transactionService.deleteTransaction(item.id!);
        _loadInitialBalances();
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

  double get _totalInitialSum {
    return _initialBalances.fold(0.0, (sum, item) => sum + item.totalSum);
  }

  @override
  Widget build(BuildContext context) {
    final sortedList = _sortedBalances;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Boshlang\'ich Qoldiqlar Ro\'yxati', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _openAddInitialBalanceDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Boshlang\'ich Qoldiq Qo\'shish'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : sortedList.isEmpty
                      ? Container(
                          decoration: AppTheme.cardDecoration(context),
                          child: const Center(
                            child: Text('Boshlang\'ich qoldiqlar topilmadi. "Boshlang\'ich Qoldiq Qo\'shish" tugmasini bosing.'),
                          ),
                        )
                      : Container(
                          decoration: AppTheme.cardDecoration(context),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              // Interactive Header (Chaqirib bosganda saralaydi)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                color: AppTheme.tableHeaderBg(context),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 50, child: Text('№', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    _buildHeaderCell(title: 'Sana', columnKey: 'date', flex: 2),
                                    _buildHeaderCell(title: 'Mahsulot Nomi', columnKey: 'name', flex: 3),
                                    _buildHeaderCell(title: 'Miqdori', columnKey: 'amount', flex: 2, textAlign: TextAlign.right),
                                    _buildHeaderCell(title: 'Narxi (So\'m)', columnKey: 'price', flex: 2, textAlign: TextAlign.right),
                                    _buildHeaderCell(title: 'Jami Summa', columnKey: 'totalSum', flex: 2, textAlign: TextAlign.right),
                                    const SizedBox(width: 90, child: Text('Amallar', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                  ],
                                ),
                              ),

                              // Data Rows
                              Expanded(
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: sortedList.length,
                                  separatorBuilder: (context, index) => Container(
                                    height: 1,
                                    color: AppTheme.dividerColor(context),
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = sortedList[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 50, child: Text('${index + 1}', style: const TextStyle(color: Colors.grey))),
                                          Expanded(flex: 2, child: Text(formatAppDate(item.date), style: const TextStyle(fontSize: 13, color: Colors.grey))),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
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
                                            width: 90,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                                  onPressed: () => _openAddInitialBalanceDialog(item: item),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                  onPressed: () => _deleteInitialBalance(item),
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

                              // Bottom Total Row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                color: AppTheme.tableHeaderBg(context),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 50, child: Text('JAMI', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const Expanded(flex: 2, child: SizedBox()),
                                    Expanded(flex: 3, child: Text('${sortedList.length} xil yozuv', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    const Expanded(flex: 2, child: SizedBox()),
                                    const Expanded(flex: 2, child: SizedBox()),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${_numberFormat.format(_totalInitialSum)} So\'m',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
                                      ),
                                    ),
                                    const SizedBox(width: 90),
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

  Widget _buildHeaderCell({
    required String title,
    required String columnKey,
    TextAlign textAlign = TextAlign.left,
    int? flex,
    double? width,
  }) {
    final isSelected = _sortColumn == columnKey;
    final icon = isSelected
        ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
        : Icons.unfold_more;

    final Widget childWidget = InkWell(
      onTap: () => _onSort(columnKey),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: textAlign == TextAlign.right
              ? MainAxisAlignment.end
              : (textAlign == TextAlign.center ? MainAxisAlignment.center : MainAxisAlignment.start),
          children: [
            Flexible(
              child: Text(
                title,
                textAlign: textAlign,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: childWidget);
    }
    return Expanded(flex: flex ?? 1, child: childWidget);
  }
}

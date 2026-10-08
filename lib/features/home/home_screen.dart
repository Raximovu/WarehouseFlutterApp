import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/transaction_model.dart';
import '../../services/inventory_service.dart';
import '../../services/partner_service.dart';
import '../../services/transaction_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _inventoryService = InventoryService();
  final _partnerService = PartnerService();
  final _transactionService = TransactionService();
  final _numberFormat = NumberFormat('#,##0.00', 'uz');

  bool _isLoading = true;

  double _rawMaterialTotalSum = 0.0;
  double _bagsTotalSum = 0.0;
  double _totalDebitorSum = 0.0;
  double _totalCreditorSum = 0.0;
  List<TransactionModel> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final balances = await _inventoryService.getInventoryBalances();
      double rawSum = 0.0;
      double bagSum = 0.0;

      for (var item in balances) {
        final category = item['category_name'].toString().toLowerCase();
        final sum = (item['current_total_sum'] as num).toDouble();
        if (category.contains('qop')) {
          bagSum += sum;
        } else {
          rawSum += sum;
        }
      }

      final partners = await _partnerService.getPartnersWithBalance();
      double debitorSum = 0.0;
      double creditorSum = 0.0;

      for (var p in partners) {
        if (p.type == 'mijoz' && p.clientBalance > 0) {
          debitorSum += p.clientBalance;
        } else if (p.type == 'taminotchi' && p.supplierBalance > 0) {
          creditorSum += p.supplierBalance;
        }
      }

      final recent = await _transactionService.getRecentTransactions(limit: 10);

      setState(() {
        _rawMaterialTotalSum = rawSum;
        _bagsTotalSum = bagSum;
        _totalDebitorSum = debitorSum;
        _totalCreditorSum = creditorSum;
        _recentTransactions = recent;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
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
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits from parent wrapper
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth > 1100
                          ? (constraints.maxWidth - 48) / 4
                          : constraints.maxWidth > 700
                              ? (constraints.maxWidth - 16) / 2
                              : constraints.maxWidth;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _StatCard(
                            width: cardWidth,
                            title: 'Xomashyo Qoldig\'i',
                            value: '${_numberFormat.format(_rawMaterialTotalSum)} So\'m',
                            subtitle: 'Ombordagi joriy xomashyolar',
                            icon: Icons.inventory_2_outlined,
                          ),
                          _StatCard(
                            width: cardWidth,
                            title: 'Tayyor Qoplar',
                            value: '${_numberFormat.format(_bagsTotalSum)} So\'m',
                            subtitle: 'Sotuvga tayyor mahsulotlar',
                            icon: Icons.shopping_bag_outlined,
                          ),
                          _StatCard(
                            width: cardWidth,
                            title: 'Mijozlar Qarzi',
                            value: '${_numberFormat.format(_totalDebitorSum)} So\'m',
                            subtitle: 'Bizga to\'lanishi kerak bo\'lgan summa',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          _StatCard(
                            width: cardWidth,
                            title: 'Ta\'minotchilarga Qarz',
                            value: '${_numberFormat.format(_totalCreditorSum)} So\'m',
                            subtitle: 'Biz to\'lashimiz kerak bo\'lgan summa',
                            icon: Icons.credit_card_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'So\'nggi 10 ta Amal va Harakatlar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loadDashboardData,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Yangilash'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: _recentTransactions.isEmpty
                        ? Container(
                            decoration: AppTheme.cardDecoration(context),
                            child: const Center(
                              child: Text('Hozircha hech qanday harakat bajarilmadi.'),
                            ),
                          )
                        : Container(
                            decoration: AppTheme.cardDecoration(context),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  color: AppTheme.tableHeaderBg(context),
                                  child: const Row(
                                    children: [
                                      SizedBox(width: 40, child: Text('№', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                      Expanded(flex: 2, child: Text('Sana', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                      Expanded(flex: 2, child: Text('Operatsiya Turi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                      Expanded(flex: 3, child: Text('Mahsulot / Xomashyo Nomi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                      Expanded(flex: 2, child: Text('Miqdori', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                      Expanded(flex: 2, child: Text('Jami Summa (So\'m)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    ],
                                  ),
                                ),

                                // Data Rows
                                Expanded(
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: _recentTransactions.length,
                                    separatorBuilder: (context, index) => Container(
                                      height: 1,
                                      color: AppTheme.dividerColor(context),
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = _recentTransactions[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        child: Row(
                                          children: [
                                            SizedBox(width: 40, child: Text('${index + 1}', style: const TextStyle(color: Colors.grey))),
                                            Expanded(flex: 2, child: Text(formatAppDate(item.date), style: const TextStyle(fontSize: 13, color: Colors.grey))),
                                            Expanded(flex: 2, child: Text(_getTransactionTypeLabel(item.type), style: const TextStyle(fontSize: 13))),
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
                                                '${_numberFormat.format(item.totalSum)} So\'m',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
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

class _StatCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: 130, // Rasmga mos ixchamlashtirilgan balandlik
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E232B), // Qora rangda aniq ko'rinishi uchun
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : const Color(0xFF495057),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

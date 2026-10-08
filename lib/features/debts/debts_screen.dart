import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/partner_balance_model.dart';
import '../../services/partner_service.dart';
import '../partners/widgets/add_payment_dialog.dart';
import '../partners/widgets/partner_sverka_dialog.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final _partnerService = PartnerService();
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat('#,##0.00', 'uz');

  // 0 = Barcha Balanslar, 1 = Mijozlar Qarzi, 2 = Mijozlar Haqdorligi, 3 = Ta'minotchilarga Qarz, 4 = Ta'minotchilarda Haqimiz
  int _selectedTab = 0;
  bool _isLoading = true;

  List<PartnerBalanceModel> _allPartners = [];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);
    try {
      final data = await _partnerService.getPartnersWithBalance();
      setState(() {
        _allPartners = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Tablar bo'yicha filtrlash:
  List<PartnerBalanceModel> get _filteredPartners {
    final query = _searchController.text.trim().toLowerCase();

    return _allPartners.where((p) {
      final matchesSearch =
          query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          (p.inn != null && p.inn!.contains(query));

      if (!matchesSearch) return false;

      final isClient = p.type == 'mijoz';
      final isSupplier = p.type == 'taminotchi';
      final clientBal = p.clientBalance;
      final suppBal = p.supplierBalance;

      switch (_selectedTab) {
        case 1: // Mijozlar Qarzi (Bizga pul berishi kerak)
          return isClient && clientBal > 0;
        case 2: // Mijozlar Haqdorligi (Mijoz bizga ortiqcha to'lagan/avans)
          return isClient && clientBal < 0;
        case 3: // Ta'minotchilarga Qarz (Biz ularga pul berishimiz kerak)
          return isSupplier && suppBal > 0;
        case 4: // Ta'minotchilarda Haqimiz (Biz oldindan avans berganmiz)
          return isSupplier && suppBal < 0;
        default: // Barcha balanslar (Faqat qarzi yoki haqi borlar)
          if (isClient && clientBal == 0) return false;
          if (isSupplier && suppBal == 0) return false;
          return true;
      }
    }).toList();
  }

  Future<void> _openAddPaymentDialog(PartnerBalanceModel partner) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AddPaymentDialog(partners: _allPartners, initialPartner: partner),
    );

    if (result == true) {
      _loadPartners();
    }
  }

  Future<void> _openSverkaDialog(PartnerBalanceModel partner) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PartnerSverkaDialog(partner: partner),
    );
    
    // Agar Sverka oynasidan biror yozuv (to'lov yoki harakat) o'chirilgan bo'lsa (true qaytsa), 
    // asosiy Qarzlar Balansi ro'yxatini ham yangilaymiz!
    if (result == true) {
      _loadPartners();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'To\'lanmagan';
    return formatAppDate(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 5 ta Tab
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton(0, 'Barchasi'),
                  const SizedBox(width: 8),
                  _buildTabButton(1, 'Mijozlar Qarzi'),
                  const SizedBox(width: 8),
                  _buildTabButton(2, 'Mijozlar Haqdorligi (Avans)'),
                  const SizedBox(width: 8),
                  _buildTabButton(3, 'Ta\'minotchilarga Qarz'),
                  const SizedBox(width: 8),
                  _buildTabButton(4, 'Ta\'minotchilarda Haqimiz'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Qidiruv Maydoni va To'lov Kiritish Tugmasi
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText:
                          'Kontragent ismi yoki STIR bo\'yicha qidirish...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _allPartners.isEmpty
                      ? null
                      : () => _openAddPaymentDialog(_allPartners.first),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('To\'lov kiritish'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Soft Flat Jadval
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildListContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? AppTheme.primaryColor
            : (isDark ? AppTheme.darkSurface : Colors.white),
        foregroundColor: isSelected
            ? Colors.white
            : (isDark ? Colors.white : Colors.black),
        elevation: 0,
        side: isSelected
            ? BorderSide.none
            : BorderSide(color: AppTheme.dividerColor(context)),
      ),
      onPressed: () => setState(() => _selectedTab = index),
      child: Text(title),
    );
  }

  Widget _buildListContent() {
    final list = _filteredPartners;

    if (list.isEmpty) {
      return Container(
        decoration: AppTheme.cardDecoration(context),
        child: const Center(
          child: Text('Ushbu kategoriyada ma\'lumotlar topilmadi.'),
        ),
      );
    }

    return Container(
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
                SizedBox(
                  width: 32,
                  child: Text(
                    '№',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Kontragent Nomi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STIR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Turi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Oxirgi To\'lov',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Joriy Balans / Holati',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),

                Expanded(
                  flex: 4,
                  child: Text(
                    'Amallar',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Data Rows
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: list.length,
              separatorBuilder: (context, index) =>
                  Container(height: 1, color: AppTheme.dividerColor(context)),
              itemBuilder: (context, index) {
                final p = list[index];
                final isClient = p.type == 'mijoz';
                final rawBal = isClient ? p.clientBalance : p.supplierBalance;

                Color badgeColor = Colors.grey;
                String balanceStatus =
                    '${_numberFormat.format(rawBal.abs())} So\'m';

                if (isClient) {
                  if (rawBal > 0) {
                    badgeColor = AppTheme.errorColor;
                    balanceStatus += ' (Qarzdor)';
                  } else if (rawBal < 0) {
                    badgeColor = AppTheme.primaryColor;
                    balanceStatus += ' (Haqdor)';
                  } else {
                    balanceStatus = '0.00 So\'m';
                  }
                } else {
                  if (rawBal > 0) {
                    badgeColor = AppTheme.warningColor;
                    balanceStatus += ' (Qarzimiz)';
                  } else if (rawBal < 0) {
                    badgeColor = AppTheme.primaryColor;
                    balanceStatus += ' (Haqimiz bor)';
                  } else {
                    balanceStatus = '0.00 So\'m';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.inn ?? 'Noma\'lum',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          isClient ? 'Mijoz' : 'Ta\'minotchi',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(p.lastPaymentDate),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          balanceStatus,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: rawBal == 0 ? Colors.grey : badgeColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openSverkaDialog(p),
                              icon: const Icon(Icons.history, size: 16),
                              label: const Text('Sverka'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _openAddPaymentDialog(p),
                              child: const Text('To\'lov / Qarz'),
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
        ],
      ),
    );
  }
}

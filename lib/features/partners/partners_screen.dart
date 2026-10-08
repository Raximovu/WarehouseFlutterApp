import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/partner_balance_model.dart';
import '../../models/partner_model.dart';
import '../../services/partner_service.dart';
import 'widgets/add_partner_dialog.dart';
import 'widgets/partner_sverka_dialog.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final _partnerService = PartnerService();
  final _searchController = TextEditingController();

  List<PartnerBalanceModel> _partners = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'mijoz', 'taminotchi'

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
      final type = _selectedFilter == 'all' ? null : _selectedFilter;
      final data = await _partnerService.getPartnersWithBalance(
        typeFilter: type,
      );
      setState(() {
        _partners = data;
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

  Future<void> _openAddPartnerDialog({PartnerBalanceModel? partner}) async {
    PartnerModel? partnerModel;
    if (partner != null) {
      partnerModel = PartnerModel(
        id: partner.id,
        name: partner.name,
        inn: partner.inn,
        type: partner.type,
        phone: partner.phone,
      );
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddPartnerDialog(initialPartner: partnerModel),
    );

    if (result == true) {
      _loadPartners();
    }
  }

  Future<void> _openSverkaDialog(PartnerBalanceModel partner) async {
    await showDialog(
      context: context,
      builder: (context) => PartnerSverkaDialog(partner: partner),
    );
  }

  Future<void> _deletePartner(PartnerBalanceModel partner) async {
    // 1. O'chirishdan oldin DB bazani tekshiramiz!
    try {
      final hasHistory = await _partnerService.getPartnerSverkaHistory(
        partner.id,
      );

      if (hasHistory.isNotEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'O\'chirish mumkin emas!',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            content: const Text(
              'Ushbu kontragentni o\'chirish mumkin emas, chunki unga bog\'langan ombor harakatlari yoki to\'lovlar mavjud.\n\n'
              '1. "Ombor Harakatlari" sahifasidan ushbu shaxsga tegishli operatsiyalarni tozalang.\n'
              '2. "Qarzlar Balansi" dagi u bilan bog\'liq bo\'lgan barcha to\'lov tarixini tozalang.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tushundim'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarixni tekshirishda xato: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // 2. Agar tarix toza bo'lsa, endigina Delete Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text(
          'Siz rostdan ham "${partner.name}" kontragentini o\'chirmoqchimisiz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Yo\'q'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _partnerService.deletePartner(partner.id);
        _loadPartners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kontragent o\'chirildi'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('O\'chirishda xatolik yuz berdi: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  List<PartnerBalanceModel> get _filteredPartners {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _partners;
    return _partners
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              (p.inn != null && p.inn!.contains(query)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Kontragent nomi yoki STIR kodi bo\'yicha qidirish...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: AppTheme.dividerColor(context)),
                      borderRadius: AppTheme.buttonRadius,
                    ),
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Barchasi')),
                        DropdownMenuItem(
                          value: 'mijoz',
                          child: Text('Faqat Mijozlar'),
                        ),
                        DropdownMenuItem(
                          value: 'taminotchi',
                          child: Text('Faqat Ta\'minotchilar'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedFilter = val);
                          _loadPartners();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _openAddPartnerDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yangi Kontragent'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPartners.isEmpty
                  ? Container(
                      decoration: AppTheme.cardDecoration(context),
                      child: const Center(
                        child: Text('Kontragentlar topilmadi.'),
                      ),
                    )
                  : Container(
                      decoration: AppTheme.cardDecoration(context),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            color: AppTheme.tableHeaderBg(context),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '№',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    'Kontragent Nomi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'STIR Kodi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Turi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Telefon',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    'Amallar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: _filteredPartners.length,
                              separatorBuilder: (context, index) => Container(
                                height: 1,
                                color: AppTheme.dividerColor(context),
                              ),
                              itemBuilder: (context, index) {
                                final partner = _filteredPartners[index];
                                final isClient = partner.type == 'mijoz';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 6,
                                        child: Text(
                                          partner.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          partner.inn ?? 'Mavjud emas',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: partner.inn != null
                                                ? AppTheme.primaryColor
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          isClient
                                              ? 'Mijoz (Xaridor)'
                                              : 'Ta\'minotchi',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          partner.phone ?? 'Noma\'lum',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 196,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _openSverkaDialog(partner),
                                              icon: const Icon(
                                                Icons.history,
                                                size: 16,
                                              ),
                                              label: const Text('Sverka'),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: Colors.orange,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _openAddPartnerDialog(
                                                    partner: partner,
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _deletePartner(partner),
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

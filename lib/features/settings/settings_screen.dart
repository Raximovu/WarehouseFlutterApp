import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/category_model.dart';
import '../../models/material_model.dart';
import '../../models/unit_model.dart';
import '../../services/backup_service.dart';
import '../../services/category_service.dart';
import '../../services/material_service.dart';
import '../../services/unit_service.dart';
import '../../services/transaction_service.dart';
import 'widgets/add_category_dialog.dart';
import 'widgets/add_material_dialog.dart';
import 'widgets/add_unit_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _materialService = MaterialService();
  final _unitService = UnitService();
  final _categoryService = CategoryService();
  final _transactionService = TransactionService();
  final _backupService = BackupService();

  List<MaterialModel> _materials = [];
  List<UnitModel> _units = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadAllSettingsData();
  }

  Future<void> _loadAllSettingsData() async {
    setState(() => _isLoading = true);
    try {
      final materials = await _materialService.getAllMaterials();
      final units = await _unitService.getAllUnits();
      final categories = await _categoryService.getAllCategories();
      setState(() {
        _materials = materials;
        _units = units;
        _categories = categories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddMaterialDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddMaterialDialog(),
    );
    if (result == true) {
      _loadAllSettingsData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saqlandi!'), backgroundColor: AppTheme.primaryColor));
    }
  }

  Future<void> _openAddUnitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddUnitDialog(),
    );
    if (result == true) {
      _loadAllSettingsData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saqlandi!'), backgroundColor: AppTheme.primaryColor));
    }
  }

  Future<void> _openAddCategoryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );
    if (result == true) {
      _loadAllSettingsData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saqlandi!'), backgroundColor: AppTheme.primaryColor));
    }
  }

  void _showDependencyWarningDialog(String itemType, String itemName, List<dynamic> usages) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('O\'chirish mumkin emas! ($itemName)', style: const TextStyle(color: Colors.red)),
          content: SizedBox(
            width: 500,
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ushbu $itemType qayerdadir ishlatilgan. Uni o\'chirishdan oldin tozalang:', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(6)),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: usages.length,
                      itemBuilder: (context, index) {
                        final item = usages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text('• Sana: ${formatAppDate(item.date)} | Miqdori: ${item.amount} | Turi: ${item.type}', style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor)),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tushundim'))],
        );
      },
    );
  }

  Future<void> _deleteMaterial(MaterialModel material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tasdiqlash'),
        content: Text('"${material.name}" o\'chirilsinmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Yo\'q')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: const Text('O\'chirish')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final usages = await _transactionService.getTransactionsByMaterialName(material.name);
        if (usages.isNotEmpty) {
          if (mounted) _showDependencyWarningDialog('xomashyo / mahsulot', material.name, usages);
          return;
        }
        await _materialService.deleteMaterial(material.id!);
        _loadAllSettingsData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    }
  }

  Future<void> _deleteUnit(UnitModel unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tasdiqlash'),
        content: Text('"${unit.name}" o\'chirilsinmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Yo\'q')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: const Text('O\'chirish')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final usages = await _transactionService.getTransactionsByUnitId(unit.id!);
        if (usages.isNotEmpty) {
          if (mounted) _showDependencyWarningDialog('o\'lchov birligi', unit.name, usages);
          return;
        }
        await _unitService.deleteUnit(unit.id!);
        _loadAllSettingsData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tasdiqlash'),
        content: Text('"${category.name}" o\'chirilsinmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Yo\'q')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: const Text('O\'chirish')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final usages = await _transactionService.getTransactionsByCategoryId(category.id!);
        if (usages.isNotEmpty) {
          if (mounted) _showDependencyWarningDialog('kategoriya', category.name, usages);
          return;
        }
        await _categoryService.deleteCategory(category.id!);
        _loadAllSettingsData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    }
  }

  Future<void> _backupDB() async {
    try {
      final success = await _backupService.backupToUserLocation();
      if (success && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saqlandi!'), backgroundColor: AppTheme.primaryColor));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e'), backgroundColor: AppTheme.errorColor));
    }
  }

  Future<void> _restoreDB() async {
    // Tiklash hozirgi barcha ma'lumotlarni almashtiradi — avval tasdiq so'raymiz
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zaxiradan tiklashni tasdiqlang'),
        content: const Text(
          'Tiklash hozirgi BARCHA ma\'lumotlarni (ombor, kontragentlar, to\'lovlar) tanlangan zaxira fayldagi ma\'lumotlar bilan almashtiradi.\n\n'
          'Xavfsizlik uchun hozirgi bazaning nusxasi avtomatik saqlab qo\'yiladi.\n\n'
          'Davom etasizmi?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Yo\'q')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ha, fayl tanlash'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final success = await _backupService.restoreFromUserLocation();
      if (success && mounted) {
        _loadAllSettingsData();
        final safetyPath = _backupService.lastSafetyCopyPath;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(safetyPath == null ? 'Tiklandi!' : 'Tiklandi! Oldingi bazaning nusxasi saqlandi:\n$safetyPath'),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $message'), backgroundColor: AppTheme.errorColor));
      }
    }
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TabButton(title: 'Xomashyolar Katalogi', isSelected: _selectedTab == 0, onPressed: () => setState(() => _selectedTab = 0)),
                  const SizedBox(width: 8),
                  _TabButton(title: 'O\'lchov Birliklari', isSelected: _selectedTab == 1, onPressed: () => setState(() => _selectedTab = 1)),
                  const SizedBox(width: 8),
                  _TabButton(title: 'Toifalar', isSelected: _selectedTab == 2, onPressed: () => setState(() => _selectedTab = 2)),
                  const SizedBox(width: 8),
                  _TabButton(title: 'Tizim (Mavzu & Zaxira)', isSelected: _selectedTab == 3, onPressed: () => setState(() => _selectedTab = 3)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildSelectedTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 0: return _buildMaterialsTab();
      case 1: return _buildUnitsTab();
      case 2: return _buildCategoriesTab();
      case 3: return _buildSystemTab();
      default: return const SizedBox();
    }
  }

  Widget _buildMaterialsTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Xomashyolar Ro\'yxati', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ElevatedButton.icon(onPressed: _openAddMaterialDialog, icon: const Icon(Icons.add, size: 18), label: const Text('Qo\'shish')),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _materials.isEmpty
              ? Container(decoration: AppTheme.cardDecoration(context), child: const Center(child: Text('Katalog bo\'sh.')))
              : Container(
                  decoration: AppTheme.cardDecoration(context),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _materials.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.dividerColor(context)),
                    itemBuilder: (context, index) {
                      final m = _materials[index];
                      return ListTile(
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Toifa: ${m.categoryName ?? ''} | Birlik: ${m.unitName ?? ''}'),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteMaterial(m)),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUnitsTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('O\'lchov Birliklari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ElevatedButton.icon(onPressed: _openAddUnitDialog, icon: const Icon(Icons.add, size: 18), label: const Text('Qo\'shish')),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _units.isEmpty
              ? Container(decoration: AppTheme.cardDecoration(context), child: const Center(child: Text('Mavjud emas.')))
              : Container(
                  decoration: AppTheme.cardDecoration(context),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _units.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.dividerColor(context)),
                    itemBuilder: (context, index) {
                      final u = _units[index];
                      return ListTile(
                        leading: const Icon(Icons.scale_outlined),
                        title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteUnit(u)),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Toifalar (Kategoriyalar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ElevatedButton.icon(onPressed: _openAddCategoryDialog, icon: const Icon(Icons.add, size: 18), label: const Text('Qo\'shish')),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _categories.isEmpty
              ? Container(decoration: AppTheme.cardDecoration(context), child: const Center(child: Text('Mavjud emas.')))
              : Container(
                  decoration: AppTheme.cardDecoration(context),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.dividerColor(context)),
                    itemBuilder: (context, index) {
                      final c = _categories[index];
                      return ListTile(
                        leading: const Icon(Icons.tag),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteCategory(c)),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSystemTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tema tanlash
        Container(
          decoration: AppTheme.cardDecoration(context),
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dizayn va Mavzu (Theme)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Ilovaning ko\'rinishini qorong\'i yoki yorug\' rejimga o\'tkazish.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Avto'), icon: Icon(Icons.brightness_auto)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Yorug\''), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Qorong\'i'), icon: Icon(Icons.dark_mode)),
                ],
                selected: {AppTheme.themeModeNotifier.value},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  setState(() {
                    AppTheme.themeModeNotifier.value = newSelection.first;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Zaxira saqlash
        Container(
          decoration: AppTheme.cardDecoration(context),
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bazani Saqlash (Backup)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Barcha ma\'lumotlar bazasidan nuskha olib, fleshkaga saqlash.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
              OutlinedButton.icon(onPressed: _backupDB, icon: const Icon(Icons.save_outlined), label: const Text('Saqlash')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tiklash
        Container(
          decoration: AppTheme.cardDecoration(context),
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Zaxiradan Tiklash (Restore)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Oldin saqlangan bazani tizimga qaytarish.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
              OutlinedButton.icon(onPressed: _restoreDB, icon: const Icon(Icons.restore), label: const Text('Tiklash')),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TabButton({required this.title, required this.isSelected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : Colors.white),
        foregroundColor: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        elevation: 0,
        side: isSelected ? BorderSide.none : BorderSide(color: AppTheme.dividerColor(context)),
      ),
      onPressed: onPressed,
      child: Text(title),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/category_model.dart';
import '../../../models/material_model.dart';
import '../../../models/unit_model.dart';
import '../../../services/category_service.dart';
import '../../../services/material_service.dart';
import '../../../services/unit_service.dart';

class AddMaterialDialog extends StatefulWidget {
  const AddMaterialDialog({super.key});

  @override
  State<AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<AddMaterialDialog> {
  final _nameController = TextEditingController();
  final _materialService = MaterialService();
  final _categoryService = CategoryService();
  final _unitService = UnitService();

  List<CategoryModel> _categories = [];
  List<UnitModel> _units = [];

  CategoryModel? _selectedCategory;
  UnitModel? _selectedUnit;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryService.getAllCategories();
      final units = await _unitService.getAllUnits();
      setState(() {
        _categories = categories;
        _units = units;
        if (categories.isNotEmpty) _selectedCategory = categories.first;
        if (units.isNotEmpty) _selectedUnit = units.first;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveMaterial() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, xomashyo/mahsulot nomini kiriting!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    if (_selectedCategory == null || _selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, toifa va o\'lchov birligini tanlang!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final material = MaterialModel(
        name: name,
        categoryId: _selectedCategory!.id!,
        unitId: _selectedUnit!.id!,
      );

      await _materialService.addMaterial(material);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e'), backgroundColor: AppTheme.errorColor));
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
      title: const Text('Yangi Xomashyo/Mahsulot Qo\'shish'),
      content: _isLoading
          ? const SizedBox(height: 120, width: 400, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nomi (Xomashyo yoki Qop turi):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Masalan: Polipropilen Ip 1000D',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Toifasi (Kategoriya):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CategoryModel>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    items: _categories.map((c) {
                      return DropdownMenuItem<CategoryModel>(
                        value: c,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Standart O\'lchov Birligi:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UnitModel>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    items: _units.map((u) {
                      return DropdownMenuItem<UnitModel>(
                        value: u,
                        child: Text(u.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Bekor qilish', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveMaterial,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Katalogga Saqlash'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/category_model.dart';
import '../../../models/material_model.dart';
import '../../../models/unit_model.dart';
import '../../../services/category_service.dart';
import '../../../services/material_service.dart';
import '../../../services/unit_service.dart';

class ProductDialog extends StatefulWidget {
  final MaterialModel? initialProduct; // Agar null bo'lmasa -> Edit rejimi

  const ProductDialog({
    super.key,
    this.initialProduct,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
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
    if (widget.initialProduct != null) {
      _nameController.text = widget.initialProduct!.name;
    }
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
        _categories = categories.where((c) => c.name.toLowerCase().contains('qop') || c.name.toLowerCase().contains('tayyor')).toList();
        _units = units;

        if (_categories.isNotEmpty) {
          if (widget.initialProduct != null) {
            _selectedCategory = _categories.firstWhere(
              (c) => c.id == widget.initialProduct!.categoryId,
              orElse: () => _categories.first,
            );
          } else {
            _selectedCategory = _categories.first;
          }
        }

        if (_units.isNotEmpty) {
          if (widget.initialProduct != null) {
            _selectedUnit = _units.firstWhere(
              (u) => u.id == widget.initialProduct!.unitId,
              orElse: () => _units.first,
            );
          } else {
            _selectedUnit = _units.firstWhere(
              (u) => u.name.toLowerCase().contains('dona'),
              orElse: () => _units.first,
            );
          }
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

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, mahsulot nomini kiriting!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    if (_selectedCategory == null || _selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, toifa va o\'lchov birligini tanlang!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final product = MaterialModel(
        id: widget.initialProduct?.id,
        name: name,
        categoryId: _selectedCategory!.id!,
        unitId: _selectedUnit!.id!,
      );

      if (widget.initialProduct == null) {
        await _materialService.addMaterial(product);
      } else {
        await _materialService.updateMaterial(product);
      }

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
    final isEdit = widget.initialProduct != null;

    return AlertDialog(
      title: Text(isEdit ? 'Mahsulotni Tahrirlash' : 'Yangi Tayyor Mahsulot Qo\'shish', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: _isLoading
          ? const SizedBox(width: 400, height: 200, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mahsulot Nomi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Masalan: Un qopi 50x100'),
                    ),
                    const SizedBox(height: 16),

                    const Text('Toifasi (Faqat tayyor mahsulot toifalari):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_categories.isEmpty)
                      const Text(
                        'Dastlab "Sozlamalar" bo\'limidan "Tayyor Qoplar" yoki "Mahsulot" degan yangi toifa (kategoriya) qo\'shing!',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      )
                    else
                      DropdownButtonFormField<CategoryModel>(
                        isExpanded: true,
                        value: _selectedCategory,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        items: _categories.map((c) {
                          return DropdownMenuItem<CategoryModel>(
                            value: c,
                            child: Text(c.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    const SizedBox(height: 16),

                    const Text('O\'lchov Birligi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UnitModel>(
                      isExpanded: true,
                      value: _selectedUnit,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                      items: _units.map((u) {
                        return DropdownMenuItem<UnitModel>(
                          value: u,
                          child: Text(u.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Bekor qilish', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: (_isSaving || _categories.isEmpty) ? null : _saveProduct,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isEdit ? 'O\'zgarishlarni Saqlash' : 'Saqlash'),
        ),
      ],
    );
  }
}

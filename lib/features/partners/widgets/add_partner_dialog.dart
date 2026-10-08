import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/partner_model.dart';
import '../../../services/partner_service.dart';

class AddPartnerDialog extends StatefulWidget {
  final PartnerModel? initialPartner; // Tahrirlash uchun beriladi

  const AddPartnerDialog({
    super.key,
    this.initialPartner,
  });

  @override
  State<AddPartnerDialog> createState() => _AddPartnerDialogState();
}

class _AddPartnerDialogState extends State<AddPartnerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _innController;
  late final TextEditingController _phoneController;
  final _partnerService = PartnerService();

  String _selectedType = 'mijoz'; // 'mijoz' yoki 'taminotchi'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPartner;
    _nameController = TextEditingController(text: p?.name ?? '');
    _innController = TextEditingController(text: p?.inn ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    if (p != null) {
      _selectedType = p.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _innController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePartner() async {
    final name = _nameController.text.trim();
    final inn = _innController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos, kontragent nomini kiriting!'), backgroundColor: AppTheme.warningColor));
      return;
    }

    if (inn.isNotEmpty) {
      if (inn.length != 9 || int.tryParse(inn) == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('STIR / INN kodi faqat 9 ta raqamdan iborat bo\'lishi shart!'), backgroundColor: AppTheme.warningColor));
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final partner = PartnerModel(
        id: widget.initialPartner?.id,
        name: name,
        inn: inn.isEmpty ? null : inn,
        type: _selectedType,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      if (widget.initialPartner != null) {
        await _partnerService.updatePartner(partner);
      } else {
        await _partnerService.addPartner(partner);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bunday kontragent allaqachon mavjud yoki xato: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialPartner != null;

    return AlertDialog(
      title: Text(isEdit ? 'Kontragentni Tahrirlash' : 'Yangi Kontragent Qo\'shish'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kontragent Turi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                items: const [
                  DropdownMenuItem(value: 'mijoz', child: Text('Mijoz (Xaridor)')),
                  DropdownMenuItem(value: 'taminotchi', child: Text('Ta\'minotchi (Xomashyo beruvchi)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 16),
              
              const Text('Kontragent Nomi (Kompaniya yoki Shaxs):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Masalan: Oltin Don MChJ yoki Ahmadaka',
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('STIR / INN kodi (Aniq 9 ta raqam):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _innController,
                maxLength: 9,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Masalan: 123456789',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('Telefon Raqami (Ixtiyoriy):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: '+998 90 123 45 67',
                ),
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
          onPressed: _isSaving ? null : _savePartner,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isEdit ? 'O\'zgarishlarni Saqlash' : 'Saqlash'),
        ),
      ],
    );
  }
}

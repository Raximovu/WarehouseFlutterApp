import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../core/utils/date_formatter.dart';
import '../models/partner_balance_model.dart';
import '../models/partner_model.dart';
import '../models/sverka_item_model.dart';
import '../models/transaction_model.dart';
import '../models/unit_model.dart';
import '../services/partner_service.dart';
import '../services/unit_service.dart';

class ExcelService {
  final _partnerService = PartnerService();
  final _unitService = UnitService();
  final _numberFormat = NumberFormat('#,##0.00', 'uz');

  /// 1. Sklad (Oborotka) Qoldiqlarini Tartibli Excelga Saqlash
  Future<bool> exportInventoryToExcel(List<Map<String, dynamic>> items) async {
    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['Qoldiqlar_Oborotka'];
    excel.delete('Sheet1');

    // Sarlavha
    sheetObject.appendRow([TextCellValue('OMBORXONA QOLDIQLARI VA OBOROTKA HISOBO T')]);
    sheetObject.appendRow([TextCellValue('Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}')]);
    sheetObject.appendRow([TextCellValue('')]);

    // Jadval ustunlari
    sheetObject.appendRow([
      TextCellValue('№'),
      TextCellValue('Toifa (Kategoriya)'),
      TextCellValue('Mahsulot / Xomashyo Nomi'),
      TextCellValue('Qoldiq Miqdori'),
      TextCellValue('O\'lchov Birligi'),
      TextCellValue('O\'rtacha Narxi (So\'m)'),
      TextCellValue('Jami Summa (So\'m)'),
    ]);

    double grandTotal = 0.0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final amount = ((item['current_amount'] ?? 0) as num).toDouble();
      final avgPrice = ((item['avg_price'] ?? 0) as num).toDouble();
      final totalSum = ((item['current_total_sum'] ?? 0) as num).toDouble();
      grandTotal += totalSum;

      sheetObject.appendRow([
        IntCellValue(i + 1),
        TextCellValue((item['category_name'] ?? '').toString()),
        TextCellValue((item['name'] ?? '').toString()),
        DoubleCellValue(amount),
        TextCellValue((item['unit_name'] ?? '').toString()),
        DoubleCellValue(avgPrice),
        DoubleCellValue(totalSum),
      ]);
    }

    // Jami Qatori
    sheetObject.appendRow([
      TextCellValue('JAMI:'),
      TextCellValue('${items.length} xil mahsulot'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(grandTotal),
    ]);

    final String? dirPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Excel saqlanadigan papkani tanlang',
    );

    if (dirPath != null) {
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final fileName = 'Ombor_Qoldiqlari_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx';
        final File file = File('$dirPath\\$fileName');
        await file.writeAsBytes(fileBytes);
        return true;
      }
    }
    return false;
  }

  /// 2. Ombor Harakatlarini (Kontragent nomi, turi, STIRi va O'lchov Birligi bilan) Tartibli Excelga Saqlash
  Future<bool> exportTransactionsToExcel(List<TransactionModel> transactions) async {
    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['Ombor_Harakatlari'];
    excel.delete('Sheet1');

    // Kontragentlarni ma'lumotlarini va O'lchov birliklarini tezkor xaritalash (Map)
    final List<PartnerModel> partnersList = await _partnerService.getAllPartners();
    final Map<int, PartnerModel> partnerMap = {
      for (var p in partnersList) if (p.id != null) p.id!: p
    };

    final List<UnitModel> unitsList = await _unitService.getAllUnits();
    final Map<int, String> unitMap = {
      for (var u in unitsList) if (u.id != null) u.id!: u.name
    };

    // Sarlavha
    sheetObject.appendRow([TextCellValue('OMBOR HARAKATLARI HISOBO T')]);
    sheetObject.appendRow([TextCellValue('Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}')]);
    sheetObject.appendRow([TextCellValue('')]);

    // Jadval ustunlari (O'lchov Birligi ustuni qo'shildi)
    sheetObject.appendRow([
      TextCellValue('№'),
      TextCellValue('Sana'),
      TextCellValue('Operatsiya Turi'),
      TextCellValue('Kontragent Turi'),
      TextCellValue('Kontragent Nomi'),
      TextCellValue('STIR / INN'),
      TextCellValue('Mahsulot / Xomashyo Nomi'),
      TextCellValue('Miqdori'),
      TextCellValue('O\'lchov Birligi'),
      TextCellValue('Narxi (So\'m)'),
      TextCellValue('Jami Summa (So\'m)'),
      TextCellValue('Izoh'),
    ]);

    double grandTotal = 0.0;

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      grandTotal += tx.totalSum;

      final partner = tx.partnerId != null ? partnerMap[tx.partnerId] : null;
      final partnerType = partner != null ? (partner.type == 'mijoz' ? 'Mijoz' : 'Ta\'minotchi') : '—';
      final partnerName = partner?.name ?? '—';
      final partnerInn = partner?.inn ?? '—';
      final unitName = unitMap[tx.unitId] ?? '—';

      sheetObject.appendRow([
        IntCellValue(i + 1),
        TextCellValue(formatAppDate(tx.date)),
        TextCellValue(tx.typeLabel),
        TextCellValue(partnerType),
        TextCellValue(partnerName),
        TextCellValue(partnerInn),
        TextCellValue(tx.name),
        DoubleCellValue(tx.amount),
        TextCellValue(unitName),
        DoubleCellValue(tx.price),
        DoubleCellValue(tx.totalSum),
        TextCellValue(tx.notes ?? ''),
      ]);
    }

    // Jami Qatori
    sheetObject.appendRow([
      TextCellValue('JAMI:'),
      TextCellValue('${transactions.length} ta operatsiya'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(grandTotal),
      TextCellValue(''),
    ]);

    final String? dirPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Excel saqlanadigan papkani tanlang',
    );

    if (dirPath != null) {
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final fileName = 'Ombor_Harakatlari_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx';
        final File file = File('$dirPath\\$fileName');
        await file.writeAsBytes(fileBytes);
        return true;
      }
    }
    return false;
  }

  /// 3. Sverka Aktini (Kontragent Turi, Nomi va STIRi bilan) Tartibli Excelga Saqlash
  Future<bool> exportSverkaToExcel(PartnerBalanceModel partner, List<SverkaItemModel> items) async {
    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['Sverka_Akti'];
    excel.delete('Sheet1');

    final isClient = partner.type == 'mijoz';
    final currentDebt = isClient ? partner.clientBalance : partner.supplierBalance;
    String debtStatus = '';
    if (isClient) {
      debtStatus = currentDebt > 0 ? 'Qarzdor' : (currentDebt < 0 ? 'Haqdor (Avansi bor)' : 'Qarz emas');
    } else {
      debtStatus = currentDebt > 0 ? 'Qarzimiz bor' : (currentDebt < 0 ? 'Haqimiz bor (Avans berganmiz)' : 'Qarz emasmiz');
    }

    // Header Bloqi (Kontragent rekvizitlari bilan)
    sheetObject.appendRow([TextCellValue('O\'ZARO HISOBLASHUVLAR SVERKA AKTI')]);
    sheetObject.appendRow([TextCellValue('Kontragent Nomi:'), TextCellValue(partner.name)]);
    sheetObject.appendRow([TextCellValue('STIR / INN kodi:'), TextCellValue(partner.inn ?? 'Mavjud emas')]);
    sheetObject.appendRow([TextCellValue('Kontragent Turi:'), TextCellValue(isClient ? 'Mijoz (Xaridor)' : 'Ta\'minotchi')]);
    sheetObject.appendRow([TextCellValue('Telefon:'), TextCellValue(partner.phone ?? 'Noma\'lum')]);
    sheetObject.appendRow([TextCellValue('Joriy Balans / Holat:'), TextCellValue('${_numberFormat.format(currentDebt.abs())} So\'m ($debtStatus)')]);
    sheetObject.appendRow([TextCellValue('')]); // Bo'sh qator

    // Jadval ustunlari
    sheetObject.appendRow([
      TextCellValue('№'),
      TextCellValue('Sana'),
      TextCellValue('Harakat Turi'),
      TextCellValue('Nomi / Tafsiloti'),
      TextCellValue('Summasi (So\'m)'),
      TextCellValue('Izoh'),
    ]);

    double grandTotal = 0.0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isPayment = item.type.contains('tolov');
      final typeLabel = isPayment ? 'To\'lov' : 'Tovar / Qop / Xomashyo';
      grandTotal += item.amount;

      sheetObject.appendRow([
        IntCellValue(i + 1),
        TextCellValue(formatAppDate(item.date)),
        TextCellValue(typeLabel),
        TextCellValue(item.title),
        DoubleCellValue(item.amount),
        TextCellValue(item.notes ?? ''),
      ]);
    }

    // Jami
    sheetObject.appendRow([
      TextCellValue('JAMI:'),
      TextCellValue('${items.length} ta amal'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(grandTotal),
      TextCellValue(''),
    ]);

    final String? dirPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Sverka Akti saqlanadigan papkani tanlang',
    );

    if (dirPath != null) {
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final safePartnerName = partner.name.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
        final fileName = '${safePartnerName}_Sverka_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx';
        
        final File file = File('$dirPath\\$fileName');
        await file.writeAsBytes(fileBytes);
        return true;
      }
    }
    return false;
  }
}

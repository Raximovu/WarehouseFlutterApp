import 'package:file_picker/file_picker.dart';
import '../database/db_helper.dart';

class BackupService {
  final dbHelper = DatabaseHelper.instance;

  Future<bool> backupToUserLocation() async {
    final String? dirPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Zaxira Saqlanadigan Papkani Tanlang',
    );

    if (dirPath != null) {
      final fileName = 'GrandPolimerPlast_Backup_${DateTime.now().toString().split(' ')[0]}.db';
      final backupPath = '$dirPath\\$fileName';
      await dbHelper.backupDatabase(backupPath);
      return true;
    }
    return false;
  }

  Future<bool> restoreFromUserLocation() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      dialogTitle: 'Zaxira Faylini Tanlang',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      await dbHelper.restoreDatabase(files.first.path!);
      return true;
    }
    return false;
  }
}

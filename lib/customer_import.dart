import 'dart:io';
import 'package:csv/csv.dart';
import 'db/db_provider.dart';

// 1. Helper to clean messy data
String cleanValue(dynamic value) {
  if (value == null) return '';
  String str = value.toString().trim();

  // Remove asterisks (*)
  str = str.replaceAll('*', '');
  
  // Remove commas (,) which break ID numbers like "24,675,554"
  str = str.replaceAll(',', ''); 

  // If multiple phones separated by '/', take the first one
  if (str.contains('/')) {
    str = str.split('/')[0].trim();
  }

  return str;
}

Future<List<String>> importCustomersFromCsvFile(File csvFile) async {
  try {
    final content = await csvFile.readAsString();
    final rows = const CsvToListConverter().convert(content, eol: '\n');
    if (rows.isEmpty) return ['Empty CSV file'];

    // 2. Normalize headers
    final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();

    // 3. Find column indexes based on your specific CSV headers
    int? findIndex(List<String> possibleNames) {
      for (var name in possibleNames) {
        int idx = headers.indexOf(name);
        if (idx != -1) return idx;
        idx = headers.indexWhere((h) => h.contains(name));
        if (idx != -1) return idx;
      }
      return null;
    }

    // Match your specific headers
    final idxName = findIndex(['name', 'customer']);
    final idxPhone = findIndex(['phone', 'mobile']);
    final idxId = findIndex(['id_no', 'id', 'national']);
    final idxBank = findIndex(['bank_account', 'bank', 'account']);
    final idxNotes = findIndex(['notes', 'comment', 'extra']);
    final idxAgent = findIndex(['agent']);
    final idxStore = findIndex(['store', 'branch']);

    final errors = <String>[];
    final dataRows = rows.skip(1).toList();
    int importedCount = 0;

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];

      String getValue(int? index) {
        if (index != null && index < row.length) {
          return cleanValue(row[index]);
        }
        return '';
      }

      final name = getValue(idxName);
      final phone = getValue(idxPhone);

      // Skip rows that don't have at least a name or phone
      if (name.isEmpty && phone.isEmpty) continue;

      try {
        await DbProvider.insert('customer', {
          'name': name.isEmpty ? 'Unknown' : name,
          'phone': phone,
          'id_no': getValue(idxId), // Now cleans commas!
          'bank_account': getValue(idxBank),
          'notes': getValue(idxNotes),
          'agent': getValue(idxAgent),
          'store': getValue(idxStore).isEmpty ? 'Main' : getValue(idxStore),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
        importedCount++;
      } catch (e) {
        errors.add('Row ${i + 2}: $e');
      }
    }

    if (importedCount == 0 && errors.isEmpty) {
      return ['No valid data found. Check column headers.'];
    }

    return errors;

  } catch (e) {
    return ['File read error: $e'];
  }
}
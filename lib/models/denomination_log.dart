// lib/models/denomination_log.dart
import 'dart:convert';

class DenominationLog {
  int? id;
  Map<String,int> amounts; // denom -> count
  int computedTotal;

  DenominationLog({this.id, required this.amounts, required this.computedTotal});

  factory DenominationLog.fromMap(Map<String,dynamic> m) {
    final jsonStr = m['amountsJson'] as String? ?? '{}';
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(jsonStr) as Map<String,dynamic>;
    } catch (e) {
      parsed = {};
    }
    final amountsParsed = parsed.map((k, v) => MapEntry(k, (v is int) ? v : int.tryParse(v.toString()) ?? 0));
    return DenominationLog(
      id: m['id'] as int?,
      amounts: Map<String,int>.from(amountsParsed),
      computedTotal: m['computedTotal'] as int? ?? 0,
    );
  }

  Map<String,dynamic> toMap() => {
    'id': id,
    'amountsJson': jsonEncode(amounts),
    'computedTotal': computedTotal,
  };
}

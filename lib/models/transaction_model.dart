class TxnModel {
  int? id;
  int? customerId;
  String type; // cash_in, cash_out, mpesa_in, mpesa_out
  int totalAmount;
  int? denominationLogId;
  int timestamp;

  TxnModel({
    this.id,
    this.customerId,
    required this.type,
    required this.totalAmount,
    this.denominationLogId,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory TxnModel.fromMap(Map<String,dynamic> m) => TxnModel(
    id: m['id'] as int?,
    customerId: m['customerId'] as int?,
    type: m['type'] as String? ?? '',
    totalAmount: m['totalAmount'] as int? ?? 0,
    denominationLogId: m['denominationLogId'] as int?,
    timestamp: m['timestamp'] as int?,
  );

  Map<String,dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'type': type,
    'totalAmount': totalAmount,
    'denominationLogId': denominationLogId,
    'timestamp': timestamp,
  };
}

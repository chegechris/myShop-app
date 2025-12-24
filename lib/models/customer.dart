class Customer {
  int? id;
  String name;
  String? phone; // E.164 preferred
  String? idNo;
  String? bankAccount;
  String? notes;
  String? agent;
  String? store;
  int? createdAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.idNo,
    this.bankAccount,
    this.notes,
    this.agent,
    this.store,
    this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
    id: m['id'] as int?,
    name: m['name'] as String? ?? '',
    phone: m['phone'] as String?,
    idNo: m['id_no'] as String?,
    bankAccount: m['bank_account'] as String?,
    notes: m['notes'] as String?,
    agent: m['agent'] as String?,
    store: m['store'] as String?,
    createdAt: m['createdAt'] as int?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'id_no': idNo,
    'bank_account': bankAccount,
    'notes': notes,
    'agent': agent,
    'store': store,
    'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
  };
}

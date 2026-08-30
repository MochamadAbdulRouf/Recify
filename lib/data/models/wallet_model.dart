class WalletModel {
  final String id;
  final String name;
  final String type; // 'CASH', 'BANK', 'E_WALLET', 'CREDIT'
  final double initialBalance;
  final double currentBalance;
  final int createdAt;

  WalletModel({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'created_at': createdAt,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  WalletModel copyWith({
    String? id,
    String? name,
    String? type,
    double? initialBalance,
    double? currentBalance,
    int? createdAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BudgetModel {
  final String id;
  final String categoryId;
  final double monthlyLimit;
  final int month;
  final int year;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.monthlyLimit,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'monthly_limit': monthlyLimit,
      'month': month,
      'year': year,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      monthlyLimit: (map['monthly_limit'] as num?)?.toDouble() ?? 0.0,
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }
}

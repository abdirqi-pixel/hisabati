class Country {
  const Country({
    required this.id,
    required this.nameAr,
    required this.code,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final int id;
  final String nameAr;
  final String code;
  final String currencyCode;
  final String currencySymbol;

  factory Country.fromMap(Map<String, Object?> map) {
    return Country(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String,
      code: map['code'] as String,
      currencyCode: map['currency_code'] as String,
      currencySymbol: map['currency_symbol'] as String,
    );
  }
}

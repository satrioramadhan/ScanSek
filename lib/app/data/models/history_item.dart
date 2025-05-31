class HistoryItem {
  final String namaMakanan;
  final int gulaPerBungkus;
  final int jumlahBungkus;
  final String? isiPerBungkus;
  final DateTime waktuInput;
  final String? id;

  HistoryItem({
    required this.namaMakanan,
    required this.gulaPerBungkus,
    required this.jumlahBungkus,
    required this.waktuInput,
    this.isiPerBungkus,
    this.id,
  });

  int get totalGula => gulaPerBungkus * jumlahBungkus;

  double get konversiSendokTeh => totalGula / 4.0;

  double get konversiSendokMakan => totalGula / 12.0;

  String get formattedKonversi =>
      "≈ ${konversiSendokTeh.toStringAsFixed(1)} sdt (${konversiSendokMakan.toStringAsFixed(1)} sdm)";

  String get formattedTime =>
      "${waktuInput.hour.toString().padLeft(2, '0')}:${waktuInput.minute.toString().padLeft(2, '0')}";

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['_id']?.toString(),
      namaMakanan: json['namaMakanan'] ?? '',
      gulaPerBungkus: json['gulaPerBungkus'] ?? 0,
      jumlahBungkus: json['jumlahBungkus'] ?? 0,
      isiPerBungkus: json['isiPerBungkus']?.toString(),
      waktuInput: DateTime.parse(json['waktuInput']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'namaMakanan': namaMakanan,
      'gulaPerBungkus': gulaPerBungkus,
      'jumlahBungkus': jumlahBungkus,
      'isiPerBungkus': isiPerBungkus,
      'totalGula': totalGula,
      'sendokTeh': konversiSendokTeh,
      'sendokMakan': konversiSendokMakan,
      'waktuInput': waktuInput.toIso8601String(),
    };
    if (id != null) map['_id'] = id;
    return map;
  }

  HistoryItem copyWith({
    String? namaMakanan,
    int? gulaPerBungkus,
    int? jumlahBungkus,
    String? isiPerBungkus,
    DateTime? waktuInput,
    String? id,
  }) {
    return HistoryItem(
      namaMakanan: namaMakanan ?? this.namaMakanan,
      gulaPerBungkus: gulaPerBungkus ?? this.gulaPerBungkus,
      jumlahBungkus: jumlahBungkus ?? this.jumlahBungkus,
      isiPerBungkus: isiPerBungkus ?? this.isiPerBungkus,
      waktuInput: waktuInput ?? this.waktuInput,
      id: id ?? this.id,
    );
  }
}

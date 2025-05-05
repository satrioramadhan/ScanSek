class HistoryItem {
  final String namaMakanan;
  final int gulaPerBungkus;
  final int jumlahBungkus;
  final int? isiPerBungkus;
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

  String get formattedTime =>
      "${waktuInput.hour.toString().padLeft(2, '0')}:${waktuInput.minute.toString().padLeft(2, '0')}";

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['_id'],
      namaMakanan: json['namaMakanan'] ?? '',
      gulaPerBungkus: json['gulaPerBungkus'] ?? 0,
      jumlahBungkus: json['jumlahBungkus'] ?? 0,
      isiPerBungkus: json['isiPerBungkus'],
      waktuInput: DateTime.parse(json['waktuInput']),
    );
  }

  Map<String, dynamic> toJson() {
    final total = totalGula;
    final sendok = konversiSendokTeh;

    final map = {
      'namaMakanan': namaMakanan,
      'gulaPerBungkus': gulaPerBungkus,
      'jumlahBungkus': jumlahBungkus,
      'isiPerBungkus': isiPerBungkus,
      'totalGula': total,
      'sendokTeh': sendok,
      'waktuInput': waktuInput.toIso8601String(),
    };

    if (id != null) map['_id'] = id;

    return map;
  }
}

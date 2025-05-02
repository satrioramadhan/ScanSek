class HistoryItem {
  final String namaMakanan;
  final int gulaPerBungkus;
  final int jumlahBungkus;
  final DateTime waktuInput;
  final int? isiPerBungkus; // opsional

  HistoryItem({
    required this.namaMakanan,
    required this.gulaPerBungkus,
    required this.jumlahBungkus,
    required this.waktuInput,
    this.isiPerBungkus,
  });

  int get totalGula => gulaPerBungkus * jumlahBungkus;

  double get konversiSendokTeh => (totalGula / 4.0);

  String get formattedDate => "${waktuInput.day}/${waktuInput.month}/${waktuInput.year}";
  String get formattedTime => "${waktuInput.hour.toString().padLeft(2, '0')}:${waktuInput.minute.toString().padLeft(2, '0')}";
}

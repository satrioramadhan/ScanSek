class ConversionHelper {
  static const double gramPerSdt = 4.0;
  static const double gramPerSdm = 12.0;

  // 🔥 Konversi ke gram
  static double toGram(double value, String satuan) {
    switch (satuan) {
      case 'sdt':
        return value * gramPerSdt;
      case 'sdm':
        return value * gramPerSdm;
      case 'gram':
      default:
        return value;
    }
  }

  // 🔥 Format tampilan lengkap
  static String format(double gram) {
    double sdt = gram / gramPerSdt;
    double sdm = gram / gramPerSdm;
    return "${gram.toStringAsFixed(1)} gram (≈ ${sdt.toStringAsFixed(1)} sdt, ${sdm.toStringAsFixed(1)} sdm)";
  }
}

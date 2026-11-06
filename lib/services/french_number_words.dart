/// Utilitaire de conversion des nombres et moyennes en toutes lettres en français
/// (ex: 12.6 -> "douze virgule six", 14.25 -> "quatorze virgule vingt-cinq")
class FrenchNumberWords {
  static const List<String> _units = [
    "zéro",
    "un",
    "deux",
    "trois",
    "quatre",
    "cinq",
    "six",
    "sept",
    "huit",
    "neuf",
    "dix",
    "onze",
    "douze",
    "treize",
    "quatorze",
    "quinze",
    "seize",
    "dix-sept",
    "dix-huit",
    "dix-neuf",
  ];

  static const List<String> _tens = [
    "",
    "dix",
    "vingt",
    "trente",
    "quarante",
    "cinquante",
    "soixante",
    "soixante-dix",
    "quatre-vingts",
    "quatre-vingt-dix",
  ];

  /// Convertit un entier de 0 à 99 en lettres
  static String convertIntBelow100(int n) {
    if (n < 0 || n > 99) return n.toString();
    if (n < 20) return _units[n];

    final ten = n ~/ 10;
    final unit = n % 10;

    if (ten == 7) {
      if (unit == 1) return "soixante et onze";
      return "soixante-${_units[10 + unit]}";
    }

    if (ten == 8) {
      if (unit == 0) return "quatre-vingts";
      return "quatre-vingt-${_units[unit]}";
    }

    if (ten == 9) {
      return "quatre-vingt-${_units[10 + unit]}";
    }

    // 20 à 69
    if (unit == 0) return _tens[ten];
    if (unit == 1) return "${_tens[ten]} et un";
    return "${_tens[ten]}-${_units[unit]}";
  }

  /// Convertit une moyenne sur 20 en lettres
  /// ex: 12.6 -> "douze virgule six"
  ///     12.0 -> "douze"
  ///     14.25 -> "quatorze virgule vingt-cinq"
  static String convertAverage(double? value) {
    if (value == null) return "-";
    if (value < 0 || value > 20) return value.toStringAsFixed(2);

    final rounded = (value * 100).round() / 100.0;
    final whole = rounded.floor();
    final decimalPart = ((rounded - whole) * 100).round();

    final wholeStr = convertIntBelow100(whole);

    if (decimalPart == 0) {
      return wholeStr;
    }

    // Gestion simplifiée des décimales
    // ex: .60 ou .6 -> "six" si multiple de 10, sinon le nombre exact
    String decStr;
    if (decimalPart % 10 == 0) {
      final singleDigit = decimalPart ~/ 10;
      decStr = convertIntBelow100(singleDigit);
    } else {
      decStr = convertIntBelow100(decimalPart);
    }

    return "$wholeStr virgule $decStr";
  }
}

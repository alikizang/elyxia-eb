import 'package:flutter_test/flutter_test.dart';
import 'package:elyxia_eb/services/french_number_words.dart';

void main() {
  group('FrenchNumberWords Tests', () {
    test('Converts integers below 20 correctly', () {
      expect(FrenchNumberWords.convertIntBelow100(0), 'zéro');
      expect(FrenchNumberWords.convertIntBelow100(1), 'un');
      expect(FrenchNumberWords.convertIntBelow100(12), 'douze');
      expect(FrenchNumberWords.convertIntBelow100(16), 'seize');
      expect(FrenchNumberWords.convertIntBelow100(19), 'dix-neuf');
    });

    test('Converts tens correctly', () {
      expect(FrenchNumberWords.convertIntBelow100(20), 'vingt');
      expect(FrenchNumberWords.convertIntBelow100(21), 'vingt et un');
      expect(FrenchNumberWords.convertIntBelow100(25), 'vingt-cinq');
      expect(FrenchNumberWords.convertIntBelow100(70), 'soixante-dix');
      expect(FrenchNumberWords.convertIntBelow100(71), 'soixante et onze');
      expect(FrenchNumberWords.convertIntBelow100(75), 'soixante-quinze');
      expect(FrenchNumberWords.convertIntBelow100(80), 'quatre-vingts');
      expect(FrenchNumberWords.convertIntBelow100(82), 'quatre-vingt-deux');
      expect(FrenchNumberWords.convertIntBelow100(90), 'quatre-vingt-dix');
      expect(FrenchNumberWords.convertIntBelow100(98), 'quatre-vingt-dix-huit');
    });

    test('Converts student averages (as in test.pdf)', () {
      // Dans test.pdf: 12,6 -> douze virgule six
      expect(FrenchNumberWords.convertAverage(12.6), 'douze virgule six');
      expect(FrenchNumberWords.convertAverage(12.0), 'douze');
      expect(FrenchNumberWords.convertAverage(14.25), 'quatorze virgule vingt-cinq');
      expect(FrenchNumberWords.convertAverage(9.73), 'neuf virgule soixante-treize');
      expect(FrenchNumberWords.convertAverage(16.32), 'seize virgule trente-deux');
    });
  });
}

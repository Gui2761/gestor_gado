import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_gado/ml/modelo_ia.dart';

void main() {
  group('AI Model Tests', () {
    test('score function should return a list of doubles', () {
      // Mock input with 11 features (matching the expectations in modelo_ia.dart)
      // Based on the code seen: input[0] is temperature, input[1] is heart rate, etc.
      final input = List<double>.filled(11, 0.5);
      input[0] = 38.5; // Temperature
      input[1] = 80.0; // Heart rate
      
      final results = score(input);
      
      expect(results, isA<List<double>>());
      expect(results.length, greaterThan(0));
      print('AI output length: ${results.length}');
    });

    test('AI Model should produce a prediction', () {
      final input = List<double>.filled(11, 0.0);
      // Setting some values to trigger a specific leaf if possible, 
      // but just testing if it runs without crashing is the goal here.
      input[0] = 39.5; 
      input[1] = 120.0;
      
      final results = score(input);
      final sum = results.reduce((a, b) => a + b);
      
      expect(sum, closeTo(1.0, 0.01)); // Usually these models sum to 1.0 (probabilities) or have one 1.0 (classification)
      print('AI prediction sum: $sum');
    });
  });
}

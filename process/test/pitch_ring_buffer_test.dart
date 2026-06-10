import 'package:test/test.dart';
import 'package:audio_process/src/pitch_ring_buffer.dart';

void main() {
  group('PitchRingBuffer Tests', () {
    test('initial state is empty', () {
      final buffer = PitchRingBuffer(3);
      expect(buffer.length, equals(0));
      expect(buffer.isEmpty, isTrue);
      expect(buffer.isFull, isFalse);
      expect(buffer.toList(), isEmpty);
    });

    test('adding elements below capacity', () {
      final buffer = PitchRingBuffer(3);
      buffer.add(10.0);
      buffer.add(20.0);

      expect(buffer.length, equals(2));
      expect(buffer.isEmpty, isFalse);
      expect(buffer.isFull, isFalse);
      expect(buffer.toList(), equals([10.0, 20.0]));
    });

    test('wrapping behavior when exceeding capacity', () {
      final buffer = PitchRingBuffer(3);
      buffer.add(10.0);
      buffer.add(20.0);
      buffer.add(30.0);

      expect(buffer.length, equals(3));
      expect(buffer.isFull, isTrue);
      expect(buffer.toList(), equals([10.0, 20.0, 30.0]));

      // Add 4th element (should wrap and overwrite the oldest 10.0)
      buffer.add(40.0);
      expect(buffer.length, equals(3));
      expect(buffer.toList(), equals([20.0, 30.0, 40.0]));

      // Add 5th element (should wrap and overwrite 20.0)
      buffer.add(50.0);
      expect(buffer.toList(), equals([30.0, 40.0, 50.0]));
    });

    test('clear resets buffer state', () {
      final buffer = PitchRingBuffer(3);
      buffer.add(10.0);
      buffer.add(20.0);
      buffer.clear();

      expect(buffer.length, equals(0));
      expect(buffer.isEmpty, isTrue);
      expect(buffer.toList(), isEmpty);
    });
  });
}

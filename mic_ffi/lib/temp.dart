import 'dart:ffi';
import 'dart:math' as math;

double calculateFloatRMS(Pointer<Float> buffer, int sampleCount) {
  if (sampleCount <= 0) return 0.0;

  double sumOfSquares = 0.0;

  for (int i = 0; i < sampleCount; i++) {
    // 1. Move the pointer forward and read the 32-bit float value directly from memory
    final double sample = buffer[i];

    // 2. Square the value and accumulate it
    sumOfSquares += sample * sample;
  }

  // 3. Calculate the mean (average)
  final double meanSquare = sumOfSquares / sampleCount;

  // 4. Take the square root to get the final amplitude (0.0 to 1.0)
  return math.sqrt(meanSquare);
}
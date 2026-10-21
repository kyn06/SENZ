import '../models/fsl_sign.dart';

class SignMatch {
  const SignMatch({required this.sign, required this.distance});

  final FslSignDefinition sign;

  /// Mean absolute sensor distance in normalized 0..1 channel space.
  final double distance;
}

/// Matches a captured sequence against examples in the reviewed sign catalog.
///
/// Sequences are resampled to a common length so examples can have different
/// recording durations. The acceptance threshold must be tuned against real,
/// signer-separated validation recordings before this is used as a product
/// accuracy claim.
class SequenceSignRecognizer {
  SequenceSignRecognizer({
    this.catalog = FslSignCatalog.signs,
    this.minimumDistance = 0.12,
    this.sequenceLength = 16,
  }) : assert(sequenceLength > 1);

  final List<FslSignDefinition> catalog;
  final double minimumDistance;
  final int sequenceLength;

  SignMatch? recognize(
    List<List<int>> sequence, {
    required List<int> openHandBaseline,
    required List<int> closedHandBaseline,
    Iterable<FslSignDefinition>? signs,
  }) {
    if (sequence.length < 2 || sequence.any((frame) => frame.length != 5)) {
      return null;
    }
    if (openHandBaseline.length != 5 || closedHandBaseline.length != 5) {
      return null;
    }
    if (List<int>.generate(
      5,
      (i) => closedHandBaseline[i] - openHandBaseline[i],
    ).any((span) => span == 0)) {
      return null;
    }

    FslSignDefinition? bestSign;
    var bestDistance = double.infinity;
    for (final sign in signs ?? catalog) {
      for (final example in sign.examples) {
        final distance = _distance(
          sequence,
          example,
          openHandBaseline,
          closedHandBaseline,
        );
        if (distance < bestDistance) {
          bestDistance = distance;
          bestSign = sign;
        }
      }
    }

    if (bestSign == null || bestDistance > minimumDistance) return null;
    return SignMatch(sign: bestSign, distance: bestDistance);
  }

  double _distance(
    List<List<int>> input,
    List<List<double>> example,
    List<int> openHandBaseline,
    List<int> closedHandBaseline,
  ) {
    if (example.length < 2 || example.any((frame) => frame.length != 5)) {
      return double.infinity;
    }
    final left = _resampleInput(input, openHandBaseline, closedHandBaseline);
    final right = _resampleExample(example);
    var total = 0.0;
    for (var frame = 0; frame < sequenceLength; frame++) {
      for (var channel = 0; channel < 5; channel++) {
        total += (left[frame][channel] - right[frame][channel]).abs();
      }
    }
    return total / (sequenceLength * 5);
  }

  List<List<double>> _resampleInput(
    List<List<int>> frames,
    List<int> openHandBaseline,
    List<int> closedHandBaseline,
  ) => List.generate(sequenceLength, (index) {
    final position = index * (frames.length - 1) / (sequenceLength - 1);
    final lower = position.floor();
    final upper = position.ceil();
    final fraction = position - lower;
    return List<double>.generate(5, (channel) {
      final a = frames[lower][channel].clamp(0, 4095).toDouble();
      final b = frames[upper][channel].clamp(0, 4095).toDouble();
      final interpolated = a + (b - a) * fraction;
      final span = closedHandBaseline[channel] - openHandBaseline[channel];
      return ((interpolated - openHandBaseline[channel]) / span)
          .clamp(0.0, 1.0)
          .toDouble();
    });
  });

  List<List<double>> _resampleExample(List<List<double>> frames) =>
      List.generate(sequenceLength, (index) {
        final position = index * (frames.length - 1) / (sequenceLength - 1);
        final lower = position.floor();
        final upper = position.ceil();
        final fraction = position - lower;
        return List<double>.generate(5, (channel) {
          final a = frames[lower][channel].clamp(0.0, 1.0).toDouble();
          final b = frames[upper][channel].clamp(0.0, 1.0).toDouble();
          return a + (b - a) * fraction;
        });
      });
}

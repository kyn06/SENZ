/// An FSL-reviewed sign and its labeled sensor examples.
///
/// Keep this catalog empty until definitions and example recordings have been
/// reviewed with FSL signers. A hand pose or ASL label must not be used as a
/// substitute for an FSL sign.
class FslSignDefinition {
  const FslSignDefinition({
    required this.id,
    required this.displayName,
    required this.translation,
    required this.examples,
  });

  final String id;
  final String displayName;
  final String translation;

  /// Each example is a time-ordered sequence of five calibrated bend values
  /// normalized to 0..1 using that signer/session's open and closed poses.
  final List<List<List<double>>> examples;
}

class FslSignCatalog {
  const FslSignCatalog._();

  /// FSL reviewed sign definitions will be added here after data collection.
  static const signs = <FslSignDefinition>[];
}

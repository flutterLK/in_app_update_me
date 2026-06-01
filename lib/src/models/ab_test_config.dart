import 'update_config.dart';

/// Configuration for A/B testing update strategies.
class ABTestConfig {
  /// Unique experiment identifier.
  final String experimentId;

  /// Map of variant name to its UpdateConfig.
  final Map<String, UpdateConfig> variants;

  /// Default variant name if assignment fails.
  final String defaultVariant;

  const ABTestConfig({
    required this.experimentId,
    required this.variants,
    this.defaultVariant = 'control',
  });
}

/// Result of an A/B test variant assignment.
class ABTestResult {
  /// The experiment ID.
  final String experimentId;

  /// The assigned variant name.
  final String variantName;

  /// The config for this variant.
  final UpdateConfig config;

  const ABTestResult({
    required this.experimentId,
    required this.variantName,
    required this.config,
  });
}

/// Manages A/B test variant assignment.
class ABTestManager {
  ABTestConfig? _config;
  String? _assignedVariant;
  String? _userId;

  /// Set the A/B test configuration.
  void configure(ABTestConfig config, {String? userId}) {
    _config = config;
    _userId = userId;
    _assignedVariant = null; // Reset assignment
  }

  /// Get the current A/B test config.
  ABTestConfig? get config => _config;

  /// Assign a variant based on user ID hash.
  ABTestResult? assignVariant() {
    if (_config == null) return null;
    if (_config!.variants.isEmpty) return null;

    // Use user ID hash for deterministic assignment
    final hash = (_userId ?? 'default').hashCode.abs();
    final variantNames = _config!.variants.keys.toList();
    final index = hash % variantNames.length;
    final variantName = variantNames[index];

    _assignedVariant = variantName;

    return ABTestResult(
      experimentId: _config!.experimentId,
      variantName: variantName,
      config: _config!.variants[variantName]!,
    );
  }

  /// Get the currently assigned variant name.
  String? get assignedVariant => _assignedVariant;

  /// Get the UpdateConfig for the assigned variant, or the default.
  UpdateConfig? getActiveConfig() {
    if (_config == null) return null;

    if (_assignedVariant != null && _config!.variants.containsKey(_assignedVariant)) {
      return _config!.variants[_assignedVariant];
    }

    return _config!.variants[_config!.defaultVariant];
  }

  /// Reset the assignment.
  void reset() {
    _assignedVariant = null;
  }
}

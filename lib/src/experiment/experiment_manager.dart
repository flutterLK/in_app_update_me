import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Represents a variant in an A/B test experiment.
class ExperimentVariant {
  final String id;
  final String name;
  final Map<String, dynamic> parameters;

  const ExperimentVariant({
    required this.id,
    required this.name,
    this.parameters = const {},
  });

  factory ExperimentVariant.fromMap(Map<String, dynamic> map) {
    return ExperimentVariant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parameters': parameters,
    };
  }

  @override
  String toString() => 'ExperimentVariant(id: $id, name: $name)';
}

/// Manages A/B testing experiments for update strategies.
class ExperimentManager {
  final Map<String, ExperimentVariant> _assignments = {};

  /// Manually assign a variant for an experiment.
  void assignVariant(String experimentId, ExperimentVariant variant) {
    _assignments[experimentId] = variant;
  }

  /// Get the assigned variant for an experiment.
  ExperimentVariant? getVariant(String experimentId) {
    return _assignments[experimentId];
  }

  /// Fetch experiment variant from a remote server.
  Future<ExperimentVariant?> fetchVariant({
    required String experimentId,
    required String endpoint,
    Map<String, String>? headers,
    String? userId,
  }) async {
    try {
      final uri = Uri.parse(endpoint).replace(queryParameters: {
        'experimentId': experimentId,
        if (userId != null) 'userId': userId,
      });

      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final variant = ExperimentVariant.fromMap(json);
        _assignments[experimentId] = variant;
        return variant;
      }

      if (kDebugMode) {
        print('Experiment fetch failed: HTTP ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Experiment fetch error: $e');
      }
      return null;
    }
  }

  /// Get a parameter value from the assigned variant.
  T? getParameter<T>(String experimentId, String key) {
    final variant = _assignments[experimentId];
    if (variant == null) return null;
    return variant.parameters[key] as T?;
  }

  /// Check if an experiment has an assigned variant.
  bool hasVariant(String experimentId) {
    return _assignments.containsKey(experimentId);
  }

  /// Clear all experiment assignments.
  void clear() {
    _assignments.clear();
  }
}

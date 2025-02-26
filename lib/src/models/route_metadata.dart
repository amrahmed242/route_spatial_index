import 'dart:math';

/// Contains metadata about the indexed route.
///
/// Used for statistics and debug information about the route and its spatial index.
class RouteMetadata {
  /// Creates new route metadata.
  ///
  /// [totalSegments] is the number of major segments in the route.
  /// [totalSubSegments] is the total number of sub-segments across all segments.
  /// [totalLengthMeters] is the sum of all segment lengths in meters.
  /// [boundingRect] is a rectangle that contains the entire route.
  RouteMetadata({
    required this.totalSegments,
    required this.totalSubSegments,
    required this.totalLengthMeters,
    required this.boundingRect,
  });

  /// Number of major segments in the route.
  final int totalSegments;

  /// Total number of sub-segments across all segments.
  final int totalSubSegments;

  /// Total length of the route in meters.
  final double totalLengthMeters;

  /// Bounding rectangle that contains the entire route.
  final Rectangle boundingRect;
}

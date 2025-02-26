import 'dart:math';

import '../../types.dart';
import 'lat_lng.dart';

/// Represents a line segment from a route.
///
/// Contains the start and end coordinates of the segment, indices to identify which
/// part of the route it represents, and a pre-calculated length for efficiency.
class LineSegment {
  /// Creates a new line segment.
  ///
  /// [start] and [end] define the segment endpoints.
  /// [segmentIndex] identifies which major segment this belongs to.
  /// [subSegmentIndex] identifies which sub-segment this is within the major segment.
  /// [calculateDistance] is the function used to calculate distances.
  LineSegment(this.start, this.end, this.segmentIndex, this.subSegmentIndex,
      this.calculateDistance)
      : length = calculateDistance(start, end);

  /// The start point of this segment.
  final LatLng start;

  /// The end point of this segment.
  final LatLng end;

  /// The index of the major segment this belongs to.
  final int segmentIndex;

  /// The index of the sub-segment within the major segment.
  final int subSegmentIndex;

  /// Function to calculate distance between points.
  final DistanceCalculator calculateDistance;

  /// Pre-calculated length of the segment in meters.
  final double length;

  /// Returns a bounding rectangle for this segment with a small buffer.
  Rectangle<double> get rect => _getBoundingRect(bufferSize: 0.0001);

  Rectangle<double> _getBoundingRect({double bufferSize = 0.0001}) {
    final double minLat = min(start.latitude, end.latitude) - bufferSize;
    final double maxLat = max(start.latitude, end.latitude) + bufferSize;
    final double minLng = min(start.longitude, end.longitude) - bufferSize;
    final double maxLng = max(start.longitude, end.longitude) + bufferSize;

    return Rectangle<double>(minLng, minLat, maxLng - minLng, maxLat - minLat);
  }

  /// Returns the midpoint of the segment for fast approximations.
  List<double> get midpoint => <double>[
        (start.latitude + end.latitude) / 2,
        (start.longitude + end.longitude) / 2
      ];
}

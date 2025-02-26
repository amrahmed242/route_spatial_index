import 'dart:math';

import '../models/lat_lng.dart';

/// Default implementation of distance calculation using the Haversine formula.
///
/// Calculates the distance between two points on the Earth's surface in meters.
double defaultDistanceCalculator(LatLng point1, LatLng point2) {
  final double lat1 = point1.latitude * pi / 180;
  final double lng1 = point1.longitude * pi / 180;
  final double lat2 = point2.latitude * pi / 180;
  final double lng2 = point2.longitude * pi / 180;

  final double dlat = lat2 - lat1;
  final double dlng = lng2 - lng1;
  final double a = sin(dlat / 2) * sin(dlat / 2) +
      cos(lat1) * cos(lat2) * sin(dlng / 2) * sin(dlng / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return 6371000 * c; // Earth radius in meters
}

/// Creates a search rectangle around a center point.
Rectangle createSearchRect(LatLng center, double radiusDegrees) {
  return Rectangle(
    center.longitude - radiusDegrees,
    center.latitude - radiusDegrees,
    radiusDegrees * 2,
    radiusDegrees * 2,
  );
}

/// Fast approximate distance calculation for sorting points.
///
/// Returns squared distance which is sufficient for comparison.
/// This is much faster than the Haversine formula but not accurate for absolute distances.
double approximatePointDistance(List<double> p1, List<double> p2) {
  final double latDiff = p1[0] - p2[0];
  final double lngDiff = p1[1] - p2[1];
  return latDiff * latDiff + lngDiff * lngDiff;
}

/// Calculates the segments range to check based on the total number of route segments.
///
/// Uses a logarithmic scaling approach to dynamically adjust the number of
/// segments checked proportional to the route's complexity.
///
/// [totalSubSegments] Total number of sub-segments in the route.
/// [minSegments] Minimum number of segments to check (default: 50).
/// [maxSegments] Maximum number of segments to check (default: 1000).
///
/// Returns a tuple containing the initial and maximum segments to check,
/// with built-in minimum and maximum limits.
({int maxInitialSegmentsToCheck, int maxTotalSegmentsToCheck})
    calculateSegmentsRangeToCheck(
  int totalSubSegments, {
  int minSegments = 50,
  int maxSegments = 1000,
}) {
  // Calculate based on total segments with a logarithmic scaling
  final int calculatedSegments = (log(totalSubSegments + 1) * 100).toInt();

  // Ensure the value is between min and max
  final maxTotalSegmentsToCheck = max(
    minSegments,
    min(calculatedSegments, maxSegments),
  );
  final maxInitialSegmentsToCheck = maxTotalSegmentsToCheck ~/ 2;

  return (
    maxInitialSegmentsToCheck: maxInitialSegmentsToCheck,
    maxTotalSegmentsToCheck: maxTotalSegmentsToCheck,
  );
}

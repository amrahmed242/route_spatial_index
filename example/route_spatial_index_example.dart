import 'package:route_spatial_index/route_spatial_index.dart';

void main() {
  // Create a sample route with segments
  final route = [
    // First segment - a rough approximation of a highway
    [
      LatLng(40.7128, -74.0060), // New York
      LatLng(40.7500, -73.9800),
      LatLng(40.7800, -73.9500),
      LatLng(40.8100, -73.9200),
    ],
    // Second segment - a branch road
    [
      LatLng(40.7500, -73.9800),
      LatLng(40.7600, -73.9600),
      LatLng(40.7700, -73.9300),
    ],
  ];

  // Create index with default distance calculator
  final routeIndex = SpatialRouteIndex(route);

  // Sample location to find nearest point for
  final currentLocation = LatLng(40.7300, -74.0000);

  // Find the nearest point
  final nearestPoint = routeIndex.findNearestPoint(currentLocation);

  // Output the result
  print({
    'nearestPoint': nearestPoint.point,
    'distanceInMeters': nearestPoint.distanceInMeters,
    'segmentIndex': nearestPoint.segmentIndex,
    'subSegmentIndex': nearestPoint.subSegmentIndex,
  });
}

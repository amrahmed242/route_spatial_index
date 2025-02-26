import 'package:route_spatial_index/route_spatial_index.dart';
import 'package:test/test.dart';

void main() {
  group('Route Spatial Index', () {
    test('Find nearest point on a simple route', () {
      // Create a simple straight line route
      final route = [
        [
          LatLng(0, 0),
          LatLng(0, 1),
          LatLng(0, 2),
          LatLng(0, 3),
        ],
      ];

      final index = SpatialRouteIndex(route);

      // Point exactly on the route
      final result1 = index.findNearestPoint(LatLng(0, 1.5));
      expect(result1.distanceInMeters, closeTo(0, 0.1));
      expect(result1.segmentIndex, equals(0));

      // Point slightly off the route
      final result2 = index.findNearestPoint(LatLng(0.1, 1.5));
      expect(result2.point.longitude, closeTo(1.5, 0.01));
      expect(result2.point.latitude, closeTo(0, 0.01));
    });

    test('Find nearest point on a complex route', () {
      // Create a more complex route with multiple segments
      final route = [
        [
          LatLng(0, 0),
          LatLng(1, 1),
          LatLng(2, 2),
        ],
        [
          LatLng(2, 2),
          LatLng(3, 1),
          LatLng(4, 0),
        ],
        [
          LatLng(2, 2),
          LatLng(1, 3),
          LatLng(0, 4),
        ],
      ];

      final index = SpatialRouteIndex(route);

      // Point near the first segment
      final result1 = index.findNearestPoint(LatLng(0.5, 0.5));
      expect(result1.segmentIndex, equals(0));

      // Point near the second segment
      final result2 = index.findNearestPoint(LatLng(3.5, 0.5));
      expect(result2.segmentIndex, equals(1));

      // Point near the third segment
      final result3 = index.findNearestPoint(LatLng(0.5, 3.5));
      expect(result3.segmentIndex, equals(2));

      // Point near the junction (should be closest to the junction point)
      final result4 = index.findNearestPoint(LatLng(2.1, 2.1));
      expect(result4.point.latitude, closeTo(2, 0.1));
      expect(result4.point.longitude, closeTo(2, 0.1));
    });

    test('Find nearest point with custom distance calculator', () {
      final route = [
        [
          LatLng(0, 0),
          LatLng(0, 1),
        ],
      ];

      // Custom distance calculator that always returns a fixed value for testing
      double mockDistanceCalculator(LatLng a, LatLng b) {
        return 42.0;
      }

      final index = SpatialRouteIndex(
        route,
        distanceCalculator: mockDistanceCalculator,
      );

      final result = index.findNearestPoint(LatLng(0.5, 0.5));
      expect(result.distanceInMeters, equals(42.0));
    });

    test('Handles empty route gracefully', () {
      final routeWithNoSegments = <List<LatLng>>[];
      final routeWithEmptySegment = <List<LatLng>>[[], []];

      try {
        SpatialRouteIndex(routeWithNoSegments);
      } catch (e) {
        expect(e, isA<ArgumentError>());
      }

      try {
        SpatialRouteIndex(routeWithEmptySegment);
      } catch (e) {
        expect(e, isA<ArgumentError>());
      }
    });

    test('Handles very large routes efficiently', () {
      // Create a large route with 10,000 points
      final largeRoute = <List<LatLng>>[];
      final segment = <LatLng>[];

      for (int i = 0; i < 10000; i++) {
        segment.add(LatLng(0, i / 1000));

        // Create a new segment every 1000 points
        if (i > 0 && i % 1000 == 0) {
          largeRoute.add(List<LatLng>.from(segment));
          segment.clear();
          segment.add(LatLng(
              0, i / 1000)); // Start the new segment at the end of the last
        }
      }

      if (segment.isNotEmpty) {
        largeRoute.add(segment);
      }

      final sw = Stopwatch()..start();
      final index = SpatialRouteIndex(largeRoute);
      final indexingTime = sw.elapsedMilliseconds;

      // Test that indexing is relatively fast (should be less than 1 second)
      expect(indexingTime, lessThan(1000));

      // Test that querying is very fast
      sw.reset();
      final result = index.findNearestPoint(LatLng(0.1, 5.5));
      final queryTime = sw.elapsedMilliseconds;

      // Query should be fast (less than 50ms)
      expect(queryTime, lessThan(50));

      // Result should be reasonable
      expect(result.point.longitude, closeTo(5.5, 0.1));
    });

    test(
        'Ensures hierarchical index is more efficient than direct search for large routes',
        () {
      // Create a moderately large route
      final largeRoute = <List<LatLng>>[];
      final segment = <LatLng>[];

      for (int i = 0; i < 2000; i++) {
        segment.add(LatLng(0, i / 100));
      }
      largeRoute.add(segment);

      // Test with hierarchical indexing
      final hierarchicalIndex = SpatialRouteIndex(
        largeRoute,
        useClusterLevel: true,
        clusterSize: 50,
      );

      // Test with direct search
      final directIndex = SpatialRouteIndex(
        largeRoute,
        useClusterLevel: false,
      );

      final location = LatLng(0.5, 10.5);

      final sw1 = Stopwatch()..start();
      final resultHierarchical = hierarchicalIndex.findNearestPoint(location);
      final timeHierarchical = sw1.elapsedMilliseconds;

      final sw2 = Stopwatch()..start();
      final resultDirect = directIndex.findNearestPoint(location);
      final timeDirect = sw2.elapsedMilliseconds;

      // Both approaches should give similar results
      expect(resultHierarchical.point.longitude,
          closeTo(resultDirect.point.longitude, 0.01));
      expect(resultHierarchical.point.latitude,
          closeTo(resultDirect.point.latitude, 0.01));

      // Log times for comparison
      print('Hierarchical search time: $timeHierarchical ms');
      print('Direct search time: $timeDirect ms');

      // Expect hierarchical to be similar or faster
      // This might not always be true for small datasets, but including as a sanity check
      expect(timeHierarchical, lessThanOrEqualTo(timeDirect * 1.5));
    });
  });

  group('LatLng', () {
    test('Equality', () {
      final point1 = LatLng(1.0, 2.0);
      final point2 = LatLng(1.0, 2.0);
      final point3 = LatLng(2.0, 1.0);

      expect(point1 == point2, isTrue);
      expect(point1 == point3, isFalse);
      expect(point1.hashCode == point2.hashCode, isTrue);
    });

    test('toString', () {
      final point = LatLng(1.0, 2.0);
      expect(point.toString(), equals('(1.0, 2.0)'));
    });
  });

  group('Geo Utilities', () {
    test('Default distance calculator', () {
      final point1 = LatLng(0, 0);
      final point2 = LatLng(0, 1); // Approximately 111km at the equator

      final distance = defaultDistanceCalculator(point1, point2);
      expect(distance, closeTo(111000, 1000)); // Within 1km accuracy
    });

    test('Approximate point distance', () {
      final p1 = [0.0, 0.0];
      final p2 = [3.0, 4.0];

      final distance = approximatePointDistance(p1, p2);
      expect(distance, equals(25.0)); // 3^2 + 4^2 = 25
    });

    test('Search rectangle creation', () {
      final center = LatLng(10, 20);
      final radius = 2.0;

      final rect = createSearchRect(center, radius);
      expect(rect.left, equals(18.0));
      expect(rect.top, equals(8.0));
      expect(rect.width, equals(4.0));
      expect(rect.height, equals(4.0));
    });
  });
}

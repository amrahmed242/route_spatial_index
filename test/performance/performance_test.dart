import 'dart:math';

import 'package:route_spatial_index/route_spatial_index.dart';
import 'package:test/test.dart';

// Helper function to create realistic routes for testing
List<List<LatLng>> createRealisticRoute(
    int numSegments, int pointsPerSegment, double complexity) {
  final route = <List<LatLng>>[];
  final random = Random(42); // Use fixed seed for reproducibility

  double lat = 0;
  double lng = 0;

  for (int i = 0; i < numSegments; i++) {
    final segment = <LatLng>[];

    // Start new segments near the end of previous segments
    if (i > 0 && route[i - 1].isNotEmpty) {
      final previousEnd = route[i - 1].last;
      lat = previousEnd.latitude + random.nextDouble() * 0.01 - 0.005;
      lng = previousEnd.longitude + random.nextDouble() * 0.01 - 0.005;
    }

    segment.add(LatLng(lat, lng));

    for (int j = 1; j < pointsPerSegment; j++) {
      // Add some randomness to create more realistic routes
      final direction = random.nextDouble() * 2 * pi;
      final distance = 0.001 * (1 + random.nextDouble() * complexity);

      lat += sin(direction) * distance;
      lng += cos(direction) * distance;

      segment.add(LatLng(lat, lng));
    }

    route.add(segment);
  }

  return route;
}

void main() {
  group('Performance Tests', () {
    test('Small route performance (100 points)', () {
      final route = createRealisticRoute(5, 20, 1.0);

      final sw = Stopwatch()..start();
      final index = SpatialRouteIndex(route);
      final indexingTime = sw.elapsedMilliseconds;

      print('Small route indexing time: $indexingTime ms');
      expect(indexingTime, lessThan(50)); // Should be very fast

      // Generate 100 random query points
      final queryPoints = List.generate(100, (_) {
        final random = Random();
        // Generate points near the route
        return LatLng(
          route[0][0].latitude + random.nextDouble() * 0.1 - 0.05,
          route[0][0].longitude + random.nextDouble() * 0.1 - 0.05,
        );
      });

      sw.reset();

      for (final point in queryPoints) {
        index.findNearestPoint(point);
      }

      final avgQueryTime = sw.elapsedMilliseconds / 100;
      print('Small route average query time: $avgQueryTime ms');
      expect(avgQueryTime, lessThan(5)); // Should be very fast
    });

    test('Medium route performance (1,000 points)', () {
      final route = createRealisticRoute(10, 100, 2.0);

      final sw = Stopwatch()..start();
      final index = SpatialRouteIndex(route);
      final indexingTime = sw.elapsedMilliseconds;

      print('Medium route indexing time: $indexingTime ms');
      expect(indexingTime, lessThan(200));

      // Generate 100 random query points
      final queryPoints = List.generate(100, (_) {
        final random = Random();
        return LatLng(
          route[0][0].latitude + random.nextDouble() * 0.2 - 0.1,
          route[0][0].longitude + random.nextDouble() * 0.2 - 0.1,
        );
      });

      sw.reset();

      for (final point in queryPoints) {
        index.findNearestPoint(point);
      }

      final avgQueryTime = sw.elapsedMilliseconds / 100;
      print('Medium route average query time: $avgQueryTime ms');
      expect(avgQueryTime, lessThan(10));
    });

    test('Large route performance (10,000 points)', () {
      final route = createRealisticRoute(20, 500, 3.0);

      final sw = Stopwatch()..start();
      final index = SpatialRouteIndex(route);
      final indexingTime = sw.elapsedMilliseconds;

      print('Large route indexing time: $indexingTime ms');

      // Generate 20 random query points (fewer to keep test time reasonable)
      final queryPoints = List.generate(20, (_) {
        final random = Random();
        return LatLng(
          route[0][0].latitude + random.nextDouble() * 0.5 - 0.25,
          route[0][0].longitude + random.nextDouble() * 0.5 - 0.25,
        );
      });

      sw.reset();

      for (final point in queryPoints) {
        index.findNearestPoint(point);
      }

      final avgQueryTime = sw.elapsedMilliseconds / 20;
      print('Large route average query time: $avgQueryTime ms');
      expect(avgQueryTime, lessThan(30));
    });

    test('Compare different cluster sizes', () {
      final route = createRealisticRoute(10, 100, 2.0);

      // Test different cluster sizes
      final clusterSizes = [10, 25, 50, 100, 200];

      for (final clusterSize in clusterSizes) {
        final sw = Stopwatch()..start();
        final index = SpatialRouteIndex(
          route,
          clusterSize: clusterSize,
        );
        final indexingTime = sw.elapsedMilliseconds;

        // Generate test points
        final queryPoints = List.generate(20, (_) {
          final random = Random();
          return LatLng(
            route[0][0].latitude + random.nextDouble() * 0.2 - 0.1,
            route[0][0].longitude + random.nextDouble() * 0.2 - 0.1,
          );
        });

        sw.reset();

        for (final point in queryPoints) {
          index.findNearestPoint(point);
        }

        final avgQueryTime = sw.elapsedMilliseconds / 20;
        print(
            'Cluster size $clusterSize: Index time = $indexingTime ms, Query time = $avgQueryTime ms');
      }

      // No explicit expectations, just collecting performance data
    });

    test('Parameter tuning for maxSegmentsToCheck', () {
      final route = createRealisticRoute(10, 100, 2.0);
      final index = SpatialRouteIndex(route);

      // Generate consistent test points
      final queryPoints = List.generate(20, (_) {
        final random = Random(123); // Fixed seed
        return LatLng(
          route[0][0].latitude + random.nextDouble() * 0.2 - 0.1,
          route[0][0].longitude + random.nextDouble() * 0.2 - 0.1,
        );
      });

      // Test different maxSegmentsToCheck values
      final segmentLimits = [10, 50, 100, 200, 400, 1000];

      Map<int, List<double>> results = {};
      Map<int, List<SegmentPointWithDistance>> points = {};

      for (final limit in segmentLimits) {
        final sw = Stopwatch()..start();
        results[limit] = [];
        points[limit] = [];

        for (final point in queryPoints) {
          final result = index.findNearestPoint(
            point,
            maxInitialSegmentsToCheck:
                limit ~/ 4, // Initial check is 1/4 of total
            maxTotalSegmentsToCheck: limit,
          );

          results[limit]!.add(result.distanceInMeters);
          points[limit]!.add(result);
        }

        final queryTime = sw.elapsedMilliseconds;
        print(
            'maxSegmentsToCheck=$limit: Query time = ${queryTime}ms, Avg distance = ${results[limit]!.reduce((a, b) => a + b) / results[limit]!.length}m');
      }

      // Compare accuracy between different limits
      // The higher limits should find the same or closer points
      for (int i = 0; i < segmentLimits.length - 1; i++) {
        final currentLimit = segmentLimits[i];
        final nextLimit = segmentLimits[i + 1];

        for (int j = 0; j < queryPoints.length; j++) {
          // Allow a small margin for floating point differences
          expect(results[nextLimit]![j] <= results[currentLimit]![j] + 0.001,
              isTrue,
              reason:
                  'Higher segment limit should find the same or closer point (Point $j, limits $currentLimit vs $nextLimit)');
        }
      }
    });
  });
}

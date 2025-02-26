import 'dart:math';

import 'package:route_spatial_index/route_spatial_index.dart';
import 'package:test/test.dart';

void main() {
  group('Edge Cases', () {
    test('Very small route (single segment with two points)', () {
      final route = [
        [
          LatLng(0, 0),
          LatLng(0, 0.0001), // Very short segment
        ],
      ];

      final index = SpatialRouteIndex(route);
      final result = index.findNearestPoint(LatLng(0, 0.00005));

      expect(result.distanceInMeters, closeTo(0, 0.1));
    });

    test('Points exactly at endpoints', () {
      final route = [
        [
          LatLng(1, 1),
          LatLng(2, 2),
        ],
      ];

      final index = SpatialRouteIndex(route);

      final resultStart = index.findNearestPoint(LatLng(1, 1));
      final resultEnd = index.findNearestPoint(LatLng(2, 2));

      // Should find exact matches
      expect(resultStart.distanceInMeters, closeTo(0, 0.1));
      expect(resultEnd.distanceInMeters, closeTo(0, 0.1));

      // Should identify correct endpoints
      expect(resultStart.point.latitude, equals(1));
      expect(resultStart.point.longitude, equals(1));
      expect(resultEnd.point.latitude, equals(2));
      expect(resultEnd.point.longitude, equals(2));
    });

    test('Route with segment of zero length', () {
      final route = [
        [
          LatLng(1, 1),
          LatLng(1, 1), // Same point twice (zero length segment)
          LatLng(2, 2),
        ],
      ];

      final index = SpatialRouteIndex(route);
      final result = index.findNearestPoint(LatLng(1.1, 1.1));

      // Should still find a valid nearest point
      expect(result.distanceInMeters.isFinite, isTrue);
      expect(result.point, isNotNull);
    });

    test('Route with collinear points', () {
      final route = [
        [
          LatLng(0, 0),
          LatLng(0.5, 0.5), // Intermediate point on the same line
          LatLng(1, 1),
        ],
      ];

      final index = SpatialRouteIndex(route);
      final result = index.findNearestPoint(LatLng(0.25, 0.25));

      // Should still find correct projection on the route
      expect(result.point.latitude, closeTo(0.25, 0.01));
      expect(result.point.longitude, closeTo(0.25, 0.01));
    });

    test('Route at the International Date Line', () {
      final route = [
        [
          LatLng(0, 179.9),
          LatLng(0, -179.9), // Crosses the date line
        ],
      ];

      final index = SpatialRouteIndex(route);
      final result = index.findNearestPoint(LatLng(0.1, 179.95));

      // Should still find a reasonable point
      expect(result.distanceInMeters.isFinite, isTrue);
      expect(result.point.longitude, closeTo(179.95, 1.0));
    });

    test('Route at the poles', () {
      final route = [
        [
          LatLng(89, 0),
          LatLng(90, 0), // North pole
        ],
      ];

      final index = SpatialRouteIndex(route);
      final result = index
          .findNearestPoint(LatLng(89.5, 10)); // Different longitude near pole

      // Should handle pole proximity correctly
      expect(result.distanceInMeters.isFinite, isTrue);
      expect(result.point.latitude, closeTo(89.5, 0.1));
    });

    test('Very distant point', () {
      final route = [
        [
          LatLng(0, 0),
          LatLng(0, 1),
        ],
      ];

      final index = SpatialRouteIndex(route);
      final result = index.findNearestPoint(LatLng(45, 45)); // Very far point

      // Should still return a valid result
      expect(result.distanceInMeters.isFinite, isTrue);
      expect(
          result.distanceInMeters > 1000000, isTrue); // Should be over 1000km
    });

    test('Route with acute angles', () {
      final route = [
        [
          LatLng(0, 0),
          LatLng(1, 1),
          LatLng(0, 2), // Creates a sharp turn
        ],
      ];

      final index = SpatialRouteIndex(route);
      final result = index.findNearestPoint(LatLng(0.5, 1.5));

      // Should find a good projection
      expect(result.point.latitude, closeTo(0.5, 0.1));
      expect(result.point.longitude, closeTo(1.5, 0.1));
    });

    test('Point exactly midway between two segments', () {
      final route = [
        [
          LatLng(0, 0),
          LatLng(1, 0),
        ],
        [
          LatLng(0, 1),
          LatLng(1, 1),
        ],
      ];

      final index = SpatialRouteIndex(route);
      final result = index
          .findNearestPoint(LatLng(0.5, 0.5)); // Equidistant from both segments

      // Should find one of the segments
      expect(result.distanceInMeters.isFinite, isTrue);
      // Both segments are equidistant, but we expect consistency
      expect(
          result.distanceInMeters,
          closeTo(defaultDistanceCalculator(LatLng(0.5, 0.5), LatLng(0.5, 0)),
              0.1));
    });

    test('Anti-meridian handling edge cases', () {
      // Test routes that span across the -180/180 longitude boundary
      final route = [
        [
          LatLng(0, 179),
          LatLng(0, -179),
        ],
      ];

      final index = SpatialRouteIndex(route);

      // Test a point at the boundary
      final result1 = index.findNearestPoint(LatLng(0, 180));
      // Test a point just on the other side
      final result2 = index.findNearestPoint(LatLng(0, -175));

      // Should find reasonable points without extreme distances
      expect(result1.distanceInMeters < 200000,
          isTrue); // Should be less than 200km
      expect(result2.distanceInMeters < 500000,
          isTrue); // Should be less than 500km
    });
  });

  group('Correctness Verification', () {
    test('Known geometrical cases', () {
      // Create a simple rectangular route
      final route = [
        [
          LatLng(0, 0),
          LatLng(0, 1),
          LatLng(1, 1),
          LatLng(1, 0),
          LatLng(0, 0), // Close the rectangle
        ],
      ];

      final index = SpatialRouteIndex(route);

      // Test points with known projections

      // 1. Point inside the rectangle
      final inside = index.findNearestPoint(LatLng(0.5, 0.5));

      // Verify it projects to the nearest edge
      expect(
          [0, 1].any((x) => (inside.point.latitude - x).abs() < 0.01) ||
              [0, 1].any((x) => (inside.point.longitude - x).abs() < 0.01),
          isTrue,
          reason: 'Inside point should project to one of the edges');

      // 2. Points outside exactly perpendicular to edges
      final outside1 =
          index.findNearestPoint(LatLng(0.5, -0.5)); // South of rectangle
      expect(outside1.point.latitude,
          closeTo(0, 0.01)); // Should be on bottom edge
      expect(outside1.point.longitude,
          closeTo(0.5, 0.01)); // Projected horizontally

      final outside2 =
          index.findNearestPoint(LatLng(-0.5, 0.5)); // West of rectangle
      expect(outside2.point.latitude,
          closeTo(0.5, 0.01)); // Projected horizontally
      expect(
          outside2.point.longitude, closeTo(0, 0.01)); // Should be on left edge

      // 3. Point near a corner (should project to the corner)
      final corner =
          index.findNearestPoint(LatLng(1.1, 1.1)); // Just outside top-right
      expect(corner.point.latitude, closeTo(1, 0.01));
      expect(corner.point.longitude, closeTo(1, 0.01));
    });

    test('Symmetry test', () {
      // Route along the equator
      final route = [
        [
          LatLng(0, -1),
          LatLng(0, 1),
        ],
      ];

      final index = SpatialRouteIndex(route);

      // Symmetrically placed points north and south
      final north = index.findNearestPoint(LatLng(0.5, 0));
      final south = index.findNearestPoint(LatLng(-0.5, 0));

      // Both should project to the same point on the route
      expect(north.point.longitude, closeTo(south.point.longitude, 0.01));
      expect(north.point.latitude, closeTo(south.point.latitude, 0.01));

      // Both should be the same distance from the route
      expect(north.distanceInMeters, closeTo(south.distanceInMeters, 1));
    });

    test('Brute force vs spatial index comparison', () {
      // Generate a route with enough points to be challenging
      final route = <List<LatLng>>[];
      final rng = Random(123);

      final segment = <LatLng>[];
      for (int i = 0; i < 100; i++) {
        segment.add(LatLng(rng.nextDouble() * 10, rng.nextDouble() * 10));
      }
      route.add(segment);

      // Create the index
      final index = SpatialRouteIndex(route);

      // Implement a brute force method for comparison
      PointWithDistance bruteForceNearest(LatLng target) {
        PointWithDistance nearest = PointWithDistance(
            route[0][0], defaultDistanceCalculator(target, route[0][0]));

        for (final segment in route) {
          for (int i = 0; i < segment.length - 1; i++) {
            final p1 = segment[i];
            final p2 = segment[i + 1];

            // Project point onto segment
            final double factor = cos(target.latitude * pi / 180);
            final double x1 = p1.longitude * factor;
            final double y1 = p1.latitude;
            final double x2 = p2.longitude * factor;
            final double y2 = p2.latitude;
            final double x = target.longitude * factor;
            final double y = target.latitude;

            final double dx = x2 - x1;
            final double dy = y2 - y1;
            final double segmentLengthSquared = dx * dx + dy * dy;

            if (segmentLengthSquared < 1e-10) continue;

            final double t = max(0,
                min(1, ((x - x1) * dx + (y - y1) * dy) / segmentLengthSquared));

            final double projX = x1 + t * dx;
            final double projY = y1 + t * dy;

            final LatLng projectedPoint = LatLng(
              projY,
              projX / factor,
            );

            final double distance =
                defaultDistanceCalculator(target, projectedPoint);

            if (distance < nearest.distanceInMeters) {
              nearest = PointWithDistance(projectedPoint, distance);
            }
          }
        }

        return nearest;
      }

      // Generate test points
      final testPoints = List.generate(
          20, (_) => LatLng(rng.nextDouble() * 10, rng.nextDouble() * 10));

      // Compare results
      for (final point in testPoints) {
        final spatialResult = index.findNearestPoint(point);
        final bruteResult = bruteForceNearest(point);

        // Allow a small margin for floating point differences
        expect(spatialResult.distanceInMeters,
            closeTo(bruteResult.distanceInMeters, 0.1),
            reason:
                'Spatial index should find the same nearest point as brute force');
      }
    });
  });
}

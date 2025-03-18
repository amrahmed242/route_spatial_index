import 'package:route_spatial_index/route_spatial_index.dart';
import 'package:test/test.dart';

void main() {
  group('LineSegment', () {
    test('Constructor and properties', () {
      final start = LatLng(1.0, 2.0);
      final end = LatLng(3.0, 4.0);

      // Custom distance calculator for testing
      double customDistanceCalculator(LatLng a, LatLng b) {
        return 100.0; // Always return 100 for testing
      }

      final segment = LineSegment(start, end, 5, 10, customDistanceCalculator);

      expect(segment.start, equals(start));
      expect(segment.end, equals(end));
      expect(segment.segmentIndex, equals(5));
      expect(segment.subSegmentIndex, equals(10));
      expect(segment.length, equals(100.0)); // From our custom calculator
    });

    test('Bounding rectangle', () {
      final segment = LineSegment(
        LatLng(1.0, 2.0),
        LatLng(3.0, 4.0),
        0,
        0,
        defaultDistanceCalculator,
      );

      final rect = segment.rect;

      // Check if the rectangle properly bounds the segment with buffer
      expect(rect.left, closeTo(2.0 - 0.0001, 0.00001));
      expect(rect.top, closeTo(1.0 - 0.0001, 0.00001));
      expect(rect.right, closeTo(4.0 + 0.0001, 0.00001));
      expect(rect.bottom, closeTo(3.0 + 0.0001, 0.00001));
    });

    test('Midpoint calculation', () {
      final segment = LineSegment(
        LatLng(1.0, 2.0),
        LatLng(3.0, 6.0),
        0,
        0,
        defaultDistanceCalculator,
      );

      final midpoint = segment.midpoint;
      expect(midpoint[0], equals(2.0)); // Midpoint latitude
      expect(midpoint[1], equals(4.0)); // Midpoint longitude
    });
  });

  group('ClusterData', () {
    test('Constructor and properties', () {
      final centroid = [10.0, 20.0];

      final cluster = ClusterData(
          1, // clusterId
          2, // startSegmentIndex
          5, // endSegmentIndex
          10, // startSubSegmentIndex
          20, // endSubSegmentIndex
          centroid // centroid
          );

      expect(cluster.clusterId, equals(1));
      expect(cluster.startSegmentIndex, equals(2));
      expect(cluster.endSegmentIndex, equals(5));
      expect(cluster.startSubSegmentIndex, equals(10));
      expect(cluster.endSubSegmentIndex, equals(20));
      expect(cluster.centroid, equals(centroid));
    });
  });

  group('Point with Distance', () {
    test('PointWithDistance - constructor and properties', () {
      final point = LatLng(1.0, 2.0);
      final pointWithDistance = PointWithDistance(point, 42.0);

      expect(pointWithDistance.point, equals(point));
      expect(pointWithDistance.distanceInMeters, equals(42.0));
    });

    test('PointWithDistance - toString', () {
      final point = LatLng(1.0, 2.0);
      final pointWithDistance = PointWithDistance(point, 42.5);

      expect(pointWithDistance.toString(), contains('42m'));
    });

    test('PointWithDistance - equality', () {
      final point1 = LatLng(1.0, 2.0);
      final point2 = LatLng(1.0, 2.0);

      final pwd1 = PointWithDistance(point1, 42.0);
      final pwd2 = PointWithDistance(point2, 42.0);
      final pwd3 = PointWithDistance(point1, 43.0);

      expect(pwd1 == pwd2, isTrue);
      expect(pwd1 == pwd3, isFalse);
    });

    test('SegmentPointWithDistance - constructor and properties', () {
      final point = LatLng(1.0, 2.0);
      final segmentPoint = SegmentPointWithDistance(point, 42.0,
          segmentIndex: 5, subSegmentIndex: 10);

      expect(segmentPoint.point, equals(point));
      expect(segmentPoint.distanceInMeters, equals(42.0));
      expect(segmentPoint.segmentIndex, equals(5));
      expect(segmentPoint.subSegmentIndex, equals(10));
    });

    test('SegmentPointWithDistance - toString', () {
      final point = LatLng(1.0, 2.0);
      final segmentPoint = SegmentPointWithDistance(point, 42.5,
          segmentIndex: 5, subSegmentIndex: 10);

      final str = segmentPoint.toString();
      expect(str, contains('42.50m'));
      expect(str, contains('segment: 5'));
      expect(str, contains('subSegment: 10'));
    });
  });
}

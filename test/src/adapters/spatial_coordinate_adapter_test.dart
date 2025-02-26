import 'package:route_spatial_index/route_spatial_index.dart';
import 'package:route_spatial_index/src/adapters/spatial_coordinate_adapter.dart';
import 'package:test/test.dart';

typedef Coordinates = ({
  double latitude,
  double longitude,
});

class MockSpatialCoordinateAdapter
    extends SpatialCoordinateAdapter<Coordinates> {
  @override
  LatLng fromCoordinates(Coordinates coords) {
    return LatLng(coords.latitude, coords.longitude);
  }

  @override
  Coordinates toCoordinates(LatLng coords) {
    return (latitude: coords.latitude, longitude: coords.longitude);
  }

  @override
  SegmentCoordinates fromSegment(List<Coordinates> segment) {
    return segment.map(fromCoordinates).toList();
  }
}

void main() {
  late MockSpatialCoordinateAdapter adapter;

  setUp(() {
    adapter = MockSpatialCoordinateAdapter();
  });

  group('SpatialCoordinateAdapter', () {
    final testLatLng = LatLng(40.7128, -74.0060);
    final testCoords = (latitude: 40.7128, longitude: -74.0060);
    final testSegment = [
      (latitude: 40.7128, longitude: -74.0060),
      (latitude: 40.7129, longitude: -74.0061)
    ];
    final testRoute = [
      [
        (latitude: 40.7128, longitude: -74.0060),
        (latitude: 40.7129, longitude: -74.0061)
      ],
      [
        (latitude: 40.7130, longitude: -74.0062),
        (latitude: 40.7131, longitude: -74.0063)
      ]
    ];

    test('unimplemented methods should throw UnimplementedError', () {
      expect(adapter.fromCoordinates(testCoords), isA<LatLng>());
      expect(adapter.toCoordinates(testLatLng), isA<Coordinates>());
      expect(adapter.fromSegment(testSegment), isA<SegmentCoordinates>());
      expect(() => adapter.fromRoute(testRoute), throwsUnimplementedError);
    });
  });
}

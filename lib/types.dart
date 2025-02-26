import 'package:route_spatial_index/route_spatial_index.dart';

import '../src/models/lat_lng.dart';

/// A function type for distance calculations between two points
typedef DistanceCalculator = double Function(LatLng point1, LatLng point2);

/// A list of geographic coordinates representing a route segment.
typedef SegmentCoordinates = List<LatLng>;

/// A list of route segments representing a complete route.
typedef Route = List<SegmentCoordinates>;

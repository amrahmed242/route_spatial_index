import '../../types.dart';
import '../models/lat_lng.dart';

/// Abstract interface for spatial coordinate system adapters
abstract class SpatialCoordinateAdapter<T> {
  /// Convert from external coordinate system to package LatLng
  LatLng fromCoordinates(T coords) {
    throw UnimplementedError('fromCoordinates() has not been implemented.');
  }

  /// Convert from package LatLng to external coordinate system
  T toCoordinates(LatLng coords) {
    throw UnimplementedError('toCoordinates() has not been implemented.');
  }

  /// Convert from external route segment to package SegmentCoordinates
  SegmentCoordinates fromSegment(List<T> segment) {
    throw UnimplementedError('fromSegment() has not been implemented.');
  }

  /// Convert from external route to package Route
  Route fromRoute(List<List<T>> segments) {
    throw UnimplementedError('fromRoute() has not been implemented.');
  }
}

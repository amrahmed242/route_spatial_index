import 'package:equatable/equatable.dart';
import 'lat_lng.dart';

/// Represents a point on a route with its distance to a reference location.
///
/// Used for general purpose nearest point calculations where segment indices
/// are not required.
class PointWithDistance extends Equatable {
  /// Creates a new point with distance.
  /// 
  /// [point] is the geographic coordinates of the point.
  /// [distanceInMeters] is the distance from this point to the reference location.
  const PointWithDistance(this.point, this.distanceInMeters);
  
  /// The geographic coordinates of this point.
  final LatLng point;
  
  /// The distance from this point to the reference location, in meters.
  final double distanceInMeters;

  @override
  String toString() {
    return 'Point(${point.latitude}, ${point.longitude}), distance: ${distanceInMeters.round()}m';
  }

  @override
  List<Object> get props => <Object>[point, distanceInMeters];
}

/// Represents a point on a route segment with its distance to a target location.
///
/// Contains the geographic coordinates of the point, its distance from the target
/// location in meters, and indices to identify which segment it belongs to.
class SegmentPointWithDistance {
  /// Creates a new point with distance and segment information.
  /// 
  /// [point] is the geographic coordinates of the point.
  /// [distanceInMeters] is the distance from this point to the reference location.
  /// [segmentIndex] identifies which major segment this point belongs to.
  /// [subSegmentIndex] identifies which sub-segment this point belongs to.
  SegmentPointWithDistance(
    this.point,
    this.distanceInMeters, {
    required this.segmentIndex,
    required this.subSegmentIndex,
  });

  /// The geographic coordinates of this point.
  final LatLng point;
  
  /// The distance from this point to the reference location, in meters.
  final double distanceInMeters;
  
  /// The index of the major segment this point belongs to.
  final int segmentIndex;
  
  /// The index of the sub-segment this point belongs to.
  final int subSegmentIndex;

  @override
  String toString() {
    return 'Point(${point.latitude}, ${point.longitude}), distance: ${distanceInMeters.toStringAsFixed(2)}m, segment: $segmentIndex, subSegment: $subSegmentIndex';
  }
}

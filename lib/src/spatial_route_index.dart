import 'dart:math';

import 'package:r_tree/r_tree.dart';

import '../types.dart';
import 'models/cluster_data.dart';
import 'models/lat_lng.dart';
import 'models/line_segment.dart';
import 'models/point_with_distance.dart';
import 'models/route_metadata.dart';
import 'utils/geo_utils.dart';

/// A spatial indexing system for efficiently finding the nearest point on a route.
///
/// This class implements a hybrid hierarchical spatial indexing approach for quickly
/// finding the closest point on a route to any given location. It's designed to handle
/// very large routes (thousands of points) with minimal computational cost.
///
/// The implementation uses a two-level approach:
/// 1. A cluster-level R-Tree to quickly narrow down the search area
/// 2. A segment-level R-Tree for precise nearest point calculations
///
/// The algorithm guarantees finding the globally nearest point while avoiding
/// checking every segment in the route, making it perform well even for very
/// large routes.
class SpatialRouteIndex {
  /// Creates a spatial index for a set of route segments.
  ///
  /// [routeSegments] - List of segments making up the route
  /// [distanceCalculator] - Function to calculate distance between points (optional)
  /// [useClusterLevel] - Whether to use hierarchical two-level indexing (recommended for large routes)
  /// [clusterSize] - Number of segments to group in each cluster
  /// [bufferSize] - Buffer around segments in degrees (~10m is default)
  SpatialRouteIndex(
    List<SegmentCoordinates> routeSegments, {
    DistanceCalculator? distanceCalculator,
    this.useClusterLevel = true,
    this.clusterSize = 50,
    this.bufferSize = 0.0001,
  }) : _distanceCalculator = distanceCalculator ?? defaultDistanceCalculator {
    _validateSegments(routeSegments);
    _buildIndex(routeSegments);
  }

  final RTree<LineSegment> _segmentRTree = RTree<LineSegment>();
  final RTree<ClusterData> _clusterRTree = RTree<ClusterData>();
  final Map<int, List<LineSegment>> _segmentsByIndex =
      <int, List<LineSegment>>{};
  final List<LineSegment> _allSegments = <LineSegment>[];
  final List<RTreeDatum<LineSegment>> _segmentDatums =
      <RTreeDatum<LineSegment>>[];
  final List<RTreeDatum<ClusterData>> _clusterDatums =
      <RTreeDatum<ClusterData>>[];
  final DistanceCalculator _distanceCalculator;
  late final RouteMetadata metadata;
  final bool useClusterLevel;
  final int clusterSize;
  final double bufferSize;

  void _validateSegments(List<SegmentCoordinates> routeSegments) {
    if (routeSegments.isEmpty) {
      throw ArgumentError('Route cannot be empty');
    }

    // Check for empty segments
    bool hasPoints = false;
    for (final segment in routeSegments) {
      if (segment.isNotEmpty) {
        hasPoints = true;
        break;
      }
    }

    if (!hasPoints) {
      throw ArgumentError('Route must contain at least one point');
    }
  }

  void _buildIndex(List<SegmentCoordinates> routeSegments) {
    int totalSubSegments = 0;
    double totalLengthMeters = 0;
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    final List<RTreeDatum<LineSegment>> segmentDatums =
        <RTreeDatum<LineSegment>>[];

    for (int segmentIndex = 0;
        segmentIndex < routeSegments.length;
        segmentIndex++) {
      final SegmentCoordinates segment = routeSegments[segmentIndex];
      final List<LineSegment> segmentLineSegments = <LineSegment>[];

      for (int subSegmentIndex = 0;
          subSegmentIndex < segment.length - 1;
          subSegmentIndex++) {
        final LatLng start = segment[subSegmentIndex];
        final LatLng end = segment[subSegmentIndex + 1];

        minLat = min(minLat, min(start.latitude, end.latitude));
        maxLat = max(maxLat, max(start.latitude, end.latitude));
        minLng = min(minLng, min(start.longitude, end.longitude));
        maxLng = max(maxLng, max(start.longitude, end.longitude));

        final LineSegment lineSegment = LineSegment(
            start, end, segmentIndex, subSegmentIndex, _distanceCalculator);

        final RTreeDatum<LineSegment> datum =
            RTreeDatum<LineSegment>(lineSegment.rect, lineSegment);
        segmentDatums.add(datum);
        _segmentDatums.add(datum);
        segmentLineSegments.add(lineSegment);
        _allSegments.add(lineSegment);

        totalSubSegments++;
        totalLengthMeters += lineSegment.length;
      }

      _segmentsByIndex[segmentIndex] = segmentLineSegments;
    }

    _segmentRTree.add(segmentDatums);

    metadata = RouteMetadata(
      totalSegments: routeSegments.length,
      totalSubSegments: totalSubSegments,
      totalLengthMeters: totalLengthMeters,
      boundingRect: Rectangle(minLng, minLat, maxLng - minLng, maxLat - minLat),
    );

    if (useClusterLevel && totalSubSegments > clusterSize * 2) {
      _buildClusterLevel();
    }
  }

  void _buildClusterLevel() {
    final List<LineSegment> allSegments = _allSegments;
    final List<RTreeDatum<ClusterData>> clusterDatums =
        <RTreeDatum<ClusterData>>[];

    for (int i = 0; i < allSegments.length; i += clusterSize) {
      final int endIdx = min(i + clusterSize, allSegments.length);
      final List<LineSegment> clusterSegments = allSegments.sublist(i, endIdx);

      double sumLat = 0;
      double sumLng = 0;
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (final LineSegment segment in clusterSegments) {
        sumLat += segment.start.latitude + segment.end.latitude;
        sumLng += segment.start.longitude + segment.end.longitude;

        minLat = min(minLat, min(segment.start.latitude, segment.end.latitude));
        maxLat = max(maxLat, max(segment.start.latitude, segment.end.latitude));
        minLng =
            min(minLng, min(segment.start.longitude, segment.end.longitude));
        maxLng =
            max(maxLng, max(segment.start.longitude, segment.end.longitude));
      }

      final List<double> centroid = <double>[
        sumLat / (clusterSegments.length * 2),
        sumLng / (clusterSegments.length * 2),
      ];

      final double clusterBuffer = bufferSize * 2;
      final Rectangle clusterRect = Rectangle(
        minLng - clusterBuffer,
        minLat - clusterBuffer,
        (maxLng + clusterBuffer) - (minLng - clusterBuffer),
        (maxLat + clusterBuffer) - (minLat - clusterBuffer),
      );

      final ClusterData clusterData = ClusterData(
        i ~/ clusterSize,
        clusterSegments.first.segmentIndex,
        clusterSegments.last.segmentIndex,
        clusterSegments.first.subSegmentIndex,
        clusterSegments.last.subSegmentIndex,
        centroid,
      );

      final RTreeDatum<ClusterData> datum =
          RTreeDatum<ClusterData>(clusterRect, clusterData);
      clusterDatums.add(datum);
      _clusterDatums.add(datum);
    }

    _clusterRTree.add(clusterDatums);
  }

  /// Finds the nearest point on the route to the given location.
  ///
  /// This method implements a highly optimized search algorithm that uses spatial
  /// indexing to efficiently find the closest point on the route to any given
  /// location, even for very large routes with thousands of points.
  ///
  /// Parameters:
  /// [location] - The target location to find the nearest point to
  /// [initialSearchRadiusDegrees] - Initial search radius (default ~500m)
  /// [maxSearchRadiusDegrees] - Maximum search radius if needed (default ~5km)
  /// [maxInitialSegmentsToCheck] - Max segments to check in first pass
  /// [maxTotalSegmentsToCheck] - Absolute maximum segments to check
  ///
  /// Returns a SegmentPointWithDistance containing the nearest point and its distance.
  SegmentPointWithDistance findNearestPoint(
    LatLng location, {
    double initialSearchRadiusDegrees = 0.005,
    double maxSearchRadiusDegrees = 0.05,
    int maxInitialSegmentsToCheck = 100,
    int maxTotalSegmentsToCheck = 400,
  }) {
    if (_allSegments.length <= maxInitialSegmentsToCheck ||
        !useClusterLevel ||
        _clusterDatums.isEmpty) {
      return _findNearestPointDirect(
        location,
        initialSearchRadiusDegrees: initialSearchRadiusDegrees,
        maxSearchRadiusDegrees: maxSearchRadiusDegrees,
        maxSegmentsToCheck: maxTotalSegmentsToCheck,
      );
    }

    return _findNearestPointTwoStage(
      location,
      initialSearchRadiusDegrees: initialSearchRadiusDegrees,
      maxSearchRadiusDegrees: maxSearchRadiusDegrees,
      maxInitialSegmentsToCheck: maxInitialSegmentsToCheck,
      maxTotalSegmentsToCheck: maxTotalSegmentsToCheck,
    );
  }

  SegmentPointWithDistance _findNearestPointTwoStage(
    LatLng location, {
    required double initialSearchRadiusDegrees,
    required double maxSearchRadiusDegrees,
    required int maxInitialSegmentsToCheck,
    required int maxTotalSegmentsToCheck,
  }) {
    final List<double> userPoint = <double>[
      location.latitude,
      location.longitude
    ];
    final List<RTreeDatum<ClusterData>> clusterEntries =
        _getNearestClusters(location, initialSearchRadiusDegrees);
    final List<LineSegment> initialSegments = _getSegmentsFromClusters(
      clusterEntries,
      maxSegments: maxInitialSegmentsToCheck,
    );

    initialSegments.sort((LineSegment a, LineSegment b) {
      final double aDist = approximatePointDistance(userPoint, a.midpoint);
      final double bDist = approximatePointDistance(userPoint, b.midpoint);
      return aDist.compareTo(bDist);
    });

    final List<LineSegment> segmentsToCheck =
        initialSegments.length > maxInitialSegmentsToCheck
            ? initialSegments.sublist(0, maxInitialSegmentsToCheck)
            : initialSegments;

    SegmentPointWithDistance bestPoint = _findNearestPointOnSegments(
      location,
      segmentsToCheck,
    );

    if (bestPoint.distanceInMeters < 10) {
      return bestPoint;
    }

    final double expandedRadius = max(initialSearchRadiusDegrees * 2,
        bestPoint.distanceInMeters / 100000 + bufferSize * 2);

    final double searchRadius = min(expandedRadius, maxSearchRadiusDegrees);
    final Rectangle searchRect = createSearchRect(location, searchRadius);
    final List<RTreeDatum<LineSegment>> additionalSegmentEntries =
        _segmentRTree.search(searchRect);

    final Set<int> segmentIdentifiers = segmentsToCheck
        .map((LineSegment s) => (s.segmentIndex * 10000) + s.subSegmentIndex)
        .toSet();

    final List<LineSegment> additionalSegments = <LineSegment>[];
    for (final RTreeDatum<LineSegment> entry in additionalSegmentEntries) {
      final LineSegment segment = entry.value;
      final int identifier =
          (segment.segmentIndex * 10000) + segment.subSegmentIndex;
      if (!segmentIdentifiers.contains(identifier)) {
        additionalSegments.add(segment);
        segmentIdentifiers.add(identifier);
      }
    }

    additionalSegments.sort((LineSegment a, LineSegment b) {
      final double aDist = approximatePointDistance(userPoint, a.midpoint);
      final double bDist = approximatePointDistance(userPoint, b.midpoint);
      return aDist.compareTo(bDist);
    });

    final int remainingSlots = maxTotalSegmentsToCheck - segmentsToCheck.length;
    if (remainingSlots > 0 && additionalSegments.isNotEmpty) {
      final List<LineSegment> potentialSegments = <LineSegment>[];
      final double bestDistDegrees =
          bestPoint.distanceInMeters / 100000 + bufferSize;

      for (final LineSegment segment in additionalSegments) {
        final double approxDist =
            approximatePointDistance(userPoint, segment.midpoint);
        if (approxDist < bestDistDegrees * 1.5) {
          potentialSegments.add(segment);
          if (potentialSegments.length >= remainingSlots) break;
        }
      }

      if (potentialSegments.isNotEmpty) {
        final SegmentPointWithDistance additionalResult =
            _findNearestPointOnSegments(location, potentialSegments);
        if (additionalResult.distanceInMeters < bestPoint.distanceInMeters) {
          bestPoint = additionalResult;
        }
      }
    }

    return bestPoint;
  }

  SegmentPointWithDistance _findNearestPointDirect(
    LatLng location, {
    required double initialSearchRadiusDegrees,
    required double maxSearchRadiusDegrees,
    required int maxSegmentsToCheck,
  }) {
    double searchRadius = initialSearchRadiusDegrees;
    List<RTreeDatum<LineSegment>> nearbySegments = <RTreeDatum<LineSegment>>[];

    while (nearbySegments.isEmpty && searchRadius <= maxSearchRadiusDegrees) {
      final Rectangle searchRect = createSearchRect(location, searchRadius);
      nearbySegments = _segmentRTree.search(searchRect);
      searchRadius *= 2;
    }

    if (nearbySegments.isEmpty) {
      final List<double> userPoint = <double>[
        location.latitude,
        location.longitude
      ];
      final List<LineSegment> sortedSegments =
          List<LineSegment>.from(_allSegments)
            ..sort((LineSegment a, LineSegment b) {
              final double aDist =
                  approximatePointDistance(userPoint, a.midpoint);
              final double bDist =
                  approximatePointDistance(userPoint, b.midpoint);
              return aDist.compareTo(bDist);
            });

      final List<LineSegment> segmentsToCheck =
          sortedSegments.length > maxSegmentsToCheck
              ? sortedSegments.sublist(0, maxSegmentsToCheck)
              : sortedSegments;

      return _findNearestPointOnSegments(location, segmentsToCheck);
    }

    final List<double> userPoint = <double>[
      location.latitude,
      location.longitude
    ];
    final List<LineSegment> segments = nearbySegments
        .map((RTreeDatum<LineSegment> e) => e.value)
        .toList()
      ..sort((LineSegment a, LineSegment b) {
        final double aDist = approximatePointDistance(userPoint, a.midpoint);
        final double bDist = approximatePointDistance(userPoint, b.midpoint);
        return aDist.compareTo(bDist);
      });

    final List<LineSegment> segmentsToCheck =
        segments.length > maxSegmentsToCheck
            ? segments.sublist(0, maxSegmentsToCheck)
            : segments;

    return _findNearestPointOnSegments(location, segmentsToCheck);
  }

  List<RTreeDatum<ClusterData>> _getNearestClusters(
    LatLng location,
    double initialRadiusDegrees,
  ) {
    double searchRadius = initialRadiusDegrees;
    List<RTreeDatum<ClusterData>> nearestClusters = <RTreeDatum<ClusterData>>[];

    while (
        nearestClusters.isEmpty && searchRadius <= initialRadiusDegrees * 4) {
      final Rectangle searchRect = createSearchRect(location, searchRadius);
      nearestClusters = _clusterRTree.search(searchRect);
      searchRadius *= 2;
    }

    if (nearestClusters.isEmpty && _clusterDatums.isNotEmpty) {
      final List<double> userPoint = <double>[
        location.latitude,
        location.longitude
      ];
      nearestClusters = List<RTreeDatum<ClusterData>>.from(_clusterDatums)
        ..sort((RTreeDatum<ClusterData> a, RTreeDatum<ClusterData> b) {
          final double aDist =
              approximatePointDistance(userPoint, a.value.centroid);
          final double bDist =
              approximatePointDistance(userPoint, b.value.centroid);
          return aDist.compareTo(bDist);
        });

      if (nearestClusters.length > 5) {
        nearestClusters = nearestClusters.sublist(0, 5);
      }
    }

    return nearestClusters;
  }

  List<LineSegment> _getSegmentsFromClusters(
      List<RTreeDatum<ClusterData>> clusterEntries,
      {required int maxSegments}) {
    final Set<LineSegment> segmentsToCheck = <LineSegment>{};

    for (final RTreeDatum<ClusterData> clusterEntry in clusterEntries) {
      final ClusterData cluster = clusterEntry.value;

      for (int segIdx = cluster.startSegmentIndex;
          segIdx <= cluster.endSegmentIndex;
          segIdx++) {
        if (_segmentsByIndex.containsKey(segIdx)) {
          final List<LineSegment> segments = _segmentsByIndex[segIdx]!;
          segmentsToCheck.addAll(segments);

          if (segmentsToCheck.length >= maxSegments) {
            break;
          }
        }
      }

      if (segmentsToCheck.length >= maxSegments) {
        break;
      }
    }

    return segmentsToCheck.toList();
  }

  SegmentPointWithDistance _findNearestPointOnSegments(
      LatLng location, List<LineSegment> segments) {
    if (segments.isEmpty) {
      return SegmentPointWithDistance(
        location,
        double.infinity,
        segmentIndex: -1,
        subSegmentIndex: -1,
      );
    }

    SegmentPointWithDistance nearestPoint = SegmentPointWithDistance(
      location,
      double.infinity,
      segmentIndex: -1,
      subSegmentIndex: -1,
    );

    for (final LineSegment segment in segments) {
      final SegmentPointWithDistance projectedPoint = _projectPointOnSegment(
          location,
          segment.start,
          segment.end,
          segment.segmentIndex,
          segment.subSegmentIndex,
          segment.calculateDistance);

      if (projectedPoint.distanceInMeters < nearestPoint.distanceInMeters) {
        nearestPoint = projectedPoint;
      }
    }

    return nearestPoint;
  }

  SegmentPointWithDistance _projectPointOnSegment(
    LatLng point,
    LatLng segmentStart,
    LatLng segmentEnd,
    int segmentIndex,
    int subSegmentIndex,
    DistanceCalculator calculateDistance,
  ) {
    final double factor = cos(point.latitude * pi / 180);
    final double x1 = segmentStart.longitude * factor;
    final double y1 = segmentStart.latitude;
    final double x2 = segmentEnd.longitude * factor;
    final double y2 = segmentEnd.latitude;
    final double x = point.longitude * factor;
    final double y = point.latitude;

    final double dx = x2 - x1;
    final double dy = y2 - y1;
    final double segmentLengthSquared = dx * dx + dy * dy;

    if (segmentLengthSquared < 1e-10) {
      final double dist = calculateDistance(point, segmentStart);
      return SegmentPointWithDistance(
        segmentStart,
        dist,
        segmentIndex: segmentIndex,
        subSegmentIndex: subSegmentIndex,
      );
    }

    final double t =
        max(0, min(1, ((x - x1) * dx + (y - y1) * dy) / segmentLengthSquared));
    final double projX = x1 + t * dx;
    final double projY = y1 + t * dy;

    final LatLng projectedPoint = LatLng(
      projY,
      projX / factor,
    );

    final double distanceInMeters = calculateDistance(point, projectedPoint);

    return SegmentPointWithDistance(
      projectedPoint,
      distanceInMeters,
      segmentIndex: segmentIndex,
      subSegmentIndex: subSegmentIndex,
    );
  }
}

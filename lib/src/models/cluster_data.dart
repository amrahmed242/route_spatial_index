/// Represents a cluster of nearby route segments in the hierarchical index.
///
/// Used to group route segments in a two-level spatial index for faster searching
/// over large routes. Contains information about segments in the cluster and its
/// geographic centroid.
class ClusterData {
  /// Creates a new cluster.
  ///
  /// [clusterId] is a unique identifier for this cluster.
  /// [startSegmentIndex] and [endSegmentIndex] define the range of segments in this cluster.
  /// [startSubSegmentIndex] and [endSubSegmentIndex] define additional sub-segment information.
  /// [centroid] is the geographic center of this cluster for quick distance calculations.
  ClusterData(
    this.clusterId,
    this.startSegmentIndex,
    this.endSegmentIndex,
    this.startSubSegmentIndex,
    this.endSubSegmentIndex,
    this.centroid,
  );

  /// Unique identifier for this cluster.
  final int clusterId;

  /// Starting segment index for segments in this cluster.
  final int startSegmentIndex;

  /// Ending segment index for segments in this cluster.
  final int endSegmentIndex;

  /// Starting sub-segment index within the first segment.
  final int startSubSegmentIndex;

  /// Ending sub-segment index within the last segment.
  final int endSubSegmentIndex;

  /// Geographic center of this cluster.
  final List<double> centroid;
}

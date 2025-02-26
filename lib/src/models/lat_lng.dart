/// A simple geographic coordinates class that's platform-agnostic.
class LatLng {
  /// The latitude in degrees. Positive values indicate north, negative values indicate south.
  final double latitude;
  
  /// The longitude in degrees. Positive values indicate east, negative values indicate west.
  final double longitude;
  
  /// Creates a new LatLng instance with the given [latitude] and [longitude].
  const LatLng(this.latitude, this.longitude);
  
  @override
  String toString() => '($latitude, $longitude)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          latitude == other.latitude &&
          longitude == other.longitude;
          
  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

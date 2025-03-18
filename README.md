[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)

# Route Spatial Index 🗺️
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Pub Version](https://img.shields.io/pub/v/route_spatial_index?style=flat-square&logo=dart)](https://pub.dev/packages/route_spatial_index)
![Pub Points](https://img.shields.io/pub/points/route_spatial_index)
[![StandWithPalestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/badges/StandWithPalestine.svg)](https://github.com/TheBSD/StandWithPalestine/blob/main/docs/README.md)

A highly optimized spatial indexing library for finding the nearest point on a route. This package is designed for performance with large geographic datasets, making it ideal for navigation apps, mapping tools, and location-based services.

## Why This Package?

Existing solutions fall short when handling large-scale routes, often degrading performance with extensive geographical datasets. Route Spatial Index tackles the complex "nearest point on route" problem with a robust, optimized approach that scales efficiently.

### Ideal For

- **Turn-by-turn Navigation Apps**: Real-time route progress tracking and position snapping
- **Fitness Tracking Applications**: Track user progress along predefined routes
- **Transportation & Logistics**: Monitor vehicle positions relative to planned routes
- **Geofencing Applications**: Calculate proximity to complex route-based geofences
- **Route Analytics**: Analyze GPS tracks in relation to planned routes


## Features

- 🚀 **High Performance**: Finds the nearest point on routes with thousands of points in milliseconds
- 💾 **Memory Efficient**: Uses spatial indexing to minimize memory usage even for very large routes
- 🌍 **Platform Agnostic**: Works with any map provider (HERE, Google Maps, Mapbox, etc.)
- 🔍 **Precise Results**: Projects points onto line segments for exact distance calculations
- ⚙️ **Configurable**: Provide your own distance calculator for maximum performance and accuracy
- 📱 **Mobile Friendly**: Optimized for resource-constrained environments like mobile devices


### Real-world Use Cases

- Showing the exact position along a navigation route
- Calculating the precise distance to the next turn or waypoint
- "Snapping" a GPS position to the nearest road or trail
- Determining if a user has deviated from a planned route
- Finding the closest access point to a route from the user's current location

## How It Works

This package implements a two-level spatial indexing approach:

1. **Segment-level R-Tree**: Indexes individual line segments for precise calculations
2. **Cluster-level R-Tree**: Groups nearby segments into clusters for quick searching
3. **Adaptive Search**: Starts with a small radius and expands if needed
4. **Point Projection**: Projects points onto segments for exact distance calculations

The algorithm uses a two-stage approach:
- First, it quickly identifies promising segments using the spatial index
- Then, it performs detailed distance calculations only where needed
- Early termination occurs when a sufficiently close point is found

## Performance

Performance varies based on route size:

| Route Size | Typical Performance |
|------------|---------------------|
| 1,000 pts  | 1-3ms per query     |
| 10,000 pts | 5-20ms per query    |
| 100,000 pts| 20-100ms per query  |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  route_spatial_index: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Usage

### Generic Example

```dart
import 'package:route_spatial_index/route_spatial_index.dart';

void main() {
  final route = [
    // First segment
    [
      LatLng(40.7128, -74.0060),  // NYC
      LatLng(40.7500, -73.9800),
      LatLng(40.7800, -73.9500),
    ],
    // Second segment
    [
      LatLng(40.7800, -73.9500),
      LatLng(40.8000, -73.9300),
      LatLng(40.8300, -73.9000),
    ],
  ];

  // Create the spatial index (do this once when your route is loaded)
  final routeIndex = SpatialRouteIndex(route);
  
  // Find the nearest point to a given location (call this whenever needed)
  final currentLocation = LatLng(40.7300, -74.0000);
  final nearestPoint = routeIndex.findNearestPoint(currentLocation);
  
  // see the result
  print({
    'nearestPoint': nearestPoint.point,
    'distanceInMeters': nearestPoint.distanceInMeters,
    'segmentIndex': nearestPoint.segmentIndex,
    'subSegmentIndex': nearestPoint.subSegmentIndex,
  });
}
```

### Using with mapping SDKs

The package provides a common adapter interface that makes it easy to integrate with any mapping SDK. Here's how to use the adapter pattern with Google Maps for example:

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_spatial_index/route_spatial_index.dart';
import 'package:route_spatial_index/adapters/google_maps_adapter.dart';

void main() {
  // Create an adapter for Google Maps
  final adapter = GoogleMapsAdapter();
  
  // Your Google Maps route (list of LatLng points)
  final List<List<gmaps.LatLng>> googleRoute = [...];
  
  // Convert to package format using the adapter
  final route = adapter.fromRoute(googleRoute);
  
  // Create the spatial index with the adapter's distance calculator
  final routeIndex = SpatialRouteIndex(route,distanceCalculator: adapter.calculateDistance);
  
  // Your Google Maps current location
  final gmaps.LatLng googleLocation = gmaps.LatLng(40.7300, -74.0000);
  
  // Convert to package format
  final location = adapter.fromCoordinates(googleLocation);
  
  // Find nearest point
  final nearestPoint = routeIndex.findNearestPoint(location);
  
  // Convert result back to Google Maps format
  final gmaps.LatLng googleNearestPoint = adapter.toCoordinates(nearestPoint.point);
  
  // Use the result with Google Maps
  print('Nearest point: ${googleNearestPoint.latitude}, ${googleNearestPoint.longitude}');
  print('Distance: ${nearestPoint.distanceInMeters} meters');
}
```

## Configuration Options

### Custom Distance Calculator

For optimal performance, provide your preferred distance calculation function:

```dart
// Create index with a custom distance calculator
final routeIndex = SpatialRouteIndex(
  route,
  distanceCalculator: (p1, p2) {
    // You can add your custom implementation of distance between two points calculator here
    // for example you can use your map sdk distance calculator
  },
);
```

### Fine-Tuning Search Parameters

The `findNearestPoint` method accepts parameters to balance performance and accuracy:

```dart
final nearestPoint = routeIndex.findNearestPoint(
  location,
  initialSearchRadiusDegrees: 0.005,   // Initial search radius (~500m)
  maxSearchRadiusDegrees: 0.05,        // Maximum search radius (~5km) 
  maxInitialSegmentsToCheck: 100,      // Check this many segments in first pass
  maxTotalSegmentsToCheck: 400,        // Maximum segments to check total
);
```

you can also use `calculateSegmentsRangeToCheck` helper to calculate segment search range automatically based on route size

```dart 
final segmentRange = calculateSegmentsRangeToCheck(routeLength);
final nearestPoint = routeIndex.findNearestPoint(
  location,
  maxInitialSegmentsToCheck: segmentRange.maxInitialSegmentsToCheck,
  maxTotalSegmentsToCheck: segmentRange.maxTotalSegmentsToCheck, 
);
```


### SpatialCoordinateAdapter

The package provides an abstract interface for adapting different spatial coordinate systems to work with the package's internal coordinate representations. This adapter allows you to convert between external coordinate formats and the package's `LatLng`, `SegmentCoordinates`, and `Route` types.

#### Methods

- `fromCoordinates(T coords)`: Converts a coordinate from an external system to a `LatLng`
- `toCoordinates(LatLng coords)`: Converts a `LatLng` to an external coordinate system
- `fromSegment(List<T> segment)`: Converts a list of external coordinates representing a route segment to `SegmentCoordinates`
- `fromRoute(List<List<T>> segments)`: Converts a list of route segments from an external format to the package's `Route` type

#### Example Usage
```dart
class GoogleMapsAdapter extends SpatialCoordinateAdapter<GoogleLatLng> {
@override
LatLng fromCoordinates(GoogleLatLng coords) {
return LatLng(coords.lat, coords.lng);
}

@override
GoogleLatLng toCoordinates(LatLng coords) {
return GoogleLatLng(coords.latitude, coords.longitude);
}

// ... implement other methods
}
```
Adapters for Google Maps, Mapbox, etc. coming soon. Contributions welcome!

## License

![MIT](https://github.com/amrahmed242/route_spatial_index/blob/main/LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request👨‍💻.

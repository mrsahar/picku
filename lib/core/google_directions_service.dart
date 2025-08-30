import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:http/http.dart' as http;

class GoogleDirectionsService {
  static const String _apiKey =
      'AIzaSyBrRRqr91A35j6PxUhjNRn4UucULfwMOiQ'; // Replace with your actual API key
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Get route points between origin and destination using Google Directions API
  static Future<List<LatLng>> getRoutePoints({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    try {
      String url =
          '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey'
          '&mode=driving'; // Ensure we get driving directions

      // Add waypoints if provided
      if (waypoints != null && waypoints.isNotEmpty) {
        String waypointsStr = waypoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join('|');
        url += '&waypoints=$waypointsStr';
      }

      print(' MRSAHAr🚗 Directions API URL: $url');

      final response = await http.get(Uri.parse(url));
      print(' MRSAHAr🔍 Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(' MRSAHAr📍 API Response Status: ${data['status']}');

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];

          print(
            '✅ Polyline points received: ${polylinePoints.substring(0, 50)}...',
          );

          // Decode the polyline points
          List<List<num>> decodedPoints = decodePolyline(polylinePoints);
          print(' MRSAHAr📊 Decoded ${decodedPoints.length} route points');

          List<LatLng> routeCoordinates = decodedPoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          print(' MRSAHAr🗺️ First point: ${routeCoordinates.first}');
          print(' MRSAHAr🏁 Last point: ${routeCoordinates.last}');

          return routeCoordinates;
        } else {
          print(' MRSAHAr❌ Directions API Error: ${data['status']}');
          if (data['error_message'] != null) {
            print(' MRSAHAr❌ Error message: ${data['error_message']}');
          }

          // Print available alternatives if any
          if (data['available_travel_modes'] != null) {
            print(
              '🚦 Available travel modes: ${data['available_travel_modes']}',
            );
          }
        }
      } else {
        print(' MRSAHAr❌ HTTP Error: ${response.statusCode}');
        print(' MRSAHAr❌ Response body: ${response.body}');
      }

      print(' MRSAHAr⚠️ Falling back to straight line');
      // Fallback to straight line if API fails
      return _createStraightLine(origin, destination);
    } catch (e) {
      print(' MRSAHAr💥 Exception in getRoutePoints: $e');
      // Fallback to straight line
      return _createStraightLine(origin, destination);
    }
  }

  /// Get route information (distance, duration, etc.)
  static Future<Map<String, dynamic>> getRouteInfo({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    try {
      String url =
          '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey'
          '&mode=driving';

      if (waypoints != null && waypoints.isNotEmpty) {
        String waypointsStr = waypoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join('|');
        url += '&waypoints=$waypointsStr';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          // Calculate total distance and duration
          int totalDistance = 0;
          int totalDuration = 0;

          for (var leg in route['legs']) {
            totalDistance += leg['distance']['value'] as int;
            totalDuration += leg['duration']['value'] as int;
          }

          return {
            'distance': '${(totalDistance / 1000).toStringAsFixed(1)} km',
            'duration': '${(totalDuration / 60).round()} min',
            'distanceValue': totalDistance, // in meters
            'durationValue': totalDuration, // in seconds
            'status': 'OK',
          };
        }
      }

      return {
        'distance': 'Unknown',
        'duration': 'Unknown',
        'distanceValue': 0,
        'durationValue': 0,
        'status': 'ERROR',
      };
    } catch (e) {
      print(' MRSAHArError getting route info: $e');
      return {
        'distance': 'Unknown',
        'duration': 'Unknown',
        'distanceValue': 0,
        'durationValue': 0,
        'status': 'ERROR',
      };
    }
  }

  /// Create a simple straight line between two points as fallback
  static List<LatLng> _createStraightLine(LatLng start, LatLng end) {
    print(' MRSAHAr📐 Creating straight line fallback');
    List<LatLng> points = [];

    // Add intermediate points for a smooth line
    int segments = 20;
    for (int i = 0; i <= segments; i++) {
      double ratio = i / segments;
      double lat = start.latitude + (end.latitude - start.latitude) * ratio;
      double lng = start.longitude + (end.longitude - start.longitude) * ratio;
      points.add(LatLng(lat, lng));
    }

    return points;
  }
}

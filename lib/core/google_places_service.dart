import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GooglePlacesService {
  static const String _apiKey = 'AIzaSyBrRRqr91A35j6PxUhjNRn4UucULfwMOiQ'; // Same API key as Directions
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Search for places using text input
  static Future<List<PlaceResult>> searchPlaces({
    required String query,
    LatLng? location,
    int radius = 50000, // 50km radius
  }) async {
    try {
      String url = '$_baseUrl/textsearch/json?query=${Uri.encodeComponent(query)}&key=$_apiKey';

      // Add location bias if current location is available
      if (location != null) {
        url += '&location=${location.latitude},${location.longitude}&radius=$radius';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          List<PlaceResult> places = [];

          for (var result in data['results']) {
            places.add(PlaceResult.fromJson(result));
          }

          return places;
        } else {
          print('SAHAr Places API Error: ${data['status']}');
          return [];
        }
      } else {
        print('SAHAr HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('SAHAr Error searching places: $e');
      return [];
    }
  }

  /// Get place autocomplete suggestions
  static Future<List<AutocompletePrediction>> getAutocompleteSuggestions({
    required String input,
    LatLng? location,
    int radius = 50000,
  }) async {
    try {
      String url = '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey';

      // Add location bias
      if (location != null) {
        url += '&location=${location.latitude},${location.longitude}&radius=$radius';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          List<AutocompletePrediction> predictions = [];

          for (var prediction in data['predictions']) {
            predictions.add(AutocompletePrediction.fromJson(prediction));
          }

          return predictions;
        } else {
          print('SAHAr Autocomplete API Error: ${data['status']}');
          return [];
        }
      } else {
        print('SAHAr HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('SAHAr Error getting autocomplete suggestions: $e');
      return [];
    }
  }

  /// Get place details by place ID
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      String url = '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey&fields=geometry,formatted_address,name';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          print('SAHAr Place Details API Error: ${data['status']}');
          return null;
        }
      } else {
        print('SAHAr HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('SAHAr Error getting place details: $e');
      return null;
    }
  }
}

class PlaceResult {
  final String name;
  final String formattedAddress;
  final LatLng location;
  final String placeId;

  PlaceResult({
    required this.name,
    required this.formattedAddress,
    required this.location,
    required this.placeId,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      location: LatLng(
        json['geometry']['location']['lat'].toDouble(),
        json['geometry']['location']['lng'].toDouble(),
      ),
      placeId: json['place_id'] ?? '',
    );
  }
}

class AutocompletePrediction {
  final String description;
  final String placeId;
  final List<String> types;

  AutocompletePrediction({
    required this.description,
    required this.placeId,
    required this.types,
  });

  factory AutocompletePrediction.fromJson(Map<String, dynamic> json) {
    return AutocompletePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

class PlaceDetails {
  final String name;
  final String formattedAddress;
  final LatLng location;

  PlaceDetails({
    required this.name,
    required this.formattedAddress,
    required this.location,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      location: LatLng(
        json['geometry']['location']['lat'].toDouble(),
        json['geometry']['location']['lng'].toDouble(),
      ),
    );
  }
}
import 'dart:async';

import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/core/google_places_service.dart';
import 'package:pick_u/core/location_service.dart';

class SearchService extends GetxService {
  static SearchService get to => Get.find();

  // Observable variables
  var searchSuggestions = <AutocompletePrediction>[].obs;
  var isSearching = false.obs;
  var activeSearchField = ''.obs;

  Timer? _searchTimer;

  @override
  void onClose() {
    _searchTimer?.cancel();
    super.onClose();
  }

  /// Search for location suggestions with debouncing
  Future<void> searchLocation(String query, String fieldType) async {
    _searchTimer?.cancel();

    if (query.length < 2) {
      searchSuggestions.clear();
      return;
    }

    activeSearchField.value = fieldType;
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      await _performLocationSearch(query);
    });
  }

  /// Perform the actual location search
  Future<void> _performLocationSearch(String query) async {
    try {
      isSearching.value = true;

      // Get current location for location bias
      final locationService = Get.find<LocationService>();
      LatLng? currentLatLng = locationService.currentLatLng.value;

      // Get autocomplete suggestions from Google Places API
      List<AutocompletePrediction> predictions =
      await GooglePlacesService.getAutocompleteSuggestions(
        input: query,
        location: currentLatLng,
        radius: 50000, // 50km radius around current location
      );

      searchSuggestions.value = predictions;
    } catch (e) {
      print(' SAHArError searching locations: $e');
      Get.snackbar('Search Error', 'Failed to search locations. Please try again.');
      searchSuggestions.clear();
    } finally {
      isSearching.value = false;
    }
  }

  /// Get place details from prediction
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      return await GooglePlacesService.getPlaceDetails(placeId);
    } catch (e) {
      print(' SAHArError getting place details: $e');
      Get.snackbar('Error', 'Failed to get location details');
      return null;
    }
  }

  /// Clear search results
  void clearSearchResults() {
    searchSuggestions.clear();
    activeSearchField.value = '';
    _searchTimer?.cancel();
  }

  /// Check if currently searching for a specific field
  bool isSearchingField(String fieldType) {
    return activeSearchField.value == fieldType && isSearching.value;
  }
}
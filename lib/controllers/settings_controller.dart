import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsController extends GetxController {
  // Theme Mode
  var themeMode = ThemeMode.system.obs;

  // Location Permission
  var isLocationEnabled = false.obs;
  var locationPermissionStatus = ''.obs;

  // Notification Permission
  var isNotificationEnabled = false.obs;

  // Cache Size
  var cacheSize = '0 MB'.obs;
  var isCalculatingCache = false.obs;

  // Location Accuracy
  var gpsAccuracy = 'Unknown'.obs;
  var lastLocationUpdate = 'Never'.obs;

  // App Info
  var appVersion = ''.obs;
  var appBuildNumber = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _loadThemeMode();
    await _checkLocationPermission();
    await _checkNotificationPermission();
    await _calculateCacheSize();
    await _checkLocationAccuracy();
    await _loadAppInfo();
  }

  // ==================== THEME MODE ====================
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode') ?? 'system';

      switch (savedTheme) {
        case 'light':
          themeMode.value = ThemeMode.light;
          break;
        case 'dark':
          themeMode.value = ThemeMode.dark;
          break;
        default:
          themeMode.value = ThemeMode.system;
      }
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    try {
      themeMode.value = mode;
      Get.changeThemeMode(mode);

      final prefs = await SharedPreferences.getInstance();
      String themeString = 'system';

      switch (mode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }

      await prefs.setString('theme_mode', themeString);
      Get.snackbar(
        'Theme Changed',
        'Theme mode updated to ${themeString.toUpperCase()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error changing theme mode: $e');
    }
  }

  String getThemeModeText() {
    switch (themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  // ==================== LOCATION PERMISSION ====================
  Future<void> _checkLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      isLocationEnabled.value = serviceEnabled;

      final permission = await Permission.location.status;

      if (permission.isGranted) {
        locationPermissionStatus.value = 'Enabled';
      } else if (permission.isDenied) {
        locationPermissionStatus.value = 'Disabled';
      } else if (permission.isPermanentlyDenied) {
        locationPermissionStatus.value = 'Permanently Disabled';
      } else {
        locationPermissionStatus.value = 'Unknown';
      }
    } catch (e) {
      print('Error checking location permission: $e');
      locationPermissionStatus.value = 'Error';
    }
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
      // Wait a bit then refresh
      await Future.delayed(const Duration(seconds: 1));
      await _checkLocationPermission();
    } catch (e) {
      print('Error opening location settings: $e');
      Get.snackbar(
        'Error',
        'Could not open location settings',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> requestLocationPermission() async {
    try {
      final permission = await Permission.location.request();

      if (permission.isGranted) {
        Get.snackbar(
          'Permission Granted',
          'Location permission enabled',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else if (permission.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Denied',
          'Please enable location permission in settings',
          snackPosition: SnackPosition.BOTTOM,
        );
        await openAppSettings();
      }

      await _checkLocationPermission();
    } catch (e) {
      print('Error requesting location permission: $e');
    }
  }

  // ==================== NOTIFICATION PERMISSION ====================
  Future<void> _checkNotificationPermission() async {
    try {
      final permission = await Permission.notification.status;
      isNotificationEnabled.value = permission.isGranted;
    } catch (e) {
      print('Error checking notification permission: $e');
      isNotificationEnabled.value = false;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await openAppSettings();
      // Wait a bit then refresh
      await Future.delayed(const Duration(seconds: 1));
      await _checkNotificationPermission();
    } catch (e) {
      print('Error opening notification settings: $e');
      Get.snackbar(
        'Error',
        'Could not open notification settings',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ==================== CACHE MANAGEMENT ====================
  Future<void> _calculateCacheSize() async {
    try {
      isCalculatingCache.value = true;

      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(tempDir.path);

      if (await cacheDir.exists()) {
        int totalSize = 0;
        await for (var entity in cacheDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (e) {
              // Skip files we can't access
            }
          }
        }

        cacheSize.value = _formatBytes(totalSize);
      } else {
        cacheSize.value = '0 MB';
      }
    } catch (e) {
      print('Error calculating cache size: $e');
      cacheSize.value = 'Error';
    } finally {
      isCalculatingCache.value = false;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> clearCache() async {
    try {
      Get.dialog(
        AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text('Are you sure you want to clear the app cache?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                await _performClearCache();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing clear cache dialog: $e');
    }
  }

  Future<void> _performClearCache() async {
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(tempDir.path);

      if (await cacheDir.exists()) {
        await for (var entity in cacheDir.list(recursive: false)) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (e) {
            // Skip files/folders we can't delete
            print('Could not delete: ${entity.path}');
          }
        }
      }

      await _calculateCacheSize();

      Get.back(); // Close loading dialog

      Get.snackbar(
        'Success',
        'Cache cleared successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      print('Error clearing cache: $e');
      Get.snackbar(
        'Error',
        'Failed to clear cache',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==================== LOCATION ACCURACY ====================
  Future<void> _checkLocationAccuracy() async {
    try {
      final permission = await Permission.location.status;

      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (position.accuracy < 10) {
          gpsAccuracy.value = 'High';
        } else if (position.accuracy < 50) {
          gpsAccuracy.value = 'Medium';
        } else {
          gpsAccuracy.value = 'Low';
        }

        lastLocationUpdate.value = _formatDateTime(DateTime.now());
      } else {
        gpsAccuracy.value = 'Not Available';
        lastLocationUpdate.value = 'Never';
      }
    } catch (e) {
      print('Error checking location accuracy: $e');
      gpsAccuracy.value = 'Unknown';
      lastLocationUpdate.value = 'Error';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> refreshLocationAccuracy() async {
    await _checkLocationAccuracy();
    Get.snackbar(
      'Refreshed',
      'Location accuracy updated',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
    );
  }

  // ==================== APP INFO ====================
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion.value = packageInfo.version.isNotEmpty
          ? packageInfo.version
          : 'Unknown';
      appBuildNumber.value = packageInfo.buildNumber.isNotEmpty
          ? packageInfo.buildNumber
          : 'Unknown';
    } catch (e) {
      print('Error loading app info: $e');
      // Fallback to unknown if package info fails
      appVersion.value = 'Unknown';
      appBuildNumber.value = 'Unknown';
    }
  }

  // ==================== RATE APP ====================
  Future<void> rateApp() async {
    try {
      // Replace with your actual app store URLs
      const androidUrl = 'https://play.google.com/store/apps/details?id=com.aariz.pick_u';
      const iosUrl = 'https://apps.apple.com/app/id123456789';

      String url;
      if (Platform.isAndroid) {
        url = androidUrl;
      } else if (Platform.isIOS) {
        url = iosUrl;
      } else {
        Get.snackbar(
          'Not Available',
          'Rating is not available on this platform',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Could not open app store',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error opening app store: $e');
      Get.snackbar(
        'Error',
        'Could not open app store',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ==================== REFRESH ALL ====================
  Future<void> refreshAll() async {
    await Future.wait([
      _checkLocationPermission(),
      _checkNotificationPermission(),
      _calculateCacheSize(),
      _checkLocationAccuracy(),
    ]);
  }
}


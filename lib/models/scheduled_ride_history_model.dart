import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class ScheduledRideHistoryResponse {
  final List<ScheduledRideItem> items;
  final int completedRides;
  final double totalFare;

  ScheduledRideHistoryResponse({
    required this.items,
    required this.completedRides,
    required this.totalFare,
  });

  factory ScheduledRideHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ScheduledRideHistoryResponse(
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ScheduledRideItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      completedRides: json['completedRides'] ?? 0,
      totalFare: (json['totalFare'] ?? 0.0).toDouble(),
    );
  }
}

class ScheduledRideItem {
  final String? rideId;
  final DateTime scheduledTime;
  final double fareFinal;
  final String status;
  final double distance;
  final String pickupLocation;
  final String dropoffLocation;
  final String rideStartTime;
  final String rideEndTime;
  final DateTime createdAt;

  ScheduledRideItem({
    this.rideId,
    required this.scheduledTime,
    required this.fareFinal,
    required this.status,
    required this.distance,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.rideStartTime,
    required this.rideEndTime,
    required this.createdAt,
  });

  factory ScheduledRideItem.fromJson(Map<String, dynamic> json) {
    // Check for rideId in various possible field names
    String? rideId = json['rideId'] as String?;
    rideId ??= json['id'] as String?;
    rideId ??= json['scheduledRideId'] as String?;
    rideId ??= json['ride_id'] as String?;
    
    return ScheduledRideItem(
      rideId: rideId,
      scheduledTime: DateTime.parse(json['scheduledTime']),
      fareFinal: (json['fareFinal'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      rideStartTime: json['rideStartTime'] ?? '',
      rideEndTime: json['rideEndTime'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get formattedScheduledDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(scheduledTime);
  }

  String get formattedScheduledTime {
    return DateFormat('hh:mm a').format(scheduledTime);
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return MColor.primaryNavy;
      case 'cancelled':
      case 'canceled':
        return MColor.danger;
      case 'pending':
        return MColor.warning;
      case 'ongoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String get shortPickupLocation {
    final parts = pickupLocation.split(',');
    return parts.length > 2 ? '${parts[0]}, ${parts[1]}...' : pickupLocation;
  }

  String get shortDropoffLocation {
    final parts = dropoffLocation.split(',');
    return parts.length > 2 ? '${parts[0]}, ${parts[1]}...' : dropoffLocation;
  }

  // For sorting - pending rides with earliest scheduled time first (upcoming)
  int compareTo(ScheduledRideItem other) {
    if (status.toLowerCase() == 'pending' && other.status.toLowerCase() == 'pending') {
      return scheduledTime.compareTo(other.scheduledTime); // Earliest/upcoming first
    } else if (status.toLowerCase() == 'pending') {
      return -1; // Pending first
    } else if (other.status.toLowerCase() == 'pending') {
      return 1; // Other pending first
    } else {
      return other.createdAt.compareTo(createdAt); // Latest created first for non-pending
    }
  }
}
import 'package:intl/intl.dart';

class RideHistoryResponse {
  final List<RideItem> items;
  final int completedRides;
  final double totalFare;

  RideHistoryResponse({
    required this.items,
    required this.completedRides,
    required this.totalFare,
  });

  factory RideHistoryResponse.fromJson(Map<String, dynamic> json) {
    return RideHistoryResponse(
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => RideItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      completedRides: json['completedRides'] ?? 0,
      totalFare: (json['totalFare'] ?? 0.0).toDouble(),
    );
  }
}

class RideItem {
  final String? rideId;
  final DateTime scheduledTime;
  final double fareFinal;
  /// Driver tip for this ride (from API `tipAmount`).
  final double tipAmount;
  final String status;
  final double distance;
  final String pickupLocation;
  final String dropoffLocation;
  final String rideStartTime;
  final String rideEndTime;
  final DateTime createdAt;

  RideItem({
    this.rideId,
    required this.scheduledTime,
    required this.fareFinal,
    this.tipAmount = 0.0,
    required this.status,
    required this.distance,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.rideStartTime,
    required this.rideEndTime,
    required this.createdAt,
  });

  double get totalWithTip => fareFinal + tipAmount;

  factory RideItem.fromJson(Map<String, dynamic> json) {
    // Check for rideId in various possible field names
    String? rideId = json['rideId'] as String?;
    rideId ??= json['id'] as String?;
    rideId ??= json['ride_id'] as String?;
    
    return RideItem(
      rideId: rideId,
      scheduledTime: DateTime.parse(json['scheduledTime']),
      fareFinal: (json['fareFinal'] ?? 0.0).toDouble(),
      tipAmount: (json['tipAmount'] ?? json['tip'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      rideStartTime: json['rideStartTime'] ?? '',
      rideEndTime: json['rideEndTime'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(scheduledTime);
  }

  String get formattedStartTime {
    return rideStartTime.split('.')[0]; // Remove milliseconds
  }

  String get formattedEndTime {
    return rideEndTime.split('.')[0]; // Remove milliseconds
  }

  // Color get statusColor {
  //   switch (status.toLowerCase()) {
  //     case 'completed':
  //       return MColor.primaryNavy;
  //     case 'cancelled':
  //     case 'canceled':
  //       return MColor.danger;
  //     case 'ongoing':
  //       return Colors.blue;
  //     default:
  //       return Colors.grey;
  //   }
  // }

  String get shortPickupLocation {
    final parts = pickupLocation.split(',');
    return parts.length > 2 ? '${parts[0]}, ${parts[1]}...' : pickupLocation;
  }

  String get shortDropoffLocation {
    final parts = dropoffLocation.split(',');
    return parts.length > 2 ? '${parts[0]}, ${parts[1]}...' : dropoffLocation;
  }
}
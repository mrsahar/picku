class RideStop {
  String? rideStopId;
  String? rideId;
  int stopOrder;
  String location;
  double latitude;
  double longitude;

  RideStop({
    this.rideStopId,
    this.rideId,
    required this.stopOrder,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'stopOrder': stopOrder,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

// 4. Ride Request Model
class RideRequest {
  String userId;
  String rideType;
  bool isScheduled;
  String? scheduledTime;
  int passengerCount;
  double fareEstimate;
  List<RideStop> stops;

  RideRequest({
    required this.userId,
    required this.rideType,
    this.isScheduled = false,
    this.scheduledTime,
    required this.passengerCount,
    required this.fareEstimate,
    required this.stops,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rideType': rideType,
      'isScheduled': isScheduled,
      'scheduledTime': scheduledTime,
      'passengerCount': passengerCount,
      'fareEstimate': fareEstimate,
      'stops': stops.map((stop) => stop.toJson()).toList(),
    };
  }
}
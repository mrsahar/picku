class ChatMessage {
  final String id;
  final String rideId;
  final String senderId;
  final String message;
  final DateTime dateTime;
  final bool isFromCurrentUser;

  ChatMessage({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.message,
    required this.dateTime,
    this.isFromCurrentUser = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      senderId: json['senderId'] ?? '',
      message: json['message'] ?? '',
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'senderId': senderId,
      'message': message,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? rideId,
    String? senderId,
    String? message,
    DateTime? dateTime,
    bool? isFromCurrentUser,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      dateTime: dateTime ?? this.dateTime,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
    );
  }
}
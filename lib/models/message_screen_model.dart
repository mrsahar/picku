class ChatMessage {
  final String id;
  final String rideId;
  final String senderId;
  final String message;
  final DateTime dateTime;
  final bool isFromCurrentUser;
  /// Hub sequence for JoinRideChat(lastReceivedSequence) / replay.
  final int? sequence;

  ChatMessage({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.message,
    required this.dateTime,
    this.isFromCurrentUser = false,
    this.sequence,
  });

  static int? _readSequence(Map<String, dynamic> json) {
    final v = json['sequence'] ?? json['Sequence'];
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static String _readString(Map<String, dynamic> json, String a, String b) {
    final v = json[a] ?? json[b];
    return v?.toString() ?? '';
  }

  static DateTime _readDateTime(Map<String, dynamic> json) {
    final v = json['dateTime'] ?? json['DateTime'];
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final seq = _readSequence(json);
    final senderId = _readString(json, 'senderId', 'SenderId');
    final text = _readString(json, 'message', 'Message');
    final dt = _readDateTime(json);
    return ChatMessage(
      id: json['id']?.toString() ?? (seq != null ? seq.toString() : ''),
      rideId: _readString(json, 'rideId', 'RideId'),
      senderId: senderId,
      message: text,
      dateTime: dt,
      sequence: seq,
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
    int? sequence,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      dateTime: dateTime ?? this.dateTime,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      sequence: sequence ?? this.sequence,
    );
  }
}


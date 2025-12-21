import 'package:intl/intl.dart';

/// Request model for audit log pagination and filtering
class AuditLogRequest {
  final int pageNumber;
  final int pageSize;
  final String? actionFilter;
  final String? entityTypeFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  AuditLogRequest({
    this.pageNumber = 1,
    this.pageSize = 20,
    this.actionFilter,
    this.entityTypeFilter,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };

    if (actionFilter != null && actionFilter!.isNotEmpty) {
      data['actionFilter'] = actionFilter;
    }

    if (entityTypeFilter != null && entityTypeFilter!.isNotEmpty) {
      data['entityTypeFilter'] = entityTypeFilter;
    }

    if (startDate != null) {
      data['startDate'] = startDate!.toIso8601String();
    }

    if (endDate != null) {
      data['endDate'] = endDate!.toIso8601String();
    }

    return data;
  }
}

/// Response model for paginated audit logs
class AuditLogResponse {
  final List<AuditLogDto> data;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  AuditLogResponse({
    required this.data,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory AuditLogResponse.fromJson(Map<String, dynamic> json) {
    return AuditLogResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => AuditLogDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 0,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }
}

/// Individual audit log entry
class AuditLogDto {
  final String? auditLogId;
  final String? userId;
  final String? userType;
  final String? action;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final Map<String, dynamic>? requestData;
  final Map<String, dynamic>? responseData;
  final String? ipAddress;
  final String? userAgent;
  final String? status;
  final String? errorMessage;
  final DateTime? timestamp;
  final int? duration;

  AuditLogDto({
    this.auditLogId,
    this.userId,
    this.userType,
    this.action,
    this.entityType,
    this.entityId,
    this.oldValues,
    this.newValues,
    this.requestData,
    this.responseData,
    this.ipAddress,
    this.userAgent,
    this.status,
    this.errorMessage,
    this.timestamp,
    this.duration,
  });

  factory AuditLogDto.fromJson(Map<String, dynamic> json) {
    return AuditLogDto(
      auditLogId: json['auditLogId']?.toString(),
      userId: json['userId']?.toString(),
      userType: json['userType']?.toString(),
      action: json['action']?.toString(),
      entityType: json['entityType']?.toString(),
      entityId: json['entityId']?.toString(),
      oldValues: _parseJsonString(json['oldValues']),
      newValues: _parseJsonString(json['newValues']),
      requestData: _parseJsonString(json['requestData']),
      responseData: _parseJsonString(json['responseData']),
      ipAddress: json['ipAddress']?.toString(),
      userAgent: json['userAgent']?.toString(),
      status: json['status']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      duration: json['duration'] as int?,
    );
  }

  /// Helper method to parse JSON strings that might be nested
  static Map<String, dynamic>? _parseJsonString(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Format timestamp for display
  String get formattedTimestamp {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm').format(timestamp!);
  }

  /// Get relative time (e.g., "2 hours ago")
  String get relativeTime {
    if (timestamp == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(timestamp!);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get notification icon based on action
  String get actionIcon {
    if (action == null) return '📋';

    final actionLower = action!.toLowerCase();
    if (actionLower.contains('login')) return '🔐';
    if (actionLower.contains('logout')) return '🚪';
    if (actionLower.contains('create')) return '➕';
    if (actionLower.contains('update')) return '✏️';
    if (actionLower.contains('delete')) return '🗑️';
    if (actionLower.contains('view')) return '👁️';
    if (actionLower.contains('ride')) return '🚗';
    if (actionLower.contains('driver')) return '👨‍✈️';
    if (actionLower.contains('payment')) return '💳';
    return '📋';
  }

  /// Get notification title
  String get notificationTitle {
    if (action == null) return 'Activity';

    final actionLower = action!.toLowerCase();
    if (actionLower.contains('login')) return 'Login Activity';
    if (actionLower.contains('logout')) return 'Logout Activity';
    if (actionLower.contains('create')) {
      return '${entityType ?? 'Item'} Created';
    }
    if (actionLower.contains('update')) {
      return '${entityType ?? 'Item'} Updated';
    }
    if (actionLower.contains('delete')) {
      return '${entityType ?? 'Item'} Deleted';
    }
    if (actionLower.contains('view')) {
      return '${entityType ?? 'Item'} Viewed';
    }
    return action!;
  }

  /// Get notification subtitle/description
  String get notificationSubtitle {
    // Build a description from available data
    final parts = <String>[];

    if (userType != null) {
      parts.add(userType!);
    }

    if (action != null) {
      parts.add(action!);
    }

    if (entityType != null && entityId != null) {
      parts.add('on $entityType');
    }

    if (status != null) {
      parts.add('• $status');
    }

    if (parts.isEmpty) {
      return 'No description available';
    }

    return parts.join(' ');
  }

  /// Get status badge color indicator
  String get statusBadge {
    if (status == null) return '⚪';

    switch (status!.toLowerCase()) {
      case 'success':
        return '✅';
      case 'failed':
        return '❌';
      case 'error':
        return '⚠️';
      default:
        return '⚪';
    }
  }

  /// Format duration in a readable way
  String get formattedDuration {
    if (duration == null) return 'N/A';

    if (duration! < 1000) {
      return '${duration}ms';
    } else if (duration! < 60000) {
      return '${(duration! / 1000).toStringAsFixed(2)}s';
    } else {
      return '${(duration! / 60000).toStringAsFixed(2)}m';
    }
  }

  /// Check if the action was successful
  bool get isSuccess => status?.toLowerCase() == 'success';

  /// Check if there are changes (old vs new values)
  bool get hasChanges =>
      (oldValues != null && oldValues!.isNotEmpty) ||
      (newValues != null && newValues!.isNotEmpty);
}


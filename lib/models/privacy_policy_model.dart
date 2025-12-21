/// Privacy Policy Model
class PrivacyPolicyResponse {
  final String? id;
  final String? title;
  final String? content;
  final String? version;
  final DateTime? effectiveDate;
  final DateTime? lastUpdated;
  final bool? isActive;
  final String? language;
  final Map<String, dynamic>? metadata;

  PrivacyPolicyResponse({
    this.id,
    this.title,
    this.content,
    this.version,
    this.effectiveDate,
    this.lastUpdated,
    this.isActive,
    this.language,
    this.metadata,
  });

  factory PrivacyPolicyResponse.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyResponse(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      content: json['content']?.toString(),
      version: json['version']?.toString(),
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.parse(json['effectiveDate'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      isActive: json['isActive'] as bool?,
      language: json['language']?.toString() ?? 'en',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'version': version,
      'effectiveDate': effectiveDate?.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'isActive': isActive,
      'language': language,
      'metadata': metadata,
    };
  }

  /// Get formatted effective date
  String get formattedEffectiveDate {
    if (effectiveDate == null) return 'N/A';
    return '${effectiveDate!.day}/${effectiveDate!.month}/${effectiveDate!.year}';
  }

  /// Get formatted last updated date
  String get formattedLastUpdated {
    if (lastUpdated == null) return 'N/A';
    return '${lastUpdated!.day}/${lastUpdated!.month}/${lastUpdated!.year}';
  }

  /// Check if content is available
  bool get hasContent => content != null && content!.isNotEmpty;

  /// Get display title or default
  String get displayTitle => title ?? 'Privacy Policy';
}


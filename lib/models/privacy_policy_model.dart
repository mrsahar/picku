/// Privacy Policy Model
class PrivacyPolicyResponse {
  final String? policyId;
  final String? policyType;
  final String? title;
  final String? content;
  final int? version;
  final bool? isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PrivacyPolicyResponse({
    this.policyId,
    this.policyType,
    this.title,
    this.content,
    this.version,
    this.isActive,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory PrivacyPolicyResponse.fromJson(Map<String, dynamic> json) {
    print('PrivacyPolicyResponse.fromJson: Parsing response...');
    print('  - policyId: ${json['policyId']}');
    print('  - title: ${json['title']}');
    print('  - content length: ${json['content']?.toString().length ?? 0}');

    return PrivacyPolicyResponse(
      policyId: json['policyId']?.toString(),
      policyType: json['policyType']?.toString(),
      title: json['title']?.toString(),
      content: json['content']?.toString(),
      version: json['version'] as int?,
      isActive: json['isActive'] as bool?,
      createdBy: json['createdBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policyId': policyId,
      'policyType': policyType,
      'title': title,
      'content': content,
      'version': version,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Get formatted created date
  String get formattedCreatedAt {
    if (createdAt == null) return 'N/A';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  /// Get formatted last updated date
  String get formattedUpdatedAt {
    if (updatedAt == null) return 'N/A';
    return '${updatedAt!.day}/${updatedAt!.month}/${updatedAt!.year}';
  }

  /// Check if content is available
  bool get hasContent => content != null && content!.isNotEmpty;

  /// Get display title or default
  String get displayTitle => title ?? 'Privacy Policy';
}


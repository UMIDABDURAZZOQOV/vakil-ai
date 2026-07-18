import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';

RiskLevel riskLevelFromString(String value) {
  switch (value) {
    case 'high':
      return RiskLevel.high;
    case 'medium':
      return RiskLevel.medium;
    default:
      return RiskLevel.low;
  }
}

class ClauseFlag {
  final String title;
  final RiskLevel risk;
  final String explanation;

  const ClauseFlag({
    required this.title,
    required this.risk,
    required this.explanation,
  });

  factory ClauseFlag.fromJson(Map<String, dynamic> json) => ClauseFlag(
        title: json['title'] as String,
        risk: riskLevelFromString(json['risk_level'] as String),
        explanation: json['explanation'] as String,
      );
}

class DocumentAnalysis {
  final String id;
  final String title;
  final String dateLabel;
  final RiskLevel riskLevel;
  final double riskScore; // out of 10
  final String originalText;
  final List<String> summaryBullets;
  final List<ClauseFlag> flags;
  final Map<String, int> complianceScores; // e.g. {'GDPR': 88}
  final List<String> keyDates;

  const DocumentAnalysis({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.riskLevel,
    required this.riskScore,
    required this.originalText,
    required this.summaryBullets,
    required this.flags,
    required this.complianceScores,
    required this.keyDates,
  });

  factory DocumentAnalysis.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now();
    return DocumentAnalysis(
      id: json['id'] as String,
      title: json['title'] as String,
      dateLabel: DateFormat('d-MMM, yyyy').format(createdAt),
      riskLevel: riskLevelFromString(json['risk_level'] as String? ?? 'low'),
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0,
      originalText: json['original_text'] as String? ?? '',
      summaryBullets: (json['summary_bullets'] as List?)?.cast<String>() ?? const [],
      flags: (json['flags'] as List?)
              ?.map((f) => ClauseFlag.fromJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
      complianceScores: (json['compliance_scores'] as Map?)?.map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ) ??
          const {},
      keyDates: (json['key_dates'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        isUser: json['is_user'] as bool,
        text: json['text'] as String,
        timestamp: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class AppUser {
  final String name;
  final String role;
  final bool telegramConnected;
  final int documentsUsed;
  final int documentsQuota;
  final bool isPremium;

  const AppUser({
    required this.name,
    required this.role,
    required this.telegramConnected,
    required this.documentsUsed,
    required this.documentsQuota,
    required this.isPremium,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        name: (json['name'] as String?)?.isNotEmpty == true
            ? json['name'] as String
            : json['identifier'] as String,
        role: json['role'] as String? ?? '',
        telegramConnected: json['telegram_connected'] as bool? ?? false,
        documentsUsed: json['documents_used'] as int? ?? 0,
        documentsQuota: json['documents_quota'] as int? ?? 2,
        isPremium: json['is_premium'] as bool? ?? false,
      );
}

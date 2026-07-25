import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/lesson.dart';

/// Firestore DTO for a lesson document.
class LessonModel {
  final String id;
  final String title;
  final String titleKin;
  final String cropTag;
  final String topicTag;
  final String level;
  final List<String> formats;
  final int durationMinutes;
  final String emoji;
  final String description;
  final String descriptionKin;
  final bool isNew;
  final bool isWomensPathway;
  final bool isActive;
  final int order;

  const LessonModel({
    required this.id,
    required this.title,
    required this.titleKin,
    required this.cropTag,
    required this.topicTag,
    required this.level,
    required this.formats,
    required this.durationMinutes,
    required this.emoji,
    required this.description,
    required this.descriptionKin,
    this.isNew = false,
    this.isWomensPathway = false,
    this.isActive = true,
    this.order = 0,
  });

  // ── Firestore → model ───────────────────────────────────────────────────
  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      titleKin: data['titleKin'] as String? ?? '',
      cropTag: data['cropTag'] as String? ?? '',
      topicTag: data['topicTag'] as String? ?? '',
      level: data['level'] as String? ?? 'beginner',
      formats: List<String>.from(data['formats'] as List? ?? ['text']),
      durationMinutes: data['durationMinutes'] as int? ?? 10,
      emoji: data['emoji'] as String? ?? '📚',
      description: data['description'] as String? ?? '',
      descriptionKin: data['descriptionKin'] as String? ?? '',
      isNew: data['isNew'] as bool? ?? false,
      isWomensPathway: data['isWomensPathway'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  // ── model → Firestore ───────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'title': title,
    'titleKin': titleKin,
    'cropTag': cropTag,
    'topicTag': topicTag,
    'level': level,
    'formats': formats,
    'durationMinutes': durationMinutes,
    'emoji': emoji,
    'description': description,
    'descriptionKin': descriptionKin,
    'isNew': isNew,
    'isWomensPathway': isWomensPathway,
    'isActive': isActive,
    'order': order,
  };

  // ── model → domain entity ───────────────────────────────────────────────
  Lesson toEntity({double progress = 0.0}) => Lesson(
    id: id,
    title: title,
    titleKin: titleKin,
    cropTag: cropTag,
    topicTag: topicTag,
    level: LessonLevel.values.firstWhere(
      (e) => e.name == level,
      orElse: () => LessonLevel.beginner,
    ),
    formats: formats
        .map((f) => LessonFormat.values.firstWhere(
              (e) => e.name == f,
              orElse: () => LessonFormat.text,
            ))
        .toList(),
    durationMinutes: durationMinutes,
    progress: progress,
    emoji: emoji,
    description: description,
    descriptionKin: descriptionKin,
    isNew: isNew,
    isWomensPathway: isWomensPathway,
    isActive: isActive,
    order: order,
  );
}

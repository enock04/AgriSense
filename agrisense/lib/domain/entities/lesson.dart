/// Lesson delivery format.
enum LessonFormat { audio, video, text }

/// Difficulty level filter.
enum LessonLevel { beginner, intermediate, advanced, all }

/// Domain entity for a learning lesson.
class Lesson {
  final String id;
  final String title;
  final String titleKin;
  final String cropTag;
  final String topicTag;
  final LessonLevel level;
  final List<LessonFormat> formats;
  final int durationMinutes;
  final double progress; // 0.0 – 1.0
  final bool isNew;
  final bool isDownloaded;
  final String emoji;
  final String description;
  final String descriptionKin;
  final bool isWomensPathway;
  final bool isActive;
  final int order;

  const Lesson({
    required this.id,
    required this.title,
    required this.titleKin,
    required this.cropTag,
    required this.topicTag,
    required this.level,
    required this.formats,
    required this.durationMinutes,
    required this.progress,
    required this.emoji,
    required this.description,
    required this.descriptionKin,
    this.isNew = false,
    this.isDownloaded = false,
    this.isWomensPathway = false,
    this.isActive = true,
    this.order = 0,
  });

  bool get isCompleted => progress >= 1.0;
  bool get isStarted   => progress > 0 && progress < 1.0;

  /// Return a copy with updated progress.
  Lesson withProgress(double newProgress) => Lesson(
    id: id, title: title, titleKin: titleKin, cropTag: cropTag,
    topicTag: topicTag, level: level, formats: formats,
    durationMinutes: durationMinutes, progress: newProgress.clamp(0.0, 1.0),
    emoji: emoji, description: description, descriptionKin: descriptionKin,
    isNew: isNew, isDownloaded: isDownloaded, isWomensPathway: isWomensPathway,
    isActive: isActive, order: order,
  );
}

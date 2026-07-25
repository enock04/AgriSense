import '../entities/lesson.dart';

/// Contract for lesson content management.
abstract class LessonRepository {
  /// Real-time stream of lessons from the backend.
  Stream<List<Lesson>> lessonsStream();

  /// Fetch today's tip. Returns null if none available.
  Future<Map<String, String>?> getTodaysTip();

  /// Seed initial lessons if the collection is empty (first-run).
  Future<void> seedLessonsIfEmpty();

  /// Seed initial tips if the collection is empty (first-run).
  Future<void> seedTipsIfEmpty();

  /// Check if the current user is an admin.
  Future<bool> isAdmin({String? storedPhone});

  /// Fetch all lessons, including inactive ones (admin only).
  Future<List<Lesson>> getAllLessonsAdmin();

  /// Create or update a lesson (admin only).
  Future<String?> saveLesson(Lesson lesson);

  /// Delete (deactivate) a lesson (admin only).
  Future<void> deleteLesson(String id);

  /// Fetch all tips, including inactive ones (admin only).
  Future<List<Map<String, dynamic>>> getAllTipsAdmin();

  /// Create or update a tip (admin only).
  Future<String?> saveTip({
    required String id,
    required String title,
    required String titleKin,
    required String body,
    required String bodyKin,
    required String emoji,
  });

  /// Delete a tip (admin only).
  Future<void> deleteTip(String id);
}

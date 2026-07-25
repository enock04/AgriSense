import '../../domain/entities/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/remote/firestore_remote_datasource.dart';
import '../datasources/local/preferences_local_datasource.dart';
import '../../data/mock_data.dart';

/// Concrete implementation of [LessonRepository].
class LessonRepositoryImpl implements LessonRepository {
  final FirestoreRemoteDatasource _remote;
  final PreferencesLocalDatasource _local;

  LessonRepositoryImpl(this._remote, this._local);

  @override
  Stream<List<Lesson>> lessonsStream() {
    return _remote.lessonsStream().map((models) {
      return models.map((m) {
        // Inject locally cached progress
        final progress = _local.getDouble('progress_${m.id}') ?? 0.0;
        return m.toEntity(progress: progress);
      }).toList();
    });
  }

  @override
  Future<Map<String, String>?> getTodaysTip() =>
      _remote.getTodaysTip();

  @override
  Future<void> seedLessonsIfEmpty() async {
    final seeds = MockData.lessons.asMap().entries.map((e) => {
      'id': e.value.id,
      'title': e.value.title,
      'titleKin': e.value.titleKin,
      'cropTag': e.value.cropTag,
      'topicTag': e.value.topicTag,
      'level': e.value.level.name,
      'formats': e.value.formats.map((f) => f.name).toList(),
      'durationMinutes': e.value.durationMinutes,
      'emoji': e.value.emoji,
      'description': e.value.description,
      'descriptionKin': e.value.descriptionKin,
      'isNew': e.value.isNew,
      'isWomensPathway': e.value.isWomensPathway,
    }).toList();
    await _remote.seedLessonsIfEmpty(seeds);
  }

  @override
  Future<void> seedTipsIfEmpty() async {
    await _remote.seedTipsIfEmpty(
        MockData.tipsOfDay.map((t) => Map<String, dynamic>.from(t)).toList());
  }

  @override
  Future<bool> isAdmin({String? storedPhone}) =>
      _remote.isAdmin(storedPhone: storedPhone ?? '');

  @override
  Future<List<Lesson>> getAllLessonsAdmin() async {
    final models = await _remote.getAllLessonsAdmin();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> deleteLesson(String id) => _remote.deleteLesson(id);

  @override
  Future<String?> saveLesson(Lesson lesson) {
    final data = {
      'title': lesson.title, 'titleKin': lesson.titleKin,
      'cropTag': lesson.cropTag, 'topicTag': lesson.topicTag,
      'level': lesson.level.name,
      'formats': lesson.formats.map((f) => f.name).toList(),
      'durationMinutes': lesson.durationMinutes, 'emoji': lesson.emoji,
      'description': lesson.description, 'descriptionKin': lesson.descriptionKin,
      'isNew': lesson.isNew, 'isWomensPathway': lesson.isWomensPathway,
      'isActive': lesson.isActive, 'order': lesson.order,
    };
    return _remote.saveLesson(lesson.id, data);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllTipsAdmin() =>
      _remote.getAllTipsAdmin();

  @override
  Future<String?> saveTip({
    required String id,
    required String title,
    required String titleKin,
    required String body,
    required String bodyKin,
    required String emoji,
  }) =>
      _remote.saveTip(
        id: id, title: title, titleKin: titleKin,
        body: body, bodyKin: bodyKin, emoji: emoji,
      );

  @override
  Future<void> deleteTip(String id) => _remote.deleteTip(id);
}

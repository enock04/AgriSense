import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/domain/entities/lesson.dart';

void main() {
  Lesson makeLesson({double progress = 0.0, bool isNew = false}) {
    return Lesson(
      id: 'lesson-001',
      title: 'Soil Health Basics',
      titleKin: 'Ubuzima bw\'Ubutaka',
      cropTag: 'maize',
      topicTag: 'soil',
      level: LessonLevel.beginner,
      formats: [LessonFormat.text, LessonFormat.audio],
      durationMinutes: 15,
      progress: progress,
      emoji: '🌱',
      description: 'Learn the basics of soil health',
      descriptionKin: 'Menya ibintu by\'ibanze ku buzima bw\'ubutaka',
      isNew: isNew,
    );
  }

  group('Lesson computed properties', () {
    test('isCompleted is true when progress is 1.0', () {
      expect(makeLesson(progress: 1.0).isCompleted, isTrue);
    });

    test('isCompleted is false when progress is below 1.0', () {
      expect(makeLesson(progress: 0.9).isCompleted, isFalse);
      expect(makeLesson(progress: 0.0).isCompleted, isFalse);
    });

    test('isStarted is true between 0 and 1 exclusive', () {
      expect(makeLesson(progress: 0.5).isStarted, isTrue);
      expect(makeLesson(progress: 0.01).isStarted, isTrue);
    });

    test('isStarted is false at 0.0 and 1.0', () {
      expect(makeLesson(progress: 0.0).isStarted, isFalse);
      expect(makeLesson(progress: 1.0).isStarted, isFalse);
    });
  });

  group('Lesson.withProgress()', () {
    test('returns a new Lesson with updated progress', () {
      final original = makeLesson(progress: 0.0);
      final updated = original.withProgress(0.5);

      expect(updated.progress, 0.5);
      expect(original.progress, 0.0); // immutable — original unchanged
    });

    test('preserves all other fields', () {
      final original = makeLesson(progress: 0.2, isNew: true);
      final updated = original.withProgress(0.8);

      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.titleKin, original.titleKin);
      expect(updated.level, original.level);
      expect(updated.formats, original.formats);
      expect(updated.durationMinutes, original.durationMinutes);
      expect(updated.isNew, original.isNew);
      expect(updated.emoji, original.emoji);
    });

    test('clamps progress to 0.0 minimum', () {
      final lesson = makeLesson().withProgress(-0.5);
      expect(lesson.progress, 0.0);
    });

    test('clamps progress to 1.0 maximum', () {
      final lesson = makeLesson().withProgress(1.5);
      expect(lesson.progress, 1.0);
    });

    test('isCompleted after withProgress(1.0)', () {
      final lesson = makeLesson(progress: 0.3).withProgress(1.0);
      expect(lesson.isCompleted, isTrue);
      expect(lesson.isStarted, isFalse);
    });
  });

  group('LessonLevel enum', () {
    test('can be looked up by name', () {
      expect(
        LessonLevel.values.firstWhere((e) => e.name == 'beginner'),
        LessonLevel.beginner,
      );
      expect(
        LessonLevel.values.firstWhere((e) => e.name == 'intermediate'),
        LessonLevel.intermediate,
      );
      expect(
        LessonLevel.values.firstWhere((e) => e.name == 'advanced'),
        LessonLevel.advanced,
      );
    });
  });

  group('LessonFormat enum', () {
    test('has audio, video, text formats', () {
      expect(LessonFormat.values, containsAll([
        LessonFormat.audio,
        LessonFormat.video,
        LessonFormat.text,
      ]));
    });
  });
}

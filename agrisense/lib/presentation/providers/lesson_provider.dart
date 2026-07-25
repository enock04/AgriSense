import 'package:flutter/material.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/mock_data.dart';

/// Manages lesson content and per-lesson progress.
class LessonProvider extends ChangeNotifier {
  final LessonRepository _lessonRepository;
  final UserRepository _userRepository;

  LessonProvider(this._lessonRepository, this._userRepository);

  List<Lesson> _lessons = [];
  List<Lesson> get lessons => _lessons.isEmpty ? MockData.lessons : _lessons;

  Map<String, String>? _todaysTip;
  Map<String, String> get todaysTip => _todaysTip ?? MockData.tipOfDay;

  final Map<String, double> _progress = {};

  bool _loaded = false;
  bool get loaded => _loaded;

  // ── Initialise ────────────────────────────────────────────────────────────

  /// Start streaming lessons from Firestore.
  void startListening() {
    _lessonRepository.lessonsStream().listen((incoming) {
      if (incoming.isNotEmpty) {
        // Re-inject local progress values in case Firestore doesn't have them yet
        _lessons = incoming.map((l) =>
            l.withProgress(_progress[l.id] ?? l.progress)).toList();
        _loaded = true;
        notifyListeners();
      }
    }, onError: (_) {
      // Fall back to mock data (default already)
    });
  }

  Future<void> loadTodaysTip() async {
    final tip = await _lessonRepository.getTodaysTip();
    if (tip != null) { _todaysTip = tip; notifyListeners(); }
  }

  Future<void> loadLocalProgress() async {
    final remote = await _userRepository.loadAllProgress();
    _progress.addAll(remote);
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  double getProgress(String lessonId) => _progress[lessonId] ?? 0.0;

  Future<void> updateProgress(String lessonId, double value) async {
    _progress[lessonId] = value.clamp(0.0, 1.0);
    // Optimistically update in-memory lessons list
    _lessons = _lessons.map((l) =>
        l.id == lessonId ? l.withProgress(_progress[lessonId]!) : l).toList();
    notifyListeners();
    // Persist both locally and to Firestore
    await _userRepository.saveLessonProgress(lessonId, _progress[lessonId]!);
  }

  void reset() {
    _lessons = [];
    _todaysTip = null;
    _progress.clear();
    _loaded = false;
    notifyListeners();
  }
}

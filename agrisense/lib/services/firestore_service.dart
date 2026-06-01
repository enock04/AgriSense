import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Collection references ────────────────────────────────────────────────
  CollectionReference get _users   => _db.collection('users');
  CollectionReference get _posts   => _db.collection('community_posts');
  CollectionReference get _lessons => _db.collection('lessons');
  CollectionReference get _tips    => _db.collection('tips');

  DocumentReference? get _userDoc =>
      _uid != null ? _users.doc(_uid) : null;

  // ════════════════════════════════════════════════════════════════════════
  // USER PROFILE
  // ════════════════════════════════════════════════════════════════════════

  Future<void> saveProfile({
    required String name,
    required String phone,
    required FarmerType farmerType,
    required List<Crop> crops,
    required String district,
    required String language,
  }) async {
    if (_userDoc == null) return;
    await _userDoc!.set({
      'name': name,
      'phone': phone,
      'farmerType': farmerType.name,
      'crops': crops.map((c) => {
        'id': c.id, 'name': c.name,
        'kinyarwanda': c.kinyarwanda, 'emoji': c.emoji,
      }).toList(),
      'district': district,
      'language': language,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadProfile() async {
    if (_userDoc == null) return null;
    try {
      final snap = await _userDoc!.get();
      return snap.exists ? snap.data() as Map<String, dynamic> : null;
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // LESSON PROGRESS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> saveLessonProgress(String lessonId, double progress) async {
    if (_userDoc == null) return;
    try {
      await _userDoc!
          .collection('progress')
          .doc(lessonId)
          .set({
        'progress': progress,
        'lessonId': lessonId,
        'updatedAt': FieldValue.serverTimestamp(),
        'completed': progress >= 1.0,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<Map<String, double>> loadAllProgress() async {
    if (_userDoc == null) return {};
    try {
      final snaps = await _userDoc!.collection('progress').get();
      return {
        for (final doc in snaps.docs)
          doc.id: ((doc.data()['progress'] as num?)?.toDouble()) ?? 0.0
      };
    } catch (_) {
      return {};
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // COMMUNITY POSTS
  // ════════════════════════════════════════════════════════════════════════

  /// Stream of all posts ordered by newest first
  Stream<List<CommunityPostData>> postsStream() {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CommunityPostData.fromFirestore(doc))
            .toList());
  }

  /// Add a new question post
  Future<String?> addPost({
    required String question,
    required String questionKin,
    required String cropTag,
    required String district,
    required String userName,
    required String userInitials,
  }) async {
    if (_uid == null) return null;
    try {
      final ref = await _posts.add({
        'question': question,
        'questionKin': questionKin,
        'cropTag': cropTag,
        'district': district,
        'userName': userName,
        'userInitials': userInitials,
        'userId': _uid,
        'upvoteCount': 0,
        'replyCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  /// Toggle upvote using a sub-collection for accuracy
  Future<void> toggleUpvote(String postId) async {
    if (_uid == null) return;
    final upvoteRef = _posts.doc(postId).collection('upvotes').doc(_uid);
    final postRef = _posts.doc(postId);

    return _db.runTransaction((tx) async {
      final upvoteSnap = await tx.get(upvoteRef);
      if (upvoteSnap.exists) {
        tx.delete(upvoteRef);
        tx.update(postRef, {'upvoteCount': FieldValue.increment(-1)});
      } else {
        tx.set(upvoteRef, {'uid': _uid, 'at': FieldValue.serverTimestamp()});
        tx.update(postRef, {'upvoteCount': FieldValue.increment(1)});
      }
    });
  }

  /// Check if current user has upvoted a post
  Future<bool> hasUpvoted(String postId) async {
    if (_uid == null) return false;
    try {
      final snap = await _posts.doc(postId).collection('upvotes').doc(_uid).get();
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // LESSONS
  // ════════════════════════════════════════════════════════════════════════

  /// Stream of active lessons ordered by sort order
  Stream<List<LessonData>> lessonsStream() {
    return _lessons
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(LessonData.fromFirestore).toList());
  }

  /// Save or update a lesson
  Future<String?> saveLesson(LessonData lesson) async {
    try {
      if (lesson.id.isEmpty) {
        final ref = await _lessons.add(lesson.toMap());
        return ref.id;
      } else {
        await _lessons.doc(lesson.id).set(lesson.toMap(), SetOptions(merge: true));
        return lesson.id;
      }
    } catch (e) {
      return null;
    }
  }

  /// Delete a lesson (soft delete — sets isActive=false)
  Future<void> deleteLesson(String lessonId) async {
    await _lessons.doc(lessonId).update({'isActive': false, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Seed mock lessons on first launch
  Future<void> seedLessonsIfEmpty() async {
    try {
      final snap = await _lessons.limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final batch = _db.batch();
      for (int i = 0; i < MockData.lessons.length; i++) {
        final l = MockData.lessons[i];
        final ref = _lessons.doc(l.id);
        batch.set(ref, {
          'id': l.id, 'title': l.title, 'titleKin': l.titleKin,
          'cropTag': l.cropTag, 'topicTag': l.topicTag,
          'level': l.level.name, 'emoji': l.emoji,
          'formats': l.formats.map((f) => f.name).toList(),
          'durationMinutes': l.durationMinutes,
          'description': l.description, 'descriptionKin': l.descriptionKin,
          'isNew': l.isNew, 'isWomensPathway': l.isWomensPathway,
          'isActive': true, 'order': i,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════════════
  // TIPS
  // ════════════════════════════════════════════════════════════════════════

  /// Today's tip — rotates by day of month
  Future<Map<String, String>?> getTodaysTip() async {
    try {
      final snap = await _tips.where('isActive', isEqualTo: true).get();
      if (snap.docs.isEmpty) return null;
      final index = DateTime.now().day % snap.docs.length;
      final doc = snap.docs[index].data() as Map<String, dynamic>;
      return {
        'title': doc['title'] ?? '',
        'titleKin': doc['titleKin'] ?? '',
        'body': doc['body'] ?? '',
        'bodyKin': doc['bodyKin'] ?? '',
        'emoji': doc['emoji'] ?? '💡',
      };
    } catch (_) {
      return null;
    }
  }

  /// Save a tip
  Future<String?> saveTip({
    required String id, required String title, required String titleKin,
    required String body, required String bodyKin, required String emoji,
  }) async {
    try {
      final data = {
        'title': title, 'titleKin': titleKin,
        'body': body, 'bodyKin': bodyKin,
        'emoji': emoji, 'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (id.isEmpty) {
        data['createdAt'] = FieldValue.serverTimestamp();
        final ref = await _tips.add(data);
        return ref.id;
      } else {
        await _tips.doc(id).set(data, SetOptions(merge: true));
        return id;
      }
    } catch (_) {
      return null;
    }
  }

  /// Seed tips if empty
  Future<void> seedTipsIfEmpty() async {
    try {
      final snap = await _tips.limit(1).get();
      if (snap.docs.isNotEmpty) return;
      final batch = _db.batch();
      for (final tip in MockData.tipsOfDay) {
        batch.set(_tips.doc(), {
          ...tip, 'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════════════
  // ADMIN
  // ════════════════════════════════════════════════════════════════════════

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    if (_uid == null) return false;
    try {
      // Try both cases since Firestore collection names are case-sensitive
      DocumentSnapshot doc = await _db.collection('Config').doc('admin').get();
      if (!doc.exists) doc = await _db.collection('config').doc('admin').get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>?;
      final adminUids = (data?['uids'] as List?)?.cast<String>() ?? [];
      final adminPhones = (data?['phones'] as List?)?.cast<String>() ?? [];
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
      return adminUids.contains(_uid) || adminPhones.contains(phone);
    } catch (_) {
      return false;
    }
  }

  /// Get all lessons including inactive (admin only)
  Future<List<LessonData>> getAllLessonsAdmin() async {
    try {
      final snap = await _lessons.orderBy('order').get();
      return snap.docs.map(LessonData.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get all tips (admin only)
  Future<List<Map<String, dynamic>>> getAllTipsAdmin() async {
    try {
      final snap = await _tips.get();
      return snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
    } catch (_) {
      return [];
    }
  }

  /// Seed mock posts on first launch (only if collection is empty)
  Future<void> seedPostsIfEmpty() async {
    try {
      final snap = await _posts.limit(1).get();
      if (snap.docs.isNotEmpty) return; // already seeded

      final batch = _db.batch();
      for (final p in MockData.communityPosts) {
        final ref = _posts.doc(p.id);
        batch.set(ref, {
          'question': p.question,
          'questionKin': p.questionKin,
          'cropTag': 'General',
          'district': p.district,
          'userName': p.userName,
          'userInitials': p.userInitials,
          'userId': 'seed',
          'upvoteCount': p.upvotes,
          'replyCount': p.replyCount,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}
  }
}

// ── Data class for Firestore community posts ─────────────────────────────

class CommunityPostData {
  final String id;
  final String userName;
  final String userInitials;
  final String district;
  final String question;
  final String questionKin;
  final int upvoteCount;
  final int replyCount;
  final String userId;
  final DateTime? createdAt;

  CommunityPostData({
    required this.id,
    required this.userName,
    required this.userInitials,
    required this.district,
    required this.question,
    required this.questionKin,
    required this.upvoteCount,
    required this.replyCount,
    required this.userId,
    this.createdAt,
  });

  factory CommunityPostData.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['createdAt'];
    return CommunityPostData(
      id: doc.id,
      userName: d['userName'] ?? 'Farmer',
      userInitials: d['userInitials'] ?? 'F',
      district: d['district'] ?? 'Rwanda',
      question: d['question'] ?? '',
      questionKin: d['questionKin'] ?? '',
      upvoteCount: (d['upvoteCount'] ?? 0) as int,
      replyCount: (d['replyCount'] ?? 0) as int,
      userId: d['userId'] ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }
}

// ── Data class for Firestore lessons ──────────────────────────────────────

class LessonData {
  final String id;
  final String title;
  final String titleKin;
  final String cropTag;
  final String topicTag;
  final String level;   // beginner / intermediate / advanced / all
  final List<String> formats; // audio / video / text
  final int durationMinutes;
  final String emoji;
  final String description;
  final String descriptionKin;
  final bool isNew;
  final bool isWomensPathway;
  final bool isActive;
  final int order;

  const LessonData({
    required this.id, required this.title, required this.titleKin,
    required this.cropTag, required this.topicTag, required this.level,
    required this.formats, required this.durationMinutes, required this.emoji,
    required this.description, required this.descriptionKin,
    this.isNew = false, this.isWomensPathway = false,
    this.isActive = true, this.order = 0,
  });

  factory LessonData.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LessonData(
      id: doc.id,
      title: d['title'] ?? '',
      titleKin: d['titleKin'] ?? '',
      cropTag: d['cropTag'] ?? '',
      topicTag: d['topicTag'] ?? '',
      level: d['level'] ?? 'beginner',
      formats: (d['formats'] as List?)?.cast<String>() ?? ['text'],
      durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 5,
      emoji: d['emoji'] ?? '🌱',
      description: d['description'] ?? '',
      descriptionKin: d['descriptionKin'] ?? '',
      isNew: d['isNew'] ?? false,
      isWomensPathway: d['isWomensPathway'] ?? false,
      isActive: d['isActive'] ?? true,
      order: (d['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title, 'titleKin': titleKin,
    'cropTag': cropTag, 'topicTag': topicTag, 'level': level,
    'formats': formats, 'durationMinutes': durationMinutes, 'emoji': emoji,
    'description': description, 'descriptionKin': descriptionKin,
    'isNew': isNew, 'isWomensPathway': isWomensPathway,
    'isActive': isActive, 'order': order,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Convert to the app's Lesson model for display
  Lesson toLesson({double progress = 0.0}) => Lesson(
    id: id, title: title, titleKin: titleKin,
    cropTag: cropTag, topicTag: topicTag,
    level: LessonLevel.values.firstWhere((e) => e.name == level, orElse: () => LessonLevel.beginner),
    formats: formats.map((f) => LessonFormat.values.firstWhere((e) => e.name == f, orElse: () => LessonFormat.text)).toList(),
    durationMinutes: durationMinutes, progress: progress, emoji: emoji,
    description: description, descriptionKin: descriptionKin,
    isNew: isNew, isWomensPathway: isWomensPathway,
  );

  /// Create from app Lesson model
  factory LessonData.fromLesson(Lesson l, {int order = 0}) => LessonData(
    id: l.id, title: l.title, titleKin: l.titleKin,
    cropTag: l.cropTag, topicTag: l.topicTag, level: l.level.name,
    formats: l.formats.map((f) => f.name).toList(),
    durationMinutes: l.durationMinutes, emoji: l.emoji,
    description: l.description, descriptionKin: l.descriptionKin,
    isNew: l.isNew, isWomensPathway: l.isWomensPathway,
    isActive: true, order: order,
  );
}

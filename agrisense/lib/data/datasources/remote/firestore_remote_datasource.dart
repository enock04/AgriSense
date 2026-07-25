import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/lesson_model.dart';
import '../../../data/models/community_post_model.dart';

/// Raw Firestore read/write operations.
/// No business logic — only data access.
class FirestoreRemoteDatasource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _users   => _db.collection('users');
  CollectionReference get _posts   => _db.collection('community_posts');
  CollectionReference get _lessons => _db.collection('lessons');
  CollectionReference get _tips    => _db.collection('tips');

  DocumentReference? get _userDoc =>
      _uid != null ? _users.doc(_uid) : null;

  // ── User Profile ─────────────────────────────────────────────────────────

  Future<void> saveProfileData(Map<String, dynamic> data) async {
    if (_userDoc == null) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _userDoc!.set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadProfileData() async {
    if (_userDoc == null) return null;
    final snap = await _userDoc!.get();
    return snap.exists ? snap.data() as Map<String, dynamic> : null;
  }

  // ── Lesson Progress ──────────────────────────────────────────────────────

  Future<void> saveLessonProgress(String lessonId, double progress) async {
    if (_userDoc == null) return;
    await _userDoc!.collection('progress').doc(lessonId).set({
      'progress': progress,
      'lessonId': lessonId,
      'completed': progress >= 1.0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, double>> loadAllProgress() async {
    if (_userDoc == null) return {};
    final snaps = await _userDoc!.collection('progress').get();
    return {
      for (final doc in snaps.docs)
        doc.id: ((doc.data()['progress'] as num?)?.toDouble()) ?? 0.0,
    };
  }

  // ── Community Posts ──────────────────────────────────────────────────────

  /// Real-time stream — no orderBy to avoid missing docs without createdAt.
  Stream<List<CommunityPostModel>> postsStream() {
    return _posts.limit(50).snapshots().map((snap) =>
        snap.docs.map(CommunityPostModel.fromFirestore).toList());
  }

  Future<String?> addPost(Map<String, dynamic> data) async {
    if (_uid == null) return null;
    data['userId'] = _uid;
    data['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _posts.add(data);
    return ref.id;
  }

  Future<void> toggleUpvote(String postId) async {
    if (_uid == null) return;
    final upvoteRef = _posts.doc(postId).collection('upvotes').doc(_uid);
    final postRef = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(upvoteRef);
      if (snap.exists) {
        tx.delete(upvoteRef);
        tx.update(postRef, {'upvoteCount': FieldValue.increment(-1)});
      } else {
        tx.set(upvoteRef, {'uid': _uid, 'at': FieldValue.serverTimestamp()});
        tx.update(postRef, {'upvoteCount': FieldValue.increment(1)});
      }
    });
  }

  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  Future<void> seedPostsIfEmpty(List<Map<String, dynamic>> seeds) async {
    final snap = await _posts.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final p in seeds) {
      batch.set(_posts.doc(p['id'] as String), {
        ...p,
        'upvoteCount': p['upvotes'] ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      }..remove('id'));
    }
    await batch.commit();
  }

  // ── Lessons ──────────────────────────────────────────────────────────────

  /// No orderBy in the query itself — combining it with the isActive filter
  /// requires a composite Firestore index. Sorted client-side instead.
  Stream<List<LessonModel>> lessonsStream() {
    return _lessons
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final lessons = snap.docs.map(LessonModel.fromFirestore).toList();
      lessons.sort((a, b) => a.order.compareTo(b.order));
      return lessons;
    });
  }

  Future<String?> saveLesson(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _lessons.add(data);
      return ref.id;
    }
    await _lessons.doc(id).set(data, SetOptions(merge: true));
    return id;
  }

  Future<List<LessonModel>> getAllLessonsAdmin() async {
    final snap = await _lessons.orderBy('order').get();
    return snap.docs.map(LessonModel.fromFirestore).toList();
  }

  Future<void> deleteLesson(String id) async {
    await _lessons.doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> seedLessonsIfEmpty(List<Map<String, dynamic>> seeds) async {
    final snap = await _lessons.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (int i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      final ref = _lessons.doc(s['id'] as String);
      batch.set(ref, {...s, 'order': i, 'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  // ── Tips ─────────────────────────────────────────────────────────────────

  Future<Map<String, String>?> getTodaysTip() async {
    final snap = await _tips.where('isActive', isEqualTo: true).get();
    if (snap.docs.isEmpty) return null;
    final index = DateTime.now().day % snap.docs.length;
    final data = snap.docs[index].data() as Map<String, dynamic>;
    return {
      'title':    data['title']    as String? ?? '',
      'titleKin': data['titleKin'] as String? ?? '',
      'body':     data['body']     as String? ?? '',
      'bodyKin':  data['bodyKin']  as String? ?? '',
      'emoji':    data['emoji']    as String? ?? '💡',
    };
  }

  Future<List<Map<String, dynamic>>> getAllTipsAdmin() async {
    final snap = await _tips.get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  Future<String?> saveTip({
    required String id,
    required String title,
    required String titleKin,
    required String body,
    required String bodyKin,
    required String emoji,
  }) async {
    final data = <String, dynamic>{
      'title': title, 'titleKin': titleKin,
      'body': body, 'bodyKin': bodyKin,
      'emoji': emoji, 'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _tips.add(data);
      return ref.id;
    }
    await _tips.doc(id).set(data, SetOptions(merge: true));
    return id;
  }

  Future<void> deleteTip(String id) async {
    await _tips.doc(id).delete();
  }

  Future<void> seedTipsIfEmpty(List<Map<String, dynamic>> seeds) async {
    final snap = await _tips.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final t in seeds) {
      batch.set(_tips.doc(), {
        ...t, 'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  Future<bool> isAdmin({String storedPhone = ''}) async {
    DocumentSnapshot doc =
        await _db.collection('Config').doc('admin').get();
    if (!doc.exists) doc = await _db.collection('config').doc('admin').get();
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return false;

    final adminUids   = (data['uids']   as List?)?.cast<String>() ?? [];
    final adminPhones = (data['phones'] as List?)?.cast<String>() ?? [];

    if (_uid != null && adminUids.contains(_uid)) return true;

    final fbPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    if (fbPhone.isNotEmpty && adminPhones.contains(fbPhone)) return true;
    if (storedPhone.isNotEmpty && adminPhones.contains(storedPhone)) return true;

    return false;
  }
}

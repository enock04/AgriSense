import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_post.dart';

/// Firestore DTO for a community post document.
class CommunityPostModel {
  final String id;
  final String userId;
  final String userName;
  final String userInitials;
  final String district;
  final String question;
  final String questionKin;
  final int upvotes;
  final int replyCount;
  final Timestamp? createdAt;

  const CommunityPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userInitials,
    required this.district,
    required this.question,
    required this.questionKin,
    required this.upvotes,
    required this.replyCount,
    this.createdAt,
  });

  // ── Firestore → model ───────────────────────────────────────────────────
  factory CommunityPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPostModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Farmer',
      userInitials: data['userInitials'] as String? ?? 'F',
      district: data['district'] as String? ?? '',
      question: data['question'] as String? ?? '',
      questionKin: data['questionKin'] as String? ?? '',
      upvotes: _safeInt(data['upvoteCount']),
      replyCount: _safeInt(data['replyCount']),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
    );
  }

  // ── Safely parse int (guards against Timestamp stored in wrong field) ───
  static int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return 0;
  }

  // ── model → domain entity ───────────────────────────────────────────────
  CommunityPost toEntity({bool isUpvoted = false}) {
    final dt = createdAt?.toDate();
    return CommunityPost(
      id: id,
      userId: userId,
      userName: userName,
      userInitials: userInitials,
      district: district,
      question: question,
      questionKin: questionKin,
      upvotes: upvotes,
      replyCount: replyCount,
      timeAgo: _relativeTime(dt),
      timeAgoKin: _relativeTimeKin(dt),
      isUpvoted: isUpvoted,
      createdAt: dt,
    );
  }

  // ── Relative time helpers ──────────────────────────────────────────────
  static String _relativeTime(DateTime? dt) {
    if (dt == null) return 'recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String _relativeTimeKin(DateTime? dt) {
    if (dt == null) return 'vuba';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24)   return '${diff.inHours}saa';
    return '${diff.inDays}d';
  }
}

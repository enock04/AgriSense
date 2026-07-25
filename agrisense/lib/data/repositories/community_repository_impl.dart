import '../../domain/entities/community_post.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/remote/firestore_remote_datasource.dart';
import '../../data/mock_data.dart';

/// Concrete implementation of [CommunityRepository].
class CommunityRepositoryImpl implements CommunityRepository {
  final FirestoreRemoteDatasource _remote;
  final Set<String> _upvotedCache = {};

  CommunityRepositoryImpl(this._remote);

  @override
  Stream<List<CommunityPost>> postsStream() {
    return _remote.postsStream().map((models) {
      final posts = models.map((m) =>
          m.toEntity(isUpvoted: _upvotedCache.contains(m.id))).toList();
      // Sort client-side: newest first
      posts.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return posts;
    });
  }

  @override
  Future<void> addPost({
    required String question,
    required String questionKin,
    required String userName,
    required String district,
  }) async {
    final initials = userName.isNotEmpty
        ? userName.trim().split(' ').map((w) => w[0].toUpperCase()).take(2).join()
        : 'F';
    await _remote.addPost({
      'question': question,
      'questionKin': questionKin,
      'userName': userName,
      'userInitials': initials,
      'district': district,
      'upvoteCount': 0,
      'replyCount': 0,
    });
  }

  @override
  Future<void> toggleUpvote(String postId) async {
    if (_upvotedCache.contains(postId)) {
      _upvotedCache.remove(postId);
    } else {
      _upvotedCache.add(postId);
    }
    await _remote.toggleUpvote(postId);
  }

  @override
  Future<void> deletePost(String postId) =>
      _remote.deletePost(postId);

  @override
  Future<void> seedPostsIfEmpty() async {
    final seeds = MockData.communityPosts.map((p) => {
      'id': p.id,
      'question': p.question,
      'questionKin': p.questionKin,
      'district': p.district,
      'userName': p.userName,
      'userInitials': p.userInitials,
      'userId': 'seed',
      'upvotes': p.upvotes,
      'replyCount': p.replyCount,
    }).toList();
    await _remote.seedPostsIfEmpty(seeds);
  }
}

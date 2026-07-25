import '../entities/community_post.dart';

/// Contract for community post operations.
abstract class CommunityRepository {
  /// Real-time stream of all community posts.
  Stream<List<CommunityPost>> postsStream();

  /// Create a new post.
  Future<void> addPost({
    required String question,
    required String questionKin,
    required String userName,
    required String district,
  });

  /// Toggle upvote on [postId] for the current user.
  Future<void> toggleUpvote(String postId);

  /// Delete a post (owner or admin only).
  Future<void> deletePost(String postId);

  /// Seed sample posts if the collection is empty (first-run).
  Future<void> seedPostsIfEmpty();
}

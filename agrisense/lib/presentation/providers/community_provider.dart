import 'package:flutter/material.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/repositories/community_repository.dart';

/// Manages community posts and upvote state.
class CommunityProvider extends ChangeNotifier {
  final CommunityRepository _communityRepository;

  CommunityProvider(this._communityRepository);

  // Upvote state is tracked locally for instant UI feedback
  final Set<String> _upvoted = {};

  Stream<List<CommunityPost>> get postsStream =>
      _communityRepository.postsStream();

  bool isUpvoted(String postId) => _upvoted.contains(postId);

  /// Toggle upvote — updates local state instantly, syncs to Firestore async.
  void toggleUpvote(String postId) {
    if (_upvoted.contains(postId)) {
      _upvoted.remove(postId);
    } else {
      _upvoted.add(postId);
    }
    notifyListeners();
    // Fire-and-forget is intentional here for snappy UI
    _communityRepository.toggleUpvote(postId).catchError((_) {
      // Revert optimistic update on failure
      if (_upvoted.contains(postId)) {
        _upvoted.remove(postId);
      } else {
        _upvoted.add(postId);
      }
      notifyListeners();
    });
  }

  /// Submit a new question post.
  Future<void> addPost({
    required String question,
    required String questionKin,
    required String userName,
    required String district,
  }) async {
    await _communityRepository.addPost(
      question: question,
      questionKin: questionKin,
      userName: userName,
      district: district,
    );
  }

  Future<void> deletePost(String postId) =>
      _communityRepository.deletePost(postId);

  void reset() {
    _upvoted.clear();
    notifyListeners();
  }
}

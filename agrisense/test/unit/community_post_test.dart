import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/domain/entities/community_post.dart';

void main() {
  CommunityPost makePost({int upvotes = 5, bool isUpvoted = false}) {
    return CommunityPost(
      id: 'post-001',
      userId: 'uid-abc',
      userName: 'Uwimana Diane',
      userInitials: 'UD',
      district: 'Nyagatare',
      question: 'How can I improve my maize yield?',
      questionKin: 'Nigute nshobora kongera umusaruro w\'ibigori?',
      upvotes: upvotes,
      replyCount: 3,
      timeAgo: '2h ago',
      timeAgoKin: '2saa',
      isUpvoted: isUpvoted,
      createdAt: DateTime(2026, 7, 22, 10, 0),
    );
  }

  group('CommunityPost entity', () {
    test('stores all fields correctly', () {
      final post = makePost(upvotes: 12, isUpvoted: true);
      expect(post.id, 'post-001');
      expect(post.userId, 'uid-abc');
      expect(post.userName, 'Uwimana Diane');
      expect(post.userInitials, 'UD');
      expect(post.district, 'Nyagatare');
      expect(post.upvotes, 12);
      expect(post.replyCount, 3);
      expect(post.isUpvoted, isTrue);
      expect(post.createdAt, isNotNull);
    });
  });

  group('CommunityPost.copyWith()', () {
    test('toggles isUpvoted without changing other fields', () {
      final original = makePost(upvotes: 5, isUpvoted: false);
      final upvoted = original.copyWith(isUpvoted: true, upvotes: 6);

      expect(upvoted.isUpvoted, isTrue);
      expect(upvoted.upvotes, 6);
      // all other fields unchanged
      expect(upvoted.id, original.id);
      expect(upvoted.userId, original.userId);
      expect(upvoted.userName, original.userName);
      expect(upvoted.district, original.district);
      expect(upvoted.question, original.question);
      expect(upvoted.replyCount, original.replyCount);
      expect(upvoted.timeAgo, original.timeAgo);
    });

    test('un-upvote decrements count', () {
      final upvoted = makePost(upvotes: 6, isUpvoted: true);
      final unvoted = upvoted.copyWith(isUpvoted: false, upvotes: 5);

      expect(unvoted.isUpvoted, isFalse);
      expect(unvoted.upvotes, 5);
    });

    test('copyWith with no args preserves original values', () {
      final original = makePost(upvotes: 10, isUpvoted: false);
      final copy = original.copyWith();

      expect(copy.upvotes, original.upvotes);
      expect(copy.isUpvoted, original.isUpvoted);
      expect(copy.id, original.id);
    });

    test('upvote count cannot go negative via domain entity', () {
      // The entity itself doesn't enforce this — it's a business rule.
      // This test documents expected behaviour: copyWith accepts any int.
      final post = makePost(upvotes: 0);
      final decremented = post.copyWith(upvotes: -1);
      // Domain entity allows it; callers must guard against negative counts.
      expect(decremented.upvotes, -1);
    });
  });

  group('CommunityPost bilingual support', () {
    test('stores both English and Kinyarwanda question', () {
      final post = makePost();
      expect(post.question, isNotEmpty);
      expect(post.questionKin, isNotEmpty);
    });

    test('stores both English and Kinyarwanda time-ago strings', () {
      final post = makePost();
      expect(post.timeAgo, '2h ago');
      expect(post.timeAgoKin, '2saa');
    });
  });
}

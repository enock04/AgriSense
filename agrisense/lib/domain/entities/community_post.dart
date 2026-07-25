/// Domain entity for a community question/post.
class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userInitials;
  final String district;
  final String question;
  final String questionKin;
  final int upvotes;
  final int replyCount;
  final String timeAgo;
  final String timeAgoKin;
  final bool isUpvoted;
  final DateTime? createdAt;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userInitials,
    required this.district,
    required this.question,
    required this.questionKin,
    required this.upvotes,
    required this.replyCount,
    required this.timeAgo,
    required this.timeAgoKin,
    this.isUpvoted = false,
    this.createdAt,
  });

  CommunityPost copyWith({int? upvotes, bool? isUpvoted}) => CommunityPost(
    id: id, userId: userId, userName: userName, userInitials: userInitials,
    district: district, question: question, questionKin: questionKin,
    upvotes: upvotes ?? this.upvotes, replyCount: replyCount,
    timeAgo: timeAgo, timeAgoKin: timeAgoKin,
    isUpvoted: isUpvoted ?? this.isUpvoted, createdAt: createdAt,
  );
}

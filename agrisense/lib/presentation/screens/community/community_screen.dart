import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../../domain/entities/community_post.dart';
import '../../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../../l10n/app_strings.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = context.trW;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(s.commTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context, isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => const _SearchSheet(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _AskQuestionSheet(provider: provider),
        ),
        backgroundColor: AppColors.green700,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(s.commAsk,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        const _CommunityStats(),
        const Divider(height: 1, color: AppColors.gray100),
        Expanded(
          child: StreamBuilder<List<CommunityPost>>(
            stream: provider.communityPostsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.green700),
                );
              }
              if (snapshot.hasError) {
                final err = snapshot.error.toString();
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.gray300),
                    const SizedBox(height: 12),
                    const Text('Could not load posts',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(err,
                          style: const TextStyle(fontSize: 10, color: AppColors.red600),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Retry', style: TextStyle(color: AppColors.green700)),
                    ),
                  ]),
                );
              }

              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return Center(
                  child: Text(s.commNoPostsYet,
                      style: const TextStyle(color: AppColors.gray500)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _PostCard(post: posts[i]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Stats bar ──────────────────────────────────────────────────────────────

class _CommunityStats extends StatelessWidget {
  const _CommunityStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _StatItem(value: '1,248', label: 'Farmers\nAbahinzi'),
        _StatItem(value: '342',   label: 'Questions\nIbibazo'),
        _StatItem(value: '12',    label: 'Districts\nAkarere'),
      ]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.green700)),
    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
  ]);
}

// ── Post card ──────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final CommunityPost post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _isUpvoted;
  late int _upvoteCount;

  @override
  void initState() {
    super.initState();
    _isUpvoted = widget.post.isUpvoted;
    _upvoteCount = widget.post.upvotes;
  }

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync with the latest stream snapshot (e.g. after our own toggle
    // round-trips to Firestore, or another user's upvote comes in live).
    if (oldWidget.post.upvotes != widget.post.upvotes ||
        oldWidget.post.isUpvoted != widget.post.isUpvoted) {
      _isUpvoted = widget.post.isUpvoted;
      _upvoteCount = widget.post.upvotes;
    }
  }

  void _toggleUpvote() {
    final provider = context.read<AppProvider>();
    setState(() {
      _isUpvoted = !_isUpvoted;
      _upvoteCount += _isUpvoted ? 1 : -1;
    });
    provider.toggleUpvote(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Author row
        Row(children: [
          CircleAvatar(
            radius: 18, backgroundColor: AppColors.green100,
            child: Text(post.userInitials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),
            Text('${post.district} · ${post.timeAgo}', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(6)),
            child: Text(context.trW.commQuestion, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.green700)),
          ),
        ]),
        const SizedBox(height: 12),

        // Question
        Text(context.trW.langText(post.question, post.questionKin), style: const TextStyle(fontSize: 14, color: AppColors.gray900, height: 1.5)),
        const SizedBox(height: 12),

        // Actions
        Row(children: [
          GestureDetector(
            onTap: _toggleUpvote,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isUpvoted ? AppColors.green50 : AppColors.gray100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _isUpvoted ? AppColors.green700 : AppColors.gray200),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_isUpvoted ? Icons.arrow_upward_rounded : Icons.arrow_upward_outlined,
                    size: 14, color: _isUpvoted ? AppColors.green700 : AppColors.gray500),
                const SizedBox(width: 4),
                Text('$_upvoteCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _isUpvoted ? AppColors.green700 : AppColors.gray500)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.gray500),
              const SizedBox(width: 4),
              Text('${post.replyCount} ${context.trW.commReplies}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
            ]),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon!'))),
            child: const Icon(Icons.share_outlined, size: 18, color: AppColors.gray400),
          ),
        ]),
      ]),
    );
  }
}

// ── Ask question sheet ─────────────────────────────────────────────────────

class _AskQuestionSheet extends StatefulWidget {
  final AppProvider provider;
  const _AskQuestionSheet({required this.provider});

  @override
  State<_AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends State<_AskQuestionSheet> {
  final _questionCtrl = TextEditingController();
  final _questionKinCtrl = TextEditingController();
  String _selectedCrop = 'General';
  bool _isPosting = false;
  String _questionError = '';

  final List<String> _crops = ['General', 'Maize · Ibigori', 'Beans · Ibishyimbo',
      'Potato · Ibirayi', 'Tomato · Inyanya', 'Sorghum · Amashaza'];

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final provider = widget.provider;
    final name = provider.farmerName.isNotEmpty ? provider.farmerName : 'Farmer';
    final initials = name.isEmpty
        ? '?'
        : name.length >= 2
            ? '${name[0]}${name.split(' ').length > 1 ? name.split(' ').last[0] : name[1]}'.toUpperCase()
            : name[0].toUpperCase();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + kb),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.green100,
            child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green700))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(provider.district, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ]),
        ]),
        const SizedBox(height: 16),

        // Crop selector
        SizedBox(height: 36, child: ListView.separated(
          scrollDirection: Axis.horizontal, itemCount: _crops.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final isSel = _selectedCrop == _crops[i];
            return GestureDetector(
              onTap: () => setState(() => _selectedCrop = _crops[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.green50 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? AppColors.green700 : AppColors.gray200),
                ),
                child: Text(_crops[i].split(' ')[0], style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isSel ? AppColors.green700 : AppColors.gray500)),
              ),
            );
          },
        )),
        const SizedBox(height: 12),

        // Question in English
        TextField(
          controller: _questionCtrl,
          maxLines: 3,
          onChanged: (_) { if (_questionError.isNotEmpty) setState(() => _questionError = ''); },
          decoration: const InputDecoration(
            hintText: 'Your farming question in English...',
            labelText: 'Question (English)',
          ),
        ),
        if (_questionError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, size: 13, color: AppColors.red600),
              const SizedBox(width: 4),
              Text(_questionError, style: const TextStyle(fontSize: 11, color: AppColors.red600)),
            ]),
          ),
        const SizedBox(height: 10),

        // Question in Kinyarwanda (optional)
        TextField(
          controller: _questionKinCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Ikibazo mu Kinyarwanda (ntabwigenge)...',
            labelText: 'Ikibazo (Kinyarwanda) · Optional',
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: _isPosting ? null : () async {
            final questionText = _questionCtrl.text.trim();
            if (questionText.isEmpty) {
              setState(() => _questionError = 'Please write your question first');
              return;
            }
            if (questionText.length < 10) {
              setState(() => _questionError = 'Question too short — add more detail');
              return;
            }
            setState(() => _questionError = '');
            // Capture context-dependent refs BEFORE any await
            final nav = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            setState(() => _isPosting = true);

            await provider.addPost(
              question: _questionCtrl.text.trim(),
              questionKin: _questionKinCtrl.text.trim(),
              district: provider.district.isNotEmpty ? provider.district : 'Rwanda',
              userName: name,
            );

            if (!mounted) return;
            nav.pop();
            messenger.showSnackBar(const SnackBar(
              content: Text('Question posted! · Ikibazo cyatangiwe!'),
              backgroundColor: AppColors.green700,
            ));
          },
          child: _isPosting
              ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Posting...', style: TextStyle(color: Colors.white)),
                ])
              : const Text('Post Question · Ohereza Ikibazo'),
        ),
      ]),
    );
  }
}

// ── Search sheet ───────────────────────────────────────────────────────────

class _SearchSheet extends StatefulWidget {
  const _SearchSheet();
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final posts = MockData.communityPosts.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.question.toLowerCase().contains(q) ||
          p.userName.toLowerCase().contains(q) ||
          p.district.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search community questions...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray400),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _query = ''))
                  : null,
            ),
          ),
        ),
        if (posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No posts found · Nta bibazo bibonetse', style: TextStyle(color: AppColors.gray500)),
          )
        else
          SizedBox(
            height: 300,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = posts[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: CircleAvatar(radius: 16, backgroundColor: AppColors.green100,
                    child: Text(p.userInitials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green700))),
                  title: Text(p.question, style: const TextStyle(fontSize: 13, color: AppColors.gray900), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${p.userName} · ${p.district}', style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
                  onTap: () => Navigator.pop(context),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ]),
    );
  }
}


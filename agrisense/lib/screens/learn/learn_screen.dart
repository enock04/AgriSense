import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_strings.dart';
import 'lesson_detail_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _filter = 'All';
  bool _searchOpen = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final List<Map<String, String>> _filters = [
    {'id': 'All',      'label': 'All',          'emoji': ''},
    {'id': 'Women',    'label': "Women's",       'emoji': '👩‍🌾'},
    {'id': 'Planting', 'label': 'Planting',      'emoji': '🌱'},
    {'id': 'Soil',     'label': 'Soil Health',   'emoji': '🌿'},
    {'id': 'Climate',  'label': 'Climate',       'emoji': '🌦'},
    {'id': 'Pests',    'label': 'Bugs',          'emoji': '🐛'},
    {'id': 'Finance',  'label': 'Finance',       'emoji': '💰'},
    {'id': 'Garden',   'label': 'Garden',        'emoji': '🥕'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = context.trW;

    final completedCount = provider.lessons.where((l) => provider.getLessonProgress(l.id) >= 1.0).length;
    final inProgressCount = provider.lessons.where((l) {
      final p = provider.getLessonProgress(l.id);
      return p > 0 && p < 1.0;
    }).length;
    final newCount = provider.lessons.where((l) => l.isNew).length;

    List<Lesson> filtered;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = provider.lessons.where((l) =>
          l.title.toLowerCase().contains(q) ||
          l.titleKin.toLowerCase().contains(q) ||
          l.cropTag.toLowerCase().contains(q) ||
          l.topicTag.toLowerCase().contains(q)).toList();
    } else if (_filter == 'Women') {
      filtered = provider.lessons.where((l) => l.isWomensPathway).toList();
    } else if (_filter == 'All') {
      filtered = provider.lessons;
    } else {
      filtered = provider.lessons.where((l) => l.topicTag == _filter).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: _searchOpen
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search lessons...',
                  hintStyle: const TextStyle(color: AppColors.gray400),
                  border: InputBorder.none,
                  filled: false,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      setState(() { _searchOpen = false; _searchQuery = ''; _searchCtrl.clear(); });
                    },
                  ),
                ),
              )
            : Text(s.learnTitle),
        actions: [
          if (!_searchOpen)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => setState(() => _searchOpen = true),
            ),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Stats bar ──────────────────────────────────────────────────
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            _StatBadge(icon: '✅', count: completedCount, label: s.learnCompleted, color: AppColors.green700),
            const SizedBox(width: 8),
            _StatBadge(icon: '⏳', count: inProgressCount, label: s.learnInProgress, color: AppColors.amber600),
            const SizedBox(width: 8),
            _StatBadge(icon: '✨', count: newCount, label: s.learnNew, color: AppColors.blue500),
          ]),
        ),

        // ── Women's Pathway Banner ─────────────────────────────────────
        _WomensPathwayBanner(onExplore: () => setState(() { _filter = 'Women'; _searchQuery = ''; })),

        // ── Filter chips ───────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final isSel = f['id'] == _filter;
              final emoji = f['emoji']!;
              return GestureDetector(
                onTap: () => setState(() => _filter = f['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.green700 : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSel ? AppColors.green700 : AppColors.gray200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (emoji.isNotEmpty) ...[
                      Text(emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                    ],
                    Text(f['label']!,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : AppColors.gray700)),
                  ]),
                ),
              );
            },
          ),
        ),

        // ── Lesson list ────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No lessons here yet.', style: TextStyle(color: AppColors.gray500)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final l = filtered[i];
                    final progress = provider.getLessonProgress(l.id);
                    return _LessonTile(
                      lesson: l, progress: progress,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: l))),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ── Stat Badge ─────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String icon;
  final int count;
  final String label;
  final Color color;
  const _StatBadge({required this.icon, required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
    );
  }
}

// ── Women's Pathway Banner ─────────────────────────────────────────────────

class _WomensPathwayBanner extends StatelessWidget {
  final VoidCallback onExplore;
  const _WomensPathwayBanner({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final womensLessons = context.watch<AppProvider>().lessons.where((l) => l.isWomensPathway).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6A1B7D), Color(0xFF9C27B0)],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Text('👩‍🌾', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Women's Pathway", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          Text("Inzira y'Abagore · $womensLessons lessons available",
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ])),
        GestureDetector(
          onTap: onExplore,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Text('Explore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6A1B7D))),
          ),
        ),
      ]),
    );
  }
}

// ── Lesson Tile ────────────────────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final double progress;
  final VoidCallback onTap;
  const _LessonTile({required this.lesson, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
            child: Center(child: Text(l.emoji, style: const TextStyle(fontSize: 32))),
          ),

          // Content
          Expanded(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Tags
              Row(children: [
                _Tag(l.topicTag),
                const SizedBox(width: 6),
                _Tag('${l.durationMinutes} min'),
                const Spacer(),
                if (l.isNew) _Badge('NEW', AppColors.green700),
                if (l.isWomensPathway) _Badge('♀', const Color(0xFF6A1B7D)),
              ]),
              const SizedBox(height: 6),
              Text(context.trW.langText(l.title, l.titleKin), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),

              if (progress > 0) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.gray100,
                        color: progress >= 1 ? AppColors.green700 : AppColors.green500, minHeight: 4))),
                  const SizedBox(width: 8),
                  Text(progress >= 1 ? context.trW.learnCompleted : '${(progress * 100).round()}%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: progress >= 1 ? AppColors.green700 : AppColors.gray500)),
                ]),
              ],
            ]),
          )),
          const Padding(
            padding: EdgeInsets.only(right: 8, top: 24),
            child: Icon(Icons.chevron_right_rounded, color: AppColors.gray300),
          ),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.gray600)),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
  );
}

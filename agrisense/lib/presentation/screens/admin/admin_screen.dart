import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/community_post.dart';
import '../../theme/app_colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Row(children: [
          Text('⚙️', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('Content Manager'),
        ]),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.green700,
          unselectedLabelColor: AppColors.gray400,
          indicatorColor: AppColors.green700,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Lessons'),
            Tab(icon: Icon(Icons.lightbulb_outlined, size: 18), text: 'Tips'),
            Tab(icon: Icon(Icons.people_outline_rounded, size: 18), text: 'Community'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _LessonsTab(),
          _TipsTab(),
          _CommunityTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LESSONS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _LessonsTab extends StatefulWidget {
  const _LessonsTab();

  @override
  State<_LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<_LessonsTab> {
  List<Lesson> _lessons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _lessons = await context.read<AppProvider>().getAllLessonsAdmin();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green700));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLessonForm(context, null),
        backgroundColor: AppColors.green700,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Lesson', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _lessons.isEmpty
          ? const Center(child: Text('No lessons yet. Tap + to add one.', style: TextStyle(color: AppColors.gray500)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _lessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final l = _lessons[i];
                return _LessonAdminCard(
                  lesson: l,
                  onEdit: () => _openLessonForm(context, l),
                  onDelete: () => _deleteLesson(l),
                  onToggleActive: () => _toggleActive(l),
                );
              },
            ),
    );
  }

  void _openLessonForm(BuildContext context, Lesson? lesson) async {
    final result = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => LessonFormScreen(lesson: lesson)));
    if (result == true) _load();
  }

  Future<void> _deleteLesson(Lesson l) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Lesson?'),
      content: Text('Remove "${l.title}" from the app?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red600))),
      ],
    ));
    if (confirm == true && mounted) {
      await context.read<AppProvider>().deleteLesson(l.id);
      _load();
    }
  }

  Future<void> _toggleActive(Lesson l) async {
    await context.read<AppProvider>().saveLesson(Lesson(
      id: l.id, title: l.title, titleKin: l.titleKin,
      cropTag: l.cropTag, topicTag: l.topicTag, level: l.level,
      formats: l.formats, durationMinutes: l.durationMinutes,
      progress: l.progress, emoji: l.emoji,
      description: l.description, descriptionKin: l.descriptionKin,
      isNew: l.isNew, isWomensPathway: l.isWomensPathway,
      isActive: !l.isActive, order: l.order,
    ));
    _load();
  }
}

class _LessonAdminCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onEdit, onDelete, onToggleActive;
  const _LessonAdminCard({required this.lesson, required this.onEdit, required this.onDelete, required this.onToggleActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lesson.isActive ? AppColors.white : AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lesson.isActive ? AppColors.gray200 : AppColors.gray300),
      ),
      child: Row(children: [
        Text(lesson.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(lesson.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900))),
            if (!lesson.isActive)
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(4)),
                child: const Text('HIDDEN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.red600))),
          ]),
          Text('${lesson.topicTag} · ${lesson.durationMinutes} min · ${lesson.level.name}',
              style: const TextStyle(fontSize: 10, color: AppColors.gray500)),
        ])),
        // Actions
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'toggle') onToggleActive();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
            PopupMenuItem(value: 'toggle', child: Row(children: [
              Icon(lesson.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16),
              const SizedBox(width: 8),
              Text(lesson.isActive ? 'Hide' : 'Show'),
            ])),
            const PopupMenuItem(value: 'delete', child: Row(children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red600),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: AppColors.red600)),
            ])),
          ],
          child: const Icon(Icons.more_vert_rounded, color: AppColors.gray400),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LESSON FORM SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class LessonFormScreen extends StatefulWidget {
  final Lesson? lesson;
  const LessonFormScreen({super.key, this.lesson});

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title, _titleKin, _desc, _descKin, _cropTag, _topicTag, _emoji, _duration;
  String _level = 'beginner';
  bool _isNew = false, _isWomens = false;
  final List<String> _formats = ['text'];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _title    = TextEditingController(text: l?.title ?? '');
    _titleKin = TextEditingController(text: l?.titleKin ?? '');
    _desc     = TextEditingController(text: l?.description ?? '');
    _descKin  = TextEditingController(text: l?.descriptionKin ?? '');
    _cropTag  = TextEditingController(text: l?.cropTag ?? '');
    _topicTag = TextEditingController(text: l?.topicTag ?? '');
    _emoji    = TextEditingController(text: l?.emoji ?? '🌱');
    _duration = TextEditingController(text: (l?.durationMinutes ?? 10).toString());
    if (l != null) {
      _level = l.level.name;
      _isNew = l.isNew;
      _isWomens = l.isWomensPathway;
      _formats.clear();
      _formats.addAll(l.formats.map((f) => f.name));
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _titleKin, _desc, _descKin, _cropTag, _topicTag, _emoji, _duration]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final l = widget.lesson;
    final formats = (_formats.isEmpty ? ['text'] : _formats)
        .map((f) => LessonFormat.values.firstWhere((e) => e.name == f, orElse: () => LessonFormat.text))
        .toList();
    final data = Lesson(
      id: l?.id ?? '',
      title: _title.text.trim(), titleKin: _titleKin.text.trim(),
      description: _desc.text.trim(), descriptionKin: _descKin.text.trim(),
      cropTag: _cropTag.text.trim(), topicTag: _topicTag.text.trim(),
      emoji: _emoji.text.trim().isNotEmpty ? _emoji.text.trim() : '🌱',
      durationMinutes: int.tryParse(_duration.text) ?? 10,
      level: LessonLevel.values.firstWhere((e) => e.name == _level, orElse: () => LessonLevel.beginner),
      formats: formats, progress: l?.progress ?? 0.0,
      isNew: _isNew, isWomensPathway: _isWomens,
      isActive: true, order: l?.order ?? 999,
    );

    final id = await context.read<AppProvider>().saveLesson(data);
    if (mounted) {
      setState(() => _saving = false);
      if (id != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l == null ? 'Lesson added!' : 'Lesson updated!'),
            backgroundColor: AppColors.green700));
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson == null ? 'Add Lesson' : 'Edit Lesson'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green700))
                : const Text('Save', style: TextStyle(color: AppColors.green700, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      backgroundColor: AppColors.surface,
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Emoji + Duration row
          Row(children: [
            SizedBox(width: 80, child: TextFormField(controller: _emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              decoration: _deco('Emoji', null))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _duration,
              keyboardType: TextInputType.number,
              decoration: _deco('Duration (min)', Icons.access_time_rounded))),
          ]),
          const SizedBox(height: 12),

          TextFormField(controller: _title, decoration: _deco('Title (English) *', null),
            validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _titleKin, decoration: _deco('Title (Kinyarwanda)', null)),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: TextFormField(controller: _cropTag, decoration: _deco('Crop Tag *', Icons.eco_rounded),
              validator: (v) => v!.isEmpty ? 'Required' : null)),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _topicTag, decoration: _deco('Topic Tag *', null),
              validator: (v) => v!.isEmpty ? 'Required' : null)),
          ]),
          const SizedBox(height: 12),

          // Level selector
          _sectionHeader('Level'),
          Wrap(spacing: 8, children: ['beginner', 'intermediate', 'advanced', 'all'].map((lv) =>
            ChoiceChip(
              label: Text(lv), selected: _level == lv,
              onSelected: (_) => setState(() => _level = lv),
              selectedColor: AppColors.green100,
              labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _level == lv ? AppColors.green700 : AppColors.gray600),
            )).toList()),
          const SizedBox(height: 12),

          // Formats
          _sectionHeader('Formats'),
          Wrap(spacing: 8, children: ['audio', 'video', 'text'].map((f) =>
            FilterChip(
              label: Text(f), selected: _formats.contains(f),
              onSelected: (v) => setState(() => v ? _formats.add(f) : _formats.remove(f)),
              selectedColor: AppColors.green100,
              labelStyle: TextStyle(fontSize: 12, color: _formats.contains(f) ? AppColors.green700 : AppColors.gray600),
            )).toList()),
          const SizedBox(height: 12),

          // Flags
          _sectionHeader('Flags'),
          Row(children: [
            Expanded(child: CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero,
              title: const Text('Mark as NEW', style: TextStyle(fontSize: 13)),
              value: _isNew, onChanged: (v) => setState(() => _isNew = v!),
              activeColor: AppColors.green700)),
            Expanded(child: CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero,
              title: const Text("Women's Pathway", style: TextStyle(fontSize: 13)),
              value: _isWomens, onChanged: (v) => setState(() => _isWomens = v!),
              activeColor: const Color(0xFF6A1B7D))),
          ]),
          const SizedBox(height: 12),

          _sectionHeader('Description (English) *'),
          TextFormField(controller: _desc, maxLines: 4, decoration: _deco('Full lesson description...', null),
            validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),

          _sectionHeader('Description (Kinyarwanda)'),
          TextFormField(controller: _descKin, maxLines: 4, decoration: _deco('Ibisobanuro by\'isomo...', null)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  InputDecoration _deco(String label, IconData? icon) => InputDecoration(
    labelText: label,
    prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.gray400) : null,
    filled: true, fillColor: AppColors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green700, width: 2)),
    labelStyle: const TextStyle(fontSize: 13, color: AppColors.gray500),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

Widget _sectionHeader(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray700)),
);

// ══════════════════════════════════════════════════════════════════════════════
// TIPS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _TipsTab extends StatefulWidget {
  const _TipsTab();

  @override
  State<_TipsTab> createState() => _TipsTabState();
}

class _TipsTabState extends State<_TipsTab> {
  List<Map<String, dynamic>> _tips = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _tips = await context.read<AppProvider>().getAllTipsAdmin();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.green700));

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTipForm(null),
        backgroundColor: AppColors.amber600,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Tip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _tips.isEmpty
          ? const Center(child: Text('No tips yet. Tap + to add one.', style: TextStyle(color: AppColors.gray500)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _tips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final t = _tips[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.amber400.withValues(alpha: 0.3))),
                  child: Row(children: [
                    Text(t['emoji'] ?? '💡', style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(t['body'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.gray600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ])),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray500),
                          onPressed: () => _openTipForm(t)),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red600),
                          onPressed: () => _deleteTip(t['id'])),
                    ]),
                  ]),
                );
              },
            ),
    );
  }

  void _openTipForm(Map<String, dynamic>? tip) async {
    await showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TipFormSheet(tip: tip, onSaved: _load));
  }

  Future<void> _deleteTip(String id) async {
    await context.read<AppProvider>().deleteTip(id);
    _load();
  }
}

// ignore: must_be_immutable — using mutable state via StatefulWidget below
class _TipFormSheet extends StatefulWidget {
  final Map<String, dynamic>? tip;
  final VoidCallback onSaved;
  const _TipFormSheet({this.tip, required this.onSaved});

  @override
  State<_TipFormSheet> createState() => _TipFormSheetState();
}

class _TipFormSheetState extends State<_TipFormSheet> {
  late TextEditingController _title, _titleKin, _body, _bodyKin, _emoji;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tip;
    _title    = TextEditingController(text: t?['title'] ?? '');
    _titleKin = TextEditingController(text: t?['titleKin'] ?? '');
    _body     = TextEditingController(text: t?['body'] ?? '');
    _bodyKin  = TextEditingController(text: t?['bodyKin'] ?? '');
    _emoji    = TextEditingController(text: t?['emoji'] ?? '💡');
  }

  @override
  void dispose() {
    for (final c in [_title, _titleKin, _body, _bodyKin, _emoji]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.isEmpty || _body.text.isEmpty) return;
    setState(() => _saving = true);
    await context.read<AppProvider>().saveTip(
      id: widget.tip?['id'] ?? '',
      title: _title.text.trim(), titleKin: _titleKin.text.trim(),
      body: _body.text.trim(), bodyKin: _bodyKin.text.trim(),
      emoji: _emoji.text.trim().isNotEmpty ? _emoji.text.trim() : '💡',
    );
    if (mounted) {
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Daily Tip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          TextButton(onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: AppColors.green700, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          SizedBox(width: 70, child: TextField(controller: _emoji, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
            decoration: const InputDecoration(labelText: 'Icon', contentPadding: EdgeInsets.all(8)))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title (EN) *'))),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _titleKin, decoration: const InputDecoration(labelText: 'Title (Kinyarwanda)')),
        const SizedBox(height: 8),
        TextField(controller: _body, maxLines: 2, decoration: const InputDecoration(labelText: 'Body (EN) *')),
        const SizedBox(height: 8),
        TextField(controller: _bodyKin, maxLines: 2, decoration: const InputDecoration(labelText: 'Body (Kinyarwanda)')),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMMUNITY TAB
// ══════════════════════════════════════════════════════════════════════════════

class _CommunityTab extends StatelessWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityPost>>(
      stream: context.watch<AppProvider>().communityPostsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.green700));
        }
        final posts = snapshot.data!;
        if (posts.isEmpty) {
          return const Center(child: Text('No community posts yet.', style: TextStyle(color: AppColors.gray500)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final p = posts[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 14, backgroundColor: AppColors.green100,
                    child: Text(p.userInitials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green700))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  Text(p.timeAgo, style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
                  const SizedBox(width: 8),
                  // Delete button
                  GestureDetector(
                    onTap: () => _deletePost(context, p.id),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Delete', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.red600))),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(p.question, style: const TextStyle(fontSize: 12, color: AppColors.gray900)),
                const SizedBox(height: 4),
                Text('${p.upvotes} upvotes · ${p.replyCount} replies · ${p.district}',
                    style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
              ]),
            );
          },
        );
      },
    );
  }

  void _deletePost(BuildContext context, String postId) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Post?'),
      content: const Text('This will permanently remove this community post.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red600))),
      ],
    ));
    if (confirm == true && context.mounted) {
      await context.read<AppProvider>().deletePost(postId);
    }
  }
}

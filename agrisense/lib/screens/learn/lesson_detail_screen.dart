import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_strings.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _isPlaying = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _progress = Provider.of<AppProvider>(context, listen: false)
        .getLessonProgress(widget.lesson.id);
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isPlaying) {
          final np = (_progress + 0.2).clamp(0.0, 1.0);
          setState(() => _progress = np);
          context.read<AppProvider>().updateLessonProgress(widget.lesson.id, np);
        }
      });
    }
  }

  Color _levelColor(LessonLevel l) {
    switch (l) {
      case LessonLevel.beginner:    return AppColors.green700;
      case LessonLevel.intermediate:return AppColors.amber600;
      case LessonLevel.advanced:    return AppColors.red600;
      case LessonLevel.all:         return AppColors.blue500;
    }
  }

  String _levelLabel(LessonLevel l, AppStrings s) {
    switch (l) {
      case LessonLevel.beginner:    return s.lessonKeyword;
      case LessonLevel.intermediate:return s.lessonIntermed;
      case LessonLevel.advanced:    return s.lessonAdvanced;
      case LessonLevel.all:         return s.lessonAllLevels;
    }
  }

  List<String> _takeaways(String id) {
    switch (id) {
      case 'l1': return [
        'Plant maize in rows 75 cm apart for optimal air circulation and reduced disease risk',
        'Sow certified seeds 5 cm deep — uncertified seed reduces yield by up to 30%',
        'Season A: plant Oct–Nov; Season B: plant Feb–Mar for best results in Northern Rwanda',
        'Apply basal fertilizer (DAP) at planting and top-dress with urea after 4 weeks',
      ];
      case 'l2': return [
        'Layer green (nitrogen-rich) and brown (carbon-rich) materials in a 3:1 ratio',
        'Turn the compost heap every 2 weeks to introduce oxygen and speed decomposition',
        'Finished compost is dark, crumbly, and has an earthy smell — ready in 6–8 weeks',
        'Apply 2–4 tonnes of compost per hectare, two weeks before planting',
      ];
      case 'l3': return [
        'Look for ragged holes in leaves and a sawdust-like frass in the whorl',
        'Check young plants at dawn — armyworm moths lay eggs on leaf surfaces at night',
        'Apply Bt (Bacillus thuringiensis) spray early when larvae are small — more effective and cheaper',
        'Set pheromone traps (1 per hectare) for early warning and mass trapping',
      ];
      case 'l4': return [
        'Dig drainage channels along the contour before the rainy season begins',
        'Mulch with dry grass or straw to reduce soil erosion by up to 70%',
        'Build raised beds (20–30 cm high) in flood-prone valley areas',
        'Use cover crops like mucuna between seasons to protect bare soil',
      ];
      case 'l5': return [
        'Record every income and expense in a dedicated farm notebook — review weekly',
        'Target saving at least 10% of each harvest sale into a VSLA group',
        'Open a Mobile Money account (MoMo) to separate personal and farm funds',
        'Apply for Agri-insurance through RHC (Rwanda Hollard Insurance) to protect against crop loss',
      ];
      case 'l6': return [
        'Start with a 3×3 m plot near your kitchen — position for 6+ hours of daily sunlight',
        'Grow: amaranth, spinach, tomatoes, onions, and carrots for nutrition and market value',
        'Water every morning before 8 AM to reduce evaporation — drip irrigation saves 60% water',
        'Rwanda planting calendar: short rains (Oct–Jan) and long rains (Mar–Jun)',
      ];
      case 'l7': return [
        'Drought-tolerant maize varieties (e.g. DRMT, WEMA) yield 30–40% more in dry conditions',
        'Zai pits (small planting holes) concentrate rainfall and organic matter at root zones',
        'Rainwater harvesting: dig small storage ponds (50–100 m³) during rainy season',
        'Conserve moisture: mulch immediately after planting to reduce soil water loss',
      ];
      case 'l8': return [
        'Plant groundnuts in rows 45 cm apart with 10 cm between seeds',
        'Inoculate seeds with Rhizobium before planting to fix nitrogen — saves on fertilizer',
        'Intercrop with maize in 2:1 ratio (2 rows groundnut, 1 row maize) for higher land use efficiency',
        'Harvest when 80% of pods have brown inner shells — dry pods to 8% moisture before storage',
      ];
      case 'l9': return [
        'Sorghum tolerates poor soils and drought better than any other cereal crop in Rwanda',
        'Improved varieties (SIMA-2, Rwampara) yield 3–4 tonnes/ha vs 1.5 for traditional varieties',
        'Leave 60 cm between rows and 20 cm between plants for best grain head development',
        'Local brewery market (urwagwa) pays premium prices — explore cooperative processing',
      ];
      case 'l10': return [
        'One dairy cow produces 5–10 tonnes of manure annually — enough to fertilize 1 hectare',
        'Chickens + vegetable garden: chicken manure is the highest-nitrogen animal fertilizer',
        'Rotate livestock grazing areas to prevent soil compaction and pasture degradation',
        'MINAGRI\'s Girinka program offers subsidized cattle — check eligibility at your sector office',
      ];
      default: return [
        'Apply best practices adapted to your local soil and climate conditions',
        'Connect with your local extension officer (RAB district office) for free technical advice',
        'Join a farmer cooperative to access better input prices and market linkages',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final s = context.trW;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Learn · Iga'),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(20)),
              child: Text(l.cropTag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green700)),
            )),
        ],
      ),
      body: ListView(padding: EdgeInsets.zero, children: [
        // Hero image area
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1A5C35), AppColors.green500],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            // Background pattern
            Positioned.fill(child: Opacity(opacity: 0.15,
              child: Center(child: Text(l.emoji, style: const TextStyle(fontSize: 120))))),
            // Content
            Padding(padding: const EdgeInsets.all(20), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(children: [
                  _LevelBadge(level: l.level, color: _levelColor(l.level), label: _levelLabel(l.level, s)),
                  const SizedBox(width: 6),
                  if (l.isNew) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                ]),
                const SizedBox(height: 8),
                Text(s.langText(l.title, l.titleKin), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            )),
          ]),
        ),

        // Rest of content
        Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _LevelBadge(level: l.level, color: _levelColor(l.level), label: _levelLabel(l.level, s)),
              const SizedBox(width: 6),
              _SmallTag(l.cropTag),
            ]),
            const SizedBox(height: 8),
            Text(s.langText(l.title, l.titleKin), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.gray900)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Meta row
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.gray400),
          const SizedBox(width: 4),
          Text('${l.durationMinutes} minutes', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
          const SizedBox(width: 16),
          ...l.formats.map((f) => Padding(padding: const EdgeInsets.only(right: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(f == LessonFormat.audio ? Icons.headphones_rounded : f == LessonFormat.video ? Icons.play_circle_outline_rounded : Icons.article_outlined,
                size: 12, color: AppColors.gray500),
            const SizedBox(width: 3),
            Text(f == LessonFormat.audio ? s.lessonAudioFmt : f == LessonFormat.video ? s.lessonVideoFmt : s.lessonTextFmt,
                style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ]))),
        ]),
        const SizedBox(height: 20),

        // Progress bar
        if (_progress > 0) ...[
          Text(
            _progress >= 1.0 ? '✓ Lesson completed' : 'Progress · ${(_progress * 100).round()}%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: _progress >= 1.0 ? AppColors.green700 : AppColors.gray700),
          ),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: _progress, backgroundColor: AppColors.gray100, color: AppColors.green700, minHeight: 8)),
          const SizedBox(height: 16),
        ],

        // Audio player
        if (l.formats.contains(LessonFormat.audio)) ...[
          _AudioPlayer(isPlaying: _isPlaying, progress: _progress, onToggle: _togglePlay),
          const SizedBox(height: 20),
        ],

        // Description
        Text(s.lessonAbout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const SizedBox(height: 8),
        Text(s.langText(l.description, l.descriptionKin), style: const TextStyle(fontSize: 14, color: AppColors.gray700, height: 1.6)),
        const SizedBox(height: 24),

        // Takeaways
        Text(s.lessonTakeaways, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const SizedBox(height: 12),
        ..._takeaways(l.id).map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6, right: 10),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green700)),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.5))),
          ]),
        )),
        const SizedBox(height: 32),

        // CTA
        if (_progress < 1.0)
          ElevatedButton.icon(
            onPressed: _togglePlay,
            icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            label: Text(_progress == 0.0 ? s.learnStartBtn : _isPlaying ? 'Pause' : s.learnContinueBtn),
          )
        else
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(s.lessonCompleted),
          ),
        const SizedBox(height: 16),
        ])), // end Padding
      ]),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final LessonLevel level;
  final Color color;
  final String label;
  const _LevelBadge({required this.level, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String text;
  const _SmallTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.gray700)),
    );
  }
}

class _AudioPlayer extends StatelessWidget {
  final bool isPlaying;
  final double progress;
  final VoidCallback onToggle;
  const _AudioPlayer({required this.isPlaying, required this.progress, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final elapsed = (progress * 480).round();
    final timeStr = '${elapsed ~/ 60}:${(elapsed % 60).toString().padLeft(2, '0')}';
    final s = context.trW;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: [
          GestureDetector(onTap: onToggle, child: Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(color: AppColors.green700, shape: BoxShape.circle),
            child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
          )),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.lessonAudioTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),
            Text(isPlaying ? s.lessonPlaying : s.lessonTapListen, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
          ])),
          Text(timeStr, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
        ]),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: AppColors.green700,
            inactiveTrackColor: AppColors.gray200,
            thumbColor: AppColors.green700,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(value: progress, onChanged: (_) {}),
        ),
      ]),
    );
  }
}

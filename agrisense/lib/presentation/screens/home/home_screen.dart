import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../../data/mock_data.dart';
import '../../../domain/entities/community_post.dart';
import '../../../domain/entities/weather.dart';
import '../../theme/app_colors.dart';
import '../../../l10n/app_strings.dart';
import '../learn/lesson_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final weather = provider.currentWeather;
    final fullName = provider.farmerName.isNotEmpty ? provider.farmerName : 'Farmer';
    final firstName = fullName.split(' ').first;

    // Day greeting
    final s = context.trW;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? s.homeGoodMorning : hour < 17 ? s.homeGoodAfternoon : s.homeGoodEvening;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(slivers: [
        // AppBar
        SliverAppBar(
          floating: true, snap: true, elevation: 0,
          backgroundColor: AppColors.white,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.homeMuraho}, $greeting 👋',
                style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w400)),
            Row(children: [
              Text(firstName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gray900)),
              const SizedBox(width: 4),
              const Text('🌱', style: TextStyle(fontSize: 16)),
            ]),
          ]),
          actions: const [],
        ),

        SliverToBoxAdapter(child: Column(children: [
          // Today's Forecast section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Section header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(s.homeForecast,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gray900)),
                TextButton(
                  onPressed: () => context.read<AppProvider>().navigateToTab(1),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(s.homeDetails, style: const TextStyle(fontSize: 13, color: AppColors.green700, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 8),

              // Severe alert if needed
              if (weather.hasSevereAlert) ...[
                _SevereAlertBanner(title: weather.alertTitle ?? '', body: weather.alertBody ?? ''),
                const SizedBox(height: 8),
              ],

              // Main forecast card
              _ForecastCard(weather: weather),
              const SizedBox(height: 20),

              // Today's Tip
              _TipCard(),
              const SizedBox(height: 20),

              // Continue Learning
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(s.homeLearning,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gray900)),
                TextButton(
                  onPressed: () => context.read<AppProvider>().navigateToTab(2),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(s.homeAllLessons, style: const TextStyle(fontSize: 13, color: AppColors.green700, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 10),
            ]),
          ),

          // Lessons horizontal scroll
          _LessonsRow(),
          const SizedBox(height: 20),

          // Community section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(s.navCommunity,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gray900)),
                TextButton(
                  onPressed: () => context.read<AppProvider>().navigateToTab(3),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(s.homeSeeAll, style: const TextStyle(fontSize: 13, color: AppColors.green700, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 10),
              if (MockData.communityPosts.isNotEmpty) _CommunityCard(post: MockData.communityPosts.first),
            ]),
          ),
          const SizedBox(height: 100),
        ])),
      ]),
    );
  }
}

// ── Severe Alert Banner ────────────────────────────────────────────────────

class _SevereAlertBanner extends StatelessWidget {
  final String title, body;
  const _SevereAlertBanner({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red50,
        border: Border.all(color: AppColors.red600, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🚨', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red600)),
          Text(body, style: const TextStyle(fontSize: 11, color: AppColors.gray700)),
        ])),
      ]),
    );
  }
}

// ── Forecast Card ──────────────────────────────────────────────────────────

class _ForecastCard extends StatelessWidget {
  final WeatherData weather;
  const _ForecastCard({required this.weather});

  Color get _bgColor {
    switch (weather.status) {
      case WeatherStatus.severe:  return const Color(0xFFFFEEEE);
      case WeatherStatus.caution: return const Color(0xFFFFF8E1);
      case WeatherStatus.good:    return const Color(0xFFE8F5E9);
    }
  }

  Color get _accentColor {
    switch (weather.status) {
      case WeatherStatus.severe:  return AppColors.red600;
      case WeatherStatus.caution: return AppColors.amber600;
      case WeatherStatus.good:    return AppColors.green700;
    }
  }

  String get _statusBadge {
    switch (weather.status) {
      case WeatherStatus.severe:  return '🔴  SEVERE · DANGER';
      case WeatherStatus.caution: return '🟡  CAUTION · WARNING';
      case WeatherStatus.good:    return '🟢  GOOD · IN SEASON';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.trW;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_statusBadge,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _accentColor, letterSpacing: 0.3)),
        ),
        const SizedBox(height: 12),

        // Temp + advisory
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(weather.conditionEmoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${weather.temperature}°C',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _accentColor, height: 1)),
            Text(weather.district,
                style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(s.langText(weather.advisoryText, weather.advisoryKin),
                style: const TextStyle(fontSize: 12, color: AppColors.gray700, height: 1.4),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ])),
        ]),
        const SizedBox(height: 12),

        // Forecast mini-row
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: weather.forecast.take(5).length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final day = weather.forecast[i];
              return Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  Text(day.dayLabel, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.gray600)),
                  Text(day.weatherEmoji, style: const TextStyle(fontSize: 18)),
                  Text('${day.tempCelsius}°', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Tip Card ──────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tip = context.watch<AppProvider>().todaysTip;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber400.withValues(alpha: 0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.amber100, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(tip['emoji']!, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.trW.homeTipTitle,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.amber600, letterSpacing: 0.5)),
          Text(tip['title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          const SizedBox(height: 2),
          Text(tip['body']!, style: const TextStyle(fontSize: 11, color: AppColors.gray700, height: 1.4)),
        ])),
      ]),
    );
  }
}

// ── Lessons Row ───────────────────────────────────────────────────────────

class _LessonsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lessons = [
      ...provider.lessons.where((l) => l.progress > 0 && l.progress < 1),
      ...provider.lessons.where((l) => l.isNew),
    ].take(4).toList();

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: lessons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final l = lessons[i];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: l))),
            child: Container(
              width: 155,
              decoration: BoxDecoration(
                color: AppColors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Thumbnail
                Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Stack(children: [
                    Center(child: Text(l.emoji, style: const TextStyle(fontSize: 36))),
                    if (l.isNew) Positioned(top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.green700, borderRadius: BorderRadius.circular(6)),
                        child: const Text('NEW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                      )),
                    if (l.isWomensPathway) Positioned(top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF7B2D8B), borderRadius: BorderRadius.circular(6)),
                        child: const Text('♀', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                      )),
                  ]),
                ),
                // Content
                Expanded(child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.title,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray900),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    if (l.progress > 0) ...[
                      ClipRRect(borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: l.progress, backgroundColor: AppColors.gray100, color: AppColors.green700, minHeight: 3)),
                      const SizedBox(height: 2),
                      Text('${(l.progress * 100).round()}%', style: const TextStyle(fontSize: 9, color: AppColors.gray400)),
                    ] else ...[
                      Text('${l.durationMinutes} min · ${l.topicTag}',
                          style: const TextStyle(fontSize: 9, color: AppColors.gray400)),
                    ],
                  ]),
                )),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Community Card ────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  final CommunityPost post;
  const _CommunityCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 16, backgroundColor: AppColors.green100,
            child: Text(post.userInitials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green700))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),
            Text('${post.district} · ${post.timeAgo}', style: const TextStyle(fontSize: 10, color: AppColors.gray500)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(6)),
            child: const Text('Pinned', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.green700))),
        ]),
        const SizedBox(height: 10),
        Text(post.question, style: const TextStyle(fontSize: 13, color: AppColors.gray900, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.green700),
          const SizedBox(width: 4),
          Text('${post.upvotes}', style: const TextStyle(fontSize: 12, color: AppColors.green700, fontWeight: FontWeight.w600)),
          const SizedBox(width: 14),
          const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.gray400),
          const SizedBox(width: 4),
          Text('${post.replyCount} replies', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
        ]),
      ]),
    );
  }
}

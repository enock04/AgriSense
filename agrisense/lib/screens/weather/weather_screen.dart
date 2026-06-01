import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_strings.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  Color _statusColor(WeatherStatus s) => s == WeatherStatus.severe
      ? AppColors.red600
      : s == WeatherStatus.caution
          ? AppColors.amber600
          : AppColors.green700;

  Color _statusBg(WeatherStatus s) => s == WeatherStatus.severe
      ? AppColors.red100
      : s == WeatherStatus.caution
          ? AppColors.amber100
          : AppColors.green100;

  Color _statusBgLight(WeatherStatus s) => s == WeatherStatus.severe
      ? AppColors.red50
      : s == WeatherStatus.caution
          ? AppColors.amber50
          : AppColors.green50;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final w = provider.currentWeather;
    final s = context.trW;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(s.weatherTitle),
        actions: const [],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // District selector
        _DistrictSelector(
          currentDistrict: provider.district.isEmpty ? w.district : provider.district,
          onSelect: provider.selectDistrict,
        ),
        const SizedBox(height: 16),

        // Loading indicator
        if (provider.isWeatherLoading)
          const _WeatherLoadingCard(),

        // Error banner
        if (provider.weatherState == WeatherLoadState.error)
          _ErrorBanner(
            message: provider.weatherError,
            onRetry: provider.refreshWeather,
          ),

        if (provider.isWeatherLoading) const SizedBox.shrink()
        else ...[

        // Severe alert
        if (w.hasSevereAlert) ...[
          _SevereAlertCard(title: w.alertTitle!, body: w.alertBody!),
          const SizedBox(height: 16),
        ],

        // Main card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _statusBg(w.status), borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Text(w.conditionEmoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 8),
            Text('${w.temperature}°C', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.gray900)),
            Text('${s.weatherFeelsLike} ${w.feelsLike}°C', style: const TextStyle(fontSize: 14, color: AppColors.gray500)),
            const SizedBox(height: 8),
            Text('${w.district} · ${w.province}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(children: [
          _StatChip(icon: '💧', label: s.weatherHumidLabel, value: '${w.humidity}%'),
          const SizedBox(width: 8),
          _StatChip(icon: '🌧', label: s.weatherRainLabel, value: '${(w.rainChance * 100).round()}%'),
          const SizedBox(width: 8),
          _StatChip(icon: '💨', label: s.weatherWindLabel, value: '${w.windSpeed.round()} km/h'),
          const SizedBox(width: 8),
          _StatChip(icon: '☀', label: s.weatherUvLabel, value: '${w.uvIndex}'),
        ]),
        const SizedBox(height: 16),

        // Advisory
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _statusBgLight(w.status),
            border: Border.all(color: _statusColor(w.status), width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.weatherAdvisory,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(w.status), letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(s.langText(w.advisoryText, w.advisoryKin), style: const TextStyle(fontSize: 14, color: AppColors.gray900)),
          ]),
        ),
        const SizedBox(height: 16),

        Text(s.weather7Day,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const SizedBox(height: 10),
        _ForecastRow(forecast: w.forecast, statusColor: _statusColor, statusBg: _statusBg),
        const SizedBox(height: 32),

        ], // end of non-loading content
      ]),
    );
  }
}

class _DistrictSelector extends StatelessWidget {
  final String currentDistrict;
  final ValueChanged<String> onSelect;
  const _DistrictSelector({required this.currentDistrict, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr.weatherSelect, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(height: 300, child: ListView.builder(
              itemCount: MockData.districts.length,
              itemBuilder: (ctx, i) {
                final d = MockData.districts[i];
                return ListTile(
                  title: Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(d['province']!, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                  selected: currentDistrict == d['name'],
                  selectedTileColor: AppColors.green50,
                  trailing: currentDistrict == d['name'] ? const Icon(Icons.check_circle_rounded, color: AppColors.green700) : null,
                  onTap: () { onSelect(d['name']!); Navigator.pop(ctx); },
                );
              },
            )),
          ]),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
        child: Row(children: [
          const Icon(Icons.location_on_rounded, color: AppColors.green700, size: 18),
          const SizedBox(width: 8),
          Text(currentDistrict, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(context.trW.weatherChangeBtn, style: const TextStyle(fontSize: 12, color: AppColors.green700, fontWeight: FontWeight.w600)),
          const Icon(Icons.expand_more_rounded, color: AppColors.green700, size: 18),
        ]),
      ),
    );
  }
}

class _SevereAlertCard extends StatelessWidget {
  final String title, body;
  const _SevereAlertCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red50, border: Border.all(color: AppColors.red600, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🚨', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.red600)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
        ])),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon, label, value;
  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gray200)),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.gray400)),
        ]),
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final List<ForecastDay> forecast;
  final Color Function(WeatherStatus) statusColor;
  final Color Function(WeatherStatus) statusBg;
  const _ForecastRow({required this.forecast, required this.statusColor, required this.statusBg});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: forecast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = forecast[i];
          return Container(
            width: 76, padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Text(day.dayLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray700)),
              Text(day.weatherEmoji, style: const TextStyle(fontSize: 22)),
              Text('${day.tempCelsius}°', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: statusBg(day.status), borderRadius: BorderRadius.circular(4)),
                child: Text(day.actionWord,
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: statusColor(day.status)),
                    textAlign: TextAlign.center),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ── Loading card ───────────────────────────────────────────────────────────

class _WeatherLoadingCard extends StatelessWidget {
  const _WeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green100),
      ),
      child: const Row(children: [
        SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.green700),
        ),
        SizedBox(width: 16),
        Text(
          'Fetching live weather data...',
          style: TextStyle(fontSize: 14, color: AppColors.green700, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber400),
      ),
      child: Row(children: [
        const Text('⚠️', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message.isNotEmpty ? message : 'Could not load weather. Showing cached data.',
            style: const TextStyle(fontSize: 12, color: AppColors.gray700),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text('Retry', style: TextStyle(color: AppColors.green700, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

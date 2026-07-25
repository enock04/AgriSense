import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../../domain/entities/crop.dart';
import '../../../domain/entities/farmer_type.dart';
import '../../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../../l10n/app_strings.dart';
import '../admin/admin_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = context.trW;

    final name = provider.farmerName.isNotEmpty ? provider.farmerName : 'Farmer';
    final phone = provider.phone.isNotEmpty
        ? provider.phone
        : provider.authUser?.phoneNumber ?? '';
    final district = provider.district.isNotEmpty ? provider.district : 'Rwanda';
    final crops = provider.selectedCrops.isNotEmpty
        ? provider.selectedCrops
        : MockData.allCrops.take(3).toList();
    final completed = provider.lessons
        .where((l) => provider.getLessonProgress(l.id) >= 1.0)
        .length;
    final inProgress = provider.lessons
        .where((l) {
          final p = provider.getLessonProgress(l.id);
          return p > 0 && p < 1.0;
        }).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(s.profileTitle),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditProfile(context, provider)),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ── Profile header ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 34, backgroundColor: AppColors.green100,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.green700),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.gray900)),
              Text(_typeLabel(provider.farmerType),
                  style: const TextStyle(fontSize: 13, color: AppColors.green700, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (phone.isNotEmpty)
                Row(children: [
                  const Icon(Icons.phone_outlined, size: 12, color: AppColors.gray400),
                  const SizedBox(width: 4),
                  Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                ]),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(district, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
              ]),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Stats ───────────────────────────────────────────────────────────
        Row(children: [
          _StatCard('$completed', 'Completed',          Icons.check_circle_rounded,           AppColors.green700),
          const SizedBox(width: 10),
          _StatCard('$inProgress', 'In Progress',       Icons.play_circle_outline_rounded,    AppColors.amber600),
          const SizedBox(width: 10),
          _StatCard('${crops.length}', 'Crops Tracked', Icons.eco_rounded,                   AppColors.blue500),
        ]),
        const SizedBox(height: 16),

        // ── Lesson progress summary ─────────────────────────────────────────
        _SectionCard(
          title: s.profileLearning,
          child: Column(children: [
            _ProgressRow('Completed', completed, provider.lessons.length, AppColors.green700),
            const SizedBox(height: 8),
            _ProgressRow('In Progress', inProgress, provider.lessons.length, AppColors.amber600),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: provider.lessons.isEmpty ? 0 : completed / provider.lessons.length,
                backgroundColor: AppColors.gray100,
                color: AppColors.green700,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$completed of ${provider.lessons.length} lessons completed',
              style: const TextStyle(fontSize: 11, color: AppColors.gray500),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── My Crops ────────────────────────────────────────────────────────
        _SectionCard(
          title: s.profileMyCrops,
          child: crops.isEmpty
              ? const Text('No crops selected', style: TextStyle(color: AppColors.gray500))
              : Wrap(
                  spacing: 8, runSpacing: 8,
                  children: crops.map((c) => _CropChip(crop: c)).toList(),
                ),
        ),
        const SizedBox(height: 12),

        // ── Language ────────────────────────────────────────────────────────
        _SectionCard(
          title: s.profileLanguage,
          child: Column(children: [
            for (final e in [('en', 'English', '🇬🇧'), ('rw', 'Kinyarwanda', '🇷🇼'), ('fr', 'Français', '🇫🇷')]) ...[
              if (e.$1 != 'en') const Divider(height: 1),
              ListTile(
                dense: true, contentPadding: EdgeInsets.zero,
                leading: Text(e.$3, style: const TextStyle(fontSize: 20)),
                title: Text(e.$2, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: provider.language == e.$1 ? AppColors.green700 : AppColors.gray700)),
                trailing: provider.language == e.$1
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.green700, size: 20)
                    : null,
                onTap: () => provider.setLanguage(e.$1),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 12),

        // ── Settings ────────────────────────────────────────────────────────
        _SectionCard(
          title: s.profileSettings,
          child: Column(children: [
            // Notifications
            ListTile(
              dense: true, contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.gray500),
              title: const Text('Notifications · Imenyesha', style: TextStyle(fontSize: 13, color: AppColors.gray700)),
              subtitle: Text(provider.notificationsEnabled ? 'On · Birakora' : 'Off · Bihagaritse',
                  style: TextStyle(fontSize: 10, color: provider.notificationsEnabled ? AppColors.green700 : AppColors.gray400)),
              trailing: Switch(
                value: provider.notificationsEnabled,
                onChanged: (v) => provider.setNotifications(v),
                activeThumbColor: AppColors.green700,
              ),
            ),
            const Divider(height: 1),
            // Offline download
            ListTile(
              dense: true, contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download_outlined, size: 20, color: AppColors.gray500),
              title: const Text('Download for offline · Bika', style: TextStyle(fontSize: 13, color: AppColors.gray700)),
              subtitle: Text(provider.offlineDownloadEnabled ? 'Lessons saved locally' : 'Stream only',
                  style: TextStyle(fontSize: 10, color: provider.offlineDownloadEnabled ? AppColors.green700 : AppColors.gray400)),
              trailing: Switch(
                value: provider.offlineDownloadEnabled,
                onChanged: (v) => provider.setOfflineDownload(v),
                activeThumbColor: AppColors.green700,
              ),
            ),
            const Divider(height: 1),
            // Location
            ListTile(
              dense: true, contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.gray500),
              title: const Text('Location · Akarere', style: TextStyle(fontSize: 13, color: AppColors.gray700)),
              subtitle: Text(district, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
              onTap: () => _showDistrictPicker(context, provider),
            ),
            const Divider(height: 1),
            // Cloud sync status
            ListTile(
              dense: true, contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.sync_rounded, size: 20, color: provider.isAuthenticated ? AppColors.green700 : AppColors.gray400),
              title: const Text('Cloud sync · Backup', style: TextStyle(fontSize: 13, color: AppColors.gray700)),
              subtitle: Text(
                provider.isAuthenticated ? '✓ Profile synced to cloud' : 'Sign in to enable cloud sync',
                style: TextStyle(fontSize: 11, color: provider.isAuthenticated ? AppColors.green700 : AppColors.gray400),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── About ────────────────────────────────────────────────────────────
        _SectionCard(
          title: s.profileAbout,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'AgriSense is a mobile agricultural education and decision-support platform built for Rwandan smallholder farmers.',
              style: TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.5),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(6)),
                child: const Text('v1.0.0 MVP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green700)),
              ),
              const SizedBox(width: 8),
              if (provider.isAuthenticated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.blue100, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Firebase Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.blue500)),
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Admin Panel (visible to admin users only) ─────────────────────
        if (provider.isAdmin) ...[
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(children: [
                Text('⚙️', style: TextStyle(fontSize: 24)),
                SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Content Manager', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Add & manage lessons, tips, posts', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Reset / Sign out ─────────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: () => _confirmReset(context, provider),
          icon: const Icon(Icons.logout_rounded, color: AppColors.red600),
          label: Text(s.profileSignOut, style: const TextStyle(color: AppColors.red600)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red600)),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  String _typeLabel(FarmerType t) {
    switch (t) {
      case FarmerType.farmer:    return 'Farmer · Umuhinzi';
      case FarmerType.landowner: return "Landowner · Nyir'ubutaka";
      case FarmerType.trader:    return 'Trader · Umucuruzi';
    }
  }

  void _showDistrictPicker(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
        builder: (_, scrollCtrl) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(alignment: Alignment.centerLeft,
              child: Text('Change District · Hindura Akarere',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gray900))),
          ),
          Expanded(child: ListView.separated(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: MockData.districts.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.gray100),
            itemBuilder: (_, i) {
              final d = MockData.districts[i];
              final name = d['name']!;
              final isSel = provider.district == name;
              return ListTile(
                onTap: () async {
                  await provider.selectDistrict(name);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                leading: CircleAvatar(radius: 16, backgroundColor: isSel ? AppColors.green100 : AppColors.gray100,
                  child: Text(name[0], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isSel ? AppColors.green700 : AppColors.gray500))),
                title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isSel ? AppColors.green700 : AppColors.gray900)),
                subtitle: Text(d['province']!, style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
                trailing: isSel ? const Icon(Icons.check_circle_rounded, color: AppColors.green700, size: 18) : null,
                tileColor: isSel ? AppColors.green50 : null,
              );
            },
          )),
        ]),
      ),
    );
  }

  void _showEditProfile(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController(text: provider.farmerName);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          String nameError = '';
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                onChanged: (_) { if (nameError.isNotEmpty) setSheetState(() => nameError = ''); },
                decoration: const InputDecoration(
                    labelText: 'Your Name · Amazina', prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              if (nameError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(nameError, style: const TextStyle(fontSize: 11, color: AppColors.red600)),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    setSheetState(() => nameError = 'Name cannot be empty');
                    return;
                  }
                  await provider.setFarmerName(nameCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save · Bika'),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _confirmReset(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
            'You will be signed out. Your profile and progress are saved in the cloud.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); provider.resetOnboarding(); },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.red600)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCard(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.gray400), textAlign: TextAlign.center),
      ]),
    ));
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _ProgressRow(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
      const Spacer(),
      Text('$count / $total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900)),
        const SizedBox(height: 12),
        Material(type: MaterialType.transparency, child: child),
      ]),
    );
  }
}

class _CropChip extends StatelessWidget {
  final Crop crop;
  const _CropChip({required this.crop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.green50, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(crop.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(crop.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green700)),
      ]),
    );
  }
}

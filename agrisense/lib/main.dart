import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'models/models.dart';
import 'data/mock_data.dart';
import 'services/auth_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: const AgriSenseApp(),
    ),
  );
}

class AgriSenseApp extends StatelessWidget {
  const AgriSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppRouter(),
    );
  }
}

/// Routes to the correct screen based on auth + profile state.
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    switch (provider.authState) {
      // ── Still loading Firebase ─────────────────────────────────────────
      case AppAuthState.loading:
        return const _SplashLoader();

      // ── Not signed in → show onboarding/splash ─────────────────────────
      case AppAuthState.unauthenticated:
        return const OnboardingScreen();

      // ── Signed in but no profile yet → show profile setup ──────────────
      case AppAuthState.needsProfile:
        return const _ProfileSetupWrapper();

      // ── Fully authenticated with profile → main app ────────────────────
      case AppAuthState.ready:
        return const MainShell();
    }
  }
}

/// Shown briefly while Firebase auth state is being determined.
class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A5C35),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🌱', style: TextStyle(fontSize: 64)),
          SizedBox(height: 24),
          Text('AgriSense',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(height: 32),
          SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5)),
        ]),
      ),
    );
  }
}

/// When a user signed in via phone but hasn't set up their profile yet,
/// skip straight to the details pages of onboarding.
class _ProfileSetupWrapper extends StatefulWidget {
  const _ProfileSetupWrapper();

  @override
  State<_ProfileSetupWrapper> createState() => _ProfileSetupWrapperState();
}

class _ProfileSetupWrapperState extends State<_ProfileSetupWrapper> {
  final _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  FarmerType _farmerType = FarmerType.farmer;
  String _selectedDistrict = '';
  String _farmerName = '';
  final List<Crop> _selectedCrops = [];
  String _language = 'rw';

  bool get _canProceed {
    if (_currentPage == 1) return _selectedDistrict.isNotEmpty;
    return true;
  }

  void _next() => _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  void _prev() => _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);

  Future<void> _complete() async {
    final provider = context.read<AppProvider>();
    final phone = provider.firebaseUser?.phoneNumber ?? '';
    await provider.completeOnboarding(
      name: _farmerName.trim().isNotEmpty ? _farmerName.trim() : 'Farmer',
      phone: phone,
      farmerType: _farmerType,
      crops: _selectedCrops.isEmpty
          ? [MockData.allCrops[0], MockData.allCrops[1]]
          : _selectedCrops,
      district: _selectedDistrict.isEmpty ? 'Musanze' : _selectedDistrict,
      language: _language,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(children: [
          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 24, 8),
            child: Row(children: [
              if (_currentPage > 0)
                IconButton(onPressed: _prev, icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), color: AppColors.gray700),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Complete your profile · Step ${_currentPage + 1} of 3',
                    style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
                const SizedBox(height: 4),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: (_currentPage + 1) / 3, backgroundColor: AppColors.gray200, color: AppColors.green700, minHeight: 4)),
              ])),
            ]),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                // Step 1: Name + Language + Farmer type
                _SetupStep1(
                  name: _farmerName, language: _language, farmerType: _farmerType,
                  onNameChanged: (v) => setState(() => _farmerName = v),
                  onLanguageChanged: (v) => setState(() => _language = v),
                  onTypeChanged: (v) => setState(() => _farmerType = v),
                  onNext: _next,
                ),
                // Step 2: District
                _SetupStep2(
                  selected: _selectedDistrict,
                  onSelect: (d) => setState(() => _selectedDistrict = d),
                  canProceed: _canProceed, onNext: _next,
                ),
                // Step 3: Crops
                _SetupStep3(
                  selectedCrops: _selectedCrops,
                  onToggle: (c) => setState(() {
                    if (_selectedCrops.any((x) => x.id == c.id)) {
                      _selectedCrops.removeWhere((x) => x.id == c.id);
                    } else { _selectedCrops.add(c); }
                  }),
                  onComplete: _complete,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _SetupStep1 extends StatelessWidget {
  final String name, language;
  final FarmerType farmerType;
  final ValueChanged<String> onNameChanged, onLanguageChanged;
  final ValueChanged<FarmerType> onTypeChanged;
  final VoidCallback onNext;

  const _SetupStep1({required this.name, required this.language, required this.farmerType,
      required this.onNameChanged, required this.onLanguageChanged,
      required this.onTypeChanged, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tell us about you', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const Text('Twandikire amakuru yawe · Set up your profile', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 28),

        const Text('Your Name · Amazina', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray700)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: name,
          onChanged: onNameChanged,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
        ),
        const SizedBox(height: 20),

        const Text('Language · Ururimi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray700)),
        const SizedBox(height: 8),
        Row(children: [
          for (final l in [('rw','🇷🇼 RW'), ('en','🇬🇧 EN'), ('fr','🇫🇷 FR')]) ...[
            Expanded(child: GestureDetector(
              onTap: () => onLanguageChanged(l.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: language == l.$1 ? AppColors.green700 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: language == l.$1 ? AppColors.green700 : AppColors.gray200),
                ),
                child: Center(child: Text(l.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: language == l.$1 ? Colors.white : AppColors.gray700))),
              ),
            )),
          ],
        ]),
        const SizedBox(height: 20),

        const Text('I am a... · Ndi...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray700)),
        const SizedBox(height: 8),
        ...[
          (FarmerType.farmer,    '👨‍🌾', 'Farmer · Umuhinzi'),
          (FarmerType.landowner, '🏡',  "Landowner · Nyir'ubutaka"),
          (FarmerType.trader,    '🛒',  'Trader · Umucuruzi'),
        ].map((t) => GestureDetector(
          onTap: () => onTypeChanged(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: farmerType == t.$1 ? AppColors.green50 : AppColors.white,
              border: Border.all(color: farmerType == t.$1 ? AppColors.green700 : AppColors.gray200, width: farmerType == t.$1 ? 2 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Text(t.$2, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Text(t.$3, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: farmerType == t.$1 ? AppColors.green700 : AppColors.gray900)),
              const Spacer(),
              if (farmerType == t.$1) const Icon(Icons.check_circle_rounded, color: AppColors.green700),
            ]),
          ),
        )),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(onPressed: onNext, child: const Text('Continue · Komeza'))),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _SetupStep2 extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final bool canProceed;
  final VoidCallback onNext;
  const _SetupStep2({required this.selected, required this.onSelect, required this.canProceed, required this.onNext});

  @override
  State<_SetupStep2> createState() => _SetupStep2State();
}

class _SetupStep2State extends State<_SetupStep2> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = MockData.districts.where((d) => d['name']!.toLowerCase().contains(_query.toLowerCase())).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your District', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const Text('Akarere kawe', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 20),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(hintText: 'Search District · Shaka Akarere',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.gray400)),
        ),
        const SizedBox(height: 12),
        Expanded(child: Container(
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
          child: ListView.separated(
            padding: EdgeInsets.zero, itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray100),
            itemBuilder: (_, i) {
              final d = filtered[i]; final name = d['name']!; final isSel = widget.selected == name;
              return ListTile(onTap: () => widget.onSelect(name), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(radius: 16, backgroundColor: isSel ? AppColors.green100 : AppColors.gray100,
                  child: Text(name[0], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isSel ? AppColors.green700 : AppColors.gray500))),
                title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isSel ? AppColors.green700 : AppColors.gray900)),
                subtitle: Text(d['province']!, style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
                trailing: isSel ? const Icon(Icons.check_circle_rounded, color: AppColors.green700, size: 18) : null,
                tileColor: isSel ? AppColors.green50 : null);
            },
          ),
        )),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: widget.canProceed ? widget.onNext : null,
            style: ElevatedButton.styleFrom(backgroundColor: widget.canProceed ? AppColors.green700 : AppColors.gray200),
            child: Text('Continue · Komeza', style: TextStyle(color: widget.canProceed ? Colors.white : AppColors.gray500)))),
      ]),
    );
  }
}

class _SetupStep3 extends StatelessWidget {
  final List<Crop> selectedCrops;
  final ValueChanged<Crop> onToggle;
  final VoidCallback onComplete;
  const _SetupStep3({required this.selectedCrops, required this.onToggle, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your Crops', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const Text('Imbuto zawe · Select all that apply', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 24),
        Expanded(child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.9, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: MockData.allCrops.length,
          itemBuilder: (_, i) {
            final crop = MockData.allCrops[i];
            final isSel = selectedCrops.any((c) => c.id == crop.id);
            return GestureDetector(onTap: () => onToggle(crop), child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(color: isSel ? AppColors.green50 : AppColors.white,
                border: Border.all(color: isSel ? AppColors.green700 : AppColors.gray200, width: isSel ? 2 : 1),
                borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(crop.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(crop.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? AppColors.green700 : AppColors.gray700), textAlign: TextAlign.center),
                if (isSel) const Icon(Icons.check_circle, color: AppColors.green700, size: 14),
              ])));
          },
        )),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: onComplete,
            child: Text(selectedCrops.isEmpty ? 'Skip · Komeza' : 'Finish Setup · Rangiza 🌱'))),
      ]),
    );
  }
}

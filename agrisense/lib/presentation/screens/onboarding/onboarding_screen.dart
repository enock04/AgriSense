import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../../domain/entities/phone_credential.dart';
import '../../../domain/entities/crop.dart';
import '../../../domain/entities/farmer_type.dart';
import '../../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Profile data
  String _selectedLanguage = 'rw'; // Default Kinyarwanda as per Figma
  FarmerType _selectedFarmerType = FarmerType.farmer;
  final List<Crop> _selectedCrops = [];
  String _selectedDistrict = '';
  String _farmerName = '';
  String _phone = '';

  // Google Sign-In state
  bool _googleLoading = false;
  String _googleError = '';

  // OTP state
  bool _otpSending = false;
  bool _otpVerifying = false;
  String _otpStatusMsg = '';
  bool _otpReady = false;
  PhoneCredential? _autoCredential;

  // Pages: Splash · Language · FarmerType · District · Phone+OTP
  static const int _totalPages = 6;

  void _goTo(int page) => _pageController.animateToPage(page,
      duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);

  void _next() => _goTo(_currentPage + 1);
  void _prev() { if (_currentPage > 0) _goTo(_currentPage - 1); }

  bool get _canProceed {
    if (_currentPage == 2) return true; // farmer type always selected
    if (_currentPage == 3) return _selectedDistrict.isNotEmpty;
    if (_currentPage == 4) return _phone.trim().length >= 9;
    return true;
  }

  // ── Google Sign-In ────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() { _googleLoading = true; _googleError = ''; });
    await context.read<AppProvider>().signInWithGoogle(
      onError: (e) {
        if (mounted) setState(() { _googleLoading = false; _googleError = e; });
      },
    );
    if (mounted) setState(() => _googleLoading = false);
  }

  // ── OTP ──────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final rawPhone = _phone.trim();
    if (rawPhone.isEmpty) return;
    final phone = rawPhone.startsWith('+')
        ? rawPhone
        : '+250${rawPhone.replaceAll(RegExp(r'^0+'), '')}';
    setState(() { _phone = phone; _otpSending = true; _otpStatusMsg = ''; _otpReady = false; });
    _next(); // go to OTP page immediately

    final provider = context.read<AppProvider>();
    await provider.sendOtp(
      phoneNumber: phone,
      onCodeSent: (_, _) {
        if (mounted) setState(() { _otpSending = false; _otpReady = true; _otpStatusMsg = 'Code sent to $phone'; });
      },
      onError: (error) {
        if (mounted) setState(() { _otpSending = false; _otpReady = false; _otpStatusMsg = error; });
      },
      onAutoVerified: (credential) {
        _autoCredential = credential;
        if (mounted) { setState(() { _otpSending = false; _otpReady = true; }); _verifyOtp('auto'); }
      },
    );
  }

  Future<void> _verifyOtp(String code) async {
    if (code != 'auto' && code.length < 6) {
      setState(() => _otpStatusMsg = 'Please enter all 6 digits');
      return;
    }
    setState(() { _otpVerifying = true; _otpStatusMsg = ''; });

    final provider = context.read<AppProvider>();

    // The debug test-code bypass and anonymous-sign-in fallback are handled
    // transparently inside AuthRemoteDatasource — both the debug test phone
    // and a real phone number flow through the same verifyOtp/signInWithCredential path.
    bool ok;
    if (_autoCredential != null) {
      ok = await provider.signInWithPhoneCredential(_autoCredential!);
    } else {
      ok = await provider.verifyOtp(
        smsCode: code,
        onError: (e) { if (mounted) setState(() { _otpVerifying = false; _otpStatusMsg = e; }); },
      );
    }

    if (ok && mounted) {
      await provider.completeOnboarding(
        name: _farmerName.trim().isNotEmpty ? _farmerName.trim() : 'Farmer',
        phone: _phone, farmerType: _selectedFarmerType,
        crops: _selectedCrops.isEmpty ? [MockData.allCrops[0], MockData.allCrops[1]] : _selectedCrops,
        district: _selectedDistrict.isEmpty ? 'Musanze' : _selectedDistrict,
        language: _selectedLanguage,
      );
    } else if (mounted) {
      setState(() => _otpVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentPage == 0 ? const Color(0xFF1A5C35) : AppColors.white,
      body: SafeArea(
        child: Column(children: [
          // Progress bar — hidden on splash page
          if (_currentPage > 0 && _currentPage < _totalPages - 1)
            _OnboardingProgress(
              current: _currentPage,
              total: _totalPages - 1,
              onBack: _prev,
            ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                // 0 ── Splash
                _SplashPage(
                  onGetStarted: _next,
                  onGoogleSignIn: _signInWithGoogle,
                  isGoogleLoading: _googleLoading,
                  googleError: _googleError,
                ),

                // 1 ── Language
                _LanguagePage(
                  selected: _selectedLanguage,
                  onSelect: (l) { setState(() => _selectedLanguage = l); context.read<AppProvider>().setLanguage(l); },
                  onNext: _next,
                ),

                // 2 ── Farmer Type
                _FarmerTypePage(
                  selected: _selectedFarmerType,
                  onSelect: (t) => setState(() => _selectedFarmerType = t),
                  onNext: _next,
                ),

                // 3 ── District (separate page)
                _DistrictPage(
                  selected: _selectedDistrict,
                  onSelect: (d) => setState(() => _selectedDistrict = d),
                  canProceed: _canProceed,
                  onNext: _next,
                ),

                // 4 ── Phone number
                _PhonePage(
                  name: _farmerName,
                  phone: _phone,
                  onNameChanged: (v) => setState(() => _farmerName = v),
                  onPhoneChanged: (v) => setState(() => _phone = v),
                  canProceed: _canProceed,
                  isSending: _otpSending,
                  onSend: _sendOtp,
                ),

                // 5 ── OTP Verification
                _OtpPage(
                  phone: _phone,
                  isSending: _otpSending,
                  isVerifying: _otpVerifying,
                  isReady: _otpReady,
                  statusMsg: _otpStatusMsg,
                  onVerify: _verifyOtp,
                  onResend: () { _goTo(4); },
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Progress bar ────────────────────────────────────────────────────────────

class _OnboardingProgress extends StatelessWidget {
  final int current, total;
  final VoidCallback onBack;
  const _OnboardingProgress({required this.current, required this.total, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 8),
      child: Row(children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.gray700,
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Step $current of ${total - 1}',
                style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / (total - 1),
                backgroundColor: AppColors.gray200,
                color: AppColors.green700,
                minHeight: 4,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 0 — SPLASH SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class _SplashPage extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onGoogleSignIn;
  final bool isGoogleLoading;
  final String googleError;
  const _SplashPage({
    required this.onGetStarted,
    required this.onGoogleSignIn,
    required this.isGoogleLoading,
    required this.googleError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A5C35),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            // Logo row
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.green500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('🌾', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              const Text('AgriSense',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),

            const Spacer(),

            // Central circular logo
            Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2E7D50),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Center(
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3A9160),
                  ),
                  child: const Center(
                    child: Text('🌱', style: TextStyle(fontSize: 52)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Tagline
            const Text('Smart Farming\nfor Every Farmer',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
            const SizedBox(height: 12),
            const Text(
              'Ubuhinzi bwa gihanga — Abahinzi b\'u Rwanda\nFarmer Smart · Hane Smart · Hamwe Smart',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFFB2D9C3), height: 1.5),
            ),

            const Spacer(),

            // CTA button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A8139),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  elevation: 0,
                ),
                child: const Text('Get Started · TANGIRA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),

            // Divider
            Row(children: const [
              Expanded(child: Divider(color: Color(0xFF3A6B52))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: TextStyle(fontSize: 12, color: Color(0xFF7AB898))),
              ),
              Expanded(child: Divider(color: Color(0xFF3A6B52))),
            ]),
            const SizedBox(height: 12),

            // Google Sign-In
            GestureDetector(
              onTap: isGoogleLoading ? null : onGoogleSignIn,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D50),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFF3A9160)),
                ),
                child: isGoogleLoading
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Signing in...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                      ])
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          child: const Center(child: Text('G', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF4285F4)))),
                        ),
                        const SizedBox(width: 10),
                        const Text('Continue with Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ]),
              ),
            ),

            // Google error (if any)
            if (googleError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(googleError, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFFF8A80))),
            ],
            const SizedBox(height: 12),

            // Sign in for returning users (phone OTP)
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign in with phone instead',
                  style: TextStyle(fontSize: 13, color: Color(0xFFB2D9C3),
                      decoration: TextDecoration.underline, decorationColor: Color(0xFFB2D9C3))),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 1 — LANGUAGE
// ══════════════════════════════════════════════════════════════════════════════

class _LanguagePage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;
  const _LanguagePage({required this.selected, required this.onSelect, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final langs = [
      ('rw', 'RW', 'Kinyarwanda', 'Ururimi rwa mbere'),
      ('en', 'GB', 'English', 'Primary language'),
      ('fr', 'FR', 'Français', 'Language Principale'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        const Text('Choose your Language',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const SizedBox(height: 4),
        const Text('Hitamo ururimi bwanyu Nibwo Langa',
            style: TextStyle(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 28),
        ...langs.map((l) => _LangCard(
          code: l.$1, flagCode: l.$2, label: l.$3, sub: l.$4,
          isSelected: selected == l.$1,
          onTap: () => onSelect(l.$1),
        )),
        const Spacer(),
        _PrimaryButton(label: 'Continue · Komeza', onPressed: onNext),
      ]),
    );
  }
}

class _LangCard extends StatelessWidget {
  final String code, flagCode, label, sub;
  final bool isSelected;
  final VoidCallback onTap;
  const _LangCard({required this.code, required this.flagCode, required this.label,
      required this.sub, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green700 : AppColors.white,
          border: Border.all(color: isSelected ? AppColors.green700 : AppColors.gray200, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          // Flag badge
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(flagCode,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.gray700)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.gray900)),
            Text(sub, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : AppColors.gray500)),
          ])),
          if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 2 — FARMER TYPE
// ══════════════════════════════════════════════════════════════════════════════

class _FarmerTypePage extends StatelessWidget {
  final FarmerType selected;
  final ValueChanged<FarmerType> onSelect;
  final VoidCallback onNext;
  const _FarmerTypePage({required this.selected, required this.onSelect, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final types = [
      (FarmerType.farmer,    '👨‍🌾', 'Farmer',            'Umuhinzi',       'I grow crops on my own land'),
      (FarmerType.landowner, '🏡',  'Landowner',         'Nyir\'ubutaka',  'I own land managed by others'),
      (FarmerType.trader,    '🛒',  'Agriculture Trader', 'Umucuruzi',     'I buy & sell agricultural produce'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        const Text('I am a...', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const SizedBox(height: 4),
        const Text('Ndi...', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 28),
        ...types.map((t) {
          final isSel = selected == t.$1;
          return GestureDetector(
            onTap: () => onSelect(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSel ? AppColors.green50 : AppColors.white,
                border: Border.all(color: isSel ? AppColors.green700 : AppColors.gray200, width: isSel ? 2 : 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Text(t.$2, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.$3, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isSel ? AppColors.green700 : AppColors.gray900)),
                  Text('${t.$4} · ${t.$5}',
                      style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                ])),
                if (isSel) const Icon(Icons.check_circle_rounded, color: AppColors.green700),
              ]),
            ),
          );
        }),
        const Spacer(),
        _PrimaryButton(label: 'Continue · Komeza', onPressed: onNext),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 3 — DISTRICT (dedicated page with search)
// ══════════════════════════════════════════════════════════════════════════════

class _DistrictPage extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final bool canProceed;
  final VoidCallback onNext;
  const _DistrictPage({required this.selected, required this.onSelect, required this.canProceed, required this.onNext});

  @override
  State<_DistrictPage> createState() => _DistrictPageState();
}

class _DistrictPageState extends State<_DistrictPage> {
  String _query = '';

  List<Map<String, String>> get _filtered => MockData.districts
      .where((d) => d['name']!.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        const Text('Your District', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const SizedBox(height: 4),
        const Text('Akarere kawe · For local weather & prices',
            style: TextStyle(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 20),

        // Search bar
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search District · Shaka Akarere',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green700, width: 2)),
            filled: true, fillColor: AppColors.white,
          ),
        ),
        const SizedBox(height: 12),

        // District list
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.gray100),
                itemBuilder: (_, i) {
                  final d = _filtered[i];
                  final name = d['name']!;
                  final isSel = widget.selected == name;
                  return ListTile(
                    onTap: () => widget.onSelect(name),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSel ? AppColors.green100 : AppColors.gray100,
                      child: Text(name[0],
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                              color: isSel ? AppColors.green700 : AppColors.gray500)),
                    ),
                    title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                        color: isSel ? AppColors.green700 : AppColors.gray900)),
                    subtitle: Text(d['province']!, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                    trailing: isSel ? const Icon(Icons.check_circle_rounded, color: AppColors.green700, size: 20) : null,
                    tileColor: isSel ? AppColors.green50 : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: widget.canProceed ? 'Continue · Komeza' : 'Select a district',
          onPressed: widget.canProceed ? widget.onNext : null,
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 4 — PHONE NUMBER
// ══════════════════════════════════════════════════════════════════════════════

class _PhonePage extends StatefulWidget {
  final String name, phone;
  final ValueChanged<String> onNameChanged, onPhoneChanged;
  final bool canProceed, isSending;
  final VoidCallback onSend;

  const _PhonePage({
    required this.name, required this.phone,
    required this.onNameChanged, required this.onPhoneChanged,
    required this.canProceed, required this.isSending,
    required this.onSend,
  });

  @override
  State<_PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<_PhonePage> {
  String _nameError = '';
  String _phoneError = '';

  void _validate() {
    String nameErr = '';
    String phoneErr = '';

    if (widget.name.trim().isEmpty) {
      nameErr = 'Please enter your name · Injiza amazina';
    }

    final rawPhone = widget.phone.trim();
    final isValidFormat = rawPhone.startsWith('+250') || rawPhone.length >= 9;
    if (rawPhone.isEmpty || !isValidFormat) {
      phoneErr = 'Enter a valid phone number (+250...)';
    }

    setState(() { _nameError = nameErr; _phoneError = phoneErr; });

    if (nameErr.isEmpty && phoneErr.isEmpty) {
      widget.onSend();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        const Text('Verify your number',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const SizedBox(height: 4),
        const Text('Emeza inomero yawe · Verify your number',
            style: TextStyle(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 28),

        // Phone illustration
        Center(
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.green50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green100, width: 3),
            ),
            child: const Center(child: Text('📱', style: TextStyle(fontSize: 44))),
          ),
        ),
        const SizedBox(height: 28),

        // Name
        const Text('Full Name · Amazina', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray700)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: widget.name,
          onChanged: (v) { widget.onNameChanged(v); if (_nameError.isNotEmpty) setState(() => _nameError = ''); },
          textCapitalization: TextCapitalization.words,
          decoration: _inputDeco('Your name · Amazina yawe', Icons.person_outline_rounded),
        ),
        if (_nameError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_nameError, style: const TextStyle(fontSize: 11, color: AppColors.red600)),
          ),
        const SizedBox(height: 16),

        // Phone
        const Text('Phone Number · Nimero ya telefoni', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray700)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: widget.phone,
          onChanged: (v) { widget.onPhoneChanged(v); if (_phoneError.isNotEmpty) setState(() => _phoneError = ''); },
          keyboardType: TextInputType.phone,
          decoration: _inputDeco('+250 788 000 000', Icons.phone_outlined),
        ),
        if (_phoneError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_phoneError, style: const TextStyle(fontSize: 11, color: AppColors.red600)),
          ),
        const SizedBox(height: 8),
        const Text('We\'ll send a 6-digit code to verify your number',
            style: TextStyle(fontSize: 11, color: AppColors.gray400)),
        const SizedBox(height: 28),

        // Send button
        _PrimaryButton(
          label: widget.isSending ? 'Sending...' : 'Send Verification Code · Ohereza Kode',
          onPressed: widget.isSending ? null : _validate,
          isLoading: widget.isSending,
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
    prefixIcon: Icon(icon, color: AppColors.gray400, size: 20),
    filled: true, fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green700, width: 2)),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 5 — OTP VERIFICATION
// ══════════════════════════════════════════════════════════════════════════════

class _OtpPage extends StatefulWidget {
  final String phone, statusMsg;
  final bool isSending, isVerifying, isReady;
  final ValueChanged<String> onVerify;
  final VoidCallback onResend;
  const _OtpPage({required this.phone, required this.isSending, required this.isVerifying,
      required this.isReady, required this.statusMsg, required this.onVerify,
      required this.onResend});

  @override
  State<_OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<_OtpPage> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _nodes[0].requestFocus());
  }

  void _startCountdown() {
    _countdown = 60; _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() { _countdown--; if (_countdown <= 0) _canResend = true; });
      return _countdown > 0;
    });
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _onType(int i, String v) {
    if (v.length == 1 && i < 5) _nodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    if (_code.length == 6) widget.onVerify(_code);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        const Text('Verify your number',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.gray900)),
        const SizedBox(height: 4),
        const Text('Emeza inomero yawe · Verify your number',
            style: TextStyle(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 24),

        // Status card
        _OtpStatusCard(phone: widget.phone, isSending: widget.isSending, isReady: widget.isReady, msg: widget.statusMsg),
        const SizedBox(height: 28),

        // Hint
        Center(child: Text('Enter 6-digit OTP · Injiza kode ya imibare 6',
            style: const TextStyle(fontSize: 12, color: AppColors.gray500))),
        const SizedBox(height: 16),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => SizedBox(
            width: 48, height: 56,
            child: TextField(
              controller: _ctrls[i],
              focusNode: _nodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gray900),
              decoration: InputDecoration(
                counterText: '', contentPadding: EdgeInsets.zero, filled: true, fillColor: AppColors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green700, width: 2.5)),
              ),
              onChanged: (v) => _onType(i, v),
            ),
          )),
        ),
        const SizedBox(height: 24),

        // Verify button
        _PrimaryButton(
          label: 'Verify & Enter AgriSense ✓',
          onPressed: widget.isVerifying ? null : () => widget.onVerify(_code),
          isLoading: widget.isVerifying,
        ),
        const SizedBox(height: 16),

        // Resend / countdown
        Center(child: _canResend
            ? GestureDetector(
                onTap: () { _startCountdown(); for (final c in _ctrls) { c.clear(); } widget.onResend(); },
                child: const Text("Didn't receive OTP · Injiza kode ↗",
                    style: TextStyle(fontSize: 13, color: AppColors.green700, fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline, decorationColor: AppColors.green700)),
              )
            : Text("Resend in ${_countdown}s",
                style: const TextStyle(fontSize: 13, color: AppColors.gray400))),
      ]),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }
}

class _OtpStatusCard extends StatelessWidget {
  final String phone, msg;
  final bool isSending, isReady;
  const _OtpStatusCard({required this.phone, required this.isSending, required this.isReady, required this.msg});

  @override
  Widget build(BuildContext context) {
    if (isSending) {
      return _statusContainer(AppColors.blue50, AppColors.blue100, AppColors.blue500,
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blue500)),
          'Sending code...', 'To $phone');
    }
    if (isReady) {
      return _statusContainer(AppColors.green50, AppColors.green100, AppColors.green700,
          const Text('📱', style: TextStyle(fontSize: 20)),
          'Code sent!', 'Enter the 6-digit code sent to $phone');
    }
    if (msg.isNotEmpty) {
      return _statusContainer(AppColors.red50, AppColors.red100, AppColors.red600,
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          'Could not send code', '$msg\n\nUse "Skip verification" below to continue.');
    }
    return _statusContainer(AppColors.green50, AppColors.green100, AppColors.green700,
        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.green700)),
        'Sending code to $phone...', '');
  }

  Widget _statusContainer(Color bg, Color border, Color textColor, Widget icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        icon,
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
          if (sub.isNotEmpty) ...[const SizedBox(height: 2), Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.gray700))],
        ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE BUTTONS
// ══════════════════════════════════════════════════════════════════════════════

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  const _PrimaryButton({required this.label, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppColors.green700 : AppColors.gray200,
          foregroundColor: enabled ? Colors.white : AppColors.gray500,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 0,
        ),
        child: isLoading
            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                SizedBox(width: 12),
                Text('Please wait...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ])
            : Text(label, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : AppColors.gray500)),
      ),
    );
  }
}


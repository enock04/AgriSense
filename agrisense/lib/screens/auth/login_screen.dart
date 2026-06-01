import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

/// Standalone login screen for returning users.
/// Accessed via "Already have an account? Sign in" on the splash.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0 = enter phone, 1 = enter OTP
  int _step = 0;

  final _phoneCtrl = TextEditingController();
  String _formattedPhone = '';

  bool _isSending = false;
  bool _isVerifying = false;
  String _errorMsg = '';
  bool _otpReady = false;

  PhoneAuthCredential? _autoCredential;

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _normalise(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('+')) return trimmed;
    return '+250${trimmed.replaceAll(RegExp(r'^0+'), '')}';
  }

  // ── Send OTP ──────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _normalise(_phoneCtrl.text);
    if (phone.length < 10) {
      setState(() => _errorMsg = 'Enter a valid Rwanda number (+250...)');
      return;
    }
    _formattedPhone = phone;
    setState(() { _isSending = true; _errorMsg = ''; _otpReady = false; });

    // Go to OTP step immediately so user sees the screen
    setState(() => _step = 1);

    final auth = context.read<AuthService>();
    await auth.sendOtp(
      phoneNumber: phone,
      onCodeSent: (_, __) {
        if (mounted) setState(() { _isSending = false; _otpReady = true; });
      },
      onError: (error) {
        if (mounted) setState(() { _isSending = false; _errorMsg = error; });
      },
      onAutoVerified: (credential) {
        _autoCredential = credential;
        if (mounted) { setState(() { _isSending = false; _otpReady = true; }); _verifyOtp('auto'); }
      },
    );
  }

  // ── Verify OTP ─────────────────────────────────────────────────────────

  Future<void> _verifyOtp(String code) async {
    if (code != 'auto' && code.length < 6) return;
    setState(() { _isVerifying = true; _errorMsg = ''; });

    final auth = context.read<AuthService>();
    UserCredential? result;

    if (_autoCredential != null || code == 'auto') {
      result = await auth.signInWithCredential(
          _autoCredential ?? PhoneAuthProvider.credential(verificationId: '', smsCode: ''));
    } else {
      result = await auth.verifyOtp(
        smsCode: code,
        onError: (e) { if (mounted) setState(() { _isVerifying = false; _errorMsg = e; }); },
      );
    }

    if (result != null && mounted) {
      // Firebase auth succeeded. AppProvider will pick up the auth state change
      // and route to the app or profile setup automatically.
      // Just show loading while that happens:
      setState(() => _isVerifying = false);
    } else {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _step == 0 ? _buildPhoneStep() : _buildOtpStep(),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 0 — Phone Entry
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPhoneStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),

      // Back button
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.gray100, shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.gray700),
        ),
      ),
      const SizedBox(height: 32),

      // Icon
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppColors.green50, shape: BoxShape.circle,
          border: Border.all(color: AppColors.green200, width: 2),
        ),
        child: const Center(child: Text('📱', style: TextStyle(fontSize: 32))),
      ),
      const SizedBox(height: 24),

      // Title
      const Text('Welcome back!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.gray900)),
      const Text('Murakaza neza!',
          style: TextStyle(fontSize: 14, color: AppColors.gray500, fontStyle: FontStyle.italic)),
      const SizedBox(height: 8),
      const Text('Enter your phone number to sign in.',
          style: TextStyle(fontSize: 14, color: AppColors.gray600)),
      const SizedBox(height: 32),

      // Phone label
      const Text('Phone Number · Nimero ya Telefoni',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray700)),
      const SizedBox(height: 8),

      // Phone input
      TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        autofocus: true,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        decoration: InputDecoration(
          hintText: '+250 788 000 000',
          hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14, fontWeight: FontWeight.w400),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.green200),
            ),
            child: const Text('🇷🇼', style: TextStyle(fontSize: 16)),
          ),
          filled: true, fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.gray200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.gray200, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.green700, width: 2)),
        ),
        onSubmitted: (_) => _sendOtp(),
      ),
      const SizedBox(height: 8),

      // Error
      if (_errorMsg.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.red100)),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red600),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMsg, style: const TextStyle(fontSize: 12, color: AppColors.red600))),
          ]),
        ),
      const SizedBox(height: 32),

      // Send button
      _ActionButton(
        label: 'Send Verification Code',
        sublabel: 'Twohereza kode · OTP',
        icon: Icons.sms_rounded,
        isLoading: _isSending,
        onPressed: _isSending ? null : _sendOtp,
      ),
      const SizedBox(height: 20),

      // Divider
      Row(children: [
        const Expanded(child: Divider(color: AppColors.gray200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Text('or', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
        ),
        const Expanded(child: Divider(color: AppColors.gray200)),
      ]),
      const SizedBox(height: 20),

      // New user
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray100, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('🌱', style: TextStyle(fontSize: 18)))),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('New to AgriSense?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),
              Text('Create your account · Fungura konti', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.gray400),
          ]),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — OTP Entry
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildOtpStep() {
    return _OtpEntryWidget(
      phone: _formattedPhone,
      isSending: _isSending,
      isVerifying: _isVerifying,
      isReady: _otpReady,
      errorMsg: _errorMsg,
      onVerify: _verifyOtp,
      onChangeNumber: () => setState(() { _step = 0; _errorMsg = ''; _otpReady = false; }),
      onResend: () {
        setState(() { _step = 0; _errorMsg = ''; });
      },
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// OTP Entry Widget
// ══════════════════════════════════════════════════════════════════════════════

class _OtpEntryWidget extends StatefulWidget {
  final String phone, errorMsg;
  final bool isSending, isVerifying, isReady;
  final ValueChanged<String> onVerify;
  final VoidCallback onChangeNumber, onResend;

  const _OtpEntryWidget({
    required this.phone, required this.errorMsg,
    required this.isSending, required this.isVerifying, required this.isReady,
    required this.onVerify, required this.onChangeNumber, required this.onResend,
  });

  @override
  State<_OtpEntryWidget> createState() => _OtpEntryWidgetState();
}

class _OtpEntryWidgetState extends State<_OtpEntryWidget> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nodes[0].canRequestFocus) _nodes[0].requestFocus();
    });
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),

      // Back button
      GestureDetector(
        onTap: widget.onChangeNumber,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.gray100, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.gray700),
        ),
      ),
      const SizedBox(height: 32),

      // Icon + title
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: AppColors.green50, shape: BoxShape.circle, border: Border.all(color: AppColors.green200, width: 2)),
        child: const Center(child: Text('🔐', style: TextStyle(fontSize: 32))),
      ),
      const SizedBox(height: 20),
      const Text('Check your messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.gray900)),
      const Text('Reba ubutumwa bwawe', style: TextStyle(fontSize: 13, color: AppColors.gray500, fontStyle: FontStyle.italic)),
      const SizedBox(height: 8),

      // Status
      if (widget.isSending)
        _StatusRow(icon: Icons.hourglass_top_rounded, color: AppColors.blue500, text: 'Sending code to ${widget.phone}...')
      else if (widget.isReady)
        _StatusRow(icon: Icons.check_circle_rounded, color: AppColors.green700, text: 'Code sent to ${widget.phone}')
      else if (widget.errorMsg.isNotEmpty)
        _StatusRow(icon: Icons.error_outline_rounded, color: AppColors.red600, text: widget.errorMsg)
      else
        _StatusRow(icon: Icons.schedule_rounded, color: AppColors.amber600, text: 'Waiting for code...'),

      const SizedBox(height: 28),

      // OTP label
      const Text('Enter 6-Digit Code · Injiza Kode',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray700)),
      const SizedBox(height: 12),

      // OTP boxes
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) => SizedBox(
          width: 48, height: 58,
          child: TextField(
            controller: _ctrls[i],
            focusNode: _nodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gray900),
            decoration: InputDecoration(
              counterText: '',
              filled: true, fillColor: AppColors.white,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.green700, width: 2.5),
              ),
            ),
            onChanged: (v) => _onType(i, v),
          ),
        )),
      ),
      const SizedBox(height: 8),

      // Error
      if (widget.errorMsg.isNotEmpty && !widget.isSending)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(widget.errorMsg,
              style: const TextStyle(fontSize: 12, color: AppColors.red600)),
        ),
      const SizedBox(height: 28),

      // Verify button
      _ActionButton(
        label: widget.isVerifying ? 'Verifying...' : 'Verify & Sign In',
        sublabel: 'Emeza kode · Enter AgriSense',
        icon: Icons.verified_rounded,
        isLoading: widget.isVerifying,
        onPressed: widget.isVerifying || widget.isSending ? null : () => widget.onVerify(_code),
      ),
      const SizedBox(height: 20),

      // Resend row
      Center(
        child: _canResend
            ? TextButton.icon(
                onPressed: () { _startCountdown(); for (final c in _ctrls) { c.clear(); } widget.onResend(); },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.green700),
                label: const Text("Didn't receive? Resend · Ohereza nshya",
                    style: TextStyle(fontSize: 13, color: AppColors.green700, fontWeight: FontWeight.w600)),
              )
            : Text('Resend code in ${_countdown}s',
                style: const TextStyle(fontSize: 13, color: AppColors.gray400)),
      ),
      const SizedBox(height: 12),

      // Change number
      Center(
        child: TextButton(
          onPressed: widget.onChangeNumber,
          child: const Text('Change number · Hindura inomero',
              style: TextStyle(fontSize: 12, color: AppColors.gray400,
                  decoration: TextDecoration.underline, decorationColor: AppColors.gray400)),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _StatusRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500))),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final String label, sublabel;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label, required this.sublabel, required this.icon,
    required this.isLoading, this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: enabled ? AppColors.green700 : AppColors.gray200,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled ? [BoxShadow(color: AppColors.green700.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: isLoading
            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                SizedBox(width: 12),
                Text('Please wait...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ])
            : Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: enabled ? 0.2 : 0.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: enabled ? Colors.white : AppColors.gray400),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: enabled ? Colors.white : AppColors.gray400)),
                  Text(sublabel, style: TextStyle(fontSize: 11, color: enabled ? Colors.white70 : AppColors.gray300)),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: enabled ? Colors.white70 : AppColors.gray300),
              ]),
      ),
    );
  }
}

/// End-to-end integration test — drives the real app on a real device/emulator
/// against the live Firebase project (agrisense-01). Exercises the full
/// onboarding → phone-OTP auth → home flow using the debug test phone number
/// bypass built into AuthRemoteDatasource (+250793442608 / code 000000).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:agrisense/main.dart' as app;

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 300));
  }
  throw TestFailure('Timed out waiting for $finder to appear');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'onboarding → phone OTP auth → home shell (live Firebase)',
    (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ── Splash page ──────────────────────────────────────────────────────
      await _pumpUntilFound(tester, find.text('Get Started · TANGIRA'));
      await tester.tap(find.text('Get Started · TANGIRA'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // ── Language page ────────────────────────────────────────────────────
      await _pumpUntilFound(tester, find.text('English'));
      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Continue · Komeza').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // ── Farmer type page (default selection is fine) ────────────────────
      await _pumpUntilFound(tester, find.text('I am a...'));
      await tester.tap(find.text('Continue · Komeza').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // ── District page ────────────────────────────────────────────────────
      await _pumpUntilFound(tester, find.text('Musanze'));
      await tester.tap(find.text('Musanze'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Continue · Komeza').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // ── Phone + name page ────────────────────────────────────────────────
      await _pumpUntilFound(tester, find.byType(TextFormField));
      final formFields = find.byType(TextFormField);
      expect(formFields, findsNWidgets(2));
      await tester.enterText(formFields.at(0), 'Test Farmer');
      await tester.enterText(formFields.at(1), '0793442608');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Send Verification Code · Ohereza Kode'));
      await tester.pump(const Duration(milliseconds: 300));

      // ── OTP page — wait for the debug test-phone bypass to report "code sent" ──
      await _pumpUntilFound(tester, find.text('Code sent!'), timeout: const Duration(seconds: 10));

      final otpBoxes = find.byType(TextField);
      expect(otpBoxes, findsNWidgets(6));
      const code = '000000';
      for (var i = 0; i < code.length; i++) {
        await tester.enterText(otpBoxes.at(i), code[i]);
        await tester.pump(const Duration(milliseconds: 150));
      }

      // ── Verification + profile creation hits real Firebase Auth + Firestore ──
      await _pumpUntilFound(
        tester,
        find.byIcon(Icons.home_rounded),
        timeout: const Duration(seconds: 20),
      );

      // ── We've reached the authenticated home shell ──────────────────────
      // (Material 3's NavigationBar renders each label twice for the
      // selected/unselected fade transition, so match at least one.)
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.text('Home'), findsAtLeastNWidgets(1));
      expect(find.text('Weather'), findsAtLeastNWidgets(1));
      expect(find.text('Learn'), findsAtLeastNWidgets(1));
      expect(find.text('Community'), findsAtLeastNWidgets(1));
      expect(find.text('Profile'), findsAtLeastNWidgets(1));

      // ── Navigate through every tab — confirms each screen builds cleanly
      //    against live Firestore streams with no uncaught exceptions ──────
      for (final tab in ['Weather', 'Learn', 'Community', 'Profile', 'Home']) {
        await tester.tap(find.text(tab).first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

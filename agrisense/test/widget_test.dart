import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:agrisense/main.dart';
import 'package:agrisense/providers/app_provider.dart';

void main() {
  testWidgets('AgriSense app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const AgriSenseApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(AgriSenseApp), findsOneWidget);
  });
}

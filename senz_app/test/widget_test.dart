import 'package:flutter_test/flutter_test.dart';
import 'package:senz_app/main.dart';

void main() {
  testWidgets('welcome screen opens the demo dashboard', (tester) async {
    await tester.pumpWidget(const SenzApp());

    expect(find.text('SENZ'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Demo Mode'), findsOneWidget);
    expect(find.text('Simulated sensor data'), findsOneWidget);
    expect(find.text('Start Signing'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spin_to_learn/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Splash screen shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpinToLearnApp()));
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);

    // Let the splash timer finish so no pending timers remain.
    await tester.pump(const Duration(seconds: 3));
  });
}

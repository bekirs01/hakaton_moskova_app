import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hakaton_moskova_app/presentation/screens/config_missing_screen.dart';

void main() {
  testWidgets('Config missing screen shows instructions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ConfigMissingScreen()),
    );
    expect(find.textContaining('MEMEOPS_API_BASE'), findsNWidgets(2));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flowcuts_app/main.dart';
import 'package:flowcuts_app/providers/app_provider.dart';

void main() {
  testWidgets('FlowCuts app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const FlowCutsApp(),
      ),
    );
    // Splash screen loads
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}

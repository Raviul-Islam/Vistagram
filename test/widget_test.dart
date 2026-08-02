import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vistagram/main.dart';

void main() {
  testWidgets('App boots and shows MainLayout', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: VistagramApp()));

    // Wait for the GoRouter to process the initial route
    await tester.pumpAndSettle();

    // Verify that the BottomNavigationBar is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // Verify that Home text is on screen
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
  });
}

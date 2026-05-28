import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leoide/main.dart';

void main() {
  testWidgets('App renders EditorShell with ActivityBar and Sidebar',
      (WidgetTester tester) async {
    // Use 1280x800 to ensure full toolbar + sidebar fit without overflow
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Run async to prevent LSP Process.start from creating fake timers
    await tester.runAsync(() async {
      await tester.pumpWidget(const LeoIDEApp());
      return;
    });
    await tester.pump();

    // Core orchestrator widgets present
    expect(find.byType(Scaffold), findsOneWidget);

    // ActivityBar: all 4 icons present
    expect(find.byIcon(Icons.folder), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.search), findsWidgets);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsWidgets);
    expect(find.byIcon(Icons.settings_outlined), findsWidgets);

    // Sidebar shows the Explorer header (default tab = explorer)
    expect(find.text('EXPLORADOR'), findsWidgets);
  });
}

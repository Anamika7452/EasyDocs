// Smoke tests for the Home Screen FAB and the Scan Locations bottom sheet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easydocs/main.dart';

void main() {
  const channel = MethodChannel('com.anamika.easydocs/documents');

  setUp(() {
    // Stub the native side so the widgets can run under test without Android.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getSelectedFolders':
          // Mirrors the native side: default folders are always present.
          return <Map<String, dynamic>>[
            {
              'uri': 'default:download',
              'name': 'Download',
              'path': 'Internal storage/Download',
              'isDefault': true,
            },
            {
              'uri': 'default:documents',
              'name': 'Documents',
              'path': 'Internal storage/Documents',
              'isDefault': true,
            },
          ];
        case 'getDocuments':
          return <Map<String, dynamic>>[];
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('FAB opens the Scan Locations sheet with an empty state',
      (tester) async {
    await tester.pumpWidget(const EasyDocsApp());
    await tester.pumpAndSettle();

    // The FAB uses the folder_open icon.
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    expect(
      find.descendant(of: fab, matching: find.byIcon(Icons.folder_open)),
      findsOneWidget,
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Scan Locations'), findsOneWidget);
    // Default folders always appear.
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    // No custom folders yet -> empty-state hint under the Custom section.
    expect(find.text('No folders selected'), findsOneWidget);
    expect(find.text('Add Folder'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('Done closes the sheet', (tester) async {
    await tester.pumpWidget(const EasyDocsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Scan Locations'), findsNothing);
  });
}

import 'package:decorra/widgets/empty_state.dart';
import 'package:decorra/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyState shows its title, message and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            title: 'Nothing here',
            message: 'Try again later.',
            action: TextButton(onPressed: () {}, child: const Text('Retry')),
          ),
        ),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Try again later.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('EmptyState without a message or action shows only the title',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyState(title: 'Empty'))),
    );

    expect(find.text('Empty'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('StatusBadge shows its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusBadge('APPROVED'))),
    );

    expect(find.text('APPROVED'), findsOneWidget);
  });
}
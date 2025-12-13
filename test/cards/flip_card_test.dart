import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindart/cards/flip_card.dart';

void main() {
  group('FlipCard', () {
    testWidgets('displays front widget initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlipCard(
              front: Text('Front Side'),
              back: Text('Back Side'),
            ),
          ),
        ),
      );

      expect(find.text('Front Side'), findsOneWidget);
      expect(find.text('Back Side'), findsNothing);
    });

    testWidgets('flips to back on double tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlipCard(
              front: Text('Front Side'),
              back: Text('Back Side'),
            ),
          ),
        ),
      );

      // Use gesture to perform double tap
      final gesture = await tester.createGesture(kind: PointerDeviceKind.touch);
      final center = tester.getCenter(find.byType(FlipCard));
      await gesture.down(center);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.down(center);
      await gesture.up();
      await tester.pumpAndSettle();

      // After flip animation completes, back should be visible
      expect(find.text('Back Side'), findsOneWidget);
      expect(find.text('Front Side'), findsNothing);
    });

    testWidgets('flips back to front on second double tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlipCard(
              front: Text('Front Side'),
              back: Text('Back Side'),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.touch);
      final center = tester.getCenter(find.byType(FlipCard));

      // First double tap - flip to back
      await gesture.down(center);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.down(center);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Back Side'), findsOneWidget);

      // Second double tap - flip back to front
      await gesture.down(center);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.down(center);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Front Side'), findsOneWidget);
      expect(find.text('Back Side'), findsNothing);
    });

    testWidgets('single tap does not flip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlipCard(
              front: Text('Front Side'),
              back: Text('Back Side'),
            ),
          ),
        ),
      );

      // Single tap should not flip
      await tester.tap(find.byType(FlipCard));
      await tester.pumpAndSettle();

      expect(find.text('Front Side'), findsOneWidget);
      expect(find.text('Back Side'), findsNothing);
    });

    testWidgets('renders with complex widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlipCard(
              front: Container(
                color: Colors.blue,
                child: const Column(
                  children: [
                    Icon(Icons.image),
                    Text('Image Title'),
                  ],
                ),
              ),
              back: Container(
                color: Colors.red,
                child: const Column(
                  children: [
                    Text('Details'),
                    Text('More Info'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.image), findsOneWidget);
      expect(find.text('Image Title'), findsOneWidget);
    });

    testWidgets('animation completes after 500ms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlipCard(
              front: Text('Front Side'),
              back: Text('Back Side'),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.touch);
      final center = tester.getCenter(find.byType(FlipCard));

      // Double tap to start flip
      await gesture.down(center);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.down(center);
      await gesture.up();

      // Pump for 500ms (full animation duration)
      await tester.pump(const Duration(milliseconds: 500));

      // Animation should be complete
      expect(find.text('Back Side'), findsOneWidget);
    });

    testWidgets('ignores double taps during animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlipCard(
              front: Text('Front Side'),
              back: Text('Back Side'),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.touch);
      final center = tester.getCenter(find.byType(FlipCard));

      // First double tap to start flip
      await gesture.down(center);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.down(center);
      await gesture.up();

      // While animating, try to double tap again (should be ignored)
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.down(center);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.down(center);
      await gesture.up();

      // Complete the animation
      await tester.pumpAndSettle();

      // Should still be on back side (mid-animation tap was ignored)
      expect(find.text('Back Side'), findsOneWidget);
    });
  });
}

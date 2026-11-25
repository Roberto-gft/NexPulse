import 'package:flutter_test/flutter_test.dart';
import 'package:nexpulse/main.dart';

void main() {
  testWidgets('Carga inicial de NexPulseApp', (WidgetTester tester) async {
    await tester.pumpWidget(const NexPulseApp());
  });
}
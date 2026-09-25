import 'package:flutter_test/flutter_test.dart';

import 'package:hunter_app/main.dart';

void main() {
  testWidgets('Awakening screen shows the SYSTEM entry', (tester) async {
    await tester.pumpWidget(const HunterApp());
    await tester.pumpAndSettle();

    expect(find.text('SYSTEM INITIALIZATION'), findsOneWidget);
    expect(find.text('ACCEPT AWAKENING'), findsOneWidget);
  });
}

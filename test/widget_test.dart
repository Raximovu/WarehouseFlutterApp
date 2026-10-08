import 'package:flutter_test/flutter_test.dart';
import 'package:grand_polimer_plast/main.dart';

void main() {
  testWidgets('Counter increment smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GrandPolimerPlastApp());
    expect(find.text('GrandPolimerPlast'), findsWidgets);
  });
}

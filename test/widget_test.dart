import 'package:flutter_test/flutter_test.dart';
import 'package:food_deilvery/main.dart';

void main() {
  testWidgets('Food delivery app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodDeliveryApp());
    expect(find.text('Order & Eat.'), findsOneWidget);
  });
}

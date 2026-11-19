import 'package:flutter_test/flutter_test.dart';
import 'package:chain_todo_app/main.dart';

void main() {
  testWidgets('Aplikasi dapat dibangun', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Logbook Lab IoT (Sepolia)'), findsOneWidget);
  });
}
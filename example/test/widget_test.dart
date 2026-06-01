import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update_me_example/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('In-App Update Example'), findsOneWidget);
  });
}

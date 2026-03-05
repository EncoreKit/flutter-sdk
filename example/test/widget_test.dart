import 'package:flutter_test/flutter_test.dart';
import 'package:encore_flutter_sdk_example/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Encore Flutter Example'), findsOneWidget);
  });
}

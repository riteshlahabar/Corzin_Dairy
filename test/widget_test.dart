import 'package:dairycorzin/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(localeCode: 'en'));
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}

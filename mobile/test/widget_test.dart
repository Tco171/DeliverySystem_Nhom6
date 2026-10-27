import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/pages/home_page.dart';

void main() {
  testWidgets('Express app loads home page', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpressApp());

    expect(find.byType(HomePage), findsOneWidget);
  });
}

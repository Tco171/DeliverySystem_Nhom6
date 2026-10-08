import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/pages/login_page.dart';

void main() {
  testWidgets(
    'Express app loads login page',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ExpressApp());

      expect(find.byType(LoginPage), findsOneWidget);
    },
  );
}
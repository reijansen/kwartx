import 'package:flutter_test/flutter_test.dart';
import 'package:kwartx/main.dart';

void main() {
  testWidgets('shows splash screen on launch', (tester) async {
    await tester.pumpWidget(const KwartXApp());

    expect(find.text('KwartX'), findsOneWidget);
    expect(
      find.text('Split expenses simply with the people around you.'),
      findsOneWidget,
    );
  });
}

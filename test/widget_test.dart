import 'package:flutter_test/flutter_test.dart';
import 'package:kwartx/main.dart';

void main() {
  testWidgets('renders KwartX placeholder', (tester) async {
    await tester.pumpWidget(const KwartXApp());

    expect(find.text('KwartX'), findsOneWidget);
  });
}

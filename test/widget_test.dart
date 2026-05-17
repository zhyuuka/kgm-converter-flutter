import 'package:flutter_test/flutter_test.dart';

import 'package:kgm_converter/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KgmConverterApp());
    expect(find.text('KGM 转换器'), findsOneWidget);
  });
}

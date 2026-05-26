import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aurcm_route/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AurcmRouteApp());
    expect(find.byType(MaterialApp), findsNothing);
  });
}

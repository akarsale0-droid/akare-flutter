import 'package:flutter_test/flutter_test.dart';

import 'package:aqarat_flutter/main.dart';

void main() {
  testWidgets('shows the guest property browsing state', (tester) async {
    await tester.pumpWidget(const AqaratApp());
    expect(find.text('العقارات'), findsOneWidget);
    expect(find.text('ربط Supabase مؤجل'), findsOneWidget);
  });
}

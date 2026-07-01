import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:s_aku/main.dart';
import 'package:s_aku/providers/transaction_provider.dart';

void main() {
  testWidgets('App renders correctly and finds S-AKU', (WidgetTester tester) async {
    // Initialize localization formatting for test context
    await initializeDateFormatting('id_ID', null);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TransactionProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that our app renders and has brand title.
    expect(find.text('S-AKU'), findsAtLeastNWidgets(1));
  });
}

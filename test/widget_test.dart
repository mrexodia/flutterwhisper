import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwhisper/main.dart';
import 'package:flutterwhisper/models/settings.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    final settings = WhisperSettings();
    await tester.pumpWidget(WhisperApp(settings: settings));
    expect(find.byType(WhisperApp), findsOneWidget);
  });
}

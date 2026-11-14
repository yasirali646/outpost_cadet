import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outpost_cadet/main.dart';
import 'package:outpost_cadet/services/oc_audio.dart';
import 'package:outpost_cadet/services/progress_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows Outpost Cadet title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    OcAudio.silenceForTests = true;
    await OcAudio.bootstrap(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const OutpostCadetApp(),
      ),
    );
    // Avoid pumpAndSettle — repeating UI tickers / route listeners can hang.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('CADET'), findsWidgets);
    expect(find.textContaining('START MISSION'), findsOneWidget);
    expect(find.text('CADET TRAINING'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('MISSIONS'), findsOneWidget);
  });
}

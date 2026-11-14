import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outpost_cadet/core/router/app_router.dart';
import 'package:outpost_cadet/core/theme/app_theme.dart';
import 'package:outpost_cadet/services/oc_audio.dart';
import 'package:outpost_cadet/services/progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await OcAudio.bootstrap(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const OutpostCadetApp(),
    ),
  );
}

class OutpostCadetApp extends StatefulWidget {
  const OutpostCadetApp({super.key});

  @override
  State<OutpostCadetApp> createState() => _OutpostCadetAppState();
}

class _OutpostCadetAppState extends State<OutpostCadetApp> {
  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_syncBedForRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBedForRoute());
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_syncBedForRoute);
    super.dispose();
  }

  void _syncBedForRoute() {
    final path = appRouter.state.uri.path;
    if (path == '/dashboard') {
      OcAudio.instance.startIntroBed(volume: 0.36);
    } else if (path == '/debrief') {
      OcAudio.instance.startDebriefBed(volume: 0.30);
    } else {
      OcAudio.instance.stopBed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Outpost Cadet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}

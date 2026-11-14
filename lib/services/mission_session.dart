import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outpost_cadet/data/content_catalog.dart';
import 'package:outpost_cadet/game/sim_engine.dart';
import 'package:outpost_cadet/models/models.dart';
import 'package:outpost_cadet/services/nasa_weather.dart';

final contentCatalogProvider = FutureProvider<ContentCatalog>((ref) {
  return ContentCatalog.load();
});

final simEngineProvider = Provider<SimEngine?>((ref) {
  final catalog = ref.watch(contentCatalogProvider).valueOrNull;
  if (catalog == null) return null;
  return SimEngine(modules: catalog.modules, events: catalog.events);
});

class MissionSession extends StateNotifier<MissionState?> {
  MissionSession(this._ref) : super(null);

  final Ref _ref;

  SimEngine get _engine {
    final e = _ref.read(simEngineProvider);
    if (e == null) {
      throw StateError('SimEngine not ready');
    }
    return e;
  }

  void startMission(MissionDef mission, {SpaceWeatherBrief? weather}) {
    final w = weather;
    state = _engine.startBuild(
      mission,
      weatherTier: w?.tier.name ?? 'active',
      weatherHeadline: w?.headline,
      weatherIsLive: w?.isLive ?? false,
      radiationEventBias: w?.radiationEventBias ?? 0,
      radiationIntensity: w?.radiationIntensity ?? 1,
    );
  }

  void placeModule(String id, {int? cell}) {
    final s = state;
    if (s == null) return;
    state = _engine.placeModule(s, id, cell: cell);
  }

  void clearCell(int cell) {
    final s = state;
    if (s == null) return;
    state = _engine.clearCell(s, cell);
  }

  void addModule(String id) {
    final s = state;
    if (s == null) return;
    state = _engine.addModule(s, id);
  }

  void removeModule(String id) {
    final s = state;
    if (s == null) return;
    state = _engine.removeModule(s, id);
  }

  void beginRun() {
    final s = state;
    if (s == null) return;
    state = _engine.beginRun(s);
  }

  void advanceSol() {
    final s = state;
    if (s == null) return;
    state = _engine.advanceSol(s);
  }

  void resolveChoice(String choiceId) {
    final s = state;
    if (s == null) return;
    state = _engine.resolveChoice(s, choiceId);
  }

  void clearLastEvent() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(clearLastEvent: true);
  }

  void reset() => state = null;

  int starsEarned() {
    final s = state;
    if (s == null) return 0;
    return _engine.starsEarned(s);
  }

  DebriefReport? report() {
    final s = state;
    if (s == null) return null;
    return _engine.buildReport(s);
  }
}

final missionSessionProvider =
    StateNotifierProvider<MissionSession, MissionState?>((ref) {
  return MissionSession(ref);
});

/// Selected module palette id while building.
final selectedModuleProvider = StateProvider<String?>((ref) => 'solar');

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressState {
  const ProgressState({
    required this.totalStars,
    required this.unlockedFactIds,
    required this.completedMissionIds,
    required this.onboardingDone,
    required this.bestStarsByMission,
  });

  final int totalStars;
  final List<String> unlockedFactIds;
  final List<String> completedMissionIds;
  final bool onboardingDone;
  final Map<String, int> bestStarsByMission;

  ProgressState copyWith({
    int? totalStars,
    List<String>? unlockedFactIds,
    List<String>? completedMissionIds,
    bool? onboardingDone,
    Map<String, int>? bestStarsByMission,
  }) {
    return ProgressState(
      totalStars: totalStars ?? this.totalStars,
      unlockedFactIds: unlockedFactIds ?? this.unlockedFactIds,
      completedMissionIds: completedMissionIds ?? this.completedMissionIds,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      bestStarsByMission: bestStarsByMission ?? this.bestStarsByMission,
    );
  }
}

class ProgressController extends StateNotifier<ProgressState> {
  ProgressController(this._prefs)
      : super(
          ProgressState(
            totalStars: _prefs.getInt(_starsKey) ?? 0,
            unlockedFactIds: _prefs.getStringList(_factsKey) ?? const [],
            completedMissionIds: _prefs.getStringList(_missionsKey) ?? const [],
            onboardingDone: _prefs.getBool(_onboardKey) ?? false,
            bestStarsByMission: _decodeBest(_prefs.getString(_bestKey)),
          ),
        );

  final SharedPreferences _prefs;

  static const _starsKey = 'total_stars';
  static const _factsKey = 'unlocked_facts';
  static const _missionsKey = 'completed_missions';
  static const _onboardKey = 'onboarding_done';
  static const _bestKey = 'best_stars';

  static Map<String, int> _decodeBest(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final map = <String, int>{};
    for (final part in raw.split('|')) {
      if (part.isEmpty) continue;
      final bits = part.split(':');
      if (bits.length == 2) {
        map[bits[0]] = int.tryParse(bits[1]) ?? 0;
      }
    }
    return map;
  }

  static String _encodeBest(Map<String, int> map) =>
      map.entries.map((e) => '${e.key}:${e.value}').join('|');

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardKey, true);
    state = state.copyWith(onboardingDone: true);
  }

  Future<void> recordWin({
    required String missionId,
    required int stars,
    required List<String> factIds,
  }) async {
    final best = Map<String, int>.from(state.bestStarsByMission);
    final prev = best[missionId] ?? 0;
    final gained = stars > prev ? stars - prev : 0;
    if (stars > prev) best[missionId] = stars;

    final facts = {...state.unlockedFactIds, ...factIds}.toList()..sort();
    final completed = {...state.completedMissionIds, missionId}.toList()
      ..sort();
    final total = state.totalStars + gained;

    await _prefs.setInt(_starsKey, total);
    await _prefs.setStringList(_factsKey, facts);
    await _prefs.setStringList(_missionsKey, completed);
    await _prefs.setString(_bestKey, _encodeBest(best));

    state = state.copyWith(
      totalStars: total,
      unlockedFactIds: facts,
      completedMissionIds: completed,
      bestStarsByMission: best,
    );
  }

  Future<void> unlockFacts(List<String> factIds) async {
    final facts = {...state.unlockedFactIds, ...factIds}.toList()..sort();
    await _prefs.setStringList(_factsKey, facts);
    state = state.copyWith(unlockedFactIds: facts);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main()');
});

final progressControllerProvider =
    StateNotifierProvider<ProgressController, ProgressState>((ref) {
  return ProgressController(ref.watch(sharedPreferencesProvider));
});

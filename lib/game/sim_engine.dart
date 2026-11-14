import 'dart:math';

import 'package:outpost_cadet/models/models.dart';

/// Pure Dart turn-based Mars outpost simulation.
class SimEngine {
  SimEngine({
    required this.modules,
    required this.events,
    Random? random,
  }) : _random = random ?? Random();

  final List<OutpostModule> modules;
  final List<MissionEventDef> events;
  final Random _random;

  static const baseLifeDrain = 4.0;
  static const baseFoodDrain = 3.5;
  static const baseRadiationRise = 3.0;
  static const basePowerDrain = 2.0;

  Map<String, OutpostModule> get _byId => {
        for (final m in modules) m.id: m,
      };

  MissionEventDef? _eventById(String id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<String?> _emptyGrid() => List<String?>.filled(OutpostGrid.cellCount, null);

  MissionState startBuild(
    MissionDef mission, {
    String weatherTier = 'active',
    String? weatherHeadline,
    bool weatherIsLive = false,
    double radiationEventBias = 0,
    double radiationIntensity = 1,
  }) {
    final grid = _emptyGrid();
    grid[OutpostGrid.habitatCell] = 'habitat';
    return MissionState(
      mission: mission,
      placements: grid,
      meters: const ResourceMeters(
        lifeSupport: 85,
        radiation: 15,
        power: 70,
        food: 80,
      ),
      sol: 0,
      phase: MissionPhase.building,
      weatherTier: weatherTier,
      weatherHeadline: weatherHeadline,
      weatherIsLive: weatherIsLive,
      radiationEventBias: radiationEventBias,
      radiationIntensity: radiationIntensity,
    );
  }

  int usedMass(Map<String, int> counts) {
    var total = 0;
    counts.forEach((id, n) {
      total += (_byId[id]?.mass ?? 0) * n;
    });
    return total;
  }

  int usedPowerDraw(Map<String, int> counts) {
    var total = 0;
    counts.forEach((id, n) {
      total += (_byId[id]?.powerDraw ?? 0) * n;
    });
    return total;
  }

  bool canAffordCounts(MissionState state, Map<String, int> next) {
    return usedMass(next) <= state.mission.massBudget &&
        usedPowerDraw(next) <= state.mission.powerBudget;
  }

  bool canPlace(MissionState state, String moduleId, int cell) {
    if (state.phase != MissionPhase.building) return false;
    if (cell < 0 || cell >= OutpostGrid.cellCount) return false;
    if (cell == OutpostGrid.habitatCell) return false;
    if (state.placements[cell] != null) return false;
    final mod = _byId[moduleId];
    if (mod == null || mod.required) return false;
    final count = state.moduleCounts[moduleId] ?? 0;
    if (count >= mod.maxCount) return false;
    final next = Map<String, int>.from(state.moduleCounts);
    next[moduleId] = count + 1;
    return canAffordCounts(state, next);
  }

  /// Places [moduleId] on [cell], or first free affordable cell if cell is null.
  MissionState placeModule(MissionState state, String moduleId, {int? cell}) {
    if (state.phase != MissionPhase.building) return state;
    final target = cell ?? _firstFreeCell(state, moduleId);
    if (target == null) return state;
    if (!canPlace(state, moduleId, target)) return state;
    final next = List<String?>.from(state.placements);
    next[target] = moduleId;
    return state.copyWith(
      placements: next,
      layoutBonusNotes: _layoutNotes(next),
    );
  }

  int? _firstFreeCell(MissionState state, String moduleId) {
    for (var i = 0; i < OutpostGrid.cellCount; i++) {
      if (canPlace(state, moduleId, i)) return i;
    }
    return null;
  }

  MissionState clearCell(MissionState state, int cell) {
    if (state.phase != MissionPhase.building) return state;
    if (cell == OutpostGrid.habitatCell) return state;
    if (state.placements[cell] == null) return state;
    final next = List<String?>.from(state.placements);
    next[cell] = null;
    return state.copyWith(
      placements: next,
      layoutBonusNotes: _layoutNotes(next),
    );
  }

  /// Backward-compatible helper used by tests / quick add.
  MissionState addModule(MissionState state, String moduleId) =>
      placeModule(state, moduleId);

  MissionState removeModule(MissionState state, String moduleId) {
    if (state.phase != MissionPhase.building) return state;
    if (moduleId == 'habitat') return state;
    final idx = state.placements.lastIndexWhere((id) => id == moduleId);
    if (idx < 0) return state;
    return clearCell(state, idx);
  }

  bool canAfford(MissionState state, String moduleId) =>
      _firstFreeCell(state, moduleId) != null;

  List<String> _layoutNotes(List<String?> placements) {
    final notes = <String>[];
    final habitatNeighbors = OutpostGrid.neighbors(OutpostGrid.habitatCell);
    var shieldAdj = 0;
    for (final n in habitatNeighbors) {
      if (placements[n] == 'shield') shieldAdj++;
    }
    if (shieldAdj > 0) {
      notes.add('Shield beside habitat (+radiation protection)');
    }

    for (var i = 0; i < placements.length; i++) {
      if (placements[i] != 'greenhouse') continue;
      for (final n in OutpostGrid.neighbors(i)) {
        if (placements[n] == 'recycler') {
          notes.add('Greenhouse beside recycler (+food)');
          break;
        }
      }
    }

    var edgeSolar = 0;
    for (var i = 0; i < placements.length; i++) {
      if (placements[i] == 'solar' && OutpostGrid.isEdge(i)) edgeSolar++;
    }
    if (edgeSolar > 0) {
      notes.add('Solar on the rim (+power from clear sky)');
    }
    return notes;
  }

  AggregatedEffects aggregate(List<String?> placements) {
    final counts = <String, int>{};
    for (final id in placements) {
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }

    var life = 0.0;
    var food = 0.0;
    var powerGen = 0.0;
    var radiation = 0.0;
    var radCap = 100.0;
    var powerCap = 100.0;
    var bonusStars = 0;
    var glitchResist = false;

    counts.forEach((id, n) {
      final m = _byId[id];
      if (m == null) return;
      life += m.effects.lifeSupportPerSol * n;
      food += m.effects.foodPerSol * n;
      powerGen += m.effects.powerPerSol * n;
      radiation += m.effects.radiationPerSol * n;
      radCap += m.effects.radiationCapBonus * n;
      powerCap += m.effects.powerCapBonus * n;
      bonusStars += m.effects.bonusStars * n;
      if (m.effects.glitchResist) glitchResist = true;
    });

    // Layout bonuses
    final habitatNeighbors = OutpostGrid.neighbors(OutpostGrid.habitatCell);
    for (final n in habitatNeighbors) {
      if (placements[n] == 'shield') {
        radiation -= 0.9;
      }
    }
    for (var i = 0; i < placements.length; i++) {
      if (placements[i] != 'greenhouse') continue;
      for (final n in OutpostGrid.neighbors(i)) {
        if (placements[n] == 'recycler') {
          food += 0.8;
          break;
        }
      }
    }
    for (var i = 0; i < placements.length; i++) {
      if (placements[i] == 'solar' && OutpostGrid.isEdge(i)) {
        powerGen += 0.6;
      }
    }

    return AggregatedEffects(
      lifeSupportPerSol: life,
      foodPerSol: food,
      powerPerSol: powerGen,
      radiationPerSol: radiation,
      radiationCap: radCap,
      powerCap: powerCap,
      bonusStars: bonusStars,
      glitchResist: glitchResist,
      layoutBonusCount: _layoutNotes(placements).length,
    );
  }

  /// Aggregate from counts only (tests without layout care) — places virtually.
  AggregatedEffects aggregateCounts(Map<String, int> counts) {
    final grid = _emptyGrid();
    grid[OutpostGrid.habitatCell] = 'habitat';
    var cursor = 0;
    counts.forEach((id, n) {
      if (id == 'habitat') return;
      for (var i = 0; i < n; i++) {
        while (cursor < OutpostGrid.cellCount &&
            (cursor == OutpostGrid.habitatCell || grid[cursor] != null)) {
          cursor++;
        }
        if (cursor < OutpostGrid.cellCount) {
          grid[cursor] = id;
          cursor++;
        }
      }
    });
    return aggregate(grid);
  }

  MissionState beginRun(MissionState state) {
    if (state.phase != MissionPhase.building) return state;
    if ((state.moduleCounts['habitat'] ?? 0) < 1) return state;
    final agg = aggregate(state.placements);
    return state.copyWith(
      phase: MissionPhase.running,
      sol: 0,
      meters: state.meters.copyWith(
        radiationCap: agg.radiationCap,
        powerCap: agg.powerCap,
        power: state.meters.power.clamp(0, agg.powerCap),
      ),
      clearWarning: true,
      clearActiveEvent: true,
      clearPendingEvent: true,
      awaitingChoice: false,
      layoutBonusNotes: _layoutNotes(state.placements),
    );
  }

  /// Advance one sol, or open a choice event without advancing.
  MissionState advanceSol(MissionState state) {
    if (state.phase != MissionPhase.running) return state;
    if (state.awaitingChoice) return state;

    var active = state.activeEvent;
    final facts = List<String>.from(state.unlockedFactIds);
    MissionEventDef? justStarted;

    if (active != null) {
      final left = active.solsRemaining - 1;
      active = left <= 0
          ? null
          : ActiveEvent(
              def: active.def,
              solsRemaining: left,
              multipliers: active.multipliers,
              choiceId: active.choiceId,
            );
    } else {
      final forcedId = state.mission.forcedEvents[state.sol + 1];
      MissionEventDef? candidate;
      if (forcedId != null) {
        candidate = _eventById(forcedId);
      } else {
        final chance = (0.35 + state.radiationEventBias).clamp(0.15, 0.65);
        if (_random.nextDouble() < chance && events.isNotEmpty) {
          candidate = _pickEvent(state);
          final agg = aggregate(state.placements);
          if (candidate.id == 'glitch' &&
              agg.glitchResist &&
              _random.nextBool()) {
            candidate = events.firstWhere(
              (e) => e.id != 'glitch',
              orElse: () => candidate!,
            );
          }
        }
      }

      if (candidate != null) {
        if (!facts.contains(candidate.factId)) {
          facts.add(candidate.factId);
        }
        justStarted = candidate;
        if (candidate.hasChoices) {
          return state.copyWith(
            pendingEvent: candidate,
            awaitingChoice: true,
            unlockedFactIds: facts,
            lastEvent: candidate,
          );
        }
        active = ActiveEvent(
          def: candidate,
          solsRemaining: candidate.durationSols,
          multipliers: candidate.multipliers,
        );
      }
    }

    return _tickSol(
      state,
      active: active,
      facts: facts,
      justStarted: justStarted,
    );
  }

  /// Player picks a response to [state.pendingEvent], then the sol ticks.
  MissionState resolveChoice(MissionState state, String choiceId) {
    if (!state.awaitingChoice || state.pendingEvent == null) return state;
    final event = state.pendingEvent!;
    final choice = event.choices.firstWhere(
      (c) => c.id == choiceId,
      orElse: () => event.choices.first,
    );

    var meters = state.meters;
    meters = meters.copyWith(
      lifeSupport: (meters.lifeSupport + choice.instant.lifeSupport)
          .clamp(0.0, meters.lifeCap),
      radiation: (meters.radiation + choice.instant.radiation)
          .clamp(0.0, meters.radiationCap),
      power: (meters.power + choice.instant.power).clamp(0.0, meters.powerCap),
      food: (meters.food + choice.instant.food).clamp(0.0, meters.foodCap),
    );

    final active = ActiveEvent(
      def: event,
      solsRemaining: event.durationSols,
      multipliers: choice.multipliers,
      choiceId: choice.id,
    );

    final withChoice = state.copyWith(
      meters: meters,
      activeEvent: active,
      clearPendingEvent: true,
      awaitingChoice: false,
      goodChoices: state.goodChoices + (choice.recommended ? 1 : 0),
      totalChoices: state.totalChoices + 1,
      clearLastEvent: true,
    );

    return _tickSol(
      withChoice,
      active: active,
      facts: List<String>.from(state.unlockedFactIds),
    );
  }

  /// Prefer body-appropriate + weather-weighted events for replay variety.
  MissionEventDef _pickEvent(MissionState state) {
    final pool = <MissionEventDef>[];
    for (final e in events) {
      var w = 1;
      if (state.mission.isMoon) {
        if (e.id == 'lunar_dust' || e.id == 'solar_flare') w += 3;
        if (e.id == 'dust_storm') w = 0; // Mars-only flavor
      } else {
        if (e.id == 'dust_storm' || e.id == 'solar_flare') w += 2;
        if (e.id == 'lunar_dust') w = 0;
      }
      if (e.id == 'solar_flare' || e.id == 'comms_delay') {
        if (state.weatherTier == 'storm') w += 3;
        if (state.weatherTier == 'active') w += 1;
      }
      if (e.id == 'comms_delay' && state.mission.isMars) w += 2;
      for (var i = 0; i < w; i++) {
        pool.add(e);
      }
    }
    if (pool.isEmpty) return events[_random.nextInt(events.length)];
    return pool[_random.nextInt(pool.length)];
  }

  MissionState _tickSol(
    MissionState state, {
    required ActiveEvent? active,
    required List<String> facts,
    MissionEventDef? justStarted,
  }) {
    final mult = active?.multipliers ?? EventMultipliers.identity;
    final agg = aggregate(state.placements);
    final counts = state.moduleCounts;

    final lifeDelta =
        -baseLifeDrain + agg.lifeSupportPerSol * mult.lifeSupport;
    final foodDelta = -baseFoodDrain + agg.foodPerSol * mult.food;
    final powerDelta = -basePowerDrain -
        usedPowerDraw(counts) * 0.35 +
        agg.powerPerSol * mult.powerFromSolar;
    final radDelta = (baseRadiationRise + agg.radiationPerSol * mult.radiation) *
        state.radiationIntensity;

    var life =
        (state.meters.lifeSupport + lifeDelta).clamp(0.0, state.meters.lifeCap);
    var food =
        (state.meters.food + foodDelta).clamp(0.0, state.meters.foodCap);
    var power = (state.meters.power + powerDelta).clamp(0.0, agg.powerCap);
    var rad =
        (state.meters.radiation + radDelta).clamp(0.0, agg.radiationCap);

    if (power < 15) {
      life = (life - 2).clamp(0.0, state.meters.lifeCap);
      food = (food - 1.5).clamp(0.0, state.meters.foodCap);
    }

    final meters = ResourceMeters(
      lifeSupport: life.toDouble(),
      radiation: rad.toDouble(),
      power: power.toDouble(),
      food: food.toDouble(),
      radiationCap: agg.radiationCap,
      powerCap: agg.powerCap,
    );

    final nextSol = state.sol + 1;
    String? warning;
    if (meters.anySoftWarning && !meters.isHardFail) {
      if (meters.lifeCritical) {
        warning = 'Life support is low — add recyclers next time!';
      } else if (meters.foodCritical) {
        warning = 'Food is running out — greenhouses help.';
      } else if (meters.powerCritical) {
        warning = 'Power is critical — solar + batteries matter.';
      } else if (meters.radiationCritical) {
        warning = 'Radiation is high — you need more shielding.';
      }
    }

    if (meters.isHardFail) {
      if (!facts.contains('fact_tradeoff')) facts.add('fact_tradeoff');
      return state.copyWith(
        sol: nextSol,
        meters: meters,
        phase: MissionPhase.lost,
        failReason: _failReason(meters),
        activeEvent: active,
        clearActiveEvent: active == null,
        warning: warning,
        unlockedFactIds: facts,
        lastEvent: justStarted,
      );
    }

    if (nextSol >= state.mission.sols) {
      if (!facts.contains('fact_mission')) facts.add('fact_mission');
      if (!facts.contains('fact_tradeoff')) facts.add('fact_tradeoff');
      return state.copyWith(
        sol: nextSol,
        meters: meters,
        phase: MissionPhase.won,
        activeEvent: active,
        clearActiveEvent: active == null,
        clearWarning: true,
        unlockedFactIds: facts,
        lastEvent: justStarted,
      );
    }

    return state.copyWith(
      sol: nextSol,
      meters: meters,
      activeEvent: active,
      clearActiveEvent: active == null,
      warning: warning,
      clearWarning: warning == null,
      unlockedFactIds: facts,
      lastEvent: justStarted,
      clearLastEvent: justStarted == null,
    );
  }

  int starsEarned(MissionState state) {
    if (state.phase != MissionPhase.won) return 0;
    final bonus = aggregate(state.placements).bonusStars;
    final report = buildReport(state);
    // Extra star for excellent score on longer missions
    final excel = report.totalScore >= 85 && state.mission.sols >= 20 ? 1 : 0;
    return state.mission.starsOnWin + bonus + excel;
  }

  DebriefReport buildReport(MissionState state) {
    final won = state.phase == MissionPhase.won;
    final agg = aggregate(state.placements);
    final lines = <ScoreLine>[];
    final tips = <String>[];

    final survival = won
        ? 40
        : ((state.sol / state.mission.sols) * 25).round().clamp(0, 25);
    lines.add(ScoreLine(
      label: won ? 'Survived full mission' : 'Survived ${state.sol} sols',
      points: survival,
    ));

    final margin = won
        ? ((state.meters.lifeSupport +
                    state.meters.food +
                    state.meters.power +
                    (state.meters.radiationCap - state.meters.radiation)) /
                4 /
                100 *
                25)
            .round()
            .clamp(0, 25)
        : 0;
    lines.add(ScoreLine(label: 'Resource margin', points: margin));

    final layout = (agg.layoutBonusCount * 8).clamp(0, 16);
    lines.add(ScoreLine(label: 'Smart layout bonuses', points: layout));

    final decisions = state.totalChoices == 0
        ? (won ? 10 : 0)
        : ((state.goodChoices / state.totalChoices) * 19)
            .round()
            .clamp(0, 19);
    lines.add(ScoreLine(label: 'Event decisions', points: decisions));

    final total =
        lines.fold<int>(0, (a, b) => a + b.points).clamp(0, 100);

    if ((state.moduleCounts['shield'] ?? 0) == 0) {
      tips.add('Next time: place a Regolith Shield next to the habitat.');
    } else if (!state.layoutBonusNotes
        .any((n) => n.toLowerCase().contains('shield'))) {
      tips.add('Move shields beside the habitat for extra protection.');
    }
    if ((state.moduleCounts['solar'] ?? 0) < 2) {
      tips.add('Next time: bring at least two Solar Arrays for dust storms.');
    }
    if ((state.moduleCounts['greenhouse'] ?? 0) == 0) {
      tips.add('Next time: add a Greenhouse — food drains every sol.');
    } else if (!state.layoutBonusNotes
        .any((n) => n.toLowerCase().contains('greenhouse'))) {
      tips.add('Place Greenhouse next to the Water Recycler for bonus food.');
    }
    if ((state.moduleCounts['battery'] ?? 0) == 0) {
      tips.add('Batteries store power for nights and dust storms.');
    }
    if (state.totalChoices > 0 &&
        state.goodChoices < state.totalChoices) {
      tips.add(
        'On flares, send the crew to the shielded habitat. On dust, lean on batteries.',
      );
    }
    if (tips.isEmpty) {
      tips.add(
        won
            ? 'Excellent engineering — try a longer stay for more stars.'
            : 'Rebuild with stronger life support and shielding, then try again.',
      );
    }

    final stars = won
        ? state.mission.starsOnWin +
            agg.bonusStars +
            (total >= 85 && state.mission.sols >= 20 ? 1 : 0)
        : 0;

    return DebriefReport(
      totalScore: total,
      stars: stars,
      lines: lines,
      tips: tips.take(3).toList(),
      won: won,
    );
  }

  String _failReason(ResourceMeters m) {
    if (m.lifeSupport <= 0) {
      return 'Life support hit zero. Recyclers and habitat keep the crew breathing.';
    }
    if (m.food <= 0) {
      return 'The crew ran out of food. Greenhouses trade mass and power for meals.';
    }
    if (m.power <= 0) {
      return 'The outpost went dark. Solar arrays and batteries keep systems online.';
    }
    return 'Radiation got too high. Regolith shields protect the crew from solar storms.';
  }
}

class AggregatedEffects {
  const AggregatedEffects({
    required this.lifeSupportPerSol,
    required this.foodPerSol,
    required this.powerPerSol,
    required this.radiationPerSol,
    required this.radiationCap,
    required this.powerCap,
    required this.bonusStars,
    required this.glitchResist,
    this.layoutBonusCount = 0,
  });

  final double lifeSupportPerSol;
  final double foodPerSol;
  final double powerPerSol;
  final double radiationPerSol;
  final double radiationCap;
  final double powerCap;
  final int bonusStars;
  final bool glitchResist;
  final int layoutBonusCount;
}

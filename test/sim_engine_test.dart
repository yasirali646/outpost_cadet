import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:outpost_cadet/game/sim_engine.dart';
import 'package:outpost_cadet/models/models.dart';

OutpostModule _mod({
  required String id,
  int mass = 4,
  int powerDraw = 2,
  double life = 0,
  double food = 0,
  double power = 0,
  double rad = 0,
  bool required = false,
  int maxCount = 3,
  bool glitchResist = false,
  int bonusStars = 0,
  double powerCapBonus = 0,
  double radCapBonus = 0,
}) {
  return OutpostModule(
    id: id,
    name: id,
    icon: 'home',
    description: id,
    mass: mass,
    powerDraw: powerDraw,
    required: required,
    maxCount: maxCount,
    effects: ModuleEffects(
      lifeSupportPerSol: life,
      foodPerSol: food,
      powerPerSol: power,
      radiationPerSol: rad,
      glitchResist: glitchResist,
      bonusStars: bonusStars,
      powerCapBonus: powerCapBonus,
      radiationCapBonus: radCapBonus,
    ),
  );
}

void main() {
  final modules = [
    _mod(id: 'habitat', required: true, maxCount: 1, life: 1.5, mass: 6),
    _mod(id: 'solar', power: 5, powerDraw: 0, mass: 4, maxCount: 4),
    _mod(id: 'battery', powerCapBonus: 20, powerDraw: 0, mass: 3),
    _mod(id: 'recycler', life: 4, powerDraw: 3, mass: 5),
    _mod(id: 'greenhouse', food: 4, life: 0.5, powerDraw: 3, mass: 5),
    _mod(id: 'shield', rad: -3, radCapBonus: 10, powerDraw: 0, mass: 6),
    _mod(id: 'lab', bonusStars: 1, mass: 4),
    _mod(id: 'spares', glitchResist: true, mass: 2, powerDraw: 0),
  ];

  final flare = MissionEventDef(
    id: 'solar_flare',
    name: 'Flare',
    description: 'flare',
    durationSols: 2,
    multipliers: const EventMultipliers(
      powerFromSolar: 1,
      food: 1,
      lifeSupport: 1,
      radiation: 2.2,
    ),
    tone: 'danger',
    factId: 'fact_flare',
    choices: const [
      EventChoice(
        id: 'shelter',
        label: 'Shelter',
        blurb: 'safe',
        recommended: true,
        multipliers: EventMultipliers(
          powerFromSolar: 1,
          food: 0.9,
          lifeSupport: 1,
          radiation: 1.15,
        ),
        instant: InstantDelta(power: -8, radiation: -6),
      ),
      EventChoice(
        id: 'keep_working',
        label: 'Work',
        blurb: 'risky',
        recommended: false,
        multipliers: EventMultipliers(
          powerFromSolar: 1.1,
          food: 1,
          lifeSupport: 1,
          radiation: 2.5,
        ),
        instant: InstantDelta(),
      ),
    ],
  );

  final mission = const MissionDef(
    id: 'short',
    title: 'Short',
    description: 'test',
    sols: 10,
    massBudget: 40,
    powerBudget: 25,
    starsOnWin: 1,
  );

  test('startBuild places habitat at center', () {
    final engine = SimEngine(modules: modules, events: [flare], random: Random(1));
    final state = engine.startBuild(mission);
    expect(state.placements[OutpostGrid.habitatCell], 'habitat');
    expect(state.moduleCounts['habitat'], 1);
    expect(state.phase, MissionPhase.building);
  });

  test('mass budget blocks extra modules', () {
    final engine = SimEngine(modules: modules, events: [flare], random: Random(1));
    var state = engine.startBuild(
      const MissionDef(
        id: 'tiny',
        title: 'Tiny',
        description: 't',
        sols: 5,
        massBudget: 6,
        powerBudget: 20,
        starsOnWin: 1,
      ),
    );
    expect(engine.canAfford(state, 'solar'), isFalse);
    state = engine.addModule(state, 'solar');
    expect(state.moduleCounts['solar'] ?? 0, 0);
  });

  test('balanced outpost can win short mission', () {
    final engine = SimEngine(
      modules: modules,
      events: const [],
      random: Random(42),
    );
    var state = engine.startBuild(mission);
    state = engine.addModule(state, 'solar');
    state = engine.addModule(state, 'solar');
    state = engine.addModule(state, 'battery');
    state = engine.addModule(state, 'recycler');
    state = engine.addModule(state, 'greenhouse');
    state = engine.addModule(state, 'shield');
    state = engine.beginRun(state);
    expect(state.phase, MissionPhase.running);

    for (var i = 0; i < 20 && state.phase == MissionPhase.running; i++) {
      state = engine.advanceSol(state);
      if (state.awaitingChoice) {
        state = engine.resolveChoice(state, state.pendingEvent!.choices.first.id);
      }
    }
    expect(state.phase, MissionPhase.won);
    expect(engine.starsEarned(state), greaterThanOrEqualTo(1));
  });

  test('underbuilt outpost fails', () {
    final engine = SimEngine(
      modules: modules,
      events: const [],
      random: Random(7),
    );
    final longMission = const MissionDef(
      id: 'long',
      title: 'Long',
      description: 'test',
      sols: 30,
      massBudget: 40,
      powerBudget: 25,
      starsOnWin: 3,
    );
    var state = engine.startBuild(longMission);
    state = engine.beginRun(state);
    for (var i = 0; i < 40 && state.phase == MissionPhase.running; i++) {
      state = engine.advanceSol(state);
    }
    expect(state.phase, MissionPhase.lost);
    expect(state.failReason, isNotNull);
  });

  test('lab adds bonus stars on win', () {
    final engine = SimEngine(
      modules: modules,
      events: const [],
      random: Random(3),
    );
    var state = engine.startBuild(mission);
    for (final id in [
      'solar',
      'solar',
      'battery',
      'recycler',
      'greenhouse',
      'shield',
      'lab',
    ]) {
      state = engine.addModule(state, id);
    }
    state = engine.beginRun(state);
    for (var i = 0; i < 20 && state.phase == MissionPhase.running; i++) {
      state = engine.advanceSol(state);
    }
    expect(state.phase, MissionPhase.won);
    expect(engine.starsEarned(state), 2);
  });

  test('event choice is required and affects score', () {
    final engine = SimEngine(
      modules: modules,
      events: [flare],
      random: Random(1),
    );
    final tutorial = MissionDef(
      id: 'tutorial',
      title: 'Train',
      description: 't',
      sols: 6,
      massBudget: 40,
      powerBudget: 25,
      starsOnWin: 1,
      isTutorial: true,
      forcedEvents: const {1: 'solar_flare'},
    );
    var state = engine.startBuild(tutorial);
    for (final id in [
      'solar',
      'solar',
      'battery',
      'recycler',
      'greenhouse',
      'shield',
    ]) {
      state = engine.addModule(state, id);
    }
    // Place shield beside habitat for layout bonus
    state = engine.clearCell(state, state.placements.indexOf('shield'));
    state = engine.placeModule(state, 'shield', cell: 1);
    state = engine.beginRun(state);

    state = engine.advanceSol(state);
    expect(state.awaitingChoice, isTrue);
    expect(state.pendingEvent?.id, 'solar_flare');

    state = engine.resolveChoice(state, 'shelter');
    expect(state.awaitingChoice, isFalse);
    expect(state.goodChoices, 1);
    expect(state.totalChoices, 1);
    expect(state.sol, 1);

    final report = engine.buildReport(
      state.copyWith(phase: MissionPhase.won, sol: tutorial.sols),
    );
    expect(report.tips, isNotEmpty);
    expect(report.totalScore, greaterThan(0));
  });

  test('shield beside habitat creates layout note', () {
    final engine = SimEngine(modules: modules, events: const [], random: Random(1));
    var state = engine.startBuild(mission);
    state = engine.placeModule(state, 'shield', cell: 1); // above habitat
    expect(state.layoutBonusNotes.any((n) => n.contains('Shield')), isTrue);
    final agg = engine.aggregate(state.placements);
    expect(agg.layoutBonusCount, greaterThan(0));
  });
}

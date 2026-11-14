class ModuleEffects {
  const ModuleEffects({
    required this.lifeSupportPerSol,
    required this.foodPerSol,
    required this.powerPerSol,
    required this.radiationPerSol,
    this.radiationCapBonus = 0,
    this.powerCapBonus = 0,
    this.bonusStars = 0,
    this.glitchResist = false,
  });

  final double lifeSupportPerSol;
  final double foodPerSol;
  final double powerPerSol;
  final double radiationPerSol;
  final double radiationCapBonus;
  final double powerCapBonus;
  final int bonusStars;
  final bool glitchResist;

  factory ModuleEffects.fromJson(Map<String, dynamic> json) {
    return ModuleEffects(
      lifeSupportPerSol: (json['lifeSupportPerSol'] as num?)?.toDouble() ?? 0,
      foodPerSol: (json['foodPerSol'] as num?)?.toDouble() ?? 0,
      powerPerSol: (json['powerPerSol'] as num?)?.toDouble() ?? 0,
      radiationPerSol: (json['radiationPerSol'] as num?)?.toDouble() ?? 0,
      radiationCapBonus: (json['radiationCapBonus'] as num?)?.toDouble() ?? 0,
      powerCapBonus: (json['powerCapBonus'] as num?)?.toDouble() ?? 0,
      bonusStars: (json['bonusStars'] as num?)?.toInt() ?? 0,
      glitchResist: json['glitchResist'] as bool? ?? false,
    );
  }
}

class OutpostModule {
  const OutpostModule({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.mass,
    required this.powerDraw,
    required this.effects,
    required this.required,
    required this.maxCount,
  });

  final String id;
  final String name;
  final String icon;
  final String description;
  final int mass;
  final int powerDraw;
  final ModuleEffects effects;
  final bool required;
  final int maxCount;

  factory OutpostModule.fromJson(Map<String, dynamic> json) {
    return OutpostModule(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      mass: json['mass'] as int,
      powerDraw: json['powerDraw'] as int,
      effects: ModuleEffects.fromJson(
        Map<String, dynamic>.from(json['effects'] as Map),
      ),
      required: json['required'] as bool? ?? false,
      maxCount: json['maxCount'] as int? ?? 1,
    );
  }
}

class MissionDef {
  const MissionDef({
    required this.id,
    required this.title,
    required this.description,
    required this.sols,
    required this.massBudget,
    required this.powerBudget,
    required this.starsOnWin,
    this.isTutorial = false,
    this.forcedEvents = const {},
    this.coachTip,
    this.body = 'mars',
    this.siteName,
    this.siteNote,
    this.siteSource,
  });

  final String id;
  final String title;
  final String description;
  final int sols;
  final int massBudget;
  final int powerBudget;
  final int starsOnWin;
  final bool isTutorial;
  final Map<int, String> forcedEvents;
  final String? coachTip;

  /// `mars` or `moon`.
  final String body;
  final String? siteName;
  final String? siteNote;
  final String? siteSource;

  bool get isMoon => body.toLowerCase() == 'moon';
  bool get isMars => !isMoon;

  /// One-way Earth radio delay used for the comms-teaching UI.
  Duration get commsDelay =>
      isMoon ? const Duration(seconds: 1) : const Duration(minutes: 20);

  String get bodyLabel => isMoon ? 'Moon' : 'Mars';

  String get dayWord => isMoon ? 'day' : 'sol';

  factory MissionDef.fromJson(Map<String, dynamic> json) {
    final forced = <int, String>{};
    final raw = json['forcedEvents'];
    if (raw is Map) {
      raw.forEach((k, v) {
        forced[int.parse(k.toString())] = v.toString();
      });
    }
    return MissionDef(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      sols: json['sols'] as int,
      massBudget: json['massBudget'] as int,
      powerBudget: json['powerBudget'] as int,
      starsOnWin: json['starsOnWin'] as int,
      isTutorial: json['isTutorial'] as bool? ?? false,
      forcedEvents: forced,
      coachTip: json['coachTip'] as String?,
      body: (json['body'] as String?) ?? 'mars',
      siteName: json['siteName'] as String?,
      siteNote: json['siteNote'] as String?,
      siteSource: json['siteSource'] as String?,
    );
  }
}

class EventMultipliers {
  const EventMultipliers({
    required this.powerFromSolar,
    required this.food,
    required this.lifeSupport,
    required this.radiation,
  });

  final double powerFromSolar;
  final double food;
  final double lifeSupport;
  final double radiation;

  factory EventMultipliers.fromJson(Map<String, dynamic> json) {
    return EventMultipliers(
      powerFromSolar: (json['powerFromSolar'] as num).toDouble(),
      food: (json['food'] as num).toDouble(),
      lifeSupport: (json['lifeSupport'] as num).toDouble(),
      radiation: (json['radiation'] as num).toDouble(),
    );
  }

  static const identity = EventMultipliers(
    powerFromSolar: 1,
    food: 1,
    lifeSupport: 1,
    radiation: 1,
  );
}

class InstantDelta {
  const InstantDelta({
    this.lifeSupport = 0,
    this.radiation = 0,
    this.power = 0,
    this.food = 0,
  });

  final double lifeSupport;
  final double radiation;
  final double power;
  final double food;

  factory InstantDelta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const InstantDelta();
    return InstantDelta(
      lifeSupport: (json['lifeSupport'] as num?)?.toDouble() ?? 0,
      radiation: (json['radiation'] as num?)?.toDouble() ?? 0,
      power: (json['power'] as num?)?.toDouble() ?? 0,
      food: (json['food'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EventChoice {
  const EventChoice({
    required this.id,
    required this.label,
    required this.blurb,
    required this.multipliers,
    required this.instant,
    required this.recommended,
  });

  final String id;
  final String label;
  final String blurb;
  final EventMultipliers multipliers;
  final InstantDelta instant;
  final bool recommended;

  factory EventChoice.fromJson(Map<String, dynamic> json) {
    return EventChoice(
      id: json['id'] as String,
      label: json['label'] as String,
      blurb: json['blurb'] as String,
      multipliers: EventMultipliers.fromJson(
        Map<String, dynamic>.from(json['multipliers'] as Map),
      ),
      instant: InstantDelta.fromJson(
        json['instant'] == null
            ? null
            : Map<String, dynamic>.from(json['instant'] as Map),
      ),
      recommended: json['recommended'] as bool? ?? false,
    );
  }
}

class MissionEventDef {
  const MissionEventDef({
    required this.id,
    required this.name,
    required this.description,
    required this.durationSols,
    required this.multipliers,
    required this.tone,
    required this.factId,
    this.choices = const [],
  });

  final String id;
  final String name;
  final String description;
  final int durationSols;
  final EventMultipliers multipliers;
  final String tone;
  final String factId;
  final List<EventChoice> choices;

  bool get hasChoices => choices.isNotEmpty;

  factory MissionEventDef.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List<dynamic>? ?? const [];
    return MissionEventDef(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      durationSols: json['durationSols'] as int,
      multipliers: EventMultipliers.fromJson(
        Map<String, dynamic>.from(json['multipliers'] as Map),
      ),
      tone: json['tone'] as String,
      factId: json['factId'] as String,
      choices: rawChoices
          .map((e) => EventChoice.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class FactCard {
  const FactCard({
    required this.id,
    required this.title,
    required this.body,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.system,
  });

  final String id;
  final String title;
  final String body;
  final String sourceTitle;
  final String sourceUrl;
  final String system;

  factory FactCard.fromJson(Map<String, dynamic> json) {
    return FactCard(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      sourceTitle: json['sourceTitle'] as String,
      sourceUrl: json['sourceUrl'] as String,
      system: json['system'] as String,
    );
  }
}

class ResourceMeters {
  const ResourceMeters({
    required this.lifeSupport,
    required this.radiation,
    required this.power,
    required this.food,
    this.lifeCap = 100,
    this.radiationCap = 100,
    this.powerCap = 100,
    this.foodCap = 100,
  });

  final double lifeSupport;
  final double radiation;
  final double power;
  final double food;
  final double lifeCap;
  final double radiationCap;
  final double powerCap;
  final double foodCap;

  ResourceMeters copyWith({
    double? lifeSupport,
    double? radiation,
    double? power,
    double? food,
    double? lifeCap,
    double? radiationCap,
    double? powerCap,
    double? foodCap,
  }) {
    return ResourceMeters(
      lifeSupport: lifeSupport ?? this.lifeSupport,
      radiation: radiation ?? this.radiation,
      power: power ?? this.power,
      food: food ?? this.food,
      lifeCap: lifeCap ?? this.lifeCap,
      radiationCap: radiationCap ?? this.radiationCap,
      powerCap: powerCap ?? this.powerCap,
      foodCap: foodCap ?? this.foodCap,
    );
  }

  bool get lifeCritical => lifeSupport < 25;
  bool get foodCritical => food < 25;
  bool get powerCritical => power < 20;
  bool get radiationCritical => radiation > 75;

  bool get anySoftWarning =>
      lifeCritical || foodCritical || powerCritical || radiationCritical;

  bool get isHardFail =>
      lifeSupport <= 0 || food <= 0 || power <= 0 || radiation >= radiationCap;
}

enum MissionPhase { building, running, won, lost }

/// 3x3 outpost grid. Cell 4 (center) is reserved for habitat.
class OutpostGrid {
  static const size = 3;
  static const cellCount = 9;
  static const habitatCell = 4;

  static int row(int cell) => cell ~/ size;
  static int col(int cell) => cell % size;

  static bool isEdge(int cell) =>
      row(cell) == 0 || row(cell) == 2 || col(cell) == 0 || col(cell) == 2;

  static List<int> neighbors(int cell) {
    final r = row(cell);
    final c = col(cell);
    final out = <int>[];
    for (final d in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
      final nr = r + d.$1;
      final nc = c + d.$2;
      if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
        out.add(nr * size + nc);
      }
    }
    return out;
  }
}

class ActiveEvent {
  const ActiveEvent({
    required this.def,
    required this.solsRemaining,
    required this.multipliers,
    this.choiceId,
  });

  final MissionEventDef def;
  final int solsRemaining;
  final EventMultipliers multipliers;
  final String? choiceId;
}

class MissionState {
  const MissionState({
    required this.mission,
    required this.placements,
    required this.meters,
    required this.sol,
    required this.phase,
    this.activeEvent,
    this.pendingEvent,
    this.awaitingChoice = false,
    this.failReason,
    this.warning,
    this.unlockedFactIds = const [],
    this.lastEvent,
    this.goodChoices = 0,
    this.totalChoices = 0,
    this.layoutBonusNotes = const [],
    this.weatherTier = 'active',
    this.weatherHeadline,
    this.weatherIsLive = false,
    this.radiationEventBias = 0,
    this.radiationIntensity = 1,
  });

  final MissionDef mission;

  /// cell index -> module id (null = empty). Length always 9.
  final List<String?> placements;
  final ResourceMeters meters;
  final int sol;
  final MissionPhase phase;
  final ActiveEvent? activeEvent;
  final MissionEventDef? pendingEvent;
  final bool awaitingChoice;
  final String? failReason;
  final String? warning;
  final List<String> unlockedFactIds;
  final MissionEventDef? lastEvent;
  final int goodChoices;
  final int totalChoices;
  final List<String> layoutBonusNotes;

  /// From NASA DONKI brief: quiet | active | storm
  final String weatherTier;
  final String? weatherHeadline;
  final bool weatherIsLive;
  final double radiationEventBias;
  final double radiationIntensity;

  Map<String, int> get moduleCounts {
    final counts = <String, int>{};
    for (final id in placements) {
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  MissionState copyWith({
    MissionDef? mission,
    List<String?>? placements,
    ResourceMeters? meters,
    int? sol,
    MissionPhase? phase,
    ActiveEvent? activeEvent,
    MissionEventDef? pendingEvent,
    bool? awaitingChoice,
    String? failReason,
    String? warning,
    List<String>? unlockedFactIds,
    MissionEventDef? lastEvent,
    int? goodChoices,
    int? totalChoices,
    List<String>? layoutBonusNotes,
    String? weatherTier,
    String? weatherHeadline,
    bool? weatherIsLive,
    double? radiationEventBias,
    double? radiationIntensity,
    bool clearActiveEvent = false,
    bool clearPendingEvent = false,
    bool clearWarning = false,
    bool clearLastEvent = false,
  }) {
    return MissionState(
      mission: mission ?? this.mission,
      placements: placements ?? this.placements,
      meters: meters ?? this.meters,
      sol: sol ?? this.sol,
      phase: phase ?? this.phase,
      activeEvent: clearActiveEvent ? null : (activeEvent ?? this.activeEvent),
      pendingEvent:
          clearPendingEvent ? null : (pendingEvent ?? this.pendingEvent),
      awaitingChoice: awaitingChoice ?? this.awaitingChoice,
      failReason: failReason ?? this.failReason,
      warning: clearWarning ? null : (warning ?? this.warning),
      unlockedFactIds: unlockedFactIds ?? this.unlockedFactIds,
      lastEvent: clearLastEvent ? null : (lastEvent ?? this.lastEvent),
      goodChoices: goodChoices ?? this.goodChoices,
      totalChoices: totalChoices ?? this.totalChoices,
      layoutBonusNotes: layoutBonusNotes ?? this.layoutBonusNotes,
      weatherTier: weatherTier ?? this.weatherTier,
      weatherHeadline: weatherHeadline ?? this.weatherHeadline,
      weatherIsLive: weatherIsLive ?? this.weatherIsLive,
      radiationEventBias: radiationEventBias ?? this.radiationEventBias,
      radiationIntensity: radiationIntensity ?? this.radiationIntensity,
    );
  }
}

class ScoreLine {
  const ScoreLine({required this.label, required this.points});

  final String label;
  final int points;
}

class DebriefReport {
  const DebriefReport({
    required this.totalScore,
    required this.stars,
    required this.lines,
    required this.tips,
    required this.won,
  });

  final int totalScore;
  final int stars;
  final List<ScoreLine> lines;
  final List<String> tips;
  final bool won;
}

/// Central paths for generated Outpost Cadet art.
abstract final class OcAssets {
  // Backgrounds
  static const marsBg = 'assets/images/mars_bg_dusk.png';
  static const marsBgBrief = 'assets/images/mars_bg_brief.png';
  static const marsBgBuild = 'assets/images/mars_bg_build.png';
  static const marsBgRun = 'assets/images/mars_bg_run.png';
  static const marsBgDebrief = 'assets/images/mars_bg_debrief.png';

  // Brand
  static const emblem = 'assets/brand/emblem.png';
  static const shieldStar = 'assets/brand/shield_star.png';
  static const appIcon = 'assets/brand/app_icon.png';
  static const logoLockup = 'assets/brand/logo_lockup.png';
  static const titleLockup = 'assets/brand/title_lockup.png';
  static const avatarCadet = 'assets/brand/avatar_cadet.png';
  static const avatarCadetBrief = 'assets/brand/avatar_cadet_brief.png';
  static const avatarBuildCadet = 'assets/brand/avatar_build_cadet.png';
  static const avatarCoach = 'assets/brand/avatar_coach.png';

  // UI
  static const rocket = 'assets/icons/ui/rocket.png';
  static const trophy = 'assets/icons/ui/trophy.png';
  static const marsDusk = 'assets/icons/brief/mars_dusk.png';

  // Debrief / mission success
  static const debriefTrophy = 'assets/icons/debrief/trophy.png';
  static const debriefShield = 'assets/icons/debrief/shield.png';
  static const debriefCrate = 'assets/icons/debrief/crate.png';
  static const debriefClipboard = 'assets/icons/debrief/clipboard.png';
  static const debriefBars = 'assets/icons/debrief/bars.png';
  static const debriefStar = 'assets/icons/debrief/star.png';
  static const debriefLightbulb = 'assets/icons/debrief/lightbulb.png';
  static const debriefDroplet = 'assets/icons/debrief/droplet.png';
  static const debriefPeople = 'assets/icons/debrief/people.png';
  static const debriefGear = 'assets/icons/debrief/gear.png';
  static const debriefStarsRow = 'assets/icons/debrief/stars_row.png';

  // Build screen chrome
  static const buildMass = 'assets/icons/build/mass_weight.png';
  static const buildPower = 'assets/icons/build/power_bolt.png';
  static const buildBonus = 'assets/icons/build/bonus_check.png';
  static const buildLock = 'assets/icons/build/lock.png';
  static const buildHelp = 'assets/icons/build/help.png';
  static const buildBack = 'assets/icons/build/back.png';
  static const launchRocket = 'assets/icons/build/launch_rocket.png';

  // Resources (run meters)
  static const life = 'assets/icons/resources/life.png';
  static const shieldRes = 'assets/icons/resources/shield.png';
  static const power = 'assets/icons/resources/power.png';
  static const food = 'assets/icons/resources/food.png';

  // Run mission chrome
  static const runMenu = 'assets/icons/run/menu.png';
  static const runPin = 'assets/icons/run/pin.png';
  static const runWarning = 'assets/icons/run/warning.png';
  static const runHelp = 'assets/icons/run/help.png';
  static const runCompass = 'assets/icons/run/compass.png';
  static const runHome = 'assets/icons/run/home.png';
  static const runGear = 'assets/icons/run/gear.png';
  static const runDroplet = 'assets/icons/run/droplet.png';
  static const runMedCross = 'assets/icons/run/med_cross.png';

  // Status (brief cards)
  static const mass = 'assets/icons/status/mass.png';
  static const powerStatus = 'assets/icons/status/power.png';
  static const target = 'assets/icons/status/target.png';
  static const book = 'assets/icons/status/book.png';

  // Missions
  static const missionTraining = 'assets/icons/missions/training.png';
  static const missionScout = 'assets/icons/missions/scout.png';
  static const missionOutpost = 'assets/icons/missions/outpost.png';
  static const missionLongStay = 'assets/icons/missions/longstay.png';

  // Nav
  static const navHome = 'assets/icons/nav/home.png';
  static const navRocket = 'assets/icons/nav/rocket.png';
  static const navJournal = 'assets/icons/nav/journal.png';
  static const navProgress = 'assets/icons/nav/progress.png';
  static const navCadet = 'assets/icons/nav/cadet.png';

  static String module(String id) => 'assets/icons/modules/$id.png';

  static String palette(String id) => 'assets/icons/palette/$id.png';

  /// Build-grid tile art (Mars soil square + isometric module).
  static String tile(String id) => 'assets/icons/tiles/$id.png';

  static const tileEmpty = 'assets/icons/tiles/empty.png';

  /// Run-screen facility preview renders.
  static String facility(String id) => 'assets/icons/facilities/$id.png';

  static String facilityGlyph(String id) => 'assets/icons/run/glyph_$id.png';

  static const facilityIds = [
    'habitat',
    'greenhouse',
    'workshop',
    'power_plant',
    'airlock',
    'storage',
    'water_recycler',
    'med_bay',
    'command',
  ];

  static String missionIcon(String missionId) {
    return switch (missionId) {
      'tutorial' => missionTraining,
      'lunar_dust' => missionScout,
      'artemis_scout' => missionTraining,
      'short' => missionScout,
      'standard' => missionOutpost,
      'long' => missionLongStay,
      _ => missionScout,
    };
  }

  static const moduleIds = [
    'habitat',
    'solar',
    'battery',
    'recycler',
    'greenhouse',
    'shield',
    'lab',
    'spares',
  ];

  // --- v2 walkable world (A pixel + C NASA iso mix) ---
  static const worldCadetDown = 'assets/world_2d/cadet/cadet_down.png';
  static const worldCadetLeft = 'assets/world_2d/cadet/cadet_left.png';
  static const worldCadetRight = 'assets/world_2d/cadet/cadet_right.png';
  static const worldCadetUp = 'assets/world_2d/cadet/cadet_up.png';

  static const worldCadetFacings = ['down', 'left', 'right', 'up'];
  static const worldCadetWalkFrames = 4;

  static String worldCadet(String facing) => switch (facing) {
        'left' => worldCadetLeft,
        'right' => worldCadetRight,
        'up' => worldCadetUp,
        _ => worldCadetDown,
      };

  /// Walk cycle frame: `cadet_{facing}_{0..3}.png` (0 = idle / plant feet).
  static String worldCadetFrame(String facing, int frame) {
    final f = facing == 'left' || facing == 'right' || facing == 'up'
        ? facing
        : 'down';
    final i = frame.clamp(0, worldCadetWalkFrames - 1);
    return 'assets/world_2d/cadet/cadet_${f}_$i.png';
  }

  static String worldTile(String id) => 'assets/world_2d/tiles/$id.png';

  static String worldBuilding(String id) => 'assets/world_2d/buildings/$id.png';

  /// Map build-module / facility ids → world building art.
  static String worldBuildingForModule(String? moduleId) {
    return switch (moduleId) {
      'habitat' => worldBuilding('habitat'),
      'greenhouse' => worldBuilding('greenhouse'),
      'solar' => worldBuilding('solar'),
      'battery' => worldBuilding('battery'),
      'recycler' => worldBuilding('recycler'),
      'shield' => worldBuilding('shield'),
      'lab' => worldBuilding('lab'),
      'spares' => worldBuilding('storage'),
      _ => worldBuilding('command'),
    };
  }

  static String worldProp(String id) => 'assets/world_2d/props/$id.png';

  /// Horizon mountain range (north rim).
  static const worldMountainRange =
      'assets/world_2d/mountains/mars_mountains_range.png';

  static const worldTileIds = [
    'regolith',
    'path',
    'crater_soil',
    'rocky',
    'gravel',
    'dune',
    'grate',
    'pad',
    'footprint',
    // Option C — Mix Path
    'road_pad',
    'road_pad_dust',
    'road_pad_round',
    'road_dirt_h',
    'road_dirt_v',
    'road_dirt_corner',
    'road_dirt_t',
    'road_dirt_cross',
    'road_transition',
  ];

  static const worldBuildingIds = [
    'habitat',
    'greenhouse',
    'solar',
    'battery',
    'recycler',
    'shield',
    'lab',
    'storage',
    'command',
  ];

  static const worldPropIds = [
    'fence_h',
    'fence_corner',
    'rocks',
    'crater',
    'crate',
    'beacon',
    'rover',
    'scrub',
    'cone',
  ];
}

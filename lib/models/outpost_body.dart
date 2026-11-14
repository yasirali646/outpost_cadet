/// Target world for a mission (Moon or Mars).
enum OutpostBody { moon, mars }

extension OutpostBodyX on OutpostBody {
  String get id => name;

  String get label => this == OutpostBody.moon ? 'Moon' : 'Mars';

  /// Kid-friendly one-way radio delay.
  Duration get commsDelay => this == OutpostBody.moon
      ? const Duration(seconds: 1)
      : const Duration(minutes: 20);

  String get commsKidLabel => this == OutpostBody.moon
      ? 'Radio delay ~1 second (almost instant)'
      : 'Radio delay ~20 minutes (Earth is far!)';

  String get dayWord => this == OutpostBody.moon ? 'day' : 'sol';

  static OutpostBody fromId(String? raw) {
    if (raw == null) return OutpostBody.mars;
    switch (raw.toLowerCase()) {
      case 'moon':
      case 'lunar':
        return OutpostBody.moon;
      default:
        return OutpostBody.mars;
    }
  }
}

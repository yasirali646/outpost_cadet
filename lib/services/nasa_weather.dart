import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Space-weather risk from real DONKI solar flares (live or cached).
enum SpaceWeatherTier { quiet, active, storm }

class DonkiFlare {
  const DonkiFlare({
    required this.id,
    required this.classType,
    required this.beginTime,
    this.peakTime,
    this.sourceLocation,
    this.link,
  });

  final String id;
  final String classType;
  final String beginTime;
  final String? peakTime;
  final String? sourceLocation;
  final String? link;

  factory DonkiFlare.fromJson(Map<String, dynamic> json) {
    return DonkiFlare(
      id: (json['flrID'] ?? json['id'] ?? '').toString(),
      classType: (json['classType'] ?? 'C1.0').toString(),
      beginTime: (json['beginTime'] ?? '').toString(),
      peakTime: json['peakTime']?.toString(),
      sourceLocation: json['sourceLocation']?.toString(),
      link: json['link']?.toString(),
    );
  }

  /// Rough GOES class rank for sorting (X > M > C > B > A).
  double get rank {
    if (classType.isEmpty) return 0;
    final letter = classType[0].toUpperCase();
    final numPart = double.tryParse(classType.substring(1)) ?? 0;
    const base = {'A': 1.0, 'B': 10.0, 'C': 100.0, 'M': 1000.0, 'X': 10000.0};
    return (base[letter] ?? 0) + numPart;
  }

  String get kidLabel {
    final L = classType.isEmpty ? '?' : classType[0].toUpperCase();
    switch (L) {
      case 'X':
        return 'Huge flare ($classType)';
      case 'M':
        return 'Strong flare ($classType)';
      case 'C':
        return 'Medium flare ($classType)';
      default:
        return 'Small flare ($classType)';
    }
  }
}

class SpaceWeatherBrief {
  const SpaceWeatherBrief({
    required this.tier,
    required this.flares,
    required this.asOf,
    required this.isLive,
    required this.sourceLabel,
    required this.sourceUrl,
    required this.headline,
  });

  final SpaceWeatherTier tier;
  final List<DonkiFlare> flares;
  final DateTime asOf;
  final bool isLive;
  final String sourceLabel;
  final String sourceUrl;
  final String headline;

  String get tierLabel {
    switch (tier) {
      case SpaceWeatherTier.quiet:
        return 'Quiet Sun';
      case SpaceWeatherTier.active:
        return 'Active Sun';
      case SpaceWeatherTier.storm:
        return 'Storm Watch';
    }
  }

  String get kidBlurb {
    switch (tier) {
      case SpaceWeatherTier.quiet:
        return 'The Sun is calm. Radiation risk is lower — still keep your shield ready.';
      case SpaceWeatherTier.active:
        return 'The Sun is busy. Flares can raise radiation — plan shielding carefully.';
      case SpaceWeatherTier.storm:
        return 'Big flares spotted in NASA data. Shelter choices will matter more.';
    }
  }

  /// Extra chance of radiation-pressure events (0–0.35).
  double get radiationEventBias {
    switch (tier) {
      case SpaceWeatherTier.quiet:
        return -0.08;
      case SpaceWeatherTier.active:
        return 0.12;
      case SpaceWeatherTier.storm:
        return 0.28;
    }
  }

  /// Multiplier on radiation event pressure.
  double get radiationIntensity {
    switch (tier) {
      case SpaceWeatherTier.quiet:
        return 0.9;
      case SpaceWeatherTier.active:
        return 1.15;
      case SpaceWeatherTier.storm:
        return 1.4;
    }
  }

  String get attributionChip =>
      isLive ? 'Live NASA DONKI' : 'Cached NASA DONKI · ${_ymd(asOf)}';

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class NasaWeatherService {
  NasaWeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// From `--dart-define=NASA_API_KEY=...` (never commit the real key).
  static const apiKey = String.fromEnvironment('NASA_API_KEY');

  static const snapshotAsset = 'assets/data/nasa_donki_snapshot.json';
  static const donkiDocUrl = 'https://ccmc.gsfc.nasa.gov/tools/DONKI/';

  Future<SpaceWeatherBrief> load({int lookbackDays = 7}) async {
    final end = DateTime.now().toUtc();
    final start = end.subtract(Duration(days: lookbackDays));
    final startStr = SpaceWeatherBrief._ymd(start);
    final endStr = SpaceWeatherBrief._ymd(end);

    // 1) api.nasa.gov with key (if provided)
    if (apiKey.isNotEmpty) {
      final live = await _tryFetch(
        Uri.parse(
          'https://api.nasa.gov/DONKI/FLR'
          '?startDate=$startStr&endDate=$endStr&api_key=$apiKey',
        ),
        isLive: true,
        sourceLabel: 'NASA Open API · DONKI FLR',
        asOf: end,
      );
      if (live != null) return live;
    }

    // 2) CCMC direct (no key) — same catalog
    final ccmc = await _tryFetch(
      Uri.parse(
        'https://ccmc.gsfc.nasa.gov/DONKI/WS/get/FLR'
        '?startDate=$startStr&endDate=$endStr',
      ),
      isLive: true,
      sourceLabel: 'CCMC DONKI · FLR',
      asOf: end,
    );
    if (ccmc != null) return ccmc;

    // 3) Bundled real snapshot (honest offline)
    return _loadSnapshot();
  }

  Future<SpaceWeatherBrief?> _tryFetch(
    Uri uri, {
    required bool isLive,
    required String sourceLabel,
    required DateTime asOf,
  }) async {
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! List) return null;
      final flares = decoded
          .whereType<Map>()
          .map((e) => DonkiFlare.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return _briefFromFlares(
        flares,
        asOf: asOf,
        isLive: isLive,
        sourceLabel: sourceLabel,
      );
    } catch (_) {
      return null;
    }
  }

  Future<SpaceWeatherBrief> _loadSnapshot() async {
    final raw = await rootBundle.loadString(snapshotAsset);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final flares = (map['flares'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => DonkiFlare.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final asOf = DateTime.tryParse(map['asOf']?.toString() ?? '') ??
        DateTime.utc(2024, 5, 14);
    return _briefFromFlares(
      flares,
      asOf: asOf,
      isLive: false,
      sourceLabel: map['source']?.toString() ?? 'Cached DONKI snapshot',
      sourceUrl: map['sourceUrl']?.toString() ?? donkiDocUrl,
    );
  }

  SpaceWeatherBrief _briefFromFlares(
    List<DonkiFlare> flares, {
    required DateTime asOf,
    required bool isLive,
    required String sourceLabel,
    String sourceUrl = donkiDocUrl,
  }) {
    final sorted = [...flares]..sort((a, b) => b.rank.compareTo(a.rank));
    final top = sorted.isEmpty ? null : sorted.first;
    final tier = _tierFor(sorted);
    final headline = top == null
        ? 'No flares in this window'
        : 'Biggest recent: ${top.classType}';
    return SpaceWeatherBrief(
      tier: tier,
      flares: sorted.take(12).toList(),
      asOf: asOf,
      isLive: isLive,
      sourceLabel: sourceLabel,
      sourceUrl: sourceUrl,
      headline: headline,
    );
  }

  SpaceWeatherTier _tierFor(List<DonkiFlare> flares) {
    if (flares.isEmpty) return SpaceWeatherTier.quiet;
    final top = flares.first.rank;
    final xCount = flares.where((f) => f.classType.startsWith('X')).length;
    final mCount = flares.where((f) => f.classType.startsWith('M')).length;
    if (xCount >= 1 || top >= 10000 || mCount >= 6) {
      return SpaceWeatherTier.storm;
    }
    if (mCount >= 1 || top >= 1000) return SpaceWeatherTier.active;
    return SpaceWeatherTier.quiet;
  }
}

final nasaWeatherServiceProvider = Provider<NasaWeatherService>((ref) {
  return NasaWeatherService();
});

final spaceWeatherProvider = FutureProvider<SpaceWeatherBrief>((ref) {
  return ref.watch(nasaWeatherServiceProvider).load();
});

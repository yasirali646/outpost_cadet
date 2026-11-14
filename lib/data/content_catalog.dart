import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:outpost_cadet/models/models.dart';

class ContentCatalog {
  ContentCatalog({
    required this.missions,
    required this.modules,
    required this.events,
    required this.facts,
  });

  final List<MissionDef> missions;
  final List<OutpostModule> modules;
  final List<MissionEventDef> events;
  final List<FactCard> facts;

  OutpostModule moduleById(String id) =>
      modules.firstWhere((m) => m.id == id);

  FactCard? factById(String id) {
    for (final f in facts) {
      if (f.id == id) return f;
    }
    return null;
  }

  MissionDef missionById(String id) =>
      missions.firstWhere((m) => m.id == id);

  static Future<ContentCatalog> load() async {
    Future<List<dynamic>> loadList(String path) async {
      final raw = await rootBundle.loadString(path);
      return jsonDecode(raw) as List<dynamic>;
    }

    final missionsJson = await loadList('assets/data/missions.json');
    final modulesJson = await loadList('assets/data/modules.json');
    final eventsJson = await loadList('assets/data/events.json');
    final factsJson = await loadList('assets/data/facts.json');

    return ContentCatalog(
      missions: missionsJson
          .map((e) => MissionDef.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      modules: modulesJson
          .map(
            (e) => OutpostModule.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      events: eventsJson
          .map(
            (e) =>
                MissionEventDef.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      facts: factsJson
          .map((e) => FactCard.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mars SFX + dusk ambience.
///
/// Short effects use [AudioPool] (preloaded + resume) so they start with the
/// tap — no create-player delay.
class OcAudio {
  OcAudio._(this._prefs)
      : muted = ValueNotifier<bool>(_prefs.getBool(_muteKey) ?? false);

  static const _muteKey = 'audio_muted';

  /// Widget tests: skip real playback so pumpAndSettle can finish.
  static var silenceForTests = false;

  static late OcAudio instance;

  final SharedPreferences _prefs;
  final ValueNotifier<bool> muted;

  AudioPlayer? _bed;
  final Map<String, AudioPool> _pools = {};
  var _ready = false;

  static const placeAsset = 'audio/sfx_place.wav';
  static const removeAsset = 'audio/sfx_remove.wav';
  static const tapAsset = 'audio/sfx_tap.wav';
  static const solAsset = 'audio/sfx_sol.wav';
  static const warnAsset = 'audio/sfx_warn.wav';
  static const successAsset = 'audio/sfx_mission_success.wav';
  static const failAsset = 'audio/sfx_fail.wav';
  static const choiceAsset = 'audio/sfx_choice.wav';
  static const emptyAsset = 'audio/sfx_empty.wav';

  static const _allSfx = [
    placeAsset,
    removeAsset,
    tapAsset,
    solAsset,
    warnAsset,
    successAsset,
    failAsset,
    choiceAsset,
    emptyAsset,
  ];

  static Future<void> bootstrap(SharedPreferences prefs) async {
    instance = OcAudio._(prefs);
    if (silenceForTests) {
      instance._ready = true;
      return;
    }
    await instance._configure();
    await instance._preloadPools();
    instance._ready = true;
  }

  Future<void> _configure() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
          ),
        ),
      );
    } catch (e) {
      debugPrint('OcAudio configure failed: $e');
    }
  }

  Future<void> _preloadPools() async {
    for (final path in _allSfx) {
      try {
        _pools[path] = await AudioPool.createFromAsset(
          path: path,
          maxPlayers: 3,
          minPlayers: 1,
          playerMode: PlayerMode.mediaPlayer,
        );
      } catch (e) {
        debugPrint('OcAudio pool failed ($path): $e');
      }
    }
  }

  bool get isMuted => muted.value;

  Future<void> setMuted(bool value) async {
    muted.value = value;
    await _prefs.setBool(_muteKey, value);
    if (value) {
      await stopBed();
    }
  }

  Future<void> toggleMuted() => setMuted(!isMuted);

  void _play(String asset, {double volume = 1.0}) {
    if (!_ready || isMuted || silenceForTests) return;
    final pool = _pools[asset];
    if (pool == null) {
      debugPrint('OcAudio missing pool: $asset');
      // Last-resort one-shot so something still plays.
      unawaited(() async {
        try {
          final p = AudioPlayer();
          await p.play(AssetSource(asset), volume: volume);
          p.onPlayerComplete.listen((_) => p.dispose());
        } catch (e) {
          debugPrint('OcAudio one-shot failed ($asset): $e');
        }
      }());
      return;
    }
    unawaited(
      pool.start(volume: volume).catchError((Object e) {
        debugPrint('OcAudio start failed ($asset): $e');
        return () async {};
      }),
    );
  }

  void tap() => _play(tapAsset, volume: 0.8);
  void sol() => _play(solAsset, volume: 0.9);
  void warn() => _play(warnAsset, volume: 1.0);
  void success() => _play(successAsset, volume: 1.0);
  void fail() => _play(failAsset, volume: 1.0);
  void choice() => _play(choiceAsset, volume: 0.95);
  void place() => _play(placeAsset, volume: 1.0);
  void remove() => _play(removeAsset, volume: 1.0);
  void empty() => _play(emptyAsset, volume: 1.0);

  Future<void> startBed({
    double volume = 0.32,
    String asset = 'audio/bed_intro.wav',
  }) async {
    if (!_ready || isMuted || silenceForTests) return;
    try {
      await stopBed();
      final player = AudioPlayer();
      _bed = player;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(volume);
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('OcAudio bed failed: $e');
    }
  }

  /// Mars-dusk winds for home / intro.
  Future<void> startIntroBed({double volume = 0.34}) =>
      startBed(volume: volume, asset: 'audio/bed_intro.wav');

  /// Softer bed for debrief (legacy procedural loop).
  Future<void> startDebriefBed({double volume = 0.28}) =>
      startBed(volume: volume, asset: 'audio/bed_mars.wav');

  Future<void> stopBed() async {
    final player = _bed;
    _bed = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopBed();
    for (final pool in _pools.values) {
      try {
        await pool.dispose();
      } catch (_) {}
    }
    _pools.clear();
    muted.dispose();
  }
}

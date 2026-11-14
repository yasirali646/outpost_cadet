import 'package:flutter_test/flutter_test.dart';
import 'package:outpost_cadet/services/nasa_weather.dart';

void main() {
  test('DonkiFlare rank orders X above M above C', () {
    const x = DonkiFlare(
      id: 'x',
      classType: 'X1.0',
      beginTime: '2024-05-01T00:00Z',
    );
    const m = DonkiFlare(
      id: 'm',
      classType: 'M5.0',
      beginTime: '2024-05-01T00:00Z',
    );
    const c = DonkiFlare(
      id: 'c',
      classType: 'C9.9',
      beginTime: '2024-05-01T00:00Z',
    );
    expect(x.rank, greaterThan(m.rank));
    expect(m.rank, greaterThan(c.rank));
  });

  test('tier biases are ordered', () {
    final asOf = DateTime.utc(2024, 5, 14);
    SpaceWeatherBrief brief(SpaceWeatherTier t) => SpaceWeatherBrief(
          tier: t,
          flares: const [],
          asOf: asOf,
          isLive: false,
          sourceLabel: 'test',
          sourceUrl: 'https://example.com',
          headline: 'h',
        );
    expect(
      brief(SpaceWeatherTier.storm).radiationIntensity,
      greaterThan(brief(SpaceWeatherTier.active).radiationIntensity),
    );
    expect(
      brief(SpaceWeatherTier.active).radiationEventBias,
      greaterThan(brief(SpaceWeatherTier.quiet).radiationEventBias),
    );
    expect(brief(SpaceWeatherTier.storm).attributionChip, contains('Cached'));
  });
}

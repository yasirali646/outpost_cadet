# Outpost Cadet

Junior astronaut mission trainer for the **NASA Space Apps Challenge 2026** — *Build a Junior Astronaut Mission Trainer*.

Kids (ages **7–12**) run a **Moon or Mars** outpost, balancing **life support, radiation shielding, power, and food**. Events force real trade-offs. Space-weather risk can come from **NASA DONKI**. Debriefs unlock NASA / CSA fact cards.

## Run

```bash
flutter pub get
./tool/run_with_nasa.sh run
# or: flutter run --dart-define=NASA_API_KEY=YOUR_KEY
flutter run -d chrome
./tool/run_with_nasa.sh build apk --release
```

Release APK: `build/app/outputs/flutter-apk/app-release.apk` (also `OutpostCadet-SpaceApps.apk`).

## Features

- Moon and Mars missions with site blurbs
- DONKI space-weather banner (live or dated cache)
- 3×3 build + walkable Flame world
- Costly event choices + comms delay teaching
- Meters: LIFE · SHIELD · POWER · FOOD

## Stack

Flutter · Riverpod · go_router · Flame · http · shared_preferences · audioplayers
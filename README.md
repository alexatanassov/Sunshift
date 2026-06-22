# Sunshift

Alarms that move with the sun. Sunshift lets users build routines anchored to solar events - sunrise, solar noon, sunset, twilight - so their schedule shifts naturally with the seasons and their location.

---

## Current Stage: Stage 1 - Solar Calculation Engine

The solar calculation engine is complete. `SunService` computes all solar events on-device for any date, location, and timezone. No network required.

---

## Solar Calculation Engine

All solar math runs on-device with no network dependency. The engine is implemented in `SunService` using NOAA-style formulae from Jean Meeus, "Astronomical Algorithms" (2nd ed.).

### Inputs (`SunCalculationInput`)

| Parameter | Type | Notes |
|---|---|---|
| `date` | `Date` | Local date and time; interpreted in the given timezone |
| `latitude` | `Double` | Degrees north/south, range -90 to +90 |
| `longitude` | `Double` | Degrees east/west, range -180 to +180 |
| `timeZoneIdentifier` | `String` | IANA timezone string, e.g. `"America/Los_Angeles"` |

### Outputs (`SunSchedule`)

| Field | Type | Notes |
|---|---|---|
| `sunrise` | `Date?` | Sun's upper limb at -0.833 degrees altitude |
| `sunset` | `Date?` | Same, evening crossing |
| `solarNoon` | `Date?` | Sun at peak altitude for the day |
| `goldenHourStart` | `Date?` | Morning: sun reaches +6 degrees altitude |
| `goldenHourEnd` | `Date?` | Evening: sun drops back to +6 degrees |
| `blueHourStart` | `Date?` | Morning: sun at -4 degrees (upper edge of blue hour) |
| `blueHourEnd` | `Date?` | Evening: sun at -4 degrees |
| `firstLight` | `Date?` | Civil dawn: sun at -6 degrees; alias for `civilTwilightStart` |
| `lastLight` | `Date?` | Civil dusk: sun at -6 degrees; alias for `civilTwilightEnd` |
| `daylightDuration` | `TimeInterval?` | Total seconds from sunrise to sunset |
| `daylightRemaining` | `TimeInterval?` | Seconds from `input.date` to sunset; nil after sunset or during polar night |
| `nextEvent` | `SunEvent?` | First event after `input.date` on the current local day |

All returned `Date` values are UTC instants. Events that cannot occur return `nil`.

`SunSchedule` also exposes `orderedEvents` (chronological array of non-nil events), `nextEvent(after:)` (query by arbitrary time), and `daylightRemaining(at:)` (query by arbitrary time) via `SunSchedule+Events.swift`.

### Approximation approach

**Golden hour** is approximated as the window when the sun is between the horizon (-0.833 degrees) and +6 degrees altitude. Morning golden hour runs from sunrise to `goldenHourStart`; evening from `goldenHourEnd` back down to sunset. The +6 degree threshold is a common photographic convention, not a perceptually exact boundary.

**Blue hour** is approximated as the window when the sun is between -4 and -6 degrees altitude (below the geometric horizon). These fixed altitude thresholds are an approximation; actual blue-hour quality varies with atmospheric conditions.

### Known edge cases

**Polar day and polar night:** When the sun never crosses a given altitude threshold, that event is `nil`. Solar noon is always computable and is never `nil`. Tested with Tromsø, Norway (69.6 N).

**Daylight saving time:** The engine uses IANA timezone identifiers and `Foundation.Calendar` for local date extraction. DST transitions are handled transparently by the system.

**Timezone changes:** Each schedule is anchored to the local calendar date in the specified timezone. The same UTC instant in different timezones can fall on different local dates and will produce different schedules. Covered by the timezone safety tests (London vs. Tokyo).

**Events near midnight:** `daylightRemaining` returns `nil` when the current time is after sunset or not on the same local day as sunset. `nextEvent` is scoped to the current local day. For cross-midnight fallback, use `SunService.nextRelevantEvent(after:schedule:input:)`, which recomputes using the following day's schedule.

### Running unit tests only

```bash
xcodebuild test \
  -scheme Sunshift \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing SunshiftTests
```

### Reference locations in tests

| Location | Coordinates | Timezone | Purpose |
|---|---|---|---|
| San Diego | 32.7157 N, 117.1611 W | America/Los_Angeles | Mid-latitude Pacific; summer and winter solstice |
| New York | 40.7128 N, 74.0060 W | America/New_York | East Coast; event ordering, next-event logic |
| Tokyo | 35.6762 N, 139.6503 E | Asia/Tokyo | UTC+9 eastern hemisphere; local-day anchoring |
| Joshua Tree | 34.1347 N, 116.3131 W | America/Los_Angeles | Desert; event ordering |
| Tromsø | 69.6492 N, 18.9553 E | Europe/Oslo | High Arctic; polar day and polar night |

---

## Tech Stack

- **Language:** Swift 6
- **UI:** SwiftUI (Observable macro, no UIKit wrappers)
- **Target:** iOS 26.5+
- **Project management:** Xcode 26.5, `PBXFileSystemSynchronizedRootGroup` - new Swift files dropped into `Sunshift/` are auto-included without editing `project.pbxproj`

---

## Folder Structure

```
Sunshift/
├── App/
│   ├── SunshiftApp.swift          # @main entry point; injects AppState and SubscriptionService
│   └── SunshiftRootView.swift     # Onboarding gate -> MainTabView
├── Core/
│   ├── AppConstants.swift         # App name, tagline
│   └── AppState.swift             # @Observable shared state (onboarding flag, etc.)
├── Design/
│   └── DesignTokens.swift         # SunshiftColors, SunshiftTypography, SunshiftSpacing,
│                                  # SunshiftCornerRadius, SunshiftGradients, cardShadow()
├── Features/
│   ├── Debug/
│   │   └── SolarDebugView.swift   # Dev-only view for inspecting SunSchedule output live
│   ├── Onboarding/
│   │   └── OnboardingView.swift   # Shown on first launch; sets hasCompletedOnboarding
│   ├── Today/
│   │   └── TodayView.swift        # Placeholder - will show today's solar events + active routines
│   ├── Routines/
│   │   └── RoutinesView.swift     # Placeholder - will list and manage light routines
│   ├── Locations/
│   │   └── LocationsView.swift    # Placeholder - will manage saved locations
│   └── Plus/
│       └── PlusView.swift         # Placeholder - subscription upsell / feature gate
├── Models/
│   ├── SunCalculationError.swift  # Error enum: invalidCoordinates, invalidTimeZone, calculationFailed
│   ├── SunCalculationInput.swift  # Input type: date, latitude, longitude, timeZoneIdentifier
│   ├── SunSchedule.swift          # Output type: all computed solar events for one local day
│   ├── SunSchedule+Events.swift   # orderedEvents, nextEvent(after:), daylightRemaining(at:)
│   ├── SunEvent.swift             # Single solar event (type + time)
│   ├── SunEventType.swift         # Enum: sunrise, solarNoon, sunset, goldenHour, twilight...
│   ├── LightRoutine.swift         # User-defined routine anchored to a solar event
│   ├── ReminderOffset.swift       # Offset (+/- minutes) from a solar event
│   ├── SavedLocation.swift        # Named lat/lon the user has pinned
│   ├── WeekdaySelection.swift     # Bitmask-style weekday picker model
│   └── SubscriptionTier.swift     # .free / .plus
├── Services/
│   ├── SunService.swift           # NOAA-style solar position engine; no network required
│   ├── SunService+NextRelevantEvent.swift  # Cross-midnight next-event fallback
│   └── SubscriptionService.swift  # @Observable service wrapping subscription state
├── Storage/
│   └── UserPreferences.swift      # UserDefaults-backed persistence layer
└── Utilities/
    ├── DateExtensions.swift        # Date formatting and local-day comparison helpers
    └── TimeIntervalExtensions.swift # Human-readable duration formatting

Docs/
└── SUNSHIFT_V1_PLAN.md            # Full v1 product plan and stage breakdown

SunshiftTests/
└── SunshiftTests.swift            # Unit tests for SunService and SunSchedule
```

---

## Running the App

1. Open `Sunshift.xcodeproj` in Xcode 26.5 or later.
2. Select the `Sunshift` scheme and a simulator (iPhone 16 family recommended).
3. Press **Cmd+R** to build and run.

No third-party dependencies. No SPM packages. No configuration required.

---

## Implemented in Stage 0

| Area | What's in place |
|---|---|
| App shell | `SunshiftApp`, environment injection (`AppState`, `SubscriptionService`) |
| Navigation | `MainTabView` with four tabs: Today, Routines, Locations, Plus |
| Onboarding gate | `SunshiftRootView` shows `OnboardingView` until `hasCompletedOnboarding` is set |
| Design system | Colors, typography, spacing, corner radius, gradients, `cardShadow()` modifier |
| Domain models | `SunEvent`, `SunEventType`, `LightRoutine`, `ReminderOffset`, `SavedLocation`, `WeekdaySelection`, `SubscriptionTier` |
| Services (stubs) | `SunService` (no-op), `SubscriptionService` (observable tier state) |
| Storage | `UserPreferences` (UserDefaults wrapper) |
| Utilities | `DateExtensions` |
| Constants | `AppConstants` (app name, tagline) |

## Implemented in Stage 1

| Area | What's in place |
|---|---|
| Solar engine | `SunService` computes sunrise, sunset, solar noon, golden hour, blue hour, civil twilight, first/last light on-device |
| Input model | `SunCalculationInput` (date, latitude, longitude, timezone identifier) |
| Output model | `SunSchedule` (all solar events + daylight duration, daylight remaining, next event) |
| Error handling | `SunCalculationError` (invalid coordinates, invalid timezone, calculation failure) |
| Event helpers | `SunSchedule+Events` - `orderedEvents`, `nextEvent(after:)`, `daylightRemaining(at:)` |
| Next-event fallback | `SunService+NextRelevantEvent` - falls back to the next day when today's events are exhausted |
| Debug view | `SolarDebugView` - live inspector for SunSchedule output during development |
| Utilities | `TimeIntervalExtensions` - human-readable duration formatting |
| Unit tests | Known-location tests for San Diego, New York, Tokyo, Joshua Tree, Tromsø; polar day/night; DST; timezone safety |

---

## Upcoming Stages

| Stage | Focus |
|---|---|
| 2 | Location System - CoreLocation integration, saved locations, permission flow |
| 3 | Today Screen - live solar timeline, next event countdown, active routines for today |
| 4 | Routine Model + Logic - full `LightRoutine` lifecycle, weekday selection, offset scheduling |
| 5 | Create Routine Flow + Onboarding - routine creation UI, onboarding walkthrough |
| 6 | Notification Scheduling - `UNUserNotificationCenter` integration, offset-aware triggers |
| 7 | Free vs Plus System - feature gates, `SubscriptionService` wired to StoreKit 2 |
| 8 | Premium Feature Buildout - unlimited routines, multiple locations, advanced offsets |
| 9 | Widgets + Travel Mode - WidgetKit extension, automatic location updates when traveling |
| 10 | Polish + App Store Launch - accessibility, localization, App Store assets, review prompts |

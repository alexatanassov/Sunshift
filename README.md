# Sunshift

Alarms that move with the sun. Sunshift lets users build routines anchored to solar events - sunrise, solar noon, sunset, twilight - so their schedule shifts naturally with the seasons and their location.

---

## Current Stage: Stage 2 - Location System

The location system is complete. `LocationViewModel` coordinates CoreLocation permission, one-shot GPS fetch, reverse geocoding, and persistence through `LocationStore`. `TodayView` feeds the active location directly into `SunService` so solar times always reflect where the user is.

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
│   │   └── SolarDebugView.swift         # Dev-only view for inspecting SunSchedule output live
│   ├── Onboarding/
│   │   └── OnboardingView.swift         # Shown on first launch; sets hasCompletedOnboarding
│   ├── Today/
│   │   └── TodayView.swift              # Solar event cards; reads active location from LocationViewModel
│   ├── Routines/
│   │   └── RoutinesView.swift           # Placeholder - will list and manage light routines
│   ├── Locations/
│   │   ├── LocationsView.swift          # Permission cards, active location display, saved list
│   │   └── ManualLocationEntryView.swift # Manual lat/lon/timezone entry form with validation
│   └── Plus/
│       └── PlusView.swift               # Placeholder - subscription upsell / feature gate
├── Models/
│   ├── ActiveLocation.swift             # Persisted pointer (UUID + timestamp) to the selected location
│   ├── DeviceLocation.swift             # One-shot GPS result decoupled from CLLocation
│   ├── GeocodedLocation.swift           # Reverse-geocoding result: city, state, country, timezone
│   ├── GeocodingError.swift             # invalidCoordinates, noResultsFound, geocodingFailed
│   ├── LocationError.swift              # permissionDenied, restricted, unavailable, fetchInProgress
│   ├── LocationPermissionStatus.swift   # CLAuthorizationStatus mirror; keeps CoreLocation out of model layer
│   ├── LocationSource.swift             # current, manual, saved, searchResult, fallback
│   ├── SunCalculationError.swift        # invalidCoordinates, invalidTimeZone, calculationFailed
│   ├── SunCalculationInput.swift        # Input type: date, latitude, longitude, timeZoneIdentifier
│   ├── SunSchedule.swift                # Output type: all computed solar events for one local day
│   ├── SunSchedule+Events.swift         # orderedEvents, nextEvent(after:), daylightRemaining(at:)
│   ├── SunEvent.swift                   # Single solar event (type + time)
│   ├── SunEventType.swift               # Enum: sunrise, solarNoon, sunset, goldenHour, twilight...
│   ├── LightRoutine.swift               # User-defined routine anchored to a solar event
│   ├── ReminderOffset.swift             # Offset (+/- minutes) from a solar event
│   ├── SavedLocation.swift              # Named lat/lon; includes source, isCurrentLocation, isHomeLocation
│   ├── WeekdaySelection.swift           # Bitmask-style weekday picker model
│   └── SubscriptionTier.swift           # .free / .plus; FreeTierLimits (maxSavedLocations = 1)
├── Services/
│   ├── DeviceLocationService.swift      # CLLocationManager wrapper; one-shot requestLocation()
│   ├── LocationGeocodingService.swift   # CLGeocoder reverse geocoding; builds SavedLocation from placemark
│   ├── LocationStore.swift              # @Observable; persists savedLocations + activeLocationID to UserDefaults
│   ├── SunService.swift                 # NOAA-style solar position engine; no network required
│   ├── SunService+NextRelevantEvent.swift # Cross-midnight next-event fallback
│   └── SubscriptionService.swift        # @Observable service wrapping subscription state
├── Storage/
│   └── UserPreferences.swift            # UserDefaults-backed persistence layer (placeholder)
├── Utilities/
│   ├── DateExtensions.swift             # Date formatting and local-day comparison helpers
│   └── TimeIntervalExtensions.swift     # Human-readable duration formatting
└── ViewModels/
    └── LocationViewModel.swift          # @Observable; coordinates permission, GPS, geocoding, persistence

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

## Implemented in Stage 2

| Area | What's in place |
|---|---|
| Location models | `SavedLocation` (named lat/lon with source, flags, timestamps), `LocationSource` (.current, .manual, .saved, .searchResult, .fallback), `ActiveLocation` (persisted UUID pointer to selected location) |
| Device GPS | `DeviceLocationService` - `CLLocationManager` wrapper with `@Observable` permission state; one-shot `requestLocation()` exposed as an async throw via `CheckedContinuation` |
| Permission mirror | `LocationPermissionStatus` - mirrors `CLAuthorizationStatus` so CoreLocation stays confined to the service layer |
| Reverse geocoding | `LocationGeocodingService` - `CLGeocoder` wrapper; produces `GeocodedLocation` with city, state, country, ISO code, and timezone; falls back to device timezone when placemark lacks one |
| Persistence | `LocationStore` - `@Observable`; saves `[SavedLocation]` and active location ID to `UserDefaults` (keys: `sunshift.savedLocations`, `sunshift.activeLocationID`) |
| ViewModel | `LocationViewModel` - coordinates permission request, GPS fetch, geocoding, and store mutations; exposes `resolvedLocation` (active location or San Diego fallback), `isUsingFallback`, `canAddManualLocation` |
| Locations screen | `LocationsView` - permission explain card, permission denied card with Settings deep-link, active location card with fallback badge, current location controls, saved locations list |
| Manual entry | `ManualLocationEntryView` - lat/lon/timezone form with inline validation; example buttons pre-fill San Diego, New York, London |
| Sun engine wired | `TodayView` reads `resolvedLocation` from `LocationViewModel` and passes it directly into `SunService`; solar times update automatically when the active location changes |
| Free vs Plus | Free plan: 1 saved non-current location (`FreeTierLimits.maxSavedLocations = 1`); Plus: unlimited; `LocationStore.canAddSavedLocation(tier:)` enforces the gate; Plus upsell shown inline when the limit is reached |
| Dev fallback | `SavedLocation.devFallback` (San Diego, fixed UUID) used only when no location has been set; `isUsingFallback` flag surfaces a badge in the UI so the placeholder is never silently mistaken for real data |

---

## Location System

### Why Sunshift asks for location

Sunshift calculates sunrise, sunset, solar noon, golden hour, and civil twilight on-device for any date and coordinates. Location is the only input the solar engine needs that cannot be inferred from the device. Without it the app shows times for a San Diego fallback.

### What location is used for

- Feeding `latitude`, `longitude`, and `timeZoneIdentifier` into `SunCalculationInput` for every `SunService.sunSchedule(for:)` call
- Reverse geocoding GPS coordinates into a human-readable place name and a confirmed IANA timezone identifier

### What is stored locally

All location data lives on the device in `UserDefaults`:

| Key | Value |
|---|---|
| `sunshift.savedLocations` | JSON-encoded `[SavedLocation]` array |
| `sunshift.activeLocationID` | UUID string of the currently selected location |

Sunshift does not transmit location data to any server.

### Current location support

`DeviceLocationService` requests `whenInUse` permission and calls `CLLocationManager.requestLocation()` for a single fix. The result is reverse-geocoded via `CLGeocoder` to resolve city, region, and timezone. The resolved `SavedLocation` is added to the saved list and set as the active location. There is never more than one current-location entry; the previous one is removed before the new one is saved.

### Manual fallback location support

`ManualLocationEntryView` accepts a name, latitude, longitude, and an IANA timezone identifier. Validation prevents saving out-of-range coordinates or unrecognized timezone strings. Example buttons pre-fill San Diego, New York, or London. The saved location is set as the active location immediately on save.

### Active location state

`LocationStore` persists the selected location ID in `UserDefaults`. On launch, `LocationStore` rehydrates the saved list and resolves the stored ID back to a `SavedLocation`. `LocationViewModel.resolvedLocation` always returns a valid location -- the San Diego fallback when nothing has been set -- so `SunService` always has coordinates to work with.

### Saved location foundation

`LocationStore` manages a `[SavedLocation]` array. Each entry carries a `LocationSource` (.current, .manual, .saved, .searchResult, .fallback), an `isCurrentLocation` flag, and an `isHomeLocation` flag. The store is `@Observable` so views update automatically when the list or active selection changes.

### Free vs Plus location foundation

| Capability | Free | Plus |
|---|---|---|
| Current location (GPS) | Yes | Yes |
| Manual location entry | 1 saved location | Unlimited |
| Saved location list | 1 non-current entry | Unlimited |

The limit is enforced by `FreeTierLimits.maxSavedLocations = 1` in `SubscriptionTier.swift`. `LocationStore.canAddSavedLocation(tier:)` and `LocationViewModel.canAddManualLocation` are the single source of truth; the UI reads from these rather than re-implementing the logic.

### Location edge cases

**Permission denied:** `LocationViewModel.useCurrentLocation()` checks `permissionStatus` before calling the service. If denied, `userFacingError` is set to a human-readable message and `LocationPermissionDeniedCard` offers a deep-link to Settings via `app-settings:`.

**Permission undetermined:** When the user taps "Use Current Location" before answering the system prompt, `pendingCurrentLocationFetch` is set to `true`. `observePermissionStatus()` uses `withObservationTracking` to re-run when the status changes and fires the fetch automatically if the user grants access, or sets an error if they deny.

**Location unavailable:** `DeviceLocationService.locationManager(_:didFailWithError:)` resumes the continuation with `LocationError.locationUnavailable`. The ViewModel surfaces a message prompting the user to try again.

**Geocoding failure:** If `CLGeocoder.reverseGeocodeLocation` fails, `fetchAndApplyCurrentLocation()` catches the error and saves a `SavedLocation` named "Current Location" using the raw GPS coordinates and the device's current timezone. Solar calculations still work; the display name is generic.

**Timezone fallback:** `LocationGeocodingService.reverseGeocode` uses `placemark.timeZone?.identifier ?? TimeZone.current.identifier`. Callers always receive a valid IANA timezone identifier. `TodayView` additionally falls back to `TimeZone.current` when it cannot construct a `TimeZone` from the stored identifier, so the UI never crashes from a stale or malformed string.

**Simulator location testing:** See the developer note below.

### Simulator location testing

Xcode Simulator does not provide a real GPS fix. To test location in Simulator:

1. Build and run the app in Simulator.
2. In Xcode's menu bar: **Features > Location** (Xcode 15 and earlier) or **Debug > Location** (Xcode 16+).
3. Choose **Apple** (Apple Park, Cupertino), **City Bicycle Ride** (moves through San Francisco), or **Custom Location** to enter specific coordinates.
4. Switch to the app and tap **Use Current Location** or **Refresh Current Location** to trigger a new GPS fetch.

Custom Location is the most useful option during development. Enter any lat/lon from the test suite (San Diego: 32.7157, -117.1611 -- New York: 40.7128, -74.0060 -- Tromsø: 69.6492, 18.9553) to verify solar times match expected values.

### Location privacy note (developer planning, not final legal copy)

Sunshift uses your location to calculate sunrise, sunset, and light-based routines for where you are. Location data is stored locally on your device for active and saved locations. Sunshift does not need continuous background tracking for the current v1 location system.

---

## Upcoming Stages

| Stage | Focus |
|---|---|
| 3 | Today Screen - live solar timeline, next event countdown, active routines for today |
| 4 | Routine Model + Logic - full `LightRoutine` lifecycle, weekday selection, offset scheduling |
| 5 | Create Routine Flow + Onboarding - routine creation UI, onboarding walkthrough |
| 6 | Notification Scheduling - `UNUserNotificationCenter` integration, offset-aware triggers |
| 7 | Free vs Plus System - feature gates, `SubscriptionService` wired to StoreKit 2 |
| 8 | Premium Feature Buildout - unlimited routines, multiple locations, advanced offsets |
| 9 | Widgets + Travel Mode - WidgetKit extension, automatic location updates when traveling |
| 10 | Polish + App Store Launch - accessibility, localization, App Store assets, review prompts |


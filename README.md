# Sunshift

Alarms that move with the sun. Sunshift lets users build routines anchored to solar events - sunrise, solar noon, sunset, twilight - so their schedule shifts naturally with the seasons and their location.

---

## Current Stage: Stage 6 - Notification Scheduling

Local notification scheduling is implemented. `RoutineNotificationScheduler` schedules a rolling window of up to 7 one-shot `UNCalendarNotificationTrigger` requests per enabled routine, derived from the routine's solar trigger times at the active location. `SunshiftApp` calls `rescheduleAll` on launch and again whenever routines, the active location, or notification permission status changes. Disabled routines produce no notifications; their existing requests are cancelled. Deleted routines are cleared because `rescheduleAll` issues a full `cancelAll` before rescheduling only the routines currently in the store. Notification identifiers are stable, keyed to routine ID and occurrence index. Content uses the routine title and `notificationMessage`, falling back to "It's time for your routine." when the message is empty. Calendar trigger components are expressed in the location's IANA timezone.

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
│   ├── SunshiftApp.swift          # @main entry point; initializes and injects all services and view models
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
│   │   ├── OnboardingView.swift         # Six-step onboarding flow; creates first routine on completion
│   │   └── OnboardingViewModel.swift    # Step navigation, template selection, timing state, buildRoutine()
│   ├── Today/
│   │   ├── TodayView.swift              # Main Today tab; routes between empty, loading, error, and content states
│   │   └── TodayTimelineView.swift      # Horizontal day timeline bar with gradient and now-indicator dot
│   ├── Routines/
│   │   ├── RoutinesView.swift           # Routine list: rows with enable toggle, create/edit sheet entry points
│   │   └── RoutineEditView.swift        # Create/edit sheet: name, template picker, timing, weekday chips, delete
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
│   ├── SunSchedule+Events.swift         # orderedEvents, nextEvent(after:), daylightRemaining(at:), event(for:)
│   ├── SunEvent.swift                   # Single solar event (type + time)
│   ├── SunEventType.swift               # Enum with routineTriggerCases (excludes daylightRemaining)
│   ├── LightRoutine.swift               # User-defined routine: event anchor, offset, weekdays, enabled flag
│   ├── ReminderOffset.swift             # Offset enum: atEvent, preset(minutes:), custom(minutes:)
│   ├── SavedLocation.swift              # Named lat/lon; includes source, isCurrentLocation, isHomeLocation
│   ├── WeekdaySelection.swift           # OptionSet bitmask; everyday/weekdays/weekends presets + friendlyLabel
│   └── SubscriptionTier.swift           # .free / .plus; RoutineTemplate enum; FreeTierLimits
├── Services/
│   ├── DeviceLocationService.swift      # CLLocationManager wrapper; one-shot requestLocation()
│   ├── LocationGeocodingService.swift   # CLGeocoder reverse geocoding; builds SavedLocation from placemark
│   ├── LocationStore.swift              # @Observable; persists savedLocations + activeLocationID to UserDefaults
│   ├── NotificationPermissionService.swift  # @Observable; tracks UNAuthorizationStatus; requests authorization via UNUserNotificationCenter
│   ├── RoutineNotificationScheduler.swift   # @MainActor; schedules rolling one-shot UNCalendarNotificationTrigger requests per routine; cancels stale notifications
│   ├── RoutineStore.swift               # @Observable; persists [LightRoutine] to UserDefaults; starts empty; first routine added by onboarding
│   ├── RoutineScheduler.swift           # Static; nextTriggerDate scans up to 8 days, respects weekdays and offsets
│   ├── SunService.swift                 # NOAA-style solar position engine; no network required
│   ├── SunService+NextRelevantEvent.swift # Cross-midnight next-event fallback
│   └── SubscriptionService.swift        # @Observable service wrapping subscription state and feature gates
├── Storage/
│   └── UserPreferences.swift            # UserDefaults-backed persistence layer (placeholder)
├── Utilities/
│   ├── DateExtensions.swift             # Date formatting and local-day comparison helpers
│   └── TimeIntervalExtensions.swift     # Human-readable duration formatting
└── ViewModels/
    ├── LocationViewModel.swift          # @Observable; coordinates permission, GPS, geocoding, persistence
    ├── RoutinesViewModel.swift          # @Observable; free-tier gate, display helpers, delegates to RoutineStore
    └── TodayViewModel.swift             # @Observable; computes Today UI state + next-routine card from RoutineStore

Docs/
└── SUNSHIFT_V1_PLAN.md            # Full v1 product plan and stage breakdown

SunshiftTests/                                   # Unit test suite covering SunService, routines,
                                                 # onboarding, locations, and notification scheduling
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

## Implemented in Stage 3

| Area | What's in place |
|---|---|
| ViewModel | `TodayViewModel` - `@Observable`; takes a `SavedLocation` and `now`, calls `SunService`, and exposes all formatted strings for the view layer |
| Hero card | Gradient card showing next event name + countdown (e.g. "Sunset in 2h 14m"), daylight remaining, a contextual one-line hint, and the active location name with a "Sample" badge when using the fallback |
| Daylight remaining | Derived from `SunSchedule.daylightRemaining(at:)` via `TimeIntervalExtensions.formattedDaylightRemaining`; clears to "Sun has set" after sunset |
| Next event countdown | Resolved via `SunService.nextRelevantEvent(after:schedule:input:)`; falls back to the next day's schedule when today's events are exhausted; formatted via `formattedCountdown` |
| Events reference | Card showing sunrise, sunset, evening golden hour start, and last light times; swaps to polar-day or polar-night copy when sunrise/sunset are nil |
| Day timeline | `TodayTimelineView` - horizontal capsule bar with a multi-stop gradient keyed to the day's actual solar events (first light through last light); a white dot with a color-matched inner circle tracks the current time |
| Next routine placeholder | `NextRoutineCard` showing a hardcoded "Sunset Walk" entry (30 min before sunset) with the computed walk time; labeled as a placeholder for Stage 4 |
| Loading state | Shown until `TodayViewModel.hasRefreshed` is true |
| Error state | Shown when `SunService` throws; includes a "Try Again" button that re-calls `refresh()` |
| Empty state | Shown when no active location has been set; prompts the user to the Locations tab |
| Fallback badge | "Sample" chip in the hero card when `isUsingFallback` is true (San Diego placeholder data) |
| Polar edge cases | Hero and timeline both handle polar day (no sunset) and polar night (no sunrise/sunset) with appropriate copy and gradient |
| Location reactivity | `TodayView` refreshes via `.onChange(of: locationViewModel.resolvedLocation.id)` so the display updates immediately when the user switches active location |

## Implemented in Stage 4

| Area | What's in place |
|---|---|
| `LightRoutine` model | Fully-specified value type: title, template reference, solar event anchor, offset (minutes + direction), weekday selection, location ID, enabled flag, notification message, created/updated timestamps |
| `RoutineTemplate` | Enum in `SubscriptionTier.swift`: sunsetWalk, morningLight, windDown, goldenHourShoot, custom; each carries default event, offset, direction, and notification message; `requiresPlus` gate |
| `WeekdaySelection` | `OptionSet` bitmask (7 bits); everyday/weekdays/weekends presets; `contains(calendarWeekday:)` maps `Calendar.weekday` (1=Sun...7=Sat); `friendlyLabel` produces human-readable summary |
| `ReminderOffset` | Enum with `.atEvent`, `.preset(minutes:)`, `.custom(minutes:)`; named presets at 5, 10, 15, 30, 60 minutes |
| `RoutineStore` | `@Observable`; persists `[LightRoutine]` to `UserDefaults` key `sunshift.light_routines` as JSON; starts empty on fresh install; `add`, `update`, `toggleEnabled`, `delete` mutations |
| `RoutineScheduler` | Static struct; `nextTriggerDate(for:sunService:location:after:)` scans today through the next 7 days; applies weekday filter, resolves the solar event via `SunSchedule.event(for:)`, applies the before/after offset, returns the first trigger strictly after `now` |
| `SunEventType` additions | `routineTriggerCases` excludes `.daylightRemaining` (duration, not a point in time); `SunSchedule.event(for:)` resolves any trigger case to a `Date?` |
| `RoutinesViewModel` | `@Observable`; `canAddRoutine` and `isAtFreeLimit` enforce `FreeTierLimits.maxActiveRoutines = 1` for free users; `triggerDescription(for:)` and `activeDaysSummary(for:)` produce display strings; mutations delegate to `RoutineStore` |
| Routine list screen | `RoutinesView`: `NavigationStack` with per-routine rows showing event icon, title, trigger description, day summary; inline enable toggle (`checkmark.circle.fill` / `circle`); "+" toolbar button hidden when `isAtFreeLimit`; free-limit hint card; empty state |
| Routine edit screen | `RoutineEditView`: `.create` and `.edit(LightRoutine)` modes; name field; template picker (create mode only) with Plus badges and preview text; timing section (event picker from `routineTriggerCases`, offset picker, before/after segmented picker); `WeekdayChipRow` with accessibility labels; notification message field with Plus gate hint; enabled toggle; delete button (edit mode only) |
| Template picker | Applies template defaults (event, offset, direction, message) when selected; auto-fills name when the current name is empty or matches a template name |
| `SubscriptionService` additions | `canUseCustomNotificationMessages`, `canUseTemplate(_:)` feature gates; `FreeTierLimits.maxActiveRoutines = 1`, `allowedTemplates = [.sunsetWalk, .custom]` |
| Today screen connection | `TodayView` reads `RoutineStore` via `@Environment`; passes first enabled routine to `TodayViewModel.refresh(enabledRoutine:)`; `TodayViewModel.updateRoutineState` calls `RoutineScheduler.nextTriggerDate` and populates `nextRoutineName`, `nextRoutineTimeText`, `nextRoutineTriggerText`; `NextRoutineCard` shows real data or "Not available today" when the scheduler returns nil; shows "No routines yet" when no enabled routine exists; reactive via `.onChange(of: routineStore.routines)` |
| App entry point | `SunshiftApp` initializes `RoutineStore` and `RoutinesViewModel`; both injected into the environment alongside `SubscriptionService` and `LocationViewModel` |
| Free vs Plus foundation | Free: 1 routine, sunsetWalk and custom templates, no custom notification messages. Plus: unlimited routines, all templates, custom messages. No real StoreKit purchase flow yet. |

## Implemented in Stage 5

| Area | What's in place |
|---|---|
| Onboarding steps | Six-step flow: welcome, template selection, timing customization, location, confirmation, notification permission |
| `OnboardingViewModel` | `@Observable`; tracks current step, selected template, offset, direction, weekday selection; `buildRoutine()` assembles the `LightRoutine` |
| Template selection | All `RoutineTemplate` cases shown; Plus templates display a "Plus" badge and an inline locked hint banner when tapped; Sunset Walk is the pre-selected free default |
| Timing customization | Offset pill row (At / 15 min / 30 min / 1 hr), before/after segmented picker (shown only when offset > 0), weekday chip row |
| Location step | "Use Current Location" triggers GPS fetch and auto-advances on success; "Skip for now" proceeds immediately; errors shown inline |
| Confirmation step | Computes next trigger time via `RoutineScheduler.nextTriggerDate` using the resolved location; shows "today", "tomorrow", or a fallback when no trigger is found within 8 days |
| Notification permission | `NotificationPermissionService` calls `UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound])`; "Not now" also advances without requesting; no notifications are scheduled |
| `NotificationPermissionService` | New `@Observable` service; tracks `UNAuthorizationStatus`; `refreshStatus()` called on init; injected into the environment from `SunshiftApp` |
| First routine creation | `RoutinesViewModel.upsertOnboardingRoutine(_:)` adds on a fresh install or updates the first routine in place on re-entry; `RoutineStore` starts with zero routines on a fresh install |
| `AppState` persistence | `hasCompletedOnboarding` is `UserDefaults`-backed (key: `sunshift.hasCompletedOnboarding`); survives app restarts; set to `true` in `OnboardingView.complete()` |
| Post-onboarding routing | `SunshiftRootView` routes to `MainTabView` (Today tab); Routines tab shows one active routine |

---

## Implemented in Stage 6

| Area | What's in place |
|---|---|
| `RoutineNotificationScheduler` | `@MainActor` final class; wraps `UNUserNotificationCenter` via `NotificationSchedulingCenter` protocol for testability; `UNUserNotificationCenter` conforms via a retroactive extension |
| Rolling window scheduling | Up to 7 one-shot `UNCalendarNotificationTrigger` requests per routine; searches up to 49 days to fill 7 occurrences for once-weekly routines |
| Permission gating | No requests added when `authStatus` is `.denied` or `.notDetermined`; `.authorized` and `.provisional` proceed |
| Enabled/disabled gate | Disabled routines: existing requests cancelled, no new ones added |
| Stale notification cleanup | `rescheduleAll` calls `cancelAll` first; routines absent from the array (deleted or not passed in) are not rescheduled |
| Stable identifiers | Format: `sunshift.routine.<routineID>.<occurrenceIndex>`; prefix `sunshift.routine.<routineID>.` allows targeted cancellation per routine |
| Notification content | Title from `routine.title`; body from `routine.notificationMessage` or fallback `"It's time for your routine."`; sound `.default` |
| Timezone-correct triggers | `UNCalendarNotificationTrigger` date components derived in the location's IANA timezone; `components.timeZone` explicitly set |
| `SunshiftApp` integration | `scheduleAll()` called on `.task` (launch), `.onChange(of: routineStore.routines)`, `.onChange(of: locationViewModel.resolvedLocation.id)`, `.onChange(of: notificationPermissionService.authorizationStatus.rawValue)` |
| Unit tests | 16 tests in `RoutineNotificationSchedulerTests.swift`: permission gating (authorized/denied/notDetermined/provisional), disabled routine cancellation, rolling window count, stale cleanup for deleted routines, identifier stability, content (title/custom body/default body), calendar trigger type, timezone components in local time, polar no-event case |

---

## Upcoming Stages

| Stage | Focus |
|---|---|
| 7 | Free vs Plus System - feature gates wired to StoreKit 2 real purchases, paywall screen |
| 8 | Premium Feature Buildout - unlimited routines, multiple locations, advanced offsets |
| 9 | Widgets + Travel Mode - WidgetKit extension, automatic location updates when traveling |
| 10 | Polish + App Store Launch - accessibility, localization, App Store assets, review prompts |


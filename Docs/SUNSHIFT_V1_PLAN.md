# Sunshift V1 Product Plan

## One-liner

A calm, beautiful alarm app for routines that move with the sun.

---

## Core Promise

Set your routine once — before sunrise, before sunset, at golden hour, or when daylight is running out — and Sunshift keeps it timed correctly every day.

The alarm time recalculates automatically as sunrise and sunset shift through the seasons. Users never touch the clock again.

---

## Target Audience

People whose mornings or evenings have a natural rhythm tied to light:

- Early risers who want to wake before or at sunrise
- Evening walkers, runners, or readers who want reminders before sunset
- Anyone who hates manually adjusting alarms twice a year for daylight saving

Secondary: wellness-oriented users who want a gentler, nature-aligned way to structure their day.

---

## V1 Free Features

The magic — enough to hook the user and demonstrate the core value.

| Feature | Notes |
|---|---|
| Today light timeline | Visual arc showing current sun position, remaining daylight |
| Daylight remaining | Live countdown or display of minutes/hours left until sunset |
| Sunrise / sunset / golden hour preview | Times shown for today |
| One active routine | Tied to a single sun event with a fixed offset |
| Sunset Walk template | Pre-built routine: 30 min before sunset |
| Current location | Auto-detected via device GPS |
| Basic push notifications | Fires at the calculated routine time |

---

## V1 Sunshift Plus Features

The lifestyle — for users who want Sunshift woven into their day.

| Feature | Notes |
|---|---|
| Unlimited routines | Multiple alarms tied to different sun events |
| All templates | Morning run, golden hour shoot, end-of-workday, etc. |
| Custom offsets | +/- minutes or hours relative to any sun event |
| Saved locations | Set routines for home, office, a recurring travel destination |
| 7-day light preview | See sunrise/sunset times for the week ahead |
| Advanced light events | Astronomical/nautical/civil dawn and dusk |
| Custom notification messages | Personalize the push notification copy per routine |
| Widgets (if feasible by v1) | Home screen widget showing next sun event or active routine |

---

## Screens Planned for V1

| Screen | Description |
|---|---|
| Today | Main tab. Light timeline, daylight remaining, next sun events, active routine summary |
| Routines | List of user's routines. Add/edit/delete. Free users see upsell after one. |
| Locations | Saved locations list (Plus). Current location always available. |
| Onboarding | Location permission, brief value prop, optional Plus upsell |
| Plus | Paywall / subscription management screen |
| Routine Editor | Create or edit a routine: pick sun event, offset, days, notification message |

---

## Intentionally Not in V1

- Social or sharing features
- Sleep tracking or smart wake windows
- Weather integration
- Apple Watch app
- Android / cross-platform
- Historical sun data or analytics
- Multiple time zones in a single view
- Integration with Calendar or Reminders
- Siri Shortcuts (post-v1 candidate)

---

## Design Personality

- **Calm and unhurried.** No aggressive alerts, no gamification, no streaks.
- **Nature-first visuals.** Warm amber/gold palette, sky gradients, soft typography.
- **Minimal chrome.** The light timeline is the hero element — UI gets out of its way.
- **Premium feel from the start.** Even free users experience the full visual polish.

Refer to `Sunshift/Design/DesignTokens.swift` for the implemented color and type system.

---

## Stage 1: Solar Calculation Engine

The on-device solar calculation engine was the first engineering milestone. It has no network dependency and runs entirely from `Foundation` and pure math.

**Algorithm:** NOAA-style solar position using formulae from Jean Meeus, "Astronomical Algorithms" (2nd ed.). A Julian Day number anchors the target calendar date, a Julian Century from J2000.0 drives the orbital mechanics, and the resulting declination and equation of time are used to solve for event crossing times via the hour angle equation.

**Timezone handling:** Calculations are anchored to the local calendar date in the given IANA timezone. The same UTC instant in different timezones can resolve to different local dates and will produce different schedules. DST transitions are handled transparently by `Foundation.Calendar`.

**Outputs per day:** sunrise, sunset, solar noon, golden hour start/end, blue hour start/end, first light (civil dawn), last light (civil dusk), daylight duration, daylight remaining, and next event.

**Polar handling:** When the sun never crosses an altitude threshold, that event is `nil`. Solar noon is always computable. The engine does not throw for polar conditions.

**Approximations:**
- Golden hour: sun between the horizon (-0.833 degrees) and +6 degrees altitude
- Blue hour: sun between -4 and -6 degrees altitude

These thresholds match common photographic usage and are intentionally fixed for predictability. They are not adaptive to atmospheric or seasonal variation.

**Test coverage:** Unit tests run against five reference locations covering event ordering, daylight duration accuracy, polar edge cases, timezone correctness, next-event logic, and cross-midnight fallback:

| Location | Timezone | Coverage |
|---|---|---|
| San Diego | America/Los_Angeles | Summer and winter solstice; event ordering; daylight duration |
| New York | America/New_York | Event ordering; next-event logic |
| Tokyo | Asia/Tokyo | Eastern hemisphere; local-day anchoring (UTC+9) |
| Joshua Tree | America/Los_Angeles | Desert; event ordering |
| Tromsø | Europe/Oslo | Polar day and polar night edge cases |

---

## Stage 2: Location System

Stage 2 wires the device to the solar engine. `TodayView` now feeds real coordinates into `SunService` so every solar time shown in the app reflects where the user actually is.

### Why the app asks for location

The solar calculation engine needs latitude, longitude, and a timezone identifier. Without real coordinates, Sunshift falls back to San Diego so the UI never displays blank values, but the fallback is clearly labelled in the interface.

### What location is used for

- Supplying `latitude`, `longitude`, and `timeZoneIdentifier` to `SunCalculationInput` on every call to `SunService.sunSchedule(for:)`
- Reverse geocoding GPS coordinates into a display name and a confirmed IANA timezone identifier

### What is stored locally

All location data stays on the device in `UserDefaults`. No server receives any location information.

| Key | Content |
|---|---|
| `sunshift.savedLocations` | JSON-encoded `[SavedLocation]` array |
| `sunshift.activeLocationID` | UUID string of the active location |

### Current location support

`DeviceLocationService` wraps `CLLocationManager`. It requests `whenInUse` permission and calls `requestLocation()` for a single GPS fix, bridged to Swift Concurrency via `CheckedContinuation`. The fix is then reverse-geocoded by `LocationGeocodingService` (`CLGeocoder`) to resolve city, state, and timezone. The result is saved to `LocationStore` and set as the active location. Only one current-location entry is kept at a time; the previous one is removed before the new one is added.

### Manual fallback location support

`ManualLocationEntryView` accepts a location name, latitude, longitude, and IANA timezone identifier. The form validates coordinates and the timezone string before the Save button becomes active. Example buttons pre-fill San Diego, New York, and London. On save the location is persisted and set as the active location immediately.

### Active location state

`LocationStore` stores the active location ID in `UserDefaults`. On app launch the store rehydrates the saved list and resolves the stored ID back to a `SavedLocation`. `LocationViewModel.resolvedLocation` always returns a valid location -- the San Diego dev fallback when nothing has been set -- so `SunService` always has coordinates to work with. `isUsingFallback` flags when the resolved location is the placeholder so the UI can surface a badge rather than silently showing San Diego data as real.

### Saved location foundation

`LocationStore` manages a `[SavedLocation]` array. Each entry carries a `LocationSource` (.current, .manual, .saved, .searchResult, .fallback), `isCurrentLocation`, and `isHomeLocation` flags, and created/updated timestamps. The store is `@Observable` so views update automatically when the list or active selection changes.

### Free vs Plus location foundation

| Capability | Free | Plus |
|---|---|---|
| Current location (GPS) | Yes | Yes |
| Manual location entry | 1 saved location | Unlimited |
| Saved location list | 1 non-current entry | Unlimited |

`FreeTierLimits.maxSavedLocations = 1` (in `SubscriptionTier.swift`) is the single source of truth. `LocationStore.canAddSavedLocation(tier:)` and `LocationViewModel.canAddManualLocation` expose the gate; the UI reads from these rather than reimplementing the check. A Plus upsell is shown inline in `LocationsView` when the free limit is reached.

### Location edge cases

**Permission denied:** `LocationViewModel.useCurrentLocation()` checks `permissionStatus` before calling the service. If denied or restricted, `userFacingError` is set with a clear message. `LocationPermissionDeniedCard` shows the message and offers a deep-link to Settings (`app-settings:`).

**Permission undetermined:** When the user requests their current location before answering the system permission prompt, `pendingCurrentLocationFetch` is set. `observePermissionStatus()` uses `withObservationTracking` to watch for the status change and fires the GPS fetch automatically on grant, or surfaces an error on deny.

**Location unavailable:** `CLLocationManager` delegate failures are caught and resume the `CheckedContinuation` with `LocationError.locationUnavailable`. The ViewModel sets a user-facing message prompting a retry.

**Geocoding failure:** If `CLGeocoder.reverseGeocodeLocation` fails, `fetchAndApplyCurrentLocation()` catches the error and saves a `SavedLocation` named "Current Location" using the raw GPS coordinates and the device timezone. Solar calculations still work correctly; only the display name is generic.

**Timezone fallback:** `LocationGeocodingService` uses `placemark.timeZone?.identifier ?? TimeZone.current.identifier`. Callers always receive a valid IANA identifier. `TodayView` additionally guards with `TimeZone(identifier:) ?? .current` so a stale or malformed stored string never crashes the schedule calculation.

**Simulator location testing:** The iOS Simulator does not provide real GPS. To test location in Simulator:

1. Build and run the app.
2. In Xcode's menu bar: **Features > Location** (Xcode 15 and earlier) or **Debug > Location** (Xcode 16+).
3. Choose **Apple** (Apple Park), **City Bicycle Ride** (moves through San Francisco), or **Custom Location** to enter specific coordinates.
4. Tap **Use Current Location** or **Refresh Current Location** in the app to trigger a new GPS fetch.

Custom Location is the most useful option during development. The test suite reference coordinates work well: San Diego (32.7157, -117.1611), New York (40.7128, -74.0060), Tromsø (69.6492, 18.9553).

### Location privacy note (developer planning, not final legal copy)

Sunshift uses your location to calculate sunrise, sunset, and light-based routines for where you are. Location data is stored locally on your device for active and saved locations. Sunshift does not need continuous background tracking for the current v1 location system.

---

## Post-1.0 Future Features

These are not in scope for v1 but are worth keeping in mind to avoid closing off architectural doors.

- **Apple Watch complication** — next sun event glanceable on wrist
- **Siri Shortcuts** — "Hey Siri, when is sunset today?"
- **iPad layout** — wider Today view with expanded timeline
- **Lock screen widgets** (iOS 16+)
- **Smart snooze** — push routine time by a fixed delta without editing it
- **Routine sharing** — export/import a routine template via link
- **Sunrise alarm sound** — gentle audio that grows with light level
- **Focus mode integration** — link a routine to a Focus filter
- **International calendars** — prayer time offsets, regional twilight definitions

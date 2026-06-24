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

## Stage 3: Today Screen

Stage 3 builds the primary user-facing screen. The Today tab is the first thing users see on every launch. It must be immediately useful, visually calm, and accurate to real location data.

### Architecture

`TodayViewModel` owns all display state for the Today tab. It is `@Observable` and stateless between calls -- `refresh(location:isUsingFallback:now:)` recomputes everything from scratch. `TodayView` calls `refresh` on `.task` and again via `.onChange(of: locationViewModel.resolvedLocation.id)` so the display stays in sync when the user switches active locations.

`TodayView` reads `resolvedLocation` and `isUsingFallback` from `LocationViewModel` (injected via `@Environment`) and passes them into the ViewModel. The view itself handles state routing: it shows an empty state, loading state, error state, or the full content stack depending on which flags are set.

### Real active location data

`TodayViewModel.refresh` accepts a `SavedLocation`. It extracts `latitude`, `longitude`, and `timeZoneIdentifier` to build a `SunCalculationInput`, then calls `SunService.sunSchedule(for:)`. Because `LocationViewModel.resolvedLocation` always returns a valid location (real or San Diego fallback), the ViewModel always has something to compute from.

`locationKind` is resolved from `isUsingFallback` and `location.isCurrentLocation`:
- `.fallback` -- San Diego placeholder, nothing real has been set
- `.current` -- active GPS position
- `.saved` -- user-saved named place

### SunService schedule connection

`TodayViewModel` calls two methods on `SunService`:
- `sunSchedule(for:)` -- computes the full `SunSchedule` for the active location and local calendar date
- `nextRelevantEvent(after:schedule:input:)` (from `SunService+NextRelevantEvent`) -- finds the next solar event; if today's events are exhausted, falls back to the next day's schedule

All formatted strings (`sunriseText`, `sunsetText`, `goldenHourText`, `lastLightText`) are computed once in `refresh` and exposed as `String` properties. The view layer does no formatting.

### Hero card

The hero card (`HeroCard`) is the visual anchor of the screen. It shows:

- **Next event countdown** -- the next solar event name rewritten in natural language (e.g. "Sunset in 2h 14m") in large display type. Shows "All done for today" after the last event, or "Night all day" for polar night.
- **Contextual hint** -- a one-line sentence keyed to the next event name (e.g. "The sky is about to put on a show" before sunset). Helps the screen feel alive rather than just informational.
- **Daylight remaining** -- formatted as "Xh Ym of daylight left"; switches to "Sun has set" after sunset; shows "Daylight all day" for polar day.
- **Location name** -- shown in the footer with a pin icon. Displays a "Sample" chip in amber when `locationKind == .fallback` so placeholder data is never silently presented as real.
- **Gradient** -- adapts to the time of day. Uses `SunshiftGradients.sunrise` during daylight, `SunshiftGradients.dusk` after sunset, `SunshiftGradients.night` for polar night.

### Daylight remaining

`daylightRemainingText` calls `SunSchedule.daylightRemaining(at: now)` and formats the result with `TimeIntervalExtensions.formattedDaylightRemaining`. Returns `nil` after sunset (which the hero card renders as "Sun has set") and `nil` for polar conditions (handled separately).

### Next light event countdown

`nextEventTitle` and `nextEventCountdownText` are set from the result of `SunService.nextRelevantEvent(after:schedule:input:)`. The countdown interval is formatted by `TimeIntervalExtensions.formattedCountdown`. `TodayViewModel` does not start a live timer; callers are expected to re-call `refresh` periodically or on significant time changes.

### Sunrise, sunset, golden hour, and last light

`EventsSection` shows four rows in a card:
- Sunrise (time of first solar limb crossing)
- Sunset (evening crossing)
- Golden Hour (start of evening golden hour, i.e. `goldenHourEnd` from `SunSchedule`)
- Last Light (civil dusk, `lastLight`)

For polar day and polar night, the sunrise/sunset rows are replaced with a context row ("The sun doesn't set today" or "No sunrise today") and only golden hour and last light are shown.

### Day timeline visualization

`TodayTimelineView` renders a horizontal capsule bar representing the day's light progression. Key details:

- **Range** -- from one hour before first light to one hour after last light (or midnight if those events are nil). This keeps the bar from spanning a full 24 hours when daylight is limited.
- **Gradient** -- multi-stop `LinearGradient` with stops keyed to the actual times of first light, blue hour start, sunrise, golden hour start, solar noon, golden hour end, sunset, blue hour end, and last light. The colors run from `nightNavy` through dawn blue, peach, gold, bright day, amber, dusk purple, and back to night.
- **Now indicator** -- a white circle with a color-matched inner dot tracks the current time along the bar. The inner dot color is resolved from which light phase `now` falls in (night, dawn, morning golden hour, day, evening golden hour, dusk, or night).
- **Labels** -- sunrise and sunset times appear below the bar at their proportional positions.
- **Polar states** -- when there is no sunrise or sunset, the timeline shows a text row ("Daylight all day" or "No sunrise today") instead of the bar.

### Next routine placeholder

`NextRoutineCard` is a static placeholder representing the "Sunset Walk" routine (30 minutes before sunset). It shows the routine name, the anchor description, and the computed walk time derived from `sunset - 30 minutes`. A footer note ("Routine scheduling comes next.") marks this as a pre-Stage 4 placeholder. The card structure and layout match what the real routine cards will look like.

### Loading, error, fallback, and empty states

| State | Trigger | What the user sees |
|---|---|---|
| Empty | `locationViewModel.activeLocation == nil` | Icon + copy directing the user to the Locations tab |
| Loading | `!viewModel.hasRefreshed` | Amber `ProgressView` spinner |
| Error | `viewModel.errorMessage != nil` | Message + "Try Again" button that re-calls `refresh()` |
| Fallback | `locationViewModel.isUsingFallback` | Full content, but hero card shows a "Sample" chip next to the location name |
| Polar day | `schedule.sunrise == nil && schedule.sunset == nil && schedule.solarNoon != nil` | "Daylight all day" in hero and timeline; adjusted events card |
| Polar night | `schedule.sunrise == nil && schedule.sunset == nil && schedule.solarNoon == nil` | "Night all day" in hero; night gradient; adjusted events card |

### Design tone

The Today screen follows the app's design personality: warm, simple, premium, uncluttered. Key decisions:

- Large display type for the countdown draws the eye immediately.
- Contextual hint copy keeps the screen conversational without being wordy.
- The gradient card and timeline are the only visual "heavy" elements; everything else is flat cards on a warm background.
- No icons in the hero -- the gradient carries the mood.
- Monospaced digits on time strings prevent layout jitter as times change.

### What is intentionally not in Stage 3

- **Real routines** -- `NextRoutineCard` is a static placeholder. The full `LightRoutine` model and scheduling logic are Stage 4.
- **Notifications** -- no `UNUserNotificationCenter` integration yet.
- **Widgets** -- WidgetKit is Stage 9.
- **Paywall changes** -- no new Free vs Plus gates introduced. The existing tier model is unchanged.
- **Live timer** -- the ViewModel does not self-update on a timer. The view must call `refresh()` externally to update countdowns.

---

## Stage 4: Routine System

Stage 4 implements the full routine lifecycle from model definition through persistence, scheduling, and UI. Routines are now real objects -- not placeholders -- and the Today screen Next Routine card reflects actual data.

### Model: LightRoutine

`LightRoutine` is a `Codable`, `Identifiable`, `Equatable` struct. Its fields:

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Stable identity across saves |
| `title` | `String` | User-editable display name |
| `templateType` | `RoutineTemplate?` | Template used to create the routine, if any |
| `sunEventType` | `SunEventType` | Solar event that anchors the trigger |
| `offsetMinutes` | `Int` | Magnitude of the offset from the anchor event |
| `isBeforeEvent` | `Bool` | `true` = offset subtracts from the event time |
| `selectedWeekdays` | `WeekdaySelection` | Bitmask of active days |
| `locationId` | `UUID?` | Reserved for future per-routine location; unused in Stage 4 |
| `isEnabled` | `Bool` | When `false`, the routine is skipped by the scheduler |
| `notificationMessage` | `String` | Custom push copy; Plus-gated in the UI |
| `createdAt` / `updatedAt` | `Date` | Timestamps; `updatedAt` is refreshed on every mutation |

### Model: RoutineTemplate

`RoutineTemplate` is a `CaseIterable`, `Codable` enum defined in `SubscriptionTier.swift`. It provides default values that pre-fill the create form.

| Template | Event | Offset | Direction | Requires Plus |
|---|---|---|---|---|
| `sunsetWalk` | Sunset | 30 min | Before | No |
| `morningLight` | Sunrise | 15 min | After | Yes |
| `windDown` | Sunset | 30 min | After | Yes |
| `goldenHourShoot` | Golden Hour Start | 10 min | Before | Yes |
| `custom` | Sunset | 0 | -- | No |

Free users see all templates in the picker but Plus templates are labelled and cannot be selected without a subscription.

### Default Seeded Routine

`RoutineStore.seed()` runs once on first launch when the `sunshift.light_routines` key is absent from `UserDefaults`. It creates a "Sunset Walk" routine using the `sunsetWalk` template defaults: 30 min before sunset, every day, enabled. This gives every new user an immediately working routine without requiring any setup.

### RoutineStore Persistence

`RoutineStore` is `@Observable`. It persists `[LightRoutine]` to `UserDefaults` under the key `sunshift.light_routines` as JSON via `Codable`. All mutations (`add`, `update`, `toggleEnabled`, `delete`) write synchronously after each change. `toggleEnabled` also stamps `updatedAt`. The store seeds on first launch and is safe to call `load()` when the key is missing (no-op).

### RoutineScheduler

`RoutineScheduler.nextTriggerDate(for:sunService:location:after:)` is a static function that finds the next valid trigger time for a routine:

1. Returns `nil` immediately if `routine.isEnabled` is `false`.
2. Builds a `Calendar` anchored to the location's timezone (`TimeZone(identifier:) ?? .current`).
3. Iterates `dayOffset` in `0..<8` (today through 7 days ahead).
4. Skips days where `routine.selectedWeekdays.contains(calendarWeekday:)` is `false`.
5. Computes the day's `SunSchedule` via `SunService.sunSchedule(for:)`. Skips days where the call throws.
6. Resolves the anchor event via `SunSchedule.event(for: routine.sunEventType)`. Skips days where the event is `nil` (polar conditions, or a non-point event type).
7. Applies the offset: `trigger = isBeforeEvent ? eventDate - offsetSeconds : eventDate + offsetSeconds`.
8. Returns `trigger` if it is strictly after `now`; otherwise continues.
9. Returns `nil` if no trigger is found in the 8-day window.

### WeekdaySelection

`WeekdaySelection` is an `OptionSet` with a 7-bit `Int` `rawValue` (one bit per day, Sunday through Saturday). Named presets: `.everyday`, `.weekdays`, `.weekends`. `contains(calendarWeekday:)` maps `Calendar.weekday` integers (1=Sunday, 2=Monday, ..., 7=Saturday) to the correct bit. `friendlyLabel` returns "Every day", "Weekdays", "Weekends", or a comma-joined list of abbreviated day names.

### Before/After Offsets

The offset system uses two fields on `LightRoutine`: `offsetMinutes` (the magnitude) and `isBeforeEvent` (the direction). `ReminderOffset` is a separate enum used only in the edit UI to present named presets (at event, 5, 10, 15, 30, 60 minutes). When the user picks a preset, `offsetMinutes` is set from `ReminderOffset.offsetMinutes`. The direction picker (Before / After) is only shown when `offsetMinutes > 0`.

### Location and Timezone Handling

`RoutineScheduler` and `TodayViewModel` both derive the working `Calendar` from the location's `timeZoneIdentifier`. The fallback chain is: `TimeZone(identifier: location.timeZoneIdentifier) ?? .current`. This means the scheduler correctly handles locations in non-device timezones and degrades gracefully when a stored timezone identifier is stale or malformed.

`locationId` on `LightRoutine` is present in the model but unused in Stage 4. All routines evaluate against the user's active location. Per-routine location overrides are a post-Stage 4 concern.

### RoutinesViewModel

`RoutinesViewModel` is `@Observable` and is the single ViewModel for the Routines tab. It holds references to `RoutineStore` and `SubscriptionService`.

- `canAddRoutine`: `true` when the user is Plus or the routine count is below `FreeTierLimits.maxActiveRoutines` (1).
- `isAtFreeLimit`: `true` when the user is Free and already has 1 routine.
- `triggerDescription(for:)`: returns "At Sunset" (zero offset) or "30 min before Sunset".
- `activeDaysSummary(for:)`: returns `selectedWeekdays.friendlyLabel`.
- All mutations delegate to `RoutineStore`.

### Routine List Screen

`RoutinesView` renders the routine list in a `NavigationStack`. Each routine appears as a `RoutineRow` card:

- Solar event icon (SF Symbol, color-keyed to event type).
- Title, trigger description, and day summary stacked vertically.
- A `checkmark.circle.fill` / `circle` toggle overlaid at the trailing edge for enable/disable.
- Tapping the main area opens the edit sheet.
- Disabled routines render at 60% opacity.
- Accessibility: combined label reads title, trigger, days, and enabled state.

The "+" toolbar button is hidden when `isAtFreeLimit`. A soft purple hint card appears below the list when the free limit is reached. An empty state with an icon and instructional copy is shown when no routines exist.

### Routine Edit Screen

`RoutineEditView` is a sheet-presented form that handles both `.create` and `.edit(LightRoutine)` modes.

- **Name section:** text field; Save button is disabled when trimmed name is empty.
- **Template section (create mode only):** list of `RoutineTemplate.allCases`; Plus templates show a "Plus" badge; selecting a template applies its defaults to all other fields and auto-fills the name if it is empty or matches a template name.
- **Timing section:** event picker from `SunEventType.routineTriggerCases`; offset picker from `ReminderOffset.presets`; before/after segmented picker (hidden when offset is 0).
- **Schedule section:** `WeekdayChipRow` -- seven circular chips (S M T W T F S), amber when active; footer shows `friendlyLabel`.
- **Notification section:** multi-line text field; a Plus hint is shown in the footer when `!subscriptionService.canUseCustomNotificationMessages`.
- **Status section:** enabled toggle.
- **Delete section (edit mode only):** destructive button.

### Today Screen Connection

`TodayView` reads `RoutineStore` from `@Environment`. Its `refresh()` function picks `routineStore.routines.first(where: { $0.isEnabled })` and passes it to `TodayViewModel.refresh(enabledRoutine:)`. The view adds `.onChange(of: routineStore.routines) { refresh() }` so the card updates immediately when routines are created, edited, or toggled.

`TodayViewModel.updateRoutineState` calls `RoutineScheduler.nextTriggerDate` with the active location and the current time to compute the displayed fire time. `nextRoutineTimeText` is set to the formatted time (e.g. "6:47 PM") or "Not available today" when the scheduler returns `nil`. `nextRoutineTriggerText` shows the offset description (e.g. "30 min before Sunset").

`NextRoutineCard` has two states:
- **Routine present:** shows the routine name, next fire time, and offset description.
- **No enabled routine:** shows "No routines yet" with a prompt to the Routines tab.

### Free vs Plus Foundation for Routines

| Capability | Free | Plus |
|---|---|---|
| Active routines | 1 (`FreeTierLimits.maxActiveRoutines`) | Unlimited |
| Templates | Sunset Walk, Custom | All templates |
| Custom notification messages | No | Yes |
| Custom offsets (model level) | Yes (any value stored) | Yes |

The model stores any offset value regardless of tier. UI restrictions are applied at the edit layer via `SubscriptionService` gates. No real StoreKit purchase flow exists yet; `isPlusUser` is toggled directly on `SubscriptionService` for development.

### Edge Cases

**Event already passed today:** On `dayOffset = 0`, the scheduler computes the trigger time and compares it against `now`. If `trigger <= now`, iteration continues to the next day. The first day where `trigger > now` is returned.

**Inactive weekday:** `routine.selectedWeekdays.contains(calendarWeekday:)` is checked before computing the schedule. Non-matching days are skipped with `continue`.

**Disabled routine:** `guard routine.isEnabled else { return nil }` is the first check in `nextTriggerDate`. Disabled routines return `nil` immediately.

**Unavailable sun event (polar day/night):** `SunSchedule.event(for:)` returns `nil` when the requested event did not occur. The scheduler skips that day with `continue`. If the event is unavailable for all 8 days (extreme polar conditions), the scheduler returns `nil` and the Today card shows "Not available today".

**Timezone fallback:** `TimeZone(identifier: location.timeZoneIdentifier) ?? .current` is applied in both `RoutineScheduler` and `TodayViewModel`. A stale or malformed timezone identifier degrades to the device timezone rather than crashing.

### What Is Intentionally Not Included in Stage 4

- **Notification scheduling:** `UNUserNotificationCenter` is not called. `nextTriggerDate` computes the correct time but does not create a system notification. This is Stage 5.
- **Notification permission request:** No `UNUserNotificationCenter.requestAuthorization` call. The notification message field is present in the edit UI but has no live effect.
- **Widgets:** WidgetKit is post-Stage 4. `RoutineStore` and `RoutineScheduler` are designed to be accessible from a widget extension but the extension does not exist yet.
- **Full paywall:** `SubscriptionService.isPlusUser` is a manually toggled Bool. StoreKit 2 purchase and restore flows are stubbed but not implemented.
- **Advanced routine templates beyond the 4 seeded templates:** The template enum can be extended, but no additional templates are defined beyond sunsetWalk, morningLight, windDown, goldenHourShoot, and custom.
- **Per-routine location overrides:** `LightRoutine.locationId` is stored but not used. All routines evaluate against the active location.

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

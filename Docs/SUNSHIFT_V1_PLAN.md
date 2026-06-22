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

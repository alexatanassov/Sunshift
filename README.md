# Sunshift

Alarms that move with the sun. Sunshift lets users build routines anchored to solar events — sunrise, solar noon, sunset, twilight — so their schedule shifts naturally with the seasons and their location.

---

## Current Stage: Stage 0 — Foundation

The app scaffold, navigation, design system, and placeholder domain models are in place. No real solar data or business logic yet.

---

## Tech Stack

- **Language:** Swift 6
- **UI:** SwiftUI (Observable macro, no UIKit wrappers)
- **Target:** iOS 26.5+
- **Project management:** Xcode 26.5, `PBXFileSystemSynchronizedRootGroup` — new Swift files dropped into `Sunshift/` are auto-included without editing `project.pbxproj`

---

## Folder Structure

```
Sunshift/
├── App/
│   ├── SunshiftApp.swift          # @main entry point; injects AppState and SubscriptionService
│   └── SunshiftRootView.swift     # Onboarding gate → MainTabView
├── Core/
│   ├── AppConstants.swift         # App name, tagline
│   └── AppState.swift             # @Observable shared state (onboarding flag, etc.)
├── Design/
│   └── DesignTokens.swift         # SunshiftColors, SunshiftTypography, SunshiftSpacing,
│                                  # SunshiftCornerRadius, SunshiftGradients, cardShadow()
├── Features/
│   ├── Onboarding/
│   │   └── OnboardingView.swift   # Shown on first launch; sets hasCompletedOnboarding
│   ├── Today/
│   │   └── TodayView.swift        # Placeholder — will show today's solar events + active routines
│   ├── Routines/
│   │   └── RoutinesView.swift     # Placeholder — will list and manage light routines
│   ├── Locations/
│   │   └── LocationsView.swift    # Placeholder — will manage saved locations
│   └── Plus/
│       └── PlusView.swift         # Placeholder — subscription upsell / feature gate
├── Models/
│   ├── SunEvent.swift             # Single solar event (type + time)
│   ├── SunEventType.swift         # Enum: sunrise, solarNoon, sunset, twilight…
│   ├── LightRoutine.swift         # User-defined routine anchored to a solar event
│   ├── ReminderOffset.swift       # Offset (±minutes) from a solar event
│   ├── SavedLocation.swift        # Named lat/lon the user has pinned
│   ├── WeekdaySelection.swift     # Bitmask-style weekday picker model
│   └── SubscriptionTier.swift     # .free / .plus
├── Services/
│   ├── SunService.swift           # Stub — will compute solar events for a date + location
│   └── SubscriptionService.swift  # @Observable service wrapping subscription state
├── Storage/
│   └── UserPreferences.swift      # UserDefaults-backed persistence layer
└── Utilities/
    └── DateExtensions.swift       # Date formatting helpers

Docs/
└── SUNSHIFT_V1_PLAN.md            # Full v1 product plan and stage breakdown
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

---

## Upcoming Stages

| Stage | Focus |
|---|---|
| 1 | Solar Calculation Engine — real sunrise/sunset math in `SunService`, no network required |
| 2 | Location System — CoreLocation integration, saved locations, permission flow |
| 3 | Today Screen — live solar timeline, next event countdown, active routines for today |
| 4 | Routine Model + Logic — full `LightRoutine` lifecycle, weekday selection, offset scheduling |
| 5 | Create Routine Flow + Onboarding — routine creation UI, onboarding walkthrough |
| 6 | Notification Scheduling — `UNUserNotificationCenter` integration, offset-aware triggers |
| 7 | Free vs Plus System — feature gates, `SubscriptionService` wired to StoreKit 2 |
| 8 | Premium Feature Buildout — unlimited routines, multiple locations, advanced offsets |
| 9 | Widgets + Travel Mode — WidgetKit extension, automatic location updates when traveling |
| 10 | Polish + App Store Launch — accessibility, localization, App Store assets, review prompts |

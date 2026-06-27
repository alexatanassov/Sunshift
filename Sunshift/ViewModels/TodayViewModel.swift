import Foundation
import Observation

@Observable
final class TodayViewModel {

    // MARK: - Location kind

    enum LocationKind: Equatable {
        case fallback   // San Diego placeholder, no real location set yet
        case current    // live GPS position
        case saved      // user-saved named place
    }

    // MARK: - UI State

    private(set) var locationDisplayName: String = ""
    private(set) var locationSubtitle: String = ""
    private(set) var locationKind: LocationKind = .fallback

    private(set) var schedule: SunSchedule? = nil
    private(set) var weekPreview: [DayPreview] = []

    private(set) var sunriseText: String = "--"
    private(set) var solarNoonText: String = "--"
    private(set) var sunsetText: String = "--"
    private(set) var goldenHourText: String = "--"     // start of evening golden hour
    private(set) var lastLightText: String = "--"

    private(set) var daylightRemainingText: String? = nil

    private(set) var nextEventTitle: String? = nil
    private(set) var nextEventCountdownText: String? = nil

    // MARK: - Routine State

    /// True when an enabled routine exists (even if its trigger time is unavailable).
    private(set) var hasNextRoutine: Bool = false
    private(set) var nextRoutineName: String = ""
    /// Formatted fire time ("6:47 PM") or "Not available today" when the event is missing.
    private(set) var nextRoutineTimeText: String = ""
    /// Human-readable offset description ("30 min before Sunset").
    private(set) var nextRoutineTriggerText: String = ""

    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String? = nil
    private(set) var hasRefreshed: Bool = false

    // True when the active schedule has no sunrise or sunset (polar day or polar night).
    var isPolarDay: Bool {
        guard let s = schedule else { return false }
        return s.sunrise == nil && s.sunset == nil && s.solarNoon != nil
    }

    var isPolarNight: Bool {
        guard let s = schedule else { return false }
        return s.sunrise == nil && s.sunset == nil && s.solarNoon == nil
    }

    // MARK: - Dependencies

    private let sunService: SunService

    init(sunService: SunService = SunService()) {
        self.sunService = sunService
    }

    // MARK: - Refresh

    /// Recomputes all UI state for `location` at `now`.
    /// Pass the first enabled routine so the next-routine card reflects real data.
    func refresh(
        location: SavedLocation,
        isUsingFallback: Bool,
        enabledRoutine: LightRoutine? = nil,
        now: Date = Date()
    ) {
        locationDisplayName = location.name
        locationSubtitle = location.subtitle
        locationKind = resolveLocationKind(location: location, isUsingFallback: isUsingFallback)

        let tz = TimeZone(identifier: location.timeZoneIdentifier) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let startOfDay = cal.startOfDay(for: now)

        let input = SunCalculationInput(
            date: startOfDay,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneIdentifier: location.timeZoneIdentifier
        )

        do {
            let s = try sunService.sunSchedule(for: input)
            schedule = s

            sunriseText    = s.sunrise.map       { $0.formattedTime(in: tz) } ?? "--"
            solarNoonText  = s.solarNoon.map     { $0.formattedTime(in: tz) } ?? "--"
            sunsetText     = s.sunset.map        { $0.formattedTime(in: tz) } ?? "--"
            goldenHourText = s.goldenHourEnd.map { $0.formattedTime(in: tz) } ?? "--"
            lastLightText  = s.lastLight.map     { $0.formattedTime(in: tz) } ?? "--"

            daylightRemainingText = s.daylightRemaining(at: now).map { $0.formattedDaylightRemaining }

            let nextEvent = try sunService.nextRelevantEvent(after: now, schedule: s, input: input)
            nextEventTitle         = nextEvent?.displayName
            nextEventCountdownText = nextEvent.map { $0.time.timeIntervalSince(now).formattedCountdown }

            weekPreview = computeWeekPreview(location: location, tz: tz, cal: cal, now: now)
            errorMessage = nil
        } catch {
            clearScheduleState()
            errorMessage = "Could not load today's sun schedule. Try again shortly."
        }

        updateRoutineState(enabledRoutine: enabledRoutine, location: location, now: now, tz: tz)

        hasRefreshed = true
    }

    // MARK: - Private

    private func updateRoutineState(
        enabledRoutine: LightRoutine?,
        location: SavedLocation,
        now: Date,
        tz: TimeZone
    ) {
        guard let routine = enabledRoutine else {
            hasNextRoutine = false
            nextRoutineName = ""
            nextRoutineTimeText = ""
            nextRoutineTriggerText = ""
            return
        }

        hasNextRoutine = true
        nextRoutineName = routine.title
        nextRoutineTriggerText = formatTriggerText(for: routine)

        if let trigger = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: sunService,
            location: location,
            after: now
        ) {
            nextRoutineTimeText = trigger.formattedTime(in: tz)
        } else {
            nextRoutineTimeText = "Not available today"
        }
    }

    private func resolveLocationKind(location: SavedLocation, isUsingFallback: Bool) -> LocationKind {
        if isUsingFallback { return .fallback }
        if location.isCurrentLocation { return .current }
        return .saved
    }

    private func clearScheduleState() {
        schedule               = nil
        weekPreview            = []
        sunriseText            = "--"
        solarNoonText          = "--"
        sunsetText             = "--"
        goldenHourText         = "--"
        lastLightText          = "--"
        daylightRemainingText  = nil
        nextEventTitle         = nil
        nextEventCountdownText = nil
    }

    private func formatTriggerText(for routine: LightRoutine) -> String {
        let eventName = routine.sunEventType.displayName
        guard routine.offsetMinutes > 0 else { return "At \(eventName)" }
        let direction = routine.isBeforeEvent ? "before" : "after"
        return "\(formatOffset(minutes: routine.offsetMinutes)) \(direction) \(eventName)"
    }

    private func formatOffset(minutes: Int) -> String {
        guard minutes > 0 else { return "" }
        if minutes < 60 { return "\(minutes) min" }
        let hrs = minutes / 60
        let rem = minutes % 60
        if rem == 0 { return hrs == 1 ? "1 hr" : "\(hrs) hrs" }
        return "\(hrs) hr \(rem) min"
    }

    private func computeWeekPreview(
        location: SavedLocation,
        tz: TimeZone,
        cal: Calendar,
        now: Date
    ) -> [DayPreview] {
        var result: [DayPreview] = []
        for dayOffset in 0..<7 {
            guard let candidate = cal.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let startOfDay = cal.startOfDay(for: candidate)
            let input = SunCalculationInput(
                date: startOfDay,
                latitude: location.latitude,
                longitude: location.longitude,
                timeZoneIdentifier: location.timeZoneIdentifier
            )
            guard let s = try? sunService.sunSchedule(for: input) else { continue }
            result.append(DayPreview(
                id: UUID(),
                date: startOfDay,
                timeZoneIdentifier: location.timeZoneIdentifier,
                sunrise: s.sunrise,
                sunset: s.sunset,
                goldenHourStart: s.goldenHourStart,
                goldenHourEnd: s.goldenHourEnd,
                lastLight: s.lastLight,
                daylightDuration: s.daylightDuration
            ))
        }
        return result
    }
}

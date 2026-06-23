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

    private(set) var sunriseText: String = "--"
    private(set) var solarNoonText: String = "--"
    private(set) var sunsetText: String = "--"
    private(set) var goldenHourText: String = "--"     // start of evening golden hour
    private(set) var lastLightText: String = "--"

    private(set) var daylightRemainingText: String? = nil

    private(set) var nextEventTitle: String? = nil
    private(set) var nextEventCountdownText: String? = nil

    private(set) var sunsetWalkTimeText: String? = nil

    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String? = nil
    private(set) var hasRefreshed: Bool = false

    // True when the active schedule has no sunrise or sunset (polar day or polar night).
    // isPolarNight is currently unreachable because SunService always produces a solarNoon.
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
    /// Call from the view on `.task` and whenever the active location changes.
    func refresh(location: SavedLocation, isUsingFallback: Bool, now: Date = Date()) {
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
            sunsetWalkTimeText = s.sunset.map { ($0 - 30 * 60).formattedTime(in: tz) }

            let nextEvent = try sunService.nextRelevantEvent(after: now, schedule: s, input: input)
            nextEventTitle        = nextEvent?.displayName
            nextEventCountdownText = nextEvent.map { $0.time.timeIntervalSince(now).formattedCountdown }

            errorMessage = nil
        } catch {
            clearScheduleState()
            errorMessage = "Could not load today's sun schedule. Try again shortly."
        }

        hasRefreshed = true
    }

    // MARK: - Private

    private func resolveLocationKind(location: SavedLocation, isUsingFallback: Bool) -> LocationKind {
        if isUsingFallback { return .fallback }
        if location.isCurrentLocation { return .current }
        return .saved
    }

    private func clearScheduleState() {
        schedule               = nil
        sunriseText            = "--"
        solarNoonText          = "--"
        sunsetText             = "--"
        goldenHourText         = "--"
        lastLightText          = "--"
        daylightRemainingText  = nil
        nextEventTitle         = nil
        nextEventCountdownText = nil
        sunsetWalkTimeText     = nil
    }
}

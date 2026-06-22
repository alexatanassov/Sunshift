import Foundation

// Self-contained NOAA-style solar position implementation.
// Formulae from Jean Meeus, "Astronomical Algorithms" (2nd ed.) and the
// NOAA Solar Calculator: https://gml.noaa.gov/grad/solcalc/
struct SunService {

    // MARK: - Public API

    /// Calculates a complete SunSchedule for a given location and local date.
    ///
    /// The `date` in `input` is interpreted as a local date in `input.timeZoneIdentifier`.
    /// All returned `Date` values are exact UTC instants.
    /// Events that cannot occur (e.g., polar day/night) are returned as `nil`.
    func sunSchedule(for input: SunCalculationInput) throws -> SunSchedule {
        guard input.latitude >= -90, input.latitude <= 90,
              input.longitude >= -180, input.longitude <= 180 else {
            throw SunCalculationError.invalidCoordinates
        }
        guard let timeZone = TimeZone(identifier: input.timeZoneIdentifier) else {
            throw SunCalculationError.invalidTimeZone
        }

        // 1. Extract local calendar date (year/month/day) in the target timezone.
        var localCal = Calendar(identifier: .gregorian)
        localCal.timeZone = timeZone
        let dc = localCal.dateComponents([.year, .month, .day], from: input.date)
        guard let year = dc.year, let month = dc.month, let day = dc.day else {
            throw SunCalculationError.calculationFailed("Could not extract date components")
        }

        // 2. Build UTC midnight for this calendar date.
        //    The NOAA algorithm expresses all event times as "minutes from UTC midnight"
        //    for the target calendar date, so this is the anchor for Date conversion.
        guard let utcMidnight = Date.localDate(
            year: year, month: month, day: day,
            timeZone: TimeZone(identifier: "UTC")!
        ) else {
            throw SunCalculationError.calculationFailed("Could not create UTC midnight")
        }

        // 3. Julian Day at noon UT for this date, converted to Julian Century from J2000.0.
        //    Using noon UT gives the representative solar position for the day.
        let jd = julianDayAtNoonUT(year: year, month: month, day: day)
        let t = (jd - 2451545.0) / 36525.0

        // 4. Compute solar parameters: equation of time and declination.
        let solar = solarParameters(t: t)

        // 5. Solar noon in minutes from UTC midnight.
        //    720 = 12 × 60 (noon in minutes). Longitude shifts by 4 min/°.
        //    Equation of time corrects for the eccentricity and axial tilt of Earth's orbit.
        let solarNoonUTCMins = 720.0 - 4.0 * input.longitude - solar.equationOfTimeMins

        // MARK: - Helpers

        /// Converts minutes-from-UTC-midnight to a `Date`. Returns nil for non-finite values.
        func date(fromUTCMins mins: Double?) -> Date? {
            guard let m = mins, m.isFinite else { return nil }
            return utcMidnight.addingTimeInterval(m * 60.0)
        }

        /// Returns minutes-from-UTC-midnight when the sun crosses `altitudeDeg`.
        func utcMins(altitude deg: Double, isMorning: Bool) -> Double? {
            crossingUTCMins(
                altitudeDeg: deg,
                latDeg: input.latitude,
                declinationRad: solar.declinationRad,
                solarNoonUTCMins: solarNoonUTCMins,
                isMorning: isMorning
            )
        }

        // MARK: - Event calculations
        //
        // Field naming convention (both golden and blue hour use the same pattern):
        //   *Start = morning crossing (inner edge going up)
        //   *End   = evening crossing (inner edge going down)
        //
        // Day segment order for a typical mid-latitude date:
        //   firstLight (−6°) → blueHourStart (−4°) → sunrise (−0.833°)
        //   → goldenHourStart (+6°) → solarNoon → goldenHourEnd (+6°)
        //   → sunset (−0.833°) → blueHourEnd (−4°) → lastLight (−6°)
        //
        // Morning golden hour = [sunrise … goldenHourStart]
        // Evening golden hour = [goldenHourEnd … sunset]
        // Morning blue hour   = [firstLight … blueHourStart]
        // Evening blue hour   = [blueHourEnd … lastLight]

        let sunrise         = date(fromUTCMins: utcMins(altitude: -0.833, isMorning: true))
        let sunset          = date(fromUTCMins: utcMins(altitude: -0.833, isMorning: false))
        let firstLight      = date(fromUTCMins: utcMins(altitude: -6.0,   isMorning: true))
        let lastLight       = date(fromUTCMins: utcMins(altitude: -6.0,   isMorning: false))
        let blueHourStart   = date(fromUTCMins: utcMins(altitude: -4.0,   isMorning: true))
        let blueHourEnd     = date(fromUTCMins: utcMins(altitude: -4.0,   isMorning: false))
        let goldenHourStart = date(fromUTCMins: utcMins(altitude: 6.0,    isMorning: true))
        let goldenHourEnd   = date(fromUTCMins: utcMins(altitude: 6.0,    isMorning: false))
        let solarNoon       = date(fromUTCMins: solarNoonUTCMins)

        // Civil twilight coincides with first/last light at −6°.
        let civilTwilightStart = firstLight
        let civilTwilightEnd   = lastLight

        // Daylight duration: total time between sunrise and sunset.
        var daylightDuration: TimeInterval? = nil
        if let rise = sunrise, let set = sunset {
            daylightDuration = set.timeIntervalSince(rise)
        }

        // Daylight remaining: non-nil when input.date is before sunset on the same local day.
        var daylightRemaining: TimeInterval? = nil
        if let set = sunset,
           input.date < set,
           input.date.isSameLocalDay(as: set, in: timeZone) {
            daylightRemaining = set.timeIntervalSince(input.date)
        }

        // Next scheduled event after input.date, using all events computed above.
        let eventCandidates: [(SunEventType, Date?)] = [
            (.firstLight,      firstLight),
            (.blueHourStart,   blueHourStart),
            (.sunrise,         sunrise),
            (.goldenHourStart, goldenHourStart),
            (.solarNoon,       solarNoon),
            (.goldenHourEnd,   goldenHourEnd),
            (.sunset,          sunset),
            (.blueHourEnd,     blueHourEnd),
            (.lastLight,       lastLight),
        ]
        let nextEvent: SunEvent? = eventCandidates
            .compactMap { type, date -> SunEvent? in
                guard let d = date, d > input.date else { return nil }
                return SunEvent(type: type, time: d)
            }
            .min(by: { $0.time < $1.time })

        return SunSchedule(
            date: input.date,
            latitude: input.latitude,
            longitude: input.longitude,
            timeZoneIdentifier: input.timeZoneIdentifier,
            sunrise: sunrise,
            sunset: sunset,
            solarNoon: solarNoon,
            goldenHourStart: goldenHourStart,
            goldenHourEnd: goldenHourEnd,
            blueHourStart: blueHourStart,
            blueHourEnd: blueHourEnd,
            firstLight: firstLight,
            lastLight: lastLight,
            civilTwilightStart: civilTwilightStart,
            civilTwilightEnd: civilTwilightEnd,
            daylightDuration: daylightDuration,
            daylightRemaining: daylightRemaining,
            nextEvent: nextEvent
        )
    }

    // MARK: - Private

    private struct SolarParameters {
        let equationOfTimeMins: Double
        let declinationRad: Double
    }

    /// Julian Day at noon UT (12:00 UTC) for the given Gregorian calendar date.
    /// Algorithm: Jean Meeus, "Astronomical Algorithms", Ch. 7.
    private func julianDayAtNoonUT(year: Int, month: Int, day: Int) -> Double {
        var y = year
        var m = month
        // January and February are treated as months 13 and 14 of the previous year.
        if m <= 2 { y -= 1; m += 12 }
        let a = Int(Double(y) / 100.0)
        let b = 2 - a + a / 4  // Gregorian calendar correction
        // The base formula gives JD at 0h UT; +0.5 shifts to noon UT.
        return floor(365.25 * Double(y + 4716))
             + floor(30.6001 * Double(m + 1))
             + Double(day) + Double(b) - 1524.5 + 0.5
    }

    /// Computes solar declination (radians) and equation of time (minutes) from a Julian Century.
    /// Source: NOAA Solar Calculator equations.
    private func solarParameters(t: Double) -> SolarParameters {
        // Geometric mean longitude of sun (degrees), clamped to [0, 360).
        let l0 = (280.46646 + t * (36000.76983 + t * 0.0003032))
                    .truncatingRemainder(dividingBy: 360.0)

        // Geometric mean anomaly of sun (degrees).
        let mDeg = 357.52911 + t * (35999.05029 - t * 0.0001537)
        let mRad = mDeg * .pi / 180.0

        // Eccentricity of Earth's orbit (dimensionless).
        let e = 0.016708634 - t * (0.000042037 + t * 0.0000001267)

        // Equation of the center: correction from mean to true anomaly (degrees).
        let c = sin(mRad) * (1.914602 - t * (0.004817 + t * 0.000014))
              + sin(2.0 * mRad) * (0.019993 - t * 0.000101)
              + sin(3.0 * mRad) * 0.000289

        // Sun's true longitude (degrees).
        let sunTrueLon = l0 + c

        // Sun's apparent longitude: applies small nutation and aberration corrections.
        // Ω = longitude of the ascending node of the moon's mean orbit.
        let omegaRad = (125.04 - 1934.136 * t) * .pi / 180.0
        let lambdaRad = (sunTrueLon - 0.00569 - 0.00478 * sin(omegaRad)) * .pi / 180.0

        // Mean obliquity of the ecliptic (degrees): Earth's axial tilt, slowly changing.
        let epsilon0 = 23.0
                     + (26.0 + (21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0

        // Corrected obliquity: small nutation term using Ω.
        let epsilonRad = (epsilon0 + 0.00256 * cos(omegaRad)) * .pi / 180.0

        // Solar declination: angular distance of sun north/south of celestial equator.
        let declinationRad = asin(sin(epsilonRad) * sin(lambdaRad))

        // Equation of time (minutes): difference between mean and apparent solar time.
        // Derived from the series expansion in Meeus Ch. 27.
        let y = pow(tan(epsilonRad / 2.0), 2.0)
        let l0Rad = l0 * .pi / 180.0
        let eqTRad = y * sin(2.0 * l0Rad)
                   - 2.0 * e * sin(mRad)
                   + 4.0 * e * y * sin(mRad) * cos(2.0 * l0Rad)
                   - 0.5 * y * y * sin(4.0 * l0Rad)
                   - 1.25 * e * e * sin(2.0 * mRad)
        // Convert radians → degrees → minutes (4 min per degree of arc).
        let equationOfTimeMins = eqTRad * (180.0 / .pi) * 4.0

        return SolarParameters(equationOfTimeMins: equationOfTimeMins, declinationRad: declinationRad)
    }

    /// Returns minutes from UTC midnight when the sun crosses `altitudeDeg` on the target date.
    ///
    /// Solves the solar hour angle equation:
    ///   cos(HA) = ( sin(alt) − sin(lat) · sin(dec) ) / ( cos(lat) · cos(dec) )
    ///
    /// The hour angle is symmetric about solar noon; `isMorning` selects the AM or PM crossing.
    /// Returns `nil` when the sun never reaches `altitudeDeg` (cosHA outside [−1, 1]),
    /// which indicates polar day (sun always above) or polar night (sun always below).
    private func crossingUTCMins(
        altitudeDeg: Double,
        latDeg: Double,
        declinationRad: Double,
        solarNoonUTCMins: Double,
        isMorning: Bool
    ) -> Double? {
        let latRad = latDeg * .pi / 180.0
        let altRad = altitudeDeg * .pi / 180.0

        let cosHA = (sin(altRad) - sin(latRad) * sin(declinationRad))
                  / (cos(latRad) * cos(declinationRad))

        guard cosHA >= -1.0, cosHA <= 1.0 else { return nil }

        // Hour angle in degrees, then converted to minutes of time (4 min/°).
        let offsetMins = acos(cosHA) * (180.0 / .pi) * 4.0

        return isMorning ? solarNoonUTCMins - offsetMins : solarNoonUTCMins + offsetMins
    }
}

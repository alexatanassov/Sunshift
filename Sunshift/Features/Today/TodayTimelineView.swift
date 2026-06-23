import SwiftUI

struct TodayTimelineView: View {
    let schedule: SunSchedule
    let now: Date

    private var timeZone: TimeZone {
        TimeZone(identifier: schedule.timeZoneIdentifier) ?? .current
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.sm) {
            Text("Light today")
                .font(SunshiftTypography.headline())
                .foregroundStyle(SunshiftColors.primaryText)
            timelineContent
        }
        .padding(SunshiftSpacing.md)
        .background(
            SunshiftColors.cardBackground,
            in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium)
        )
        .cardShadow()
    }

    // MARK: - Day classification

    private enum DayType { case normal, polarDay, polarNight }

    private var dayType: DayType {
        if schedule.sunrise != nil || schedule.sunset != nil { return .normal }
        return schedule.solarNoon != nil ? .polarDay : .polarNight
    }

    @ViewBuilder
    private var timelineContent: some View {
        switch dayType {
        case .polarDay:
            specialStateRow(
                icon: "sun.max.fill",
                color: SunshiftColors.sunsetAmber,
                text: "Daylight all day"
            )
        case .polarNight:
            specialStateRow(
                icon: "moon.stars.fill",
                color: SunshiftColors.duskPurple,
                text: "No sunrise today"
            )
        case .normal:
            VStack(spacing: 8) {
                barWithIndicator
                eventLabels
            }
        }
    }

    private func specialStateRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: SunshiftSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SunshiftSpacing.xs)
    }

    // MARK: - Timeline range

    private var rangeStart: Date {
        let base = schedule.date.startOfDay(in: timeZone)
        guard let fl = schedule.firstLight else { return base }
        return max(base, fl.addingTimeInterval(-3600))
    }

    private var rangeEnd: Date {
        let base = schedule.date.addingDays(1, in: timeZone)
        guard let ll = schedule.lastLight else { return base }
        return min(base, ll.addingTimeInterval(3600))
    }

    private var totalDuration: Double {
        max(1, rangeEnd.timeIntervalSince(rangeStart))
    }

    private func fraction(of date: Date?) -> CGFloat? {
        guard let date = date else { return nil }
        let f = CGFloat(date.timeIntervalSince(rangeStart) / totalDuration)
        return f.isFinite ? f : nil
    }

    private var nowFraction: CGFloat? { fraction(of: now) }

    // MARK: - Gradient

    private var timelineGradient: LinearGradient {
        let night = SunshiftColors.nightNavy
        let dawn  = Color(red: 0.38, green: 0.40, blue: 0.65)
        let peach = SunshiftColors.sunrisePeach
        let gold  = Color(red: 1.00, green: 0.82, blue: 0.38)
        let day   = Color(red: 0.99, green: 0.91, blue: 0.62)
        let amber = SunshiftColors.sunsetAmber
        let dusk  = SunshiftColors.duskPurple

        var stops: [Gradient.Stop] = [.init(color: night, location: 0)]

        func add(_ date: Date?, _ color: Color) {
            guard let f = fraction(of: date) else { return }
            stops.append(.init(color: color, location: max(0, min(1, f))))
        }

        add(schedule.firstLight,      dawn)
        add(schedule.blueHourStart,   dawn)
        add(schedule.sunrise,         peach)
        add(schedule.goldenHourStart, gold)
        add(schedule.solarNoon,       day)
        add(schedule.goldenHourEnd,   amber)
        add(schedule.sunset,          peach)
        add(schedule.blueHourEnd,     dusk)
        add(schedule.lastLight,       night)

        stops.append(.init(color: night, location: 1))
        stops.sort { $0.location < $1.location }

        var deduped: [Gradient.Stop] = []
        for stop in stops {
            if let last = deduped.last, abs(last.location - stop.location) < 0.001 {
                deduped[deduped.count - 1] = stop
            } else {
                deduped.append(stop)
            }
        }

        return LinearGradient(stops: deduped, startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - Now dot color

    private var nowDotColor: Color {
        let s = schedule
        if let fl = s.firstLight,      now < fl  { return SunshiftColors.nightNavy }
        if let ll = s.lastLight,       now >= ll  { return SunshiftColors.nightNavy }
        if let sr = s.sunrise,         now < sr   { return Color(red: 0.38, green: 0.40, blue: 0.65) }
        if let gs = s.goldenHourStart, now < gs   { return SunshiftColors.sunrisePeach }
        if let ge = s.goldenHourEnd,   now < ge   { return Color(red: 1.00, green: 0.82, blue: 0.38) }
        if let ss = s.sunset,          now < ss   { return SunshiftColors.sunsetAmber }
        return SunshiftColors.duskPurple
    }

    // MARK: - Bar

    private var barWithIndicator: some View {
        Capsule()
            .fill(timelineGradient)
            .frame(height: 14)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    if let frac = nowFraction, frac >= 0, frac <= 1 {
                        let x = max(9, min(frac * geo.size.width, geo.size.width - 9))
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 18, height: 18)
                                .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 1)
                            Circle()
                                .fill(nowDotColor)
                                .frame(width: 8, height: 8)
                        }
                        .position(x: x, y: geo.size.height / 2)
                    }
                }
            }
    }

    // MARK: - Labels

    private struct LabelItem: Identifiable {
        let id = UUID()
        let date: Date
        let name: String
        let timeString: String
    }

    private var labelItems: [LabelItem] {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        fmt.timeZone = timeZone

        var items: [LabelItem] = []
        if let d = schedule.sunrise {
            items.append(LabelItem(date: d, name: "Sunrise", timeString: fmt.string(from: d)))
        }
        if let d = schedule.sunset {
            items.append(LabelItem(date: d, name: "Sunset", timeString: fmt.string(from: d)))
        }
        return items
    }

    private var eventLabels: some View {
        GeometryReader { geo in
            ForEach(labelItems) { item in
                if let frac = fraction(of: item.date) {
                    let x = max(30, min(frac * geo.size.width, geo.size.width - 30))
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(SunshiftColors.secondaryText.opacity(0.25))
                            .frame(width: 1, height: 5)
                        Text(item.timeString)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(SunshiftColors.primaryText)
                        Text(item.name)
                            .font(.system(size: 9, weight: .regular, design: .rounded))
                            .foregroundStyle(SunshiftColors.secondaryText)
                    }
                    .fixedSize()
                    .position(x: x, y: 16)
                }
            }
        }
        .frame(height: 36)
    }
}

// MARK: - Preview

#Preview {
    let tz = TimeZone(identifier: "America/Los_Angeles")!
    let today = Date()
    func t(_ h: Int, _ m: Int) -> Date {
        Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: today)!
    }
    return TodayTimelineView(
        schedule: SunSchedule(
            date: today,
            latitude: 32.7157,
            longitude: -117.1611,
            timeZoneIdentifier: tz.identifier,
            sunrise:         t(5, 45),
            sunset:          t(19, 58),
            solarNoon:       t(12, 51),
            goldenHourStart: t(6, 15),
            goldenHourEnd:   t(19, 28),
            blueHourStart:   t(5, 17),
            blueHourEnd:     t(20, 24),
            firstLight:      t(5, 17),
            lastLight:       t(20, 24)
        ),
        now: t(14, 30)
    )
    .padding()
    .background(SunshiftColors.softBackground)
}

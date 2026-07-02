import SwiftUI

struct WeekPreviewView: View {
    let viewModel: TodayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Light this week")
                .font(SunshiftTypography.headline())
                .foregroundStyle(SunshiftColors.primaryText)
                .padding(.horizontal, SunshiftSpacing.md)
                .padding(.top, SunshiftSpacing.md)
                .padding(.bottom, SunshiftSpacing.sm)

            content
        }
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.weekPreview.isEmpty {
            Text("Weekly light data is unavailable for this location.")
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, SunshiftSpacing.md)
                .padding(.bottom, SunshiftSpacing.md)
        } else {
            weekRows
        }
    }

    private var weekRows: some View {
        let previews = Array(viewModel.weekPreview.prefix(7))
        return VStack(spacing: 0) {
            ForEach(previews) { preview in
                if preview.id != previews.first?.id {
                    Divider()
                        .padding(.leading, SunshiftSpacing.md)
                }
                WeekPreviewRow(preview: preview)
            }
        }
    }
}

// MARK: - Week Preview Row

private struct WeekPreviewRow: View {
    let preview: DayPreview

    private var timeZone: TimeZone {
        TimeZone(identifier: preview.timeZoneIdentifier) ?? .current
    }

    var body: some View {
        HStack(spacing: SunshiftSpacing.sm) {
            dayLabel
            Spacer()
            sunriseLabel
            sunsetLabel
            durationLabel
        }
        .padding(.horizontal, SunshiftSpacing.md)
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var dayLabel: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(weekdayText)
                .font(SunshiftTypography.caption(11))
                .foregroundStyle(SunshiftColors.secondaryText)
            Text(dayNumberText)
                .font(SunshiftTypography.headline())
                .foregroundStyle(SunshiftColors.primaryText)
        }
        .frame(width: 36, alignment: .leading)
    }

    private var sunriseLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 10))
                .foregroundStyle(SunshiftColors.sunrisePeach)
            Text(sunriseText)
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.primaryText)
                .monospacedDigit()
        }
    }

    private var sunsetLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: "sunset.fill")
                .font(.system(size: 10))
                .foregroundStyle(SunshiftColors.sunsetAmber)
            Text(sunsetText)
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.primaryText)
                .monospacedDigit()
        }
    }

    private var durationLabel: some View {
        Text(durationText)
            .font(SunshiftTypography.caption())
            .foregroundStyle(SunshiftColors.secondaryText)
            .monospacedDigit()
            .frame(minWidth: 44, alignment: .trailing)
    }

    private var weekdayText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        fmt.timeZone = timeZone
        return fmt.string(from: preview.date)
    }

    private var dayNumberText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        fmt.timeZone = timeZone
        return fmt.string(from: preview.date)
    }

    private var sunriseText: String {
        preview.sunrise.map { $0.formattedTime(in: timeZone) } ?? "--"
    }

    private var sunsetText: String {
        preview.sunset.map { $0.formattedTime(in: timeZone) } ?? "--"
    }

    private var durationText: String {
        preview.daylightDuration.map { $0.formattedDuration } ?? "--"
    }

    private var accessibilityText: String {
        "\(weekdayText) \(dayNumberText). Sunrise \(sunriseText). Sunset \(sunsetText). Daylight \(durationText)."
    }
}

// MARK: - Previews

#Preview("Empty") {
    WeekPreviewView(viewModel: TodayViewModel())
        .padding()
        .background(SunshiftColors.softBackground)
}

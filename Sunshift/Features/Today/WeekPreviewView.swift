import SwiftUI

struct WeekPreviewView: View {
    let viewModel: TodayViewModel
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var showingPlus = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Light this week")
                .font(SunshiftTypography.headline())
                .foregroundStyle(SunshiftColors.primaryText)
                .padding(.horizontal, SunshiftSpacing.md)
                .padding(.top, SunshiftSpacing.md)
                .padding(.bottom, SunshiftSpacing.sm)

            if subscriptionService.canUse7DayPreview {
                plusContent
            } else {
                lockedContent
            }
        }
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
        .sheet(isPresented: $showingPlus) {
            PlusView()
                .environment(subscriptionService)
        }
    }

    // MARK: - Plus content

    @ViewBuilder
    private var plusContent: some View {
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

    // MARK: - Locked content

    private var lockedContent: some View {
        Button {
            showingPlus = true
        } label: {
            HStack(spacing: SunshiftSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(SunshiftColors.sunsetAmber)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: SunshiftSpacing.xs) {
                    Text("Sunrise and sunset for the next 7 days.")
                        .font(SunshiftTypography.body())
                        .foregroundStyle(SunshiftColors.primaryText)
                        .multilineTextAlignment(.leading)
                    Text("Available with Helio Plus.")
                        .font(SunshiftTypography.caption())
                        .foregroundStyle(SunshiftColors.secondaryText)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(SunshiftColors.secondaryText.opacity(0.55))
            }
            .padding(.horizontal, SunshiftSpacing.md)
            .padding(.bottom, SunshiftSpacing.md)
        }
        .buttonStyle(.plain)
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

#Preview("Free") {
    WeekPreviewView(viewModel: TodayViewModel())
        .environment(SubscriptionService())
        .padding()
        .background(SunshiftColors.softBackground)
}

#Preview("Plus (empty)") {
    let svc = SubscriptionService()
    svc.isPlusUser = true
    return WeekPreviewView(viewModel: TodayViewModel())
        .environment(svc)
        .padding()
        .background(SunshiftColors.softBackground)
}

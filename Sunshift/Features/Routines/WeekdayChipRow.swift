import SwiftUI

struct WeekdayChipRow: View {
    @Binding var selection: WeekdaySelection

    private struct DayChip: Identifiable {
        let id: Int
        let day: WeekdaySelection
        let label: String
        let fullName: String
    }

    private let chips: [DayChip] = [
        DayChip(id: 0, day: .sunday,    label: "S", fullName: "Sunday"),
        DayChip(id: 1, day: .monday,    label: "M", fullName: "Monday"),
        DayChip(id: 2, day: .tuesday,   label: "T", fullName: "Tuesday"),
        DayChip(id: 3, day: .wednesday, label: "W", fullName: "Wednesday"),
        DayChip(id: 4, day: .thursday,  label: "T", fullName: "Thursday"),
        DayChip(id: 5, day: .friday,    label: "F", fullName: "Friday"),
        DayChip(id: 6, day: .saturday,  label: "S", fullName: "Saturday"),
    ]

    var body: some View {
        HStack(spacing: SunshiftSpacing.sm) {
            ForEach(chips) { chip in
                let isOn = selection.contains(chip.day)
                Button {
                    if isOn {
                        selection.remove(chip.day)
                    } else {
                        selection.insert(chip.day)
                    }
                } label: {
                    Text(chip.label)
                        .font(SunshiftTypography.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(isOn ? .white : SunshiftColors.secondaryText)
                        .frame(width: 36, height: 36)
                        .background(
                            isOn
                                ? AnyShapeStyle(SunshiftColors.sunsetAmber)
                                : AnyShapeStyle(SunshiftColors.softBackground),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isOn)
                .accessibilityLabel(chip.fullName)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
    }
}

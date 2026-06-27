import SwiftUI

struct PlusView: View {
    @Environment(SubscriptionService.self) private var subscriptionService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.xl) {
                    if subscriptionService.isPlusUser {
                        subscribedHero
                    } else {
                        paywallHero
                    }

                    featuresList

                    if !subscriptionService.isPlusUser {
                        ctaSection
                    }

                    #if DEBUG
                    developerSection
                    #endif

                    Spacer(minLength: SunshiftSpacing.xl)
                }
                .padding(.top, SunshiftSpacing.lg)
                .padding(.bottom, SunshiftSpacing.xl)
            }
            .background(SunshiftColors.softBackground)
            .navigationTitle("Plus")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(SunshiftColors.softBackground)
    }

    // MARK: - Heroes

    private var paywallHero: some View {
        VStack(spacing: SunshiftSpacing.sm) {
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 72))
                .foregroundStyle(SunshiftGradients.dusk)

            VStack(spacing: SunshiftSpacing.xs) {
                Text("Sunshift Plus")
                    .font(SunshiftTypography.display())
                    .foregroundStyle(SunshiftColors.primaryText)

                Text("Build your whole day around the light.")
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, SunshiftSpacing.lg)
    }

    private var subscribedHero: some View {
        VStack(spacing: SunshiftSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(SunshiftColors.sunsetAmber)

            VStack(spacing: SunshiftSpacing.xs) {
                Text("You have Sunshift Plus")
                    .font(SunshiftTypography.display())
                    .foregroundStyle(SunshiftColors.primaryText)
                    .multilineTextAlignment(.center)

                Text("All features are unlocked. Enjoy the light.")
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, SunshiftSpacing.lg)
    }

    // MARK: - Feature list

    private var featuresList: some View {
        VStack(spacing: SunshiftSpacing.sm) {
            PlusFeatureRow(
                icon: "bell.badge.fill",
                color: SunshiftColors.sunrisePeach,
                title: "Unlimited Routines",
                detail: "One routine on the free plan. Plus removes the limit."
            )
            PlusFeatureRow(
                icon: "square.grid.2x2.fill",
                color: SunshiftColors.sunsetAmber,
                title: "All Templates",
                detail: "Morning Light, Wind Down, Golden Hour Shoot, and more."
            )
            PlusFeatureRow(
                icon: "location.fill",
                color: SunshiftColors.sunsetAmber,
                title: "Multiple Saved Locations",
                detail: "Pin home, office, or anywhere you spend time regularly."
            )
            PlusFeatureRow(
                icon: "text.bubble.fill",
                color: SunshiftColors.duskPurple,
                title: "Custom Notifications",
                detail: "Write your own reminder message for each routine."
            )
            PlusFeatureRow(
                icon: "slider.horizontal.3",
                color: SunshiftColors.sunrisePeach,
                title: "Advanced Timing",
                detail: "Fine-grained offsets: 5, 10, and 60 minute options."
            )
            PlusFeatureRow(
                icon: "calendar",
                color: SunshiftColors.duskPurple,
                title: "7-Day Light Preview",
                detail: "See sunrise and sunset times for the week ahead."
            )
        }
        .padding(.horizontal, SunshiftSpacing.md)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: SunshiftSpacing.sm) {
            Button {
                #if DEBUG
                subscriptionService.isPlusUser = true
                #else
                Task { try? await subscriptionService.purchase() }
                #endif
            } label: {
                Text("Get Sunshift Plus")
                    .font(SunshiftTypography.headline())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(SunshiftColors.sunsetAmber)
            .controlSize(.large)
            .padding(.horizontal, SunshiftSpacing.md)

            Button {
                Task { try? await subscriptionService.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(SunshiftTypography.caption())
                    .foregroundStyle(SunshiftColors.secondaryText)
            }
        }
    }

    // MARK: - Developer section

    #if DEBUG
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.sm) {
            Text("Developer")
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.secondaryText)
                .textCase(.uppercase)
                .kerning(0.5)
                .padding(.horizontal, SunshiftSpacing.md)

            Toggle(
                "Simulate Plus",
                isOn: Binding(
                    get: { subscriptionService.isPlusUser },
                    set: { subscriptionService.isPlusUser = $0 }
                )
            )
            .font(SunshiftTypography.body())
            .tint(SunshiftColors.sunsetAmber)
            .padding(SunshiftSpacing.md)
            .background(
                SunshiftColors.cardBackground,
                in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium)
            )
            .cardShadow()
            .padding(.horizontal, SunshiftSpacing.md)
        }
    }
    #endif
}

// MARK: - Feature Row

private struct PlusFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: SunshiftSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(SunshiftColors.primaryText)
                Text(detail)
                    .font(SunshiftTypography.caption())
                    .foregroundStyle(SunshiftColors.secondaryText)
            }
            Spacer()
        }
        .padding(SunshiftSpacing.md)
        .background(
            SunshiftColors.cardBackground,
            in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium)
        )
        .cardShadow()
    }
}

// MARK: - Previews

#Preview("Free") {
    PlusView()
        .environment(SubscriptionService())
}

#Preview("Plus") {
    let svc = SubscriptionService()
    svc.isPlusUser = true
    return PlusView()
        .environment(svc)
}

import SwiftUI

struct PlusView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var showingPurchaseUnavailable = false

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
            .alert("In-App Purchases Coming Soon", isPresented: $showingPurchaseUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Helio Plus is not available for purchase in this build yet.")
            }
        }
        .background(SunshiftColors.softBackground)
    }

    // MARK: - Heroes

    private var paywallHero: some View {
        VStack(spacing: SunshiftSpacing.sm) {
            // TODO: Replace temp mascot with final transparent Helio mascot asset.
            Image("helio-mascot-temp")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            VStack(spacing: SunshiftSpacing.xs) {
                Text("Helio Plus")
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
                Text("You have Helio Plus")
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
                icon: "moon.haze.fill",
                color: SunshiftColors.duskPurple,
                title: "Advanced Light Events",
                detail: "Blue hour, civil twilight, and first and last light as routine anchors."
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
                showingPurchaseUnavailable = true
                #endif
            } label: {
                Text("Get Helio Plus")
                    .font(SunshiftTypography.headline())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(SunshiftColors.sunsetAmber)
            .controlSize(.large)
            .padding(.horizontal, SunshiftSpacing.md)

            Button {
                #if DEBUG
                Task { try? await subscriptionService.restorePurchases() }
                #else
                showingPurchaseUnavailable = true
                #endif
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(detail).")
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

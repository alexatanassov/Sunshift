import Testing
@testable import Sunshift

struct AppConstantsTests {
    @Test func appNameIsHelio() {
        #expect(AppConstants.appName == "Helio")
    }

    @Test func taglineMatchesBrand() {
        #expect(AppConstants.tagline == "Plan your day around the sun.")
    }
}

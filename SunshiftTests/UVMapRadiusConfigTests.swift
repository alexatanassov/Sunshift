import Testing
@testable import Sunshift

struct UVMapRadiusConfigTests {

    @Test func defaultRadiusIs25Miles() {
        #expect(UVMapRadiusConfig.defaultRadiusMiles == 25)
    }

    @Test func spanDegreesScalesLinearlyWithRadius() {
        let span20 = UVMapRadiusConfig.spanDegrees(forRadiusMiles: 20)
        let span25 = UVMapRadiusConfig.spanDegrees(forRadiusMiles: 25)
        let span30 = UVMapRadiusConfig.spanDegrees(forRadiusMiles: 30)

        #expect(span20 < span25)
        #expect(span25 < span30)
        #expect(abs(span30 / span20 - 30.0 / 20.0) < 0.0001)
    }

    @Test func defaultSpanDegreesMatchesDefaultRadius() {
        let expected = UVMapRadiusConfig.spanDegrees(forRadiusMiles: UVMapRadiusConfig.defaultRadiusMiles)
        #expect(UVMapRadiusConfig.defaultSpanDegrees == expected)
    }

    @Test func spanDegreesFallsWithinSamplerMaxSpan() {
        #expect(UVMapRadiusConfig.defaultSpanDegrees <= UVMapGridSampler.maxSpanDegrees)
    }
}

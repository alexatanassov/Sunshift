import Testing
import Foundation
@testable import Sunshift

// Serialized because MockURLProtocol.stub is shared mutable state.
@Suite(.serialized)
struct OpenMeteoUVServiceTests {

    private func makeService() -> OpenMeteoUVService {
        OpenMeteoUVService(session: MockURLProtocol.makeSession())
    }

    // MARK: - Single location

    @Test func decodesSuccessfulSingleLocationResponse() async throws {
        let json = """
        {
            "latitude": 32.75,
            "longitude": -117.15,
            "current": {"time": "2026-07-15T14:00", "interval": 900, "uv_index": 6.4}
        }
        """
        MockURLProtocol.stub = .init(statusCode: 200, data: Data(json.utf8))

        let service = makeService()
        let points = try await service.fetchCurrentUVIndex(
            for: [UVForecastCoordinate(latitude: 32.75, longitude: -117.15)]
        )

        #expect(points.count == 1)
        #expect(points[0].uvIndex == 6.4)
        #expect(points[0].latitude == 32.75)
        #expect(points[0].longitude == -117.15)
    }

    // MARK: - Multi location

    @Test func decodesSuccessfulMultiLocationResponse() async throws {
        let json = """
        [
            {
                "latitude": 32.75,
                "longitude": -117.15,
                "current": {"time": "2026-07-15T14:00", "interval": 900, "uv_index": 6.4}
            },
            {
                "latitude": 48.85,
                "longitude": 2.35,
                "current": {"time": "2026-07-15T14:00", "interval": 900, "uv_index": 2.1}
            }
        ]
        """
        MockURLProtocol.stub = .init(statusCode: 200, data: Data(json.utf8))

        let service = makeService()
        let points = try await service.fetchCurrentUVIndex(for: [
            UVForecastCoordinate(latitude: 32.75, longitude: -117.15),
            UVForecastCoordinate(latitude: 48.85, longitude: 2.35),
        ])

        #expect(points.count == 2)
        #expect(points[0].uvIndex == 6.4)
        #expect(points[1].uvIndex == 2.1)
    }

    @Test func multiLocationResponsePreservesInputCoordinateOrder() async throws {
        let json = """
        [
            {"latitude": 1, "longitude": 1, "current": {"time": "2026-07-15T14:00", "uv_index": 1.0}},
            {"latitude": 2, "longitude": 2, "current": {"time": "2026-07-15T14:00", "uv_index": 2.0}},
            {"latitude": 3, "longitude": 3, "current": {"time": "2026-07-15T14:00", "uv_index": 3.0}}
        ]
        """
        MockURLProtocol.stub = .init(statusCode: 200, data: Data(json.utf8))

        let inputCoordinates = [
            UVForecastCoordinate(latitude: 10, longitude: 10),
            UVForecastCoordinate(latitude: 20, longitude: 20),
            UVForecastCoordinate(latitude: 30, longitude: 30),
        ]
        let service = makeService()
        let points = try await service.fetchCurrentUVIndex(for: inputCoordinates)

        #expect(points.map(\.latitude) == inputCoordinates.map(\.latitude))
        #expect(points.map(\.longitude) == inputCoordinates.map(\.longitude))
        #expect(points.map(\.uvIndex) == [1.0, 2.0, 3.0])
    }

    // MARK: - Errors

    @Test func nonSuccessStatusCodeThrowsBadResponse() async throws {
        MockURLProtocol.stub = .init(statusCode: 500, data: Data("{}".utf8))

        let service = makeService()
        await #expect(throws: UVForecastError.self) {
            _ = try await service.fetchCurrentUVIndex(
                for: [UVForecastCoordinate(latitude: 0, longitude: 0)]
            )
        }
    }

    @Test func nonSuccessStatusCodeThrowsWithStatusCode() async throws {
        MockURLProtocol.stub = .init(statusCode: 404, data: Data("{}".utf8))

        let service = makeService()
        do {
            _ = try await service.fetchCurrentUVIndex(
                for: [UVForecastCoordinate(latitude: 0, longitude: 0)]
            )
            Issue.record("Expected badResponse to be thrown")
        } catch UVForecastError.badResponse(let statusCode) {
            #expect(statusCode == 404)
        } catch {
            Issue.record("Expected UVForecastError.badResponse, got \(error)")
        }
    }

    @Test func malformedJSONThrowsDecodingFailed() async throws {
        MockURLProtocol.stub = .init(statusCode: 200, data: Data("not json".utf8))

        let service = makeService()
        do {
            _ = try await service.fetchCurrentUVIndex(
                for: [UVForecastCoordinate(latitude: 0, longitude: 0)]
            )
            Issue.record("Expected decodingFailed to be thrown")
        } catch UVForecastError.decodingFailed {
            // expected
        } catch {
            Issue.record("Expected UVForecastError.decodingFailed, got \(error)")
        }
    }

    @Test func missingUVIndexThrowsMissingUVData() async throws {
        let json = """
        {
            "latitude": 32.75,
            "longitude": -117.15,
            "current": {"time": "2026-07-15T14:00", "interval": 900}
        }
        """
        MockURLProtocol.stub = .init(statusCode: 200, data: Data(json.utf8))

        let service = makeService()
        do {
            _ = try await service.fetchCurrentUVIndex(
                for: [UVForecastCoordinate(latitude: 32.75, longitude: -117.15)]
            )
            Issue.record("Expected missingUVData to be thrown")
        } catch UVForecastError.missingUVData {
            // expected
        } catch {
            Issue.record("Expected UVForecastError.missingUVData, got \(error)")
        }
    }

    @Test func missingCurrentBlockThrowsMissingUVData() async throws {
        let json = """
        {"latitude": 32.75, "longitude": -117.15}
        """
        MockURLProtocol.stub = .init(statusCode: 200, data: Data(json.utf8))

        let service = makeService()
        await #expect(throws: UVForecastError.self) {
            _ = try await service.fetchCurrentUVIndex(
                for: [UVForecastCoordinate(latitude: 32.75, longitude: -117.15)]
            )
        }
    }

    @Test func emptyCoordinatesThrowsInvalidRequest() async throws {
        let service = makeService()
        do {
            _ = try await service.fetchCurrentUVIndex(for: [])
            Issue.record("Expected invalidRequest to be thrown")
        } catch UVForecastError.invalidRequest {
            // expected
        } catch {
            Issue.record("Expected UVForecastError.invalidRequest, got \(error)")
        }
    }
}

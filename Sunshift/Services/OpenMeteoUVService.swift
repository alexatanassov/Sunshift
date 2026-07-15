import Foundation

// Fetches current UV Index data for one or more coordinates.
protocol UVForecastServiceProtocol {
    func fetchCurrentUVIndex(for coordinates: [UVForecastCoordinate]) async throws -> [UVDataPoint]
}

// Open-Meteo Forecast API client. No API key required, no backend involved.
// https://open-meteo.com/en/docs
final class OpenMeteoUVService: UVForecastServiceProtocol {

    private let session: URLSession
    private let baseURL: URL

    init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://api.open-meteo.com/v1/forecast")!
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    // MARK: - UVForecastServiceProtocol

    func fetchCurrentUVIndex(for coordinates: [UVForecastCoordinate]) async throws -> [UVDataPoint] {
        guard !coordinates.isEmpty else { throw UVForecastError.invalidRequest }
        for coordinate in coordinates {
            guard (-90...90).contains(coordinate.latitude),
                  (-180...180).contains(coordinate.longitude) else {
                throw UVForecastError.invalidRequest
            }
        }

        let request = try makeRequest(for: coordinates)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw UVForecastError.requestFailed(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UVForecastError.requestFailed(underlying: URLError(.badServerResponse))
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UVForecastError.badResponse(statusCode: httpResponse.statusCode)
        }

        let payload: OpenMeteoResponsePayload
        do {
            payload = try JSONDecoder().decode(OpenMeteoResponsePayload.self, from: data)
        } catch {
            throw UVForecastError.decodingFailed(underlying: error)
        }

        // Open-Meteo returns locations in request order; matched positionally against the
        // input coordinates rather than by echoed lat/lon, which can differ slightly by rounding.
        let locations = payload.locations
        guard locations.count == coordinates.count else {
            throw UVForecastError.missingUVData
        }

        return try zip(coordinates, locations).map { coordinate, location in
            guard let current = location.current, let uvIndex = current.uvIndex else {
                throw UVForecastError.missingUVData
            }
            return UVDataPoint(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                uvIndex: uvIndex,
                time: Self.parseTime(current.time) ?? Date()
            )
        }
    }

    // MARK: - Request building

    private func makeRequest(for coordinates: [UVForecastCoordinate]) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw UVForecastError.invalidRequest
        }
        components.queryItems = [
            URLQueryItem(name: "latitude", value: coordinates.map { String($0.latitude) }.joined(separator: ",")),
            URLQueryItem(name: "longitude", value: coordinates.map { String($0.longitude) }.joined(separator: ",")),
            URLQueryItem(name: "current", value: "uv_index"),
            URLQueryItem(name: "timezone", value: "UTC"),
        ]
        guard let url = components.url else { throw UVForecastError.invalidRequest }
        return URLRequest(url: url)
    }

    // MARK: - Time parsing

    // Open-Meteo returns "current.time" as a local ISO8601-style string without a UTC
    // offset (e.g. "2026-07-15T14:00"); pinning timezone=UTC in the request makes this
    // value always UTC.
    private static func parseTime(_ raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: raw)
    }
}

// MARK: - Open-Meteo DTOs

// Open-Meteo returns a single JSON object when one coordinate is requested, and a JSON
// array of objects (one per coordinate, in request order) when multiple are requested.
private enum OpenMeteoResponsePayload: Decodable {
    case single(OpenMeteoLocationResponse)
    case multiple([OpenMeteoLocationResponse])

    init(from decoder: Decoder) throws {
        if let multiple = try? [OpenMeteoLocationResponse](from: decoder) {
            self = .multiple(multiple)
            return
        }
        self = .single(try OpenMeteoLocationResponse(from: decoder))
    }

    var locations: [OpenMeteoLocationResponse] {
        switch self {
        case .single(let location): return [location]
        case .multiple(let locations): return locations
        }
    }
}

private struct OpenMeteoLocationResponse: Decodable {
    let current: OpenMeteoCurrentBlock?
}

private struct OpenMeteoCurrentBlock: Decodable {
    let time: String
    let uvIndex: Double?

    enum CodingKeys: String, CodingKey {
        case time
        case uvIndex = "uv_index"
    }
}

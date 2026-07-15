import Foundation

nonisolated enum UVForecastError: Error, LocalizedError {
    case invalidRequest
    case requestFailed(underlying: Error)
    case badResponse(statusCode: Int)
    case decodingFailed(underlying: Error)
    case missingUVData

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "The UV forecast request was invalid."
        case .requestFailed(let error):
            return "The UV forecast request failed: \(error.localizedDescription)"
        case .badResponse(let statusCode):
            return "The UV forecast server returned an unexpected response (status \(statusCode))."
        case .decodingFailed(let error):
            return "The UV forecast response could not be read: \(error.localizedDescription)"
        case .missingUVData:
            return "No UV data was available for this location."
        }
    }
}

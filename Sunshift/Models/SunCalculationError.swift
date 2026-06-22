import Foundation

enum SunCalculationError: Error, Equatable {
    case invalidCoordinates
    case invalidTimeZone
    case polarDay
    case polarNight
    case calculationFailed(String)
}

import Foundation

struct SunEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let type: SunEventType
    let time: Date
    var subtitle: String?

    var displayName: String { type.displayName }

    init(id: UUID = UUID(), type: SunEventType, time: Date, subtitle: String? = nil) {
        self.id = id
        self.type = type
        self.time = time
        self.subtitle = subtitle
    }
}

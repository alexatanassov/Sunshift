import Foundation

struct LightRoutine: Identifiable {
    let id: UUID
    var title: String
    var templateType: RoutineTemplate?
    var sunEventType: SunEventType
    var offsetMinutes: Int
    var isBeforeEvent: Bool
    var selectedWeekdays: WeekdaySelection
    var locationId: UUID?
    var isEnabled: Bool
    var notificationMessage: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        templateType: RoutineTemplate? = nil,
        sunEventType: SunEventType,
        offsetMinutes: Int = 0,
        isBeforeEvent: Bool = false,
        selectedWeekdays: WeekdaySelection = .everyday,
        locationId: UUID? = nil,
        isEnabled: Bool = true,
        notificationMessage: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.templateType = templateType
        self.sunEventType = sunEventType
        self.offsetMinutes = offsetMinutes
        self.isBeforeEvent = isBeforeEvent
        self.selectedWeekdays = selectedWeekdays
        self.locationId = locationId
        self.isEnabled = isEnabled
        self.notificationMessage = notificationMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

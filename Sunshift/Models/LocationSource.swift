import Foundation

enum LocationSource: String, Codable, CaseIterable {
    case current       // Live GPS position from device
    case manual        // Typed or pinned by the user without a search
    case saved         // Loaded from the user's saved list
    case searchResult  // Chosen from a place search
    case fallback      // Dev/first-launch placeholder; never treated as real user location
}

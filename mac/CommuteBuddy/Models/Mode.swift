import Foundation

enum Mode: String, CaseIterable, Equatable {
    case auto = "auto"
    case on   = "on"

    var label: String { rawValue.capitalized }
}

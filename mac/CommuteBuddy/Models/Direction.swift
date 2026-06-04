import Foundation

enum Direction {
    case toWork   // HOB → 23S (morning)
    case toHome   // 23S → HOB (evening)

    var originStation: String {
        switch self {
        case .toWork: Config.homeStation
        case .toHome: Config.workStation
        }
    }

    var destinationLabel: String {
        switch self {
        case .toWork: "ToNY"
        case .toHome: "ToNJ"
        }
    }

    var walkMinutes: Int {
        switch self {
        case .toWork: Config.walkFromHome
        case .toHome: Config.walkFromWork
        }
    }

    var fromLabel: String {
        switch self {
        case .toWork: "Hoboken"
        case .toHome: "23 St"
        }
    }

    var toLabel: String {
        switch self {
        case .toWork: "23 St"
        case .toHome: "Hoboken"
        }
    }
}

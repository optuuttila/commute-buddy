import Foundation

struct Train: Identifiable {
    let id = UUID()
    let secondsToArrival: Int
    let headSign: String
    let lineColors: [Color]   // parsed from "4D92FB,FF9900"
    let lastUpdated: Date

    var minutesToArrival: Double {
        Double(secondsToArrival) / 60
    }

    var arrivalTime: Date {
        Date().addingTimeInterval(TimeInterval(secondsToArrival))
    }

    /// Signed minutes remaining before you must leave.
    /// Negative = you should have left already.
    func bufferMinutes(walkMinutes: Int) -> Double {
        minutesToArrival - Double(walkMinutes)
    }

    // MARK: - Hex colour helper
    struct Color {
        let hex: String
        var nsColor: NSColor { NSColor(hex: hex) ?? .controlAccentColor }
    }
}

// MARK: - NSColor hex init
extension NSColor {
    convenience init?(hex: String) {
        var str = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if str.count == 6 { str = "FF" + str }
        guard str.count == 8,
              let value = UInt64(str, radix: 16) else { return nil }
        self.init(
            red:   CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >>  8) & 0xFF) / 255,
            blue:  CGFloat((value      ) & 0xFF) / 255,
            alpha: CGFloat((value >> 24) & 0xFF) / 255
        )
    }
}

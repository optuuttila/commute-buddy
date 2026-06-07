import Foundation

struct Train: Identifiable {
    let id = UUID()
    /// Absolute departure time, computed once at fetch.
    /// Using a stored Date (not a computed one) means bufferMinutes
    /// stays accurate as time passes between refreshes.
    let arrivalTime: Date
    let headSign: String
    let lineColors: [Color]
    let lastUpdated: Date

    var minutesToArrival: Double {
        arrivalTime.timeIntervalSinceNow / 60
    }

    /// Signed minutes before you must leave.
    /// Negative means you should have left already.
    func bufferMinutes(walkMinutes: Int) -> Double {
        minutesToArrival - Double(walkMinutes)
    }

    // MARK: - Line colour helper

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

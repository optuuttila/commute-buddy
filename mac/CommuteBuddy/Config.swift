// Config.swift
// Edit this file to match your commute.

import Foundation

enum Config {
    // MARK: - Stations
    static let homeStation = "HOB"   // Hoboken
    static let workStation = "23S"   // 23rd Street

    // MARK: - Walk times (minutes)
    static let walkFromHome = 8
    static let walkFromWork = 5

    // MARK: - Active commute windows
    static let morningWindow = TimeWindow(start: "07:30", end: "09:30")  // → work
    static let eveningWindow = TimeWindow(start: "17:00", end: "20:00")  // → home

    // MARK: - Display
    static let trainCount = 3
    static let refreshInterval: TimeInterval = 30

    // MARK: - API
    // Native apps can call PANYNJ directly — no CORS restriction in URLSession.
    // The Cloudflare Worker is only needed for the web app.
    static let apiURL = URL(string: "https://www.panynj.gov/bin/portauthority/ridepath.json")!

    // MARK: -
    struct TimeWindow {
        let start: String  // "HH:MM"
        let end: String

        var startMinutes: Int { parse(start) }
        var endMinutes: Int   { parse(end)   }

        private func parse(_ hhmm: String) -> Int {
            let parts = hhmm.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return 0 }
            return parts[0] * 60 + parts[1]
        }
    }
}

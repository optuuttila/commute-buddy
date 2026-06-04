import SwiftUI

// MARK: - State

enum CommuteState {
    case idle(nextWindow: String?)
    case loading
    case loaded(direction: Direction, trains: [Train])
    case error(String)
}

// MARK: - ViewModel

@MainActor
final class CommuteViewModel: ObservableObject {
    @Published private(set) var state: CommuteState = .loading
    @Published private(set) var lastUpdated: Date?

    private let service = PathService()
    private var timer: Timer?

    // MARK: - Lifecycle

    func start() {
        Task { await refresh() }
        timer = Timer.scheduledTimer(
            withTimeInterval: Config.refreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Refresh

    func refresh() async {
        guard let direction = currentDirection() else {
            state = .idle(nextWindow: nextWindowLabel())
            return
        }

        // Keep previous data visible while refreshing
        if case .idle = state { state = .loading }

        do {
            let trains = try await service.fetchTrains(direction: direction)
            if trains.isEmpty {
                state = .error("No trains found. Service may be suspended.")
            } else {
                state = .loaded(direction: direction, trains: trains)
                lastUpdated = Date()
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Direction detection

    private func currentDirection() -> Direction? {
        let mins = nowMinutes()
        let m = Config.morningWindow
        let e = Config.eveningWindow
        if mins >= m.startMinutes && mins <= m.endMinutes { return .toWork }
        if mins >= e.startMinutes && mins <= e.endMinutes { return .toHome }
        return nil
    }

    private func nowMinutes() -> Int {
        let c = Calendar.current
        let now = Date()
        return c.component(.hour, from: now) * 60 + c.component(.minute, from: now)
    }

    private func nextWindowLabel() -> String? {
        let mins = nowMinutes()
        let m = Config.morningWindow
        let e = Config.eveningWindow
        if mins < m.startMinutes { return "Morning window opens at \(m.start)" }
        if mins < e.startMinutes { return "Evening window opens at \(e.start)" }
        return nil
    }
}

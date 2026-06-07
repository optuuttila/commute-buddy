import SwiftUI

// MARK: - App state

enum CommuteState {
    case idle(nextWindow: String?)
    case loading
    case loaded(direction: Direction, trains: [Train])
    case error(String)
}

// MARK: - ViewModel

@MainActor
final class CommuteViewModel: ObservableObject {

    // MARK: Published

    @Published private(set) var state: CommuteState = .loading
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var refreshCountdown: Int = Int(Config.refreshInterval)

    /// Persisted to UserDefaults; changing it immediately re-evaluates direction + refetches.
    @Published var mode: Mode {
        didSet {
            guard mode != oldValue else { return }
            UserDefaults.standard.set(mode.rawValue, forKey: "commute-mode")
            restartCycle()
        }
    }

    // MARK: Private

    private let service = PathService()
    private var refreshTimer: Timer?
    private var countdownTimer: Timer?
    private var errorRetryTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        let saved = UserDefaults.standard.string(forKey: "commute-mode") ?? Mode.auto.rawValue
        mode = Mode(rawValue: saved) ?? .auto
    }

    // MARK: - Lifecycle

    func start() {
        restartCycle()
    }

    func stop() {
        refreshTimer?.invalidate()
        countdownTimer?.invalidate()
        errorRetryTask?.cancel()
        refreshTimer   = nil
        countdownTimer = nil
    }

    // MARK: - Manual refresh

    func refresh() async {
        errorRetryTask?.cancel()
        restartCycle()
    }

    // MARK: - Private

    /// Fetch data, then schedule the next automatic refresh.
    private func restartCycle() {
        refreshTimer?.invalidate()
        countdownTimer?.invalidate()
        refreshCountdown = Int(Config.refreshInterval)

        // Kick off fetch immediately
        Task { await fetchAndUpdate() }

        // Schedule periodic refresh
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: Config.refreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { await self?.fetchAndUpdate() }
            self?.refreshCountdown = Int(Config.refreshInterval)
        }

        // Countdown tick
        countdownTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            guard let self, self.refreshCountdown > 0 else { return }
            self.refreshCountdown -= 1
        }
    }

    private func fetchAndUpdate() async {
        guard let direction = currentDirection() else {
            state = .idle(nextWindow: nextWindowLabel())
            return
        }

        // Show loading only on first load (no data yet)
        if case .idle = state { state = .loading }
        if case .error = state { state = .loading }

        do {
            let trains = try await service.fetchTrains(direction: direction)
            if trains.isEmpty {
                state = .error("No trains found. Service may be suspended.")
                scheduleErrorRetry()
            } else {
                state = .loaded(direction: direction, trains: trains)
                lastUpdated = Date()
            }
        } catch {
            state = .error(error.localizedDescription)
            scheduleErrorRetry()
        }
    }

    /// On error, retry after 60 s (independent of the normal 30 s refresh).
    private func scheduleErrorRetry() {
        errorRetryTask?.cancel()
        errorRetryTask = Task {
            try? await Task.sleep(for: .seconds(60))
            guard !Task.isCancelled else { return }
            await fetchAndUpdate()
        }
    }

    // MARK: - Direction detection

    private func currentDirection() -> Direction? {
        switch mode {
        case .on:
            // Always active: before noon → to work, noon onward → to home
            return Calendar.current.component(.hour, from: Date()) < 12 ? .toWork : .toHome
        case .auto:
            let mins = nowMinutes()
            let m = Config.morningWindow
            let e = Config.eveningWindow
            if mins >= m.startMinutes && mins <= m.endMinutes { return .toWork }
            if mins >= e.startMinutes && mins <= e.endMinutes { return .toHome }
            return nil
        }
    }

    private func nowMinutes() -> Int {
        let c = Calendar.current
        return c.component(.hour, from: Date()) * 60 + c.component(.minute, from: Date())
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

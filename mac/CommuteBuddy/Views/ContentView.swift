import SwiftUI

struct ContentView: View {
    @StateObject private var vm = CommuteViewModel()

    var body: some View {
        VStack(spacing: 0) {
            switch vm.state {
            case .idle(let nextWindow):
                IdleView(nextWindow: nextWindow)
            case .loading:
                LoadingView()
            case .loaded(let direction, let trains):
                ActiveView(direction: direction, trains: trains, lastUpdated: vm.lastUpdated)
            case .error(let msg):
                ErrorView(message: msg) {
                    Task { await vm.refresh() }
                }
            }

            Divider()
            FooterView(lastUpdated: vm.lastUpdated) {
                Task { await vm.refresh() }
            }
        }
        .frame(width: 300)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

// MARK: - Idle

private struct IdleView: View {
    let nextWindow: String?

    var body: some View {
        VStack(spacing: 6) {
            Text(Date(), style: .time)
                .font(.system(size: 42, weight: .ultraLight, design: .rounded))
            Text("No active commute window")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            if let nextWindow {
                Text(nextWindow)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Loading…")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active

private struct ActiveView: View {
    let direction: Direction
    let trains: [Train]
    let lastUpdated: Date?

    private var nextTrain: Train { trains[0] }
    private var walkMins: Int    { direction.walkMinutes }
    private var buffer: Double   { nextTrain.bufferMinutes(walkMinutes: walkMins) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(direction.fromLabel.uppercased())
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
                Text("→ \(direction.toLabel.uppercased())")
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
                Spacer()
                Circle()
                    .fill(.green)
                    .frame(width: 7, height: 7)
            }
            .font(.caption)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Status
            VStack(alignment: .leading, spacing: 4) {
                Text(statusLabel)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
                Text("Next train at \(nextTrain.arrivalTime, style: .time) · walk \(walkMins) min")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            // Train list
            VStack(spacing: 0) {
                ForEach(trains) { train in
                    TrainRow(train: train, walkMins: walkMins)
                    if train.id != trains.last?.id { Divider() }
                }
            }
        }
    }

    private var statusLabel: String {
        if buffer <= 0  { return "Leave Now" }
        let mins = Int(ceil(buffer))
        return "Leave in \(mins) min"
    }

    private var statusColor: Color {
        if buffer <= 0 { return .red    }
        if buffer <= 4 { return .orange }
        return .green
    }
}

// MARK: - Train row

private struct TrainRow: View {
    let train: Train
    let walkMins: Int

    private var buffer: Double { train.bufferMinutes(walkMinutes: walkMins) }

    var body: some View {
        HStack {
            // Line colour dot
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)

            Text(train.arrivalTime, style: .time)
                .fontWeight(.semibold)
                .font(.subheadline)
                .monospacedDigit()

            Spacer()

            Text(badgeLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(badgeColor.opacity(0.15))
                .foregroundStyle(badgeColor)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var dotColor: Color {
        train.lineColors.first.map { Color(nsColor: $0.nsColor) } ?? .accentColor
    }

    private var badgeLabel: String {
        if buffer <= 0 { return "Leave now" }
        return "Leave in \(Int(ceil(buffer)))m"
    }

    private var badgeColor: Color {
        if buffer <= 0 { return .red    }
        if buffer <= 4 { return .orange }
        return .green
    }
}

// MARK: - Error

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Could not load schedule")
                .fontWeight(.semibold)
                .foregroundStyle(.red)
            Text(message)
                .foregroundStyle(.secondary)
                .font(.caption)
                .multilineTextAlignment(.center)
            Button("Try again", action: onRetry)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Footer

private struct FooterView: View {
    let lastUpdated: Date?
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            if let lastUpdated {
                Text("Updated \(lastUpdated, style: .time)")
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

import SwiftUI

// MARK: - Root

struct ContentView: View {
    @StateObject private var vm = CommuteViewModel()

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(mode: Binding(get: { vm.mode }, set: { vm.mode = $0 }))
            Divider()

            switch vm.state {
            case .idle(let nextWindow):
                IdleView(nextWindow: nextWindow)
            case .loading:
                LoadingView()
            case .loaded(let direction, let trains):
                ActiveView(direction: direction, trains: trains, mode: vm.mode)
            case .error(let msg):
                ErrorView(message: msg) { Task { await vm.refresh() } }
            }

            Divider()
            FooterView(
                lastUpdated: vm.lastUpdated,
                countdown: vm.refreshCountdown,
                onRefresh: { Task { await vm.refresh() } }
            )
        }
        .frame(width: 300)
        .onAppear  { vm.start() }
        .onDisappear { vm.stop() }
    }
}

// MARK: - Top bar (wordmark + mode toggle)

private struct TopBarView: View {
    @Binding var mode: Mode

    var body: some View {
        HStack {
            Text("Commute Buddy")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .kerning(0.8)

            Spacer()

            // Auto / On pill toggle
            HStack(spacing: 2) {
                ForEach(Mode.allCases, id: \.self) { m in
                    Button(m.label) { mode = m }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(mode == m ? Color.accentColor : Color.clear)
                        .foregroundStyle(mode == m ? Color.white : Color.secondary)
                        .clipShape(Capsule())
                }
            }
            .padding(3)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}

// MARK: - Idle

private struct IdleView: View {
    let nextWindow: String?

    var body: some View {
        // TimelineView drives a 1-second repaint so the clock ticks live
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 6) {
                Text(context.date, style: .time)
                    .font(.system(size: 42, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                Text("No active commute window")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                if let nextWindow {
                    Label(nextWindow, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
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
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active

private struct ActiveView: View {
    let direction: Direction
    let trains: [Train]
    let mode: Mode

    var body: some View {
        VStack(spacing: 0) {
            HeaderRow(direction: direction)
            Divider()

            switch mode {
            case .auto: AutoStatusView(train: trains[0], walkMins: direction.walkMinutes)
            case .on:   OnStatusView  (train: trains[0], walkMins: direction.walkMinutes)
            }

            Divider()
            TrainListView(trains: trains, walkMins: direction.walkMinutes)
        }
    }
}

// MARK: - Header row (route label + pulsing live dot)

private struct HeaderRow: View {
    let direction: Direction
    @State private var dotOpacity = 1.0

    var body: some View {
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
                .opacity(dotOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        dotOpacity = 0.3
                    }
                }
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Auto mode status
// "Leave in N min" / "Leave Now" with green → orange → red colour ramp.
// Wrapped in TimelineView so the countdown and colour update every second
// using the stored arrivalTime (not the stale secondsToArrival snapshot).

private struct AutoStatusView: View {
    let train: Train
    let walkMins: Int

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let buffer = train.bufferMinutes(walkMinutes: walkMins)
            VStack(alignment: .leading, spacing: 4) {
                Text(autoLabel(buffer))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(autoColor(buffer))
                    .contentTransition(.numericText())
                Text("Next train at \(train.arrivalTime, style: .time) · walk \(walkMins) min")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private func autoLabel(_ buffer: Double) -> String {
        if buffer <= 0 { return "Leave Now" }
        return "Leave in \(Int(ceil(buffer))) min"
    }

    private func autoColor(_ buffer: Double) -> Color {
        if buffer <= 0 { return .red    }
        if buffer  < 4 { return .orange }
        return .green
    }
}

// MARK: - On mode status
// Large live clock on the left, Go / Wait signal on the right.
// TimelineView ticks every second for the clock and re-evaluates the signal.

private struct OnStatusView: View {
    let train: Train
    let walkMins: Int

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let buffer = train.bufferMinutes(walkMinutes: walkMins)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline) {
                    Text(context.date, style: .time)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Spacer()
                    Text(signalLabel(buffer))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(signalColor(buffer))
                }
                Text("Train at \(train.arrivalTime, style: .time) · walk \(walkMins) min")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private func signalLabel(_ buffer: Double) -> String {
        buffer > 3 ? "Wait" : "Go"
    }

    private func signalColor(_ buffer: Double) -> Color {
        buffer > 3 ? .secondary : Color(red: 1.0, green: 0.6, blue: 0.0)
    }
}

// MARK: - Train list
// Wrapped in TimelineView so leave badges update every second between refreshes.

private struct TrainListView: View {
    let trains: [Train]
    let walkMins: Int

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            VStack(spacing: 0) {
                ForEach(trains) { train in
                    TrainRow(train: train, walkMins: walkMins)
                    if train.id != trains.last?.id { Divider() }
                }
            }
        }
    }
}

// MARK: - Train row

private struct TrainRow: View {
    let train: Train
    let walkMins: Int

    private var buffer: Double { train.bufferMinutes(walkMinutes: walkMins) }

    var body: some View {
        HStack {
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
        if buffer  < 4 { return .orange }
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
            Text("Auto-retrying in 60 s…")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Footer

private struct FooterView: View {
    let lastUpdated: Date?
    let countdown: Int
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            if let lastUpdated {
                Text("Updated \(lastUpdated, style: .time)")
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text("Refresh in \(countdown)s")
                .foregroundStyle(.tertiary)
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

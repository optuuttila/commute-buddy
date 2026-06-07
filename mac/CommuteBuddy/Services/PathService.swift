import Foundation

// MARK: - PANYNJ ridepath.json response shape

private struct RidepathResponse: Decodable {
    let results: [StationResult]
}

private struct StationResult: Decodable {
    let consideredStation: String
    let destinations: [Destination]
}

private struct Destination: Decodable {
    let label: String
    let messages: [TrainMessage]
}

private struct TrainMessage: Decodable {
    let target: String
    let secondsToArrival: String
    let headSign: String
    let lineColor: String
    let lastUpdated: String
}

// MARK: - Service

actor PathService {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    func fetchTrains(direction: Direction) async throws -> [Train] {
        var request = URLRequest(url: Config.apiURL)
        // URLSession is not bound by CORS — we can set Referer freely.
        request.setValue(
            "https://www.panynj.gov/path/en/index.html",
            forHTTPHeaderField: "Referer"
        )
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PathError.badResponse
        }

        let decoded = try JSONDecoder().decode(RidepathResponse.self, from: data)
        return extract(from: decoded, direction: direction)
    }

    // MARK: - Private

    private func extract(from response: RidepathResponse, direction: Direction) -> [Train] {
        guard
            let station = response.results.first(where: {
                $0.consideredStation == direction.originStation
            }),
            let dest = station.destinations.first(where: {
                $0.label == direction.destinationLabel
            })
        else { return [] }

        var messages = dest.messages

        // Morning: WTC-bound trains skip 23rd St — only keep 33S-bound.
        if direction == .toWork {
            messages = messages.filter { $0.target == "33S" }
        }

        let fetchTime = Date()

        return messages
            .compactMap { msg -> Train? in
                guard let seconds = Int(msg.secondsToArrival) else { return nil }
                let colors = msg.lineColor
                    .split(separator: ",")
                    .map { Train.Color(hex: String($0)) }
                // Store absolute arrival time once — bufferMinutes stays accurate
                // as time passes between refreshes.
                return Train(
                    arrivalTime: fetchTime.addingTimeInterval(TimeInterval(seconds)),
                    headSign: msg.headSign,
                    lineColors: colors,
                    lastUpdated: fetchTime
                )
            }
            .sorted { $0.arrivalTime < $1.arrivalTime }
            .prefix(Config.trainCount)
            .map { $0 }
    }
}

// MARK: - Errors

enum PathError: LocalizedError {
    case badResponse

    var errorDescription: String? {
        switch self {
        case .badResponse: "Unexpected response from PATH API."
        }
    }
}

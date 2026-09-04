import Foundation

/// A calm, factual roll-up of confirmed overcharges — never a score, never
/// a streak. Just what was proven and what it added up to.
public struct MonthlySummary: Equatable, Sendable {
    public let month: Date
    public let tripCount: Int
    public let confirmedOverchargeTotal: Decimal
    public let confirmedMismatchCount: Int
}

public struct MonthlySummaryUseCase: Sendable {
    private let tripStore: TripStore
    private let calendar: Calendar

    public init(tripStore: TripStore, calendar: Calendar = .current) {
        self.tripStore = tripStore
        self.calendar = calendar
    }

    public func callAsFunction(for referenceDate: Date = .now) async throws -> MonthlySummary {
        let trips = try await tripStore.fetchAll().filter {
            calendar.isDate($0.date, equalTo: referenceDate, toGranularity: .month)
        }

        let confirmedMismatches = trips.flatMap(\.matches).filter { $0.decision == .confirmedMismatch }

        return MonthlySummary(
            month: referenceDate,
            tripCount: trips.count,
            confirmedOverchargeTotal: trips.map(\.confirmedOverchargeTotal).reduce(0, +),
            confirmedMismatchCount: confirmedMismatches.count
        )
    }
}

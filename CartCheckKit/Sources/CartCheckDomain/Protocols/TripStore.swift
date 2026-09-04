import Foundation

/// Persists shopping trips. Implemented in CartCheckData on top of
/// SwiftData.
public protocol TripStore: Sendable {
    func save(_ trip: Trip) async throws
    func fetchAll() async throws -> [Trip]
    func fetch(id: UUID) async throws -> Trip?
    func delete(id: UUID) async throws
}

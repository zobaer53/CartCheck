import Foundation
import CartCheckDomain

@Observable
@MainActor
final class HistoryViewModel {
    private let dependencies: AppDependencies

    var trips: [Trip] = []
    var summary: MonthlySummary?
    var isLoading = false
    var errorMessage: String?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            trips = try await dependencies.tripStore.fetchAll()
            summary = try await dependencies.monthlySummary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

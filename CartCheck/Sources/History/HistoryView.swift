import SwiftUI
import CartCheckDomain

struct HistoryView: View {
    @Bindable var viewModel: HistoryViewModel

    var body: some View {
        NavigationStack {
            List {
                if let summary = viewModel.summary {
                    Section("This Month") {
                        HStack {
                            summaryStat(value: "\(summary.tripCount)", caption: "trips")
                            Spacer()
                            summaryStat(value: summary.confirmedOverchargeTotal.currencyString, caption: "confirmed overcharges")
                            Spacer()
                            summaryStat(value: "\(summary.confirmedMismatchCount)", caption: "mismatches")
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Trips") {
                    if viewModel.trips.isEmpty {
                        ContentUnavailableView(
                            "No Trips Yet",
                            systemImage: "cart",
                            description: Text("Trips show up here once you've photographed a receipt.")
                        )
                    } else {
                        ForEach(viewModel.trips) { trip in
                            NavigationLink {
                                TripDetailView(trip: trip)
                            } label: {
                                tripRow(trip)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .task { await viewModel.refresh() }
            .refreshable { await viewModel.refresh() }
            .safeAreaInset(edge: .top) {
                if let error = viewModel.errorMessage {
                    InlineErrorBanner(message: error)
                }
            }
        }
    }

    private func summaryStat(value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3.weight(.semibold).monospacedDigit())
            Text(caption).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func tripRow(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(trip.store ?? "Unnamed store")
                    .font(.headline)
                Spacer()
                Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                if trip.confirmedOverchargeTotal > 0 {
                    Label(trip.confirmedOverchargeTotal.currencyString, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
                if trip.pendingReviewCount > 0 {
                    Text("\(trip.pendingReviewCount) to review")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

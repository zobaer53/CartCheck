import SwiftUI
import CartCheckDomain

/// Mirrors the "show your work, then ask" review moment: two comparison
/// cards, a flag banner naming the delta and confidence, the model's
/// reasoning, and three neutral options — never a pre-selected default.
struct MatchReviewCard: View {
    let review: PendingReview
    let onDecide: (ReviewDecision) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let store = review.tripStore {
                Text(store.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                comparisonColumn(
                    label: "You scanned",
                    name: review.match.cartItem?.name,
                    price: review.match.cartItem?.priceSeen
                )
                comparisonColumn(
                    label: "Receipt says",
                    name: review.match.receiptLine?.parsedName,
                    price: review.match.receiptLine?.price
                )
            }

            flagBanner

            Text(review.match.reasoning)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("Yes, that's a mismatch") { onDecide(.confirmedMismatch) }
                    .buttonStyle(.borderedProminent)
                Button("No, different item") { onDecide(.notAMismatch) }
                    .buttonStyle(.bordered)
            }
            Button("Not sure — skip it") { onDecide(.skipped) }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    private func comparisonColumn(label: String, name: String?, price: Decimal?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(name ?? "(not found)")
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            Text(price.currencyStringOrDash)
                .font(.system(.body, design: .monospaced))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }

    private var flagBanner: some View {
        HStack {
            Text(bannerText)
            Spacer()
            Text("confidence: \(review.match.confidence.rawValue)")
                .font(.caption)
        }
        .font(.subheadline.weight(.medium))
        .padding(10)
        .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    private var bannerText: String {
        switch review.match.outcome {
        case .priceMismatch:
            if let delta = review.match.priceDelta {
                let sign = delta > 0 ? "+" : ""
                return "Same item, different price — \(sign)\(delta.currencyString)"
            }
            return "Same item, different price"
        case .missingFromReceipt:
            return "Scanned, but not on the receipt"
        case .missingFromCart:
            return "On the receipt, but nothing scanned matches it"
        case .matchesExactly:
            return "Matches"
        }
    }
}

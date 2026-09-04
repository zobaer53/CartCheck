import SwiftUI
import CartCheckDomain

/// The comparison-card visual language ("You scanned" / "Receipt says" +
/// outcome banner + reasoning) shared between the live Review flow and the
/// read-only Trip Detail history view. Callers supply whatever goes below
/// the reasoning — decision buttons on Review, a status badge in History.
struct MatchComparisonCard<Accessory: View>: View {
    let match: ProposedMatch
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                comparisonColumn(
                    label: "You scanned",
                    name: match.cartItem?.name,
                    price: match.cartItem?.priceSeen
                )
                comparisonColumn(
                    label: "Receipt says",
                    name: match.receiptLine?.parsedName,
                    price: match.receiptLine?.price
                )
            }

            flagBanner

            Text(match.reasoning)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            accessory()
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
            Text("confidence: \(match.confidence.rawValue)")
                .font(.caption)
        }
        .font(.subheadline.weight(.medium))
        .padding(10)
        .background(bannerTint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    private var bannerTint: Color {
        match.outcome == .matchesExactly ? .green : .orange
    }

    private var bannerText: String {
        switch match.outcome {
        case .priceMismatch:
            if let delta = match.priceDelta {
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

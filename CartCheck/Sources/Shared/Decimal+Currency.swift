import Foundation

extension Decimal {
    var currencyString: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

extension Optional where Wrapped == Decimal {
    var currencyStringOrDash: String {
        self?.currencyString ?? "—"
    }
}

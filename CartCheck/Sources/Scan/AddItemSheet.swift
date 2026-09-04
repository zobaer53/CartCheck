import SwiftUI
import CartCheckDomain

/// Confirms what a barcode scan resolved to, collects a manually entered
/// item, or edits an item already in the cart — before it's saved. A
/// barcode alone is just digits: CartCheck has no external product
/// database, so the shopper is always the one who says what it is and what
/// they saw it priced at.
struct AddItemSheet: View {
    let barcode: String?
    let existingItem: CartItem?
    let onSave: (String, Decimal?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var priceText: String
    @FocusState private var nameFieldFocused: Bool

    init(barcode: String? = nil, existingItem: CartItem? = nil, onSave: @escaping (String, Decimal?) -> Void) {
        self.barcode = barcode ?? existingItem?.barcode
        self.existingItem = existingItem
        self.onSave = onSave
        _name = State(initialValue: existingItem?.name ?? "")
        _priceText = State(initialValue: existingItem?.priceSeen.map { "\($0)" } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                if let barcode {
                    Section("Barcode") {
                        Text(barcode).monospaced().foregroundStyle(.secondary)
                    }
                }
                Section("Item") {
                    TextField("Name", text: $name)
                        .focused($nameFieldFocused)
                    TextField("Price seen on shelf (optional)", text: $priceText)
                        .keyboardType(.decimalPad)
                    if priceIsInvalid {
                        Text("Enter a valid price, like 3.99")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingItem == nil ? "Add" : "Save") {
                        onSave(name, parsedPrice)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || priceIsInvalid)
                }
            }
        }
        .onAppear { nameFieldFocused = true }
    }

    private var navigationTitle: String {
        if existingItem != nil { return "Edit Item" }
        return barcode == nil ? "Add Item" : "New Item"
    }

    private var parsedPrice: Decimal? {
        let trimmed = priceText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let cleaned = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "$€£"))
        return Decimal(string: cleaned, locale: .current) ?? Decimal(string: cleaned)
    }

    private var priceIsInvalid: Bool {
        let trimmed = priceText.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && parsedPrice == nil
    }
}

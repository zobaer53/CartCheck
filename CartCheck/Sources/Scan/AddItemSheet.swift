import SwiftUI

/// Confirms what a barcode scan resolved to — or collects a manually
/// entered item — before it's added to the cart. A barcode alone is just
/// digits: CartCheck has no external product database, so the shopper is
/// always the one who says what it is and what they saw it priced at.
struct AddItemSheet: View {
    let barcode: String?
    let onAdd: (String, Decimal?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var priceText = ""
    @FocusState private var nameFieldFocused: Bool

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
                }
            }
            .navigationTitle(barcode == nil ? "Add Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name, Decimal(string: priceText))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { nameFieldFocused = true }
    }
}

import SwiftUI
import PhotosUI
import UIKit
import CartCheckDomain

struct ScanView: View {
    @Bindable var viewModel: ActiveTripViewModel

    @State private var isShowingScanner = false
    @State private var isShowingManualAdd = false
    @State private var pendingBarcode: String?
    @State private var isShowingCamera = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var editingItem: CartItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Store") {
                    TextField("Where are you shopping? (optional)", text: $viewModel.store)
                        .textInputAutocapitalization(.words)
                }

                Section("Cart (\(viewModel.cartItems.count))") {
                    if viewModel.cartItems.isEmpty {
                        ContentUnavailableView(
                            "Nothing Scanned Yet",
                            systemImage: "barcode.viewfinder",
                            description: Text("Scan a barcode or add an item as you shop.")
                        )
                    } else {
                        ForEach(viewModel.cartItems) { item in
                            Button {
                                editingItem = item
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                        if let barcode = item.barcode {
                                            Text(barcode).font(.caption).foregroundStyle(.secondary).monospaced()
                                        }
                                    }
                                    Spacer()
                                    Text(item.priceSeen.currencyStringOrDash)
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { viewModel.removeItems(at: $0) }
                    }
                }

                Section {
                    Button {
                        isShowingScanner = true
                    } label: {
                        Label("Scan Barcode", systemImage: "barcode.viewfinder")
                    }
                    Button {
                        pendingBarcode = nil
                        isShowingManualAdd = true
                    } label: {
                        Label("Add Item Manually", systemImage: "plus.circle")
                    }
                }

                Section("At Checkout") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            isShowingCamera = true
                        } label: {
                            Label("Photograph Receipt", systemImage: "camera")
                        }
                    }
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Label("Choose Receipt Photo", systemImage: "photo.on.rectangle")
                    }
                }
                .disabled(viewModel.cartItems.isEmpty || viewModel.isReconciling)

                if viewModel.isReconciling {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Comparing your receipt on-device…")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let error = viewModel.reconciliationError {
                    Section {
                        InlineErrorBanner(message: error)
                    }
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Scan")
            .sheet(isPresented: $isShowingScanner) {
                ScannerSheet { payload in
                    pendingBarcode = payload
                    isShowingManualAdd = true
                }
            }
            .sheet(isPresented: $isShowingManualAdd) {
                AddItemSheet(barcode: pendingBarcode) { name, price in
                    viewModel.addItem(barcode: pendingBarcode, name: name, priceSeen: price)
                }
            }
            .sheet(item: $editingItem) { item in
                AddItemSheet(existingItem: item) { name, price in
                    viewModel.updateItem(id: item.id, name: name, priceSeen: price)
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraCaptureView(
                    onCapture: { image in
                        isShowingCamera = false
                        Task { await submitReceipt(image) }
                    },
                    onCancel: { isShowingCamera = false }
                )
                .ignoresSafeArea()
            }
            .onChange(of: photoPickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await viewModel.processReceipt(imageData: data)
                    }
                    photoPickerItem = nil
                }
            }
            .alert(
                "Trip Reconciled",
                isPresented: Binding(
                    get: { viewModel.justCompletedTrip != nil },
                    set: { if !$0 { viewModel.dismissCompletedTrip() } }
                )
            ) {
                Button("OK") { viewModel.dismissCompletedTrip() }
            } message: {
                if let trip = viewModel.justCompletedTrip {
                    Text(reconciliationSummary(for: trip))
                }
            }
        }
    }

    private func submitReceipt(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        await viewModel.processReceipt(imageData: data)
    }

    private func reconciliationSummary(for trip: Trip) -> String {
        let flagged = trip.matches.filter(\.needsReview).count
        if flagged == 0 {
            return "Everything matched — nothing to review."
        } else if flagged == 1 {
            return "1 item needs your review. Check the Review tab."
        } else {
            return "\(flagged) items need your review. Check the Review tab."
        }
    }
}

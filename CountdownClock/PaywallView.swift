import SwiftUI
import StoreKit

/// Presented when a free user tries to add a second event.
/// Dismiss happens automatically on successful purchase or restore.
struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    /// Called after the sheet is dismissed following a successful unlock,
    /// so the caller can immediately open the Add Event sheet.
    var onUnlocked: (() -> Void)? = nil

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {

                    // Icon + headline
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 64))
                            .foregroundStyle(.tint)
                            .padding(.top, 32)

                        Text("Unlock Unlimited Events")
                            .font(.title2.bold())

                        Text("Track as many countdowns as you like — vacations, birthdays, anniversaries, and more.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Feature list
                    VStack(alignment: .leading, spacing: 16) {
                        PaywallFeatureRow(text: "Unlimited countdown events")
                        PaywallFeatureRow(text: "All events on your Apple Watch")
                        PaywallFeatureRow(text: "One-time purchase — no subscription, ever")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)

                    // Error feedback
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Action buttons
                    VStack(spacing: 14) {
                        Button {
                            Task { await buyTapped() }
                        } label: {
                            Group {
                                if purchaseManager.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(purchaseManager.product.map {
                                        "Unlock for \($0.displayPrice)"
                                    } ?? "Unlock — $2.99")
                                    .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(purchaseManager.isLoading)

                        Button("Restore Purchase") {
                            Task { await restoreTapped() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .disabled(purchaseManager.isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Actions

    private func buyTapped() async {
        errorMessage = nil
        do {
            try await purchaseManager.purchase()
            if purchaseManager.isUnlocked {
                dismiss()
                onUnlocked?()
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
    }

    private func restoreTapped() async {
        errorMessage = nil
        await purchaseManager.restore()
        if purchaseManager.isUnlocked {
            dismiss()
            onUnlocked?()
        } else {
            errorMessage = "No previous purchase found for this Apple ID."
        }
    }
}

// MARK: - Supporting view

private struct PaywallFeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}

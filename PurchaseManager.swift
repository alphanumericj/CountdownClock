import Foundation
import StoreKit

/// Manages the "Unlimited Events" non-consumable in-app purchase.
/// Inject as an @EnvironmentObject from CountdownClockApp.
@MainActor
final class PurchaseManager: ObservableObject {

    // MARK: - Published state

    /// true once the user has successfully purchased or restored Unlimited Events.
    @Published private(set) var isUnlocked: Bool = false

    /// true while a purchase or restore network call is in flight.
    @Published private(set) var isLoading: Bool = false

    /// The StoreKit product, loaded on init. Used to display the real price.
    @Published private(set) var product: Product?

    // MARK: - Private

    private static let productID = "com.chipmania.CountdownClock.unlimitedEvents"
    private var transactionListener: Task<Void, Never>?

    // MARK: - Init / deinit

    init() {
        transactionListener = startTransactionListener()
        Task {
            await loadProduct()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public API

    /// Initiates the StoreKit purchase flow. Throws on error; caller should display a message.
    func purchase() async throws {
        guard let product else {
            throw PurchaseError.productNotFound
        }
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verified(verification)
            await transaction.finish()
            isUnlocked = true
        case .userCancelled, .pending:
            break   // no action needed
        @unknown default:
            break
        }
    }

    /// Asks Apple to restore previous purchases and refreshes entitlements.
    func restore() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Private helpers

    private func loadProduct() async {
        let products = try? await Product.products(for: [Self.productID])
        product = products?.first
    }

    /// Walks the current-entitlements sequence to check if the user already owns the IAP.
    private func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == Self.productID,
               tx.revocationDate == nil {
                isUnlocked = true
                return
            }
        }
    }

    /// Background task that catches transactions completed outside this session
    /// (e.g. on another device, or after an interrupted purchase).
    private func startTransactionListener() -> Task<Void, Never> {
        let productID = Self.productID
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result, tx.productID == productID {
                    await tx.finish()
                    guard let self else { return }
                    await MainActor.run { self.isUnlocked = true }
                }
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw PurchaseError.verificationFailed
        case .verified(let value): return value
        }
    }

    enum PurchaseError: LocalizedError {
        case verificationFailed
        case productNotFound
        var errorDescription: String? {
            switch self {
            case .verificationFailed:
                return "Purchase could not be verified. Please try again."
            case .productNotFound:
                return "Product unavailable — check your internet connection, or make sure the StoreKit configuration is set up in your Xcode scheme."
            }
        }
    }
}

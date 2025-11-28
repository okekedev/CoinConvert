import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {

    // MARK: - Development Flag
    // Set to true to enable Pro features without purchase (for testing only)
    private let ENABLE_PRO_FOR_DEVELOPMENT = false

    // MARK: - Published Properties
    @Published var isPro: Bool = false
    @Published var isLoading: Bool = false
    @Published var products: [Product] = []
    @Published var secretUnlocked: Bool = false  // Secret unlock - persists until app force-close

    // MARK: - Product IDs
    private let monthlySubscriptionID = "com.christianokeke.liveexchange.pro.monthly"

    // MARK: - Transaction Updates
    private var updateListenerTask: Task<Void, Error>? = nil

    // MARK: - Initialization
    init() {
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateProStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = [monthlySubscriptionID]
            let loadedProducts = try await Product.products(for: productIDs)

            DispatchQueue.main.async {
                self.products = loadedProducts
                print("✅ Loaded \(loadedProducts.count) products")
            }
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try StoreManager.checkVerified(verification)
            await updateProStatus()
            await transaction.finish()
            print("✅ Purchase successful")
            return true

        case .userCancelled:
            print("ℹ️ User cancelled purchase")
            return false

        case .pending:
            print("⏳ Purchase pending")
            return false

        @unknown default:
            print("⚠️ Unknown purchase result")
            return false
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updateProStatus()
            print("✅ Purchases restored")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
        }
    }

    // MARK: - Pro Status
    func updateProStatus() async {
        if ENABLE_PRO_FOR_DEVELOPMENT {
            DispatchQueue.main.async {
                self.isPro = true
                print("🔓 Pro features enabled (development mode)")
            }
            return
        }

        // Check secret unlock first
        if secretUnlocked {
            DispatchQueue.main.async {
                self.isPro = true
                print("🔓 Pro features unlocked (secret code)")
            }
            return
        }

        var isProUser = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try StoreManager.checkVerified(result)

                if transaction.productID == monthlySubscriptionID {
                    isProUser = true
                    break
                }
            } catch {
                print("❌ Transaction verification failed: \(error)")
            }
        }

        DispatchQueue.main.async {
            self.isPro = isProUser
            print(self.isPro ? "✅ User is Pro" : "ℹ️ User is Free")
        }
    }

    // MARK: - Transaction Listener
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try StoreManager.checkVerified(result)

                    Task { @MainActor in
                        await self.updateProStatus()
                    }

                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Transaction Verification
    nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Store Errors
enum StoreError: Error {
    case failedVerification
}

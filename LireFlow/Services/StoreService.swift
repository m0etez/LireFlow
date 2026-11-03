import Foundation
import StoreKit

/// StoreKit 2 service for managing LireFlow Pro purchases
@MainActor
class StoreService: ObservableObject {
    static let shared = StoreService()
    
    // MARK: - Product IDs
    
    static let proProductID = "com.lireflow.app.pro"
    
    // MARK: - Published Properties
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published private(set) var isLoading = false
    
    // MARK: - Computed Properties
    
    /// Whether user has Pro access
    var isPro: Bool {
        purchasedProductIDs.contains(Self.proProductID)
    }
    
    /// The Pro product if loaded
    var proProduct: Product? {
        products.first { $0.id == Self.proProductID }
    }
    
    // MARK: - Free Tier Limits
    
    static let maxFreeFeeds = 15
    static let maxFreeReadingLists = 1
    
    // MARK: - Purchase State
    
    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(String)
        case restored
    }
    
    // MARK: - Private Properties
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    private init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()
        
        // Load products and check entitlements
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let storeProducts = try await Product.products(for: [Self.proProductID])
            products = storeProducts
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase() async {
        guard let product = proProduct else {
            purchaseState = .failed("Product not available")
            return
        }
        
        purchaseState = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check if transaction is verified
                let transaction = try checkVerified(verification)
                
                // Update purchased products
                await updatePurchasedProducts()
                
                // Finish transaction
                await transaction.finish()
                
                purchaseState = .purchased
                
            case .userCancelled:
                purchaseState = .idle
                
            case .pending:
                purchaseState = .idle
                
            @unknown default:
                purchaseState = .failed("Unknown purchase result")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            
            if isPro {
                purchaseState = .restored
            }
        } catch {
            purchaseState = .failed("Failed to restore purchases: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Check Entitlements
    
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        // Iterate through all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if it's our Pro product
                if transaction.productID == Self.proProductID {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        purchasedProductIDs = purchased
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if user can add more feeds
    func canAddFeed(currentCount: Int) -> Bool {
        return isPro || currentCount < Self.maxFreeFeeds
    }
    
    /// Check if user can add more reading lists
    func canAddReadingList(currentCount: Int) -> Bool {
        return isPro || currentCount < Self.maxFreeReadingLists
    }
    
    /// Get remaining feeds in free tier
    func remainingFreeFeeds(currentCount: Int) -> Int {
        return max(0, Self.maxFreeFeeds - currentCount)
    }
    
    /// Get remaining reading lists in free tier
    func remainingFreeReadingLists(currentCount: Int) -> Int {
        return max(0, Self.maxFreeReadingLists - currentCount)
    }
    
    /// Reset purchase state to idle
    func resetPurchaseState() {
        purchaseState = .idle
    }
    
    /// Format price for display
    var formattedPrice: String {
        proProduct?.displayPrice ?? "€4.99"
    }
}

//
//  StoreManager.swift
//  Noisic
//
//  Created on 2025-01-06
//

import StoreKit

@MainActor
class StoreManager: ObservableObject {
    // 各サウンドのプロダクトID
    static let productIds: Set<String> = [
        "com.noisic.sound.ocean",
        "com.noisic.sound.drive",
        "com.noisic.sound.river"
    ]

    @Published var products: [Product] = []
    @Published var purchasedProductIds: Set<String> = []
    @Published var isLoading = false

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // 特定のサウンドがアンロックされているか
    func isUnlocked(_ sound: AmbientSound) -> Bool {
        if !sound.isPremium {
            return true
        }
        guard let productId = sound.productId else {
            return true
        }
        return purchasedProductIds.contains(productId)
    }

    // 特定のサウンドのプロダクトを取得
    func product(for sound: AmbientSound) -> Product? {
        guard let productId = sound.productId else { return nil }
        return products.first { $0.id == productId }
    }

    // プロダクトを読み込み
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Self.productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }

    // 特定のサウンドを購入
    func purchase(sound: AmbientSound) async throws -> Bool {
        guard let productId = sound.productId,
              let product = products.first(where: { $0.id == productId }) else {
            return false
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    // 購入の復元
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }

    // 購入済みプロダクトの更新
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchased.insert(transaction.productID)
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }

        purchasedProductIds = purchased
    }

    // トランザクションの監視
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }

    // 検証（nonisolatedでバックグラウンドタスクからも呼び出し可能）
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

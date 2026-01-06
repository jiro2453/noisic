//
//  PaywallView.swift
//  Noisic
//
//  Created on 2025-01-06
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Binding var isPresented: Bool
    let targetSound: AmbientSound

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 閉じるボタン
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // サウンドアイコン
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: targetSound.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                // タイトル
                VStack(spacing: 8) {
                    Text(targetSound.displayName)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Unlock this ambient sound")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // 購入ボタン
                VStack(spacing: 12) {
                    if let product = storeManager.product(for: targetSound) {
                        Button(action: {
                            purchase()
                        }) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Buy - \(product.displayPrice)")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(27)
                        }
                        .disabled(isPurchasing)
                    } else if storeManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(height: 54)
                    } else {
                        Text("Product unavailable")
                            .foregroundColor(.white.opacity(0.5))
                            .frame(height: 54)
                    }

                    // 復元ボタン
                    Button(action: {
                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.isUnlocked(targetSound) {
                                isPresented = false
                            }
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func purchase() {
        isPurchasing = true
        Task {
            do {
                let success = try await storeManager.purchase(sound: targetSound)
                if success {
                    isPresented = false
                }
            } catch {
                errorMessage = "Purchase failed. Please try again."
                showError = true
            }
            isPurchasing = false
        }
    }
}

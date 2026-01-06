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

                // タイトル
                VStack(spacing: 12) {
                    Text("Premium Sounds")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("すべての環境音をアンロック")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }

                // プレミアムサウンドのプレビュー
                HStack(spacing: 24) {
                    PremiumSoundIcon(icon: "water.waves", name: "Ocean")
                    PremiumSoundIcon(icon: "car.fill", name: "Drive")
                    PremiumSoundIcon(icon: "drop.fill", name: "River")
                }
                .padding(.vertical, 32)

                // 特典
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "3つの追加環境音")
                    FeatureRow(icon: "checkmark.circle.fill", text: "美しい動画背景")
                    FeatureRow(icon: "checkmark.circle.fill", text: "一度の購入で永久利用")
                }
                .padding(.horizontal, 40)

                Spacer()

                // 購入ボタン
                VStack(spacing: 12) {
                    if let product = storeManager.products.first {
                        Button(action: {
                            purchase()
                        }) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("購入する - \(product.displayPrice)")
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
                        Text("製品情報を読み込めません")
                            .foregroundColor(.white.opacity(0.5))
                            .frame(height: 54)
                    }

                    // 復元ボタン
                    Button(action: {
                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.isPremiumUnlocked {
                                isPresented = false
                            }
                        }
                    }) {
                        Text("購入を復元")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func purchase() {
        isPurchasing = true
        Task {
            do {
                let success = try await storeManager.purchase()
                if success {
                    isPresented = false
                }
            } catch {
                errorMessage = "購入に失敗しました。もう一度お試しください。"
                showError = true
            }
            isPurchasing = false
        }
    }
}

struct PremiumSoundIcon: View {
    let icon: String
    let name: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 70, height: 70)

                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.green)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

//
//  PaywallView.swift
//  CoinConvert
//
//  Pro subscription paywall for camera scanning feature
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    @State private var showProductLoadError = false
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""

    var onContinueToCalculator: (() -> Void)?

    var body: some View {
        ZStack {
            // Gradient background (gold to dark gold)
            LinearGradient(
                colors: [AppTheme.gold, AppTheme.darkGold],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Falling flags background
            FallingFlagsView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)

                    // App Icon centered with rounded corners
                    AppLogoView()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)

                    // Title
                    VStack(spacing: 10) {
                        Text("Unlock Pro")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Scan prices with your camera")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Feature list
                    VStack(alignment: .leading, spacing: 18) {
                        PaywallFeatureRow(icon: "camera.viewfinder", title: "Camera Scanner", description: "Point at any price tag and instantly convert")
                        PaywallFeatureRow(icon: "text.viewfinder", title: "Smart Recognition", description: "Automatically detects prices in any currency")
                        PaywallFeatureRow(icon: "bolt.fill", title: "Real-time Conversion", description: "See converted amounts as you scan")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    if let product = storeManager.products.first {
                        // Pricing
                        VStack(spacing: 10) {
                            Text("7-Day Free Trial")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text("Then \(product.displayPrice)/month")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.9))

                            Text("Cancel anytime")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        // Subscribe button
                        Button(action: {
                            Task {
                                do {
                                    let success = try await storeManager.purchase(product)
                                    if success {
                                        dismiss()
                                    }
                                } catch {
                                    print("❌ Purchase error: \(error)")
                                    purchaseErrorMessage = "Unable to complete purchase. Please try again."
                                    showPurchaseError = true
                                }
                            }
                        }) {
                            Group {
                                if storeManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.gold))
                                } else {
                                    Text("Start Free Trial")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .foregroundColor(AppTheme.darkGold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .disabled(storeManager.isLoading)
                    } else if showProductLoadError {
                        VStack(spacing: 12) {
                            Text("Unable to load subscription")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)

                            Button(action: {
                                showProductLoadError = false
                                Task {
                                    await storeManager.loadProducts()
                                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                                    if storeManager.products.isEmpty {
                                        showProductLoadError = true
                                    }
                                }
                            }) {
                                Text("Retry")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(AppTheme.darkGold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .onAppear {
                                Task {
                                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                                    if storeManager.products.isEmpty {
                                        showProductLoadError = true
                                    }
                                }
                            }
                    }

                    // Restore button
                    Button(action: {
                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.isPro {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .disabled(storeManager.isLoading)

                    // Privacy & Terms links
                    HStack(spacing: 12) {
                        Link("Privacy Policy", destination: URL(string: "https://okekedev.github.io/CoinConvert/privacy.html")!)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))

                        Text("•")
                            .foregroundColor(.white.opacity(0.4))

                        Link("Terms of Use", destination: URL(string: "https://okekedev.github.io/CoinConvert/terms.html")!)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 8)

                    Spacer().frame(height: 16)

                    // Continue button - styled prominently
                    Button(action: {
                        if let onContinue = onContinueToCalculator {
                            dismiss()
                            onContinue()
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseErrorMessage)
        }
    }
}

// MARK: - Falling Flags Background
struct FallingFlagsView: View {
    // Currency flags and symbols to display
    private let items: [String] = [
        "🇺🇸", "🇪🇺", "🇬🇧", "🇯🇵", "🇨🇦", "🇦🇺", "🇨🇭", "🇨🇳",
        "🇮🇳", "🇧🇷", "🇲🇽", "🇰🇷", "🇸🇬", "🇭🇰", "🇳🇿", "🇸🇪",
        "🇳🇴", "🇩🇰", "🇿🇦", "🇹🇭", "🇵🇭", "🇮🇩", "🇲🇾", "🇻🇳",
        "$", "€", "£", "¥", "₹", "₩", "₽", "₿"
    ]

    @State private var fallingItems: [FallingItem] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(fallingItems) { item in
                    Text(item.symbol)
                        .font(.system(size: item.size))
                        .opacity(item.opacity)
                        .position(x: item.x, y: item.y)
                }
            }
            .onAppear {
                startFalling(in: geometry.size)
            }
        }
    }

    private func startFalling(in size: CGSize) {
        // Create initial items spread across the screen
        for i in 0..<20 {
            let delay = Double(i) * 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                addNewItem(in: size)
            }
        }

        // Continuously add new items
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            addNewItem(in: size)
        }
    }

    private func addNewItem(in size: CGSize) {
        let item = FallingItem(
            symbol: items.randomElement() ?? "💰",
            x: CGFloat.random(in: 20...(size.width - 20)),
            y: -50,
            size: CGFloat.random(in: 20...40),
            opacity: Double.random(in: 0.15...0.35),
            duration: Double.random(in: 8...15)
        )

        fallingItems.append(item)

        // Animate falling
        withAnimation(.linear(duration: item.duration)) {
            if let index = fallingItems.firstIndex(where: { $0.id == item.id }) {
                fallingItems[index].y = size.height + 50
            }
        }

        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + item.duration) {
            fallingItems.removeAll { $0.id == item.id }
        }
    }
}

struct FallingItem: Identifiable {
    let id = UUID()
    let symbol: String
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let opacity: Double
    let duration: Double
}

// MARK: - App Logo View
struct AppLogoView: View {
    var body: some View {
        if let uiImage = UIImage(named: "AppLogo") {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Debug: show red box if image fails to load
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.red)
                .overlay(
                    Text("IMG\nFAIL")
                        .font(.caption)
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Paywall Feature Row
struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
    }
}

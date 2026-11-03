import SwiftUI

/// Upgrade sheet for LireFlow Pro purchase
struct UpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeService = StoreService.shared
    
    @State private var showingSuccess = false
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 0) {
            if storeService.isPro {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Pro Unlocked!")
                }
                .font(.headline)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
            }
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Unlock Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Get the most out of LireFlow")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            .padding(.horizontal, 24)
            
            Divider()
            
            // Feature comparison
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "infinity", title: "Unlimited Feeds", description: "Free: 15 feeds • Pro: Unlimited")
                        featureRow(icon: "list.bullet.rectangle", title: "Unlimited Reading Lists", description: "Free: 1 list • Pro: Unlimited")
                        featureRow(icon: "paintpalette", title: "Premium Themes", description: "Sepia, Nord, and Ocean themes")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            
            Divider()
            
            // Footer with purchase button
            VStack(spacing: 16) {
                // Purchase button
                Button {
                    Task {
                        await storeService.purchase()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if storeService.purchaseState == .purchasing {
                            ProgressView()
                                .controlSize(.small)
                            Text("Processing...")
                        } else {
                            Image(systemName: "star.fill")
                            Text("Unlock Pro – \(storeService.formattedPrice)")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(storeService.purchaseState == .purchasing || storeService.isLoading || storeService.isPro)
                
                Text("One-time purchase • No subscription")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                // Restore purchases
                Button("Restore Purchase") {
                    Task {
                        await storeService.restorePurchases()
                    }
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .disabled(storeService.isLoading)
                
                // Maybe Later
                Button("Maybe Later") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
                .font(.caption)
            }
            .padding(24)
        }
        .frame(width: 580, height: 650)
        .onChange(of: storeService.purchaseState) { _, newState in
            switch newState {
            case .purchased, .restored:
                showingSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            case .failed:
                showingError = true
            default:
                break
            }
        }
        .alert("Welcome to Pro!", isPresented: $showingSuccess) {
            Button("Awesome!") {
                dismiss()
            }
        } message: {
            Text("Thank you for your purchase! All Pro features are unlocked.")
        }
        .alert("Purchase failed", isPresented: $showingError) {
            Button("OK") {
                storeService.resetPurchaseState()
            }
        } message: {
            if case .failed(let message) = storeService.purchaseState {
                Text(message)
            } else {
                Text("Something went wrong. Please try again.")
            }
        }
    }
    
    // MARK: - Feature Column
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    UpgradeSheet()
}

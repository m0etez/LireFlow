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
                    Text("Pro Débloqué !")
                }
                .font(.headline)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
            }
            
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                
                Text("LireFlow Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Libérez tout le potentiel")
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
                        featureRow(
                            icon: "infinity",
                            title: "Flux illimités",
                            freeText: "15 flux",
                            proText: "Illimité"
                        )
                        
                        featureRow(
                            icon: "bookmark.fill",
                            title: "Listes de lecture",
                            freeText: "3 listes",
                            proText: "Illimité"
                        )
                        
                        featureRow(
                            icon: "paintpalette.fill",
                            title: "Thèmes Premium",
                            freeText: "Clair & Sombre",
                            proText: "Sépia, Nord, Océan, Forêt"
                        )
                        
                        featureRow(
                            icon: "magnifyingglass",
                            title: "Recherche plein texte",
                            freeText: "Titres uniquement",
                            proText: "Tout le contenu"
                        )
                        
                        featureRow(
                            icon: "slider.horizontal.3",
                            title: "Filtres avancés",
                            freeText: "Basique",
                            proText: "Date, auteur, mots-clés"
                        )
                        
                        featureRow(
                            icon: "heart.fill",
                            title: "Soutenir le développement",
                            freeText: "",
                            proText: "Aidez-nous à améliorer LireFlow !"
                        )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
            
            Divider()
            
            // Footer with purchase button
            VStack(spacing: 16) {
                // Price display
                VStack(spacing: 4) {
                    Text("Achat unique")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(storeService.formattedPrice)
                        .font(.system(size: 32, weight: .bold))
                }
                
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
                            Text("Traitement...")
                        } else {
                            Image(systemName: "star.fill")
                            Text("Débloquer Pro")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(storeService.purchaseState == .purchasing || storeService.isLoading || storeService.isPro)
                
                // Restore purchases
                Button("Restaurer l'achat") {
                    Task {
                        await storeService.restorePurchases()
                    }
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .disabled(storeService.isLoading)
                
                // Maybe Later
                Button("Peut-être plus tard") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
                .font(.caption)
            }
            .padding(24)
        }
        #if os(macOS)
        .frame(width: 520, height: 700)
        #endif
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
        .alert("Bienvenue dans Pro !", isPresented: $showingSuccess) {
            Button("Génial !") {
                dismiss()
            }
        } message: {
            Text("Merci de votre achat ! Toutes les fonctionnalités Pro sont maintenant débloquées.")
        }
        .alert("Achat échoué", isPresented: $showingError) {
            Button("OK") {
                storeService.resetPurchaseState()
            }
        } message: {
            if case .failed(let message) = storeService.purchaseState {
                Text(message)
            } else {
                Text("Une erreur est survenue. Veuillez réessayer.")
            }
        }
    }
    
    // MARK: - Feature Row
    
    private func featureRow(icon: String, title: String, freeText: String, proText: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                
                HStack(spacing: 20) {
                    // Free tier
                    if !freeText.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(freeText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(minWidth: 80, alignment: .leading)
                    }
                    
                    // Pro tier
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(proText)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Upgrade Banner (for Settings)

struct UpgradeBanner: View {
    @StateObject private var storeService = StoreService.shared
    @Binding var showUpgradeSheet: Bool
    
    var body: some View {
        if !storeService.isPro {
            Button {
                showUpgradeSheet = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Passer à Pro")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Flux illimités, thèmes & plus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(storeService.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Pro Badge

struct ProBadge: View {
    var small: Bool = false
    
    var body: some View {
        Text("PRO")
            .font(small ? .caption2 : .caption)
            .fontWeight(.bold)
            .padding(.horizontal, small ? 4 : 6)
            .padding(.vertical, small ? 2 : 3)
            .background(
                LinearGradient(
                    colors: [.orange, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: small ? 3 : 4))
    }
}

// MARK: - Pro Status View (for Settings when Pro)

struct ProStatusView: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("LireFlow Pro")
                        .font(.headline)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                
                Text("Toutes les fonctionnalités débloquées")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    UpgradeSheet()
}

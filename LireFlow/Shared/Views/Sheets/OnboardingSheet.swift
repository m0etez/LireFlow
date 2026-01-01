import SwiftUI

struct OnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var configService = ConfigService.shared
    @StateObject private var storeService = StoreService.shared
    
    @State private var currentStep = 0
    @State private var searchText = ""
    
    private let totalSteps = 3  // Welcome, Europresse, Pro
    
    private var filteredPortals: [EuropressePortal] {
        if searchText.isEmpty {
            return EuropressePortal.availablePortals
        }
        return EuropressePortal.availablePortals.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                
                Text("Welcome to LireFlow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("A modern RSS reader for macOS")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            Divider()
            
            // Content based on step
            switch currentStep {
            case 0:
                welcomeStep
            case 1:
                europresseStep
            case 2:
                proStep
            default:
                welcomeStep
            }
            
            Spacer()
            
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 16)
            
            // Footer buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep < totalSteps - 1 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .frame(width: 600, height: 700)
    }
    
    // MARK: - Welcome Step
    
    private var welcomeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                featureRow(
                    icon: "list.bullet.rectangle",
                    iconColor: .blue,
                    title: "Subscribe to Your Favorite Sites",
                    description: "Add RSS feeds from news sites, blogs, and more. Organize them into folders."
                )
                
                featureRow(
                    icon: "newspaper",
                    iconColor: .orange,
                    title: "Read Full Articles via Europresse",
                    description: "If you have a university or library account, read paywalled articles through Europresse."
                )
                
                featureRow(
                    icon: "cloud.sun",
                    iconColor: .cyan,
                    title: "Weather Widget",
                    description: "See local weather at a glance in the sidebar."
                )
                
                featureRow(
                    icon: "keyboard",
                    iconColor: .purple,
                    title: "Keyboard Shortcuts",
                    description: "Navigate with J/K, star with S, mark read with M, and more."
                )
                
                featureRow(
                    icon: "lock.shield",
                    iconColor: .green,
                    title: "Privacy First",
                    description: "All data is stored locally on your Mac. No tracking, no cloud sync."
                )
            }
            .padding(32)
        }
    }
    
    // MARK: - Europresse Step
    
    private var europresseStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "building.columns")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
                
                Text("Connect to Europresse")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("If your university or library offers Europresse access, select it below to read full articles from major newspapers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 16)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search institutions...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 24)
            
            // Portal list
            ScrollView {
                LazyVStack(spacing: 4) {
                    // None option
                    portalRow(nil, isSelected: configService.config.europressePortal == nil)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    ForEach(filteredPortals) { portal in
                        portalRow(portal, isSelected: configService.config.europressePortal?.name == portal.name)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Selected status
            if let portal = configService.config.europressePortal {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Selected: \(portal.name)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func featureRow(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func portalRow(_ portal: EuropressePortal?, isSelected: Bool) -> some View {
        Button {
            configService.config.europressePortal = portal
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(portal?.name ?? "None (Skip Europresse)")
                        .font(.subheadline)
                        .foregroundStyle(portal == nil ? .secondary : .primary)
                    
                    if portal == nil {
                        Text("You can configure this later in Settings")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Pro Step
    
    private var proStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Unlock Pro")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Get the most out of LireFlow")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)
            
            // Feature comparison
            VStack(alignment: .leading, spacing: 12) {
                proFeatureRow(icon: "infinity", title: "Unlimited Feeds", description: "Free: 15 feeds • Pro: Unlimited")
                proFeatureRow(icon: "list.bullet.rectangle", title: "Unlimited Reading Lists", description: "Free: 1 list • Pro: Unlimited")
                proFeatureRow(icon: "paintpalette", title: "Premium Themes", description: "Sepia, Nord, and Ocean themes")
            }
            .padding(20)
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            
            // Price and button
            VStack(spacing: 12) {
                if storeService.isPro {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Pro Unlocked!")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Button {
                        Task {
                            await storeService.purchase()
                        }
                    } label: {
                        HStack {
                            if storeService.purchaseState == .purchasing {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Processing...")
                            } else {
                                Image(systemName: "star.fill")
                                Text("Unlock Pro – \(storeService.formattedPrice)")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(storeService.purchaseState == .purchasing)
                }
                
                Text("One-time purchase • No subscription")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func proFeatureRow(icon: String, title: String, description: String) -> some View {
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
    }
    
    // MARK: - Actions
    
    private func completeOnboarding() {
        configService.config.hasCompletedOnboarding = true
        dismiss()
    }
}

#Preview {
    OnboardingSheet()
}

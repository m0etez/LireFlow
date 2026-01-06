import SwiftUI

struct OnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var configService = ConfigService.shared
    @StateObject private var storeService = StoreService.shared
    
    @State private var currentStep = 0
    @State private var searchText = ""
    
    @State private var selectedFeeds: Set<String> = []
    
    private let totalSteps = 5  // Welcome, Theme, Europresse, Feeds, Pro
    
    private var filteredPortals: [EuropressePortal] {
        if searchText.isEmpty {
            return EuropressePortal.availablePortals
        }
        return EuropressePortal.availablePortals.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        #if os(iOS)
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Compact header for iOS
                    VStack(spacing: 12) {
                        Image("LireFlowLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Text("Bienvenue sur LireFlow")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Un lecteur RSS moderne")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Step indicator
                    HStack(spacing: 8) {
                        ForEach(0..<totalSteps, id: \.self) { step in
                            Circle()
                                .fill(step == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Content based on step with slide animation
                    Group {
                        switch currentStep {
                        case 0:
                            welcomeStepContent
                        case 1:
                            themeStepContent
                        case 2:
                            europresseStepContent
                        case 3:
                            feedsStepContent
                        case 4:
                            proStepContent
                        default:
                            welcomeStepContent
                        }
                    }
                    .id(currentStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
                .padding(.bottom, 100) // Space for buttons
            }
            .overlay(alignment: .bottom) {
                // Footer buttons
                HStack {
                    if currentStep > 0 {
                        Button {
                            withAnimation {
                                currentStep -= 1
                            }
                        } label: {
                            Text("Retour")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    if currentStep < totalSteps - 1 {
                        Button {
                            withAnimation {
                                currentStep += 1
                            }
                        } label: {
                            Text("Suivant")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Commencer")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue.gradient)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        #else
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
                europresseStep
            case 3:
                feedsStep
            case 4:
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
        #endif
    }
    
    // MARK: - iOS Step Content
    
    private var welcomeStepContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            featureRow(
                icon: "list.bullet.rectangle",
                iconColor: .blue,
                title: "Abonnez-vous à vos sites préférés",
                description: "Ajoutez des flux RSS de sites d'actualités, blogs, et plus encore."
            )
            
            featureRow(
                icon: "bubble.left.and.bubble.right",
                iconColor: .purple,
                title: "Réseaux sociaux décentralisés",
                description: "Suivez des subreddits, comptes Mastodon, et communautés Lemmy."
            )
            
            featureRow(
                icon: "newspaper",
                iconColor: .orange,
                title: "Articles complets via Europresse",
                description: "Accédez aux articles payants grâce à votre bibliothèque."
            )
            
            featureRow(
                icon: "cloud.sun",
                iconColor: .cyan,
                title: "Widget Météo",
                description: "Consultez la météo locale en un coup d'œil."
            )
            
            featureRow(
                icon: "lock.shield",
                iconColor: .green,
                title: "Confidentialité garantie",
                description: "Toutes vos données restent sur votre appareil. Aucun tracking."
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var themeStepContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 40))
                    .foregroundStyle(.purple)
                
                Text("Choisissez votre thème")
                    .font(.headline)
                
                Text("Personnalisez l'apparence de LireFlow")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AppTheme.allCases.filter { $0 != .system }, id: \.self) { theme in
                    let isPremium = theme.isPremium && !storeService.isPro
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.backgroundColor)
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(configService.config.selectedTheme == theme ? theme.accentColor : Color.clear, lineWidth: 3)
                                )
                                .overlay(
                                    Image(systemName: theme.icon)
                                        .font(.title2)
                                        .foregroundStyle(theme.accentColor)
                                )

                            if isPremium {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.black.opacity(0.4))
                                    .frame(height: 60)
                                Image(systemName: "lock.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            }
                        }

                        HStack(spacing: 4) {
                            Text(theme.displayName)
                                .font(.caption)
                                .fontWeight(configService.config.selectedTheme == theme ? .semibold : .regular)
                                .foregroundStyle(isPremium ? .secondary : (configService.config.selectedTheme == theme ? theme.accentColor : .secondary))
                            if isPremium {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isPremium {
                            configService.config.selectedTheme = theme
                        }
                    }
                    .opacity(isPremium ? 0.7 : 1.0)
                }
            }
            .padding(.horizontal, 24)
            
            if !storeService.isPro {
                Text("Thèmes premium disponibles avec LireFlow Pro")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var europresseStepContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "building.columns")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
                
                Text("Connectez-vous à Europresse")
                    .font(.headline)
                
                Text("Sélectionnez votre université ou bibliothèque.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Rechercher...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 24)
            
            // Portal list
            LazyVStack(spacing: 4) {
                portalRow(nil, isSelected: configService.config.europressePortal == nil)
                
                ForEach(filteredPortals) { portal in
                    portalRow(portal, isSelected: configService.config.europressePortal?.name == portal.name)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var proStepContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                
                Text("Débloquer Pro")
                    .font(.headline)
                
                Text("Profitez pleinement de LireFlow")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                proFeatureRow(icon: "infinity", title: "Flux illimités", description: "Pro : Illimité")
                proFeatureRow(icon: "list.bullet.rectangle", title: "Listes illimitées", description: "Pro : Illimité")
                proFeatureRow(icon: "paintpalette", title: "Thèmes Premium", description: "Sepia, Nord, Ocean")
            }
            .padding(.horizontal, 24)
            
            if !storeService.isPro {
                Button {
                    Task {
                        await storeService.purchase()
                    }
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Débloquer Pro – \(storeService.formattedPrice)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.horizontal, 24)
            }
        }
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
    
    // MARK: - Feeds Step
    
    private var feedsStepContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                
                Text("Vos premiers flux")
                    .font(.headline)
                
                Text("Sélectionnez quelques sources pour commencer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Limit indicator
            if !storeService.isPro {
                HStack {
                    Image(systemName: selectedFeeds.count > StoreService.maxFreeFeeds ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    Text("\(selectedFeeds.count)/\(StoreService.maxFreeFeeds) flux gratuits sélectionnés")
                }
                .font(.caption)
                .foregroundStyle(selectedFeeds.count > StoreService.maxFreeFeeds ? .red : .secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(selectedFeeds.count > StoreService.maxFreeFeeds ? Color.red.opacity(0.1) : Color.platformSecondaryBackground)
                .clipShape(Capsule())
            }
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(DefaultFeeds.categories, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString(category, comment: ""))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            
                            ForEach(DefaultFeeds.feeds(for: category), id: \.url) { feedInfo in
                                HStack(spacing: 12) {
                                    Image(systemName: selectedFeeds.contains(feedInfo.url) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(selectedFeeds.contains(feedInfo.url) ? Color.accentColor : Color.secondary)
                                        .contentTransition(.symbolEffect(.replace))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(feedInfo.title)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.platformSecondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedFeeds.contains(feedInfo.url) ? Color.accentColor : Color.clear, lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedFeeds.contains(feedInfo.url) {
                                        selectedFeeds.remove(feedInfo.url)
                                    } else {
                                        selectedFeeds.insert(feedInfo.url)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    // Minimal wrapper for macOS consistency (reusing content as structure is similar)
    private var feedsStep: some View {
        feedsStepContent
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(portal?.name ?? NSLocalizedString("None (Skip Europresse)", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(portal == nil ? .secondary : .primary)

                if portal == nil {
                    Text(NSLocalizedString("You can configure this later in Settings", comment: ""))
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
        .contentShape(Rectangle())
        .onTapGesture {
            configService.config.europressePortal = portal
        }
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
        // Save selected feeds
        if !selectedFeeds.isEmpty {
            Task {
                var addedCount = 0
                for feedURL in selectedFeeds {
                     // Simple limit enforcement: Stop if limit reached and not pro
                    if !storeService.isPro && addedCount >= StoreService.maxFreeFeeds {
                        break
                    }
                    try? await FeedService().addFeed(url: feedURL, to: nil, in: modelContext)
                    addedCount += 1
                }
            }
        }
        
        configService.config.hasCompletedOnboarding = true
        dismiss()
    }
}

#Preview {
    OnboardingSheet()
}

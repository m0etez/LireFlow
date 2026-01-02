import SwiftUI
import SwiftData

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var folders: [Folder]
    @Query private var feeds: [Feed]
    @Query private var readingLists: [ReadingList]
    @Query(sort: \Article.publishedDate, order: .reverse) private var articles: [Article]

    @ObservedObject var configService = ConfigService.shared
    @StateObject private var storeService = StoreService.shared

    @StateObject private var exportService = ExportService()
    @StateObject private var importService = ImportService()

    @State private var selectedTab: SettingsTab = .general
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingCleanupAlert = false
    @State private var cleanupMessage = ""
    @State private var showingUpgrade = false
    
    // iOS ShareSheet state
    @State private var shareURL: URL?
    @State private var showingShareSheet = false

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "Général"
        case backup = "Sauvegarde"
        case about = "À propos"

        var id: String { rawValue }
        
        var localizedName: String {
            rawValue
        }
    }

    var hoverColor: Binding<Color> {
        Binding(
            get: {
                if configService.config.hoverColorHex.isEmpty {
                    return Color.clear // Default
                }
                return Color(hex: configService.config.hoverColorHex)
            },
            set: {
                configService.config.hoverColorHex = $0.toHex() ?? ""
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Paramètres")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()


            }
            .padding()

            Divider()

            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.localizedName).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Tab content
            ScrollView {
                switch selectedTab {
                case .general:
                    generalSettings
                case .backup:
                    backupSettings
                case .about:
                    aboutSettings
                }
            }
        }
        #if os(macOS)
        .frame(width: 650, height: 550)
        #endif
        .background(Color.platformBackground)
        .alert("Succès", isPresented: $showingSuccessAlert) {
            Button("OK") { showingSuccessAlert = false }
        } message: {
            Text(successMessage)
        }
        .alert("Erreur", isPresented: $showingErrorAlert) {
            Button("OK") { showingErrorAlert = false }
        } message: {
            Text(errorMessage)
        }
        .alert("Nettoyage terminé", isPresented: $showingCleanupAlert) { // Added for GeneralSettingsView
            Button("OK") { showingCleanupAlert = false }
        } message: {
            Text(cleanupMessage)
        }
        .sheet(isPresented: $showingUpgrade) { // Added for GeneralSettingsView
            UpgradeSheet()
        }
        #if os(iOS)
        .sheet(isPresented: $showingShareSheet, onDismiss: { shareURL = nil }) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        #endif
    }
    
    // MARK: - Backup Settings View

    private var backupSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Export Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Exporter la bibliothèque")
                            .font(.headline)

                        Text("Sauvegardez vos flux, dossiers et listes de lecture dans un fichier")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await exportJSON() }
                    } label: {
                        Label("Exporter en JSON", systemImage: "doc.text")
                    }
                    .disabled(isExporting || feeds.isEmpty)
                    .help("Exporter une sauvegarde complète (recommandé)")

                    Button {
                        Task { await exportOPML() }
                    } label: {
                        Label("Exporter en OPML", systemImage: "doc.text")
                    }
                    .disabled(isExporting || feeds.isEmpty)
                    .help("Exporter les flux uniquement (compatible avec d'autres lecteurs RSS)")
                }

                if isExporting {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Exportation en cours...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    Label("\(feeds.count)", systemImage: "newspaper")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .help("Flux")

                    Label("\(folders.count)", systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .help("Dossiers")

                    Label("\(readingLists.count)", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .help("Listes de lecture")
                }
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Import Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title2)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Importer la bibliothèque")
                            .font(.headline)

                        Text("Restaurez des flux depuis un fichier JSON ou OPML. Les doublons seront ignorés.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await importJSON() }
                    } label: {
                        Label("Importer depuis JSON", systemImage: "doc.text")
                    }
                    .disabled(isImporting)
                    .help("Importer un fichier de sauvegarde LireFlow")

                    Button {
                        Task { await importOPML() }
                    } label: {
                        Label("Importer depuis OPML", systemImage: "doc.text")
                    }
                    .disabled(isImporting)
                    .help("Importer des flux depuis un fichier OPML")
                }

                if isImporting {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Importation en cours...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Note : Les flux existants avec la même URL ne seront pas dupliqués.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Info Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                    Text("À propos des formats d'exportation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("JSON")
                                .fontWeight(.medium)
                            Text("Sauvegarde complète incluant flux, dossiers et listes de lecture. Utilisez ceci pour des sauvegardes complètes.")
                        }
                        .font(.caption)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("OPML")
                                .fontWeight(.medium)
                            Text("Format RSS standard. Exporte uniquement les flux et dossiers. Utilisez ceci pour migrer vers d'autres lecteurs RSS.")
                        }
                        .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.platformSecondaryBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }
    
    // MARK: - Export Actions

    private func exportJSON() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let url = try await exportService.exportToJSON(
                folders: folders,
                feeds: feeds,
                readingLists: readingLists
            )
            #if os(iOS)
            shareURL = url
            showingShareSheet = true
            #else
            successMessage = "Exporté avec succès vers :\n\(url.lastPathComponent)"
            showingSuccessAlert = true
            #endif
        } catch ExportService.ExportError.userCancelled {
            // Silent - user cancelled
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    private func exportOPML() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let url = try await exportService.exportToOPML(
                folders: folders,
                feeds: feeds
            )
            #if os(iOS)
            shareURL = url
            showingShareSheet = true
            #else
            successMessage = "Exporté avec succès vers :\n\(url.lastPathComponent)"
            showingSuccessAlert = true
            #endif
        } catch ExportService.ExportError.userCancelled {
            // Silent - user cancelled
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    // MARK: - Import Actions

    private func importJSON() async {
        #if os(macOS)
        isImporting = true
        defer { isImporting = false }

        do {
            let result = try await importService.importFromJSON(in: modelContext)
            successMessage = """
            Importation terminée !

            Importés :
            • \(result.foldersImported) dossiers
            • \(result.feedsImported) flux
            • \(result.readingListsImported) listes de lecture

            Doublons ignorés : \(result.duplicatesSkipped)
            """
            showingSuccessAlert = true
        } catch ImportService.ImportError.userCancelled {
            // Silent - user cancelled
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
        #else
        errorMessage = "L'importation n'est pas encore disponible sur iOS. Veuillez utiliser l'application macOS pour importer des flux."
        showingErrorAlert = true
        #endif
    }

    private func importOPML() async {
        #if os(macOS)
        isImporting = true
        defer { isImporting = false }

        do {
            let result = try await importService.importFromOPML(in: modelContext)
            successMessage = """
            Importation terminée !

            Importés :
            • \(result.foldersImported) dossiers
            • \(result.feedsImported) flux

            Doublons ignorés : \(result.duplicatesSkipped)
            """
            showingSuccessAlert = true
        } catch ImportService.ImportError.userCancelled {
            // Silent - user cancelled
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
        #else
        errorMessage = "L'importation n'est pas encore disponible sur iOS. Veuillez utiliser l'application macOS pour importer des flux."
        showingErrorAlert = true
        #endif
    }

    // MARK: - General Settings View

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            // MARK: - LireFlow Pro Section
            if !storeService.isPro {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LireFlow Pro")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("libérez tout le potentiel")
                                .font(.subheadline)
                                .opacity(0.9)
                        }
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "infinity")
                            Text("Flux illimités")
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle")
                            Text("Listes de lecture illimitées")
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "paintpalette")
                            Text("Thèmes Premium")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    
                    Button {
                        showingUpgrade = true
                    } label: {
                        Text("Passer à Pro – \(storeService.formattedPrice)")
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        Task {
                            await storeService.restorePurchases()
                        }
                    } label: {
                        Text("Restaurer les achats")
                            .font(.caption)
                            .underline()
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            } else {
                // Pro Active State
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LireFlow Pro Actif")
                            .font(.headline)
                        Text("Merci pour votre soutien !")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
                )
            }

            // MARK: - Appearance Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "paintbrush")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apparence")
                            .font(.headline)

                        Text("Personnalisez l'apparence de LireFlow")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Theme picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Thème")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                        ForEach(AppTheme.allCases.filter { $0 != .system }) { theme in
                            themeButton(theme)
                        }
                    }
                }

                // Hover Color
                HStack {
                    ColorPicker("Couleur de survol", selection: hoverColor, supportsOpacity: true)
                        .help("Couleur personnalisée pour les effets de survol")
                    
                    if !configService.config.hoverColorHex.isEmpty {
                        Button("Réinitialiser") {
                            configService.config.hoverColorHex = ""
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }

                Toggle("Afficher le nombre de non-lus", isOn: $configService.config.showUnreadCount)
                    .help("Afficher le nombre d'articles non lus dans la barre latérale")
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Reading Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "book")
                        .font(.title2)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lecture")
                            .font(.headline)

                        Text("Configurer les préférences de lecture")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Taille de police :")
                        Spacer()
                        Text("\(configService.config.articleFontSize)pt")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(configService.config.articleFontSize) },
                        set: { configService.config.articleFontSize = Int($0) }
                    ), in: 12...24, step: 1)
                }

                Toggle("Marquer comme lu au défilement", isOn: $configService.config.markAsReadOnScroll)
                    .help("Marquer automatiquement les articles comme lus lors du défilement")
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Feeds Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Flux")
                            .font(.headline)

                        Text("Paramètres de rafraîchissement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Intervalle :")
                        Spacer()
                        Text("\(configService.config.refreshIntervalMinutes) minutes")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(configService.config.refreshIntervalMinutes) },
                        set: { configService.config.refreshIntervalMinutes = Int($0) }
                    ), in: 5...120, step: 5)
                }

                HStack {
                    Text("Catégorie par défaut :")
                    Spacer()
                    TextField("Catégorie", text: $configService.config.defaultFeedCategory)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                }
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Weather Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cloud.sun")
                        .font(.title2)
                        .foregroundStyle(.cyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Météo")
                            .font(.headline)

                        Text("Configurer l'affichage météo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle("Afficher le widget météo", isOn: $configService.config.showWeather)
                    .help("Afficher la météo dans la barre latérale")

                HStack {
                    Text("Lieu :")
                    Spacer()
                    TextField("Détection auto", text: Binding(
                        get: { configService.config.weatherLocation ?? "" },
                        set: { configService.config.weatherLocation = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                }
                .disabled(!configService.config.showWeather)

                Text("Laissez vide pour la détection automatique")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Europresse Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "newspaper")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Intégration Europresse")
                            .font(.headline)

                        Text("Accès via votre université ou bibliothèque")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Sélectionnez votre institution :")
                        .font(.subheadline)

                    Picker("Institution", selection: Binding(
                        get: { configService.config.europressePortal },
                        set: { configService.config.europressePortal = $0 }
                    )) {
                        Text("Aucune (Désactivé)").tag(nil as EuropressePortal?)

                        Divider()

                        ForEach(EuropressePortal.availablePortals) { portal in
                            Text(portal.name).tag(portal as EuropressePortal?)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let portal = configService.config.europressePortal {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Connecté à \(portal.name)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        Text("Un bouton \"Lire sur Europresse\" apparaîtra sur les articles.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("À propos d'Europresse")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    Text("Europresse est un service d'archives de presse disponible via de nombreuses universités et bibliothèques européennes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Votre institution non répertoriée ? Vérifiez auprès de votre bibliothèque si elle propose un accès Europresse.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Performance Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "gauge.high")
                        .font(.title2)
                        .foregroundStyle(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Performance")
                            .font(.headline)

                        Text("Optimiser les performances et le stockage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle("Charger les images", isOn: $configService.config.loadImages)
                    .help("Désactiver pour économiser la bande passante")

                Toggle("Rafraîchissement en arrière-plan", isOn: $configService.config.backgroundRefreshEnabled)
                    .help("Autoriser les flux à se rafraîchir en arrière-plan")

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max articles par flux :")
                        Spacer()
                        Text("\(configService.config.maxArticlesPerFeed)")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(configService.config.maxArticlesPerFeed) },
                        set: { configService.config.maxArticlesPerFeed = Int($0) }
                    ), in: 100...1000, step: 50)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Supprimer les articles plus vieux que :")
                        Spacer()
                        Text("\(configService.config.cleanupOldArticlesDays) jours")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(configService.config.cleanupOldArticlesDays) },
                        set: { configService.config.cleanupOldArticlesDays = Int($0) }
                    ), in: 7...90, step: 7)
                }

                Button {
                    cleanupOldArticles()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Nettoyer les vieux articles maintenant")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Advanced Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avancé")
                            .font(.headline)

                        Text("Fichier de configuration et options avancées")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fichier de configuration :")
                            .font(.subheadline)
                        Text(configService.configFilePath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    Spacer()

                    #if os(macOS)
                    Button("Afficher dans le Finder") {
                        if let url = URL(string: "file://" + configService.configFilePath) {
                            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                        }
                    }
                    .buttonStyle(.bordered)
                    #endif
                }
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }

    private func applyAppearance() {
        configService.config.selectedTheme.apply()
    }

    private func cleanupOldArticles() {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -configService.config.cleanupOldArticlesDays,
            to: Date()
        ) ?? Date()

        // Filter articles to delete: older than cutoff, not starred, not archived
        let articlesToDelete = articles.filter { article in
            article.publishedDate < cutoffDate &&
            !article.isStarred &&
            !article.isArchived
        }

        let deleteCount = articlesToDelete.count

        // Delete articles
        for article in articlesToDelete {
            modelContext.delete(article)
        }

        // Save context
        do {
            try modelContext.save()
            cleanupMessage = "Succès : \(deleteCount) anciens articles supprimés."
            showingCleanupAlert = true
        } catch {
            cleanupMessage = "Erreur lors du nettoyage : \(error.localizedDescription)"
            showingCleanupAlert = true
        }
    }

    // MARK: - Helper Views

    private func themeButton(_ theme: AppTheme) -> some View {
        Button {
            if theme.isPremium && !storeService.isPro {
                showingUpgrade = true
            } else {
                configService.config.selectedTheme = theme
                applyAppearance()
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: theme.icon)
                    .font(.title2)
                    .frame(height: 28)

                Text(theme.displayName)
                    .font(.caption)

                if theme.isPremium && !storeService.isPro {
                    Text("Pro")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configService.config.selectedTheme == theme ? Color.accentColor.opacity(0.15) : Color.platformSecondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(configService.config.selectedTheme == theme ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func proFeatureItem(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.9))
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    // MARK: - About Settings View

    private var aboutSettings: some View {
        VStack(spacing: 20) {
            Image("LireFlowLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 8) {
                Text("LireFlow")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                #if os(macOS)
                Text("Lecteur RSS moderne pour macOS")
                    .foregroundStyle(.primary.opacity(0.7))
                #else
                Text("Lecteur RSS moderne pour iOS")
                    .foregroundStyle(.primary.opacity(0.7))
                #endif

                Text("Version 1.3.0")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.5))
                    .padding(.top, 8)
            }

            Divider()
                .padding(.horizontal, 80)

            VStack(alignment: .leading, spacing: 12) {
                Label("Native SwiftUI & SwiftData", systemImage: "swift")
                Label("Support Mode Sombre & Clair", systemImage: "moon.stars")
                Label("Intégration d'un Widget Météo", systemImage: "cloud.sun")
                Label("Listes de lecture & Favoris", systemImage: "star")
            }
            .font(.callout)
            .foregroundStyle(.primary.opacity(0.8))

            Spacer()
                .frame(height: 20)

            // Links Section
            VStack(spacing: 10) {
                Button {
                    if let url = URL(string: "https://github.com/m0etez/LireFlow") {
                        PlatformApplication.openURL(url)
                    }
                } label: {
                    Label("Voir sur GitHub", systemImage: "globe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    if let url = URL(string: "https://twitter.com/mo_saadani") {
                        PlatformApplication.openURL(url)
                    }
                } label: {
                    Label("Suivre sur Twitter", systemImage: "at")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: 300)

            Spacer()
                .frame(height: 10)

            // Built with Claude
            HStack(spacing: 4) {
                Text("Construit avec")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.5))
                Link("Claude", destination: URL(string: "https://claude.ai")!)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    SettingsSheet()
}

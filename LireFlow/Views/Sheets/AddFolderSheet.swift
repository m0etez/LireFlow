import SwiftUI
import SwiftData

struct AddFolderSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var folderName = ""
    @State private var selectedIcon = "folder"
    
    private let icons = [
        "folder", "folder.fill", "tray", "archivebox",
        "star", "heart", "bookmark", "tag",
        "globe", "newspaper", "book", "lightbulb",
        "cpu", "desktopcomputer", "gamecontroller", "camera",
        "music.note", "film", "paintbrush", "hammer"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Folder")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Content
            VStack(spacing: 24) {
                // Folder name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Folder Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("My Folder", text: $folderName)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Icon picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(selectedIcon == icon ? .primary : .secondary)
                        }
                    }
                }
                
                // Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: selectedIcon)
                            .foregroundStyle(.secondary)
                        
                        Text(folderName.isEmpty ? "My Folder" : folderName)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Create Folder") {
                    createFolder()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(folderName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 380, height: 550)
    }
    
    private func createFolder() {
        let folder = Folder(
            name: folderName.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon
        )
        
        modelContext.insert(folder)
        try? modelContext.save()
        
        dismiss()
    }
}

#Preview {
    AddFolderSheet()
        .modelContainer(for: [Feed.self, Article.self, Folder.self], inMemory: true)
}

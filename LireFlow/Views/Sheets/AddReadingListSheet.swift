import SwiftUI
import SwiftData

struct AddReadingListSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "bookmark"
    
    private let icons = [
        "bookmark", "bookmark.fill",
        "star", "star.fill",
        "heart", "heart.fill",
        "flag", "flag.fill",
        "tag", "tag.fill",
        "book", "book.fill",
        "list.bullet", "checklist",
        "clock", "clock.fill",
        "folder", "folder.fill",
        "tray", "tray.full"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Reading List")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                
                TextField("Enter reading list name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                selectedIcon = icon
                            }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create") {
                    createReadingList()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400, height: 380)
    }
    
    private func createReadingList() {
        let readingList = ReadingList(name: name, icon: selectedIcon)
        modelContext.insert(readingList)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddReadingListSheet()
        .modelContainer(for: ReadingList.self, inMemory: true)
}

import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var order: Int
    var icon: String
    
    var feeds: [Feed]
    
    init(
        id: UUID = UUID(),
        name: String,
        order: Int = 0,
        icon: String = "folder"
    ) {
        self.id = id
        self.name = name
        self.order = order
        self.icon = icon
        self.feeds = []
    }
    
    var unreadCount: Int {
        feeds.reduce(0) { $0 + $1.unreadCount }
    }
}

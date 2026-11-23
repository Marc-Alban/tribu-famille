import Foundation

struct EventTaskItem: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var category: String // "Apéritif", "Entrée", "Plat", "Fromage", "Dessert", "Boisson"
    var assignedToName: String?
    var isCompleted: Bool = false
}

struct FamilyEvent: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var date: Date
    var location: String
    var description: String
    var category: String = "Repas" // "Repas", "Fête", "Vacances", "Garde", "Sortie"
    var attendeesCount: Int = 12
    var items: [EventTaskItem] = []
}

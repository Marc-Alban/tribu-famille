import Foundation

struct ShoppingItem: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var category: String // "Frais", "Fruits & Légumes", "Épicerie", "Bébé", "Maison"
    var quantity: String?
    var addedByName: String
    var isBought: Bool = false
}

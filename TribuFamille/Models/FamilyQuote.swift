import Foundation

struct FamilyQuote: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var quoteText: String
    var authorName: String
    var context: String
    var dateString: String
    var likesCount: Int = 1
}

struct EmergencyContact: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var detail: String
    var isPhone: Bool = true
}

struct PhotoPost: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var authorName: String
    var caption: String
    var dateString: String
    var likesCount: Int = 1
}

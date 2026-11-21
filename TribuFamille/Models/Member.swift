import Foundation

struct WishlistItem: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var priceEstimate: String?
    var isReservedBy: String? // Nom de la personne qui réserve en secret
}

struct Member: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var role: String // "Grand-mère", "Père", "Mère", "Fils", etc.
    var birthDate: Date // Date de naissance
    var phone: String?
    var allergies: String?
    var isChild: Bool = false
    var wishlist: [WishlistItem] = []

    // Calcul de l'âge qu'aura la personne au prochain anniversaire
    var nextAge: Int {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: birthDate)
        let nextBirthdayDate = nextBirthday
        let nextYear = calendar.component(.year, from: nextBirthdayDate)
        return nextYear - birthYear
    }

    // Date exacte du prochain anniversaire
    var nextBirthday: Date {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let birthMonth = calendar.component(.month, from: birthDate)
        let birthDay = calendar.component(.day, from: birthDate)

        var components = DateComponents()
        components.year = currentYear
        components.month = birthMonth
        components.day = birthDay
        components.hour = 9
        components.minute = 0

        guard let birthdayThisYear = calendar.date(from: components) else {
            return now
        }

        if birthdayThisYear < now {
            components.year = currentYear + 1
            return calendar.date(from: components) ?? now
        }
        return birthdayThisYear
    }

    // Nombre de jours restants jusqu'au prochain anniversaire
    var daysUntilBirthday: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfBirthday = calendar.startOfDay(for: nextBirthday)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfBirthday)
        return max(0, components.day ?? 0)
    }
}

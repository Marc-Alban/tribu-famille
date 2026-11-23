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
    var shoeSize: String? = nil
    var clothingSize: String? = nil
    var favouriteTreat: String? = nil
    var appleUserId: String? = nil
    var appleEmail: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, name, role, birthDate, phone, allergies, isChild, wishlist, shoeSize, clothingSize, favouriteTreat, appleUserId, appleEmail
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        role: String,
        birthDate: Date,
        phone: String? = nil,
        allergies: String? = nil,
        isChild: Bool = false,
        wishlist: [WishlistItem] = [],
        shoeSize: String? = nil,
        clothingSize: String? = nil,
        favouriteTreat: String? = nil,
        appleUserId: String? = nil,
        appleEmail: String? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.birthDate = birthDate
        self.phone = phone
        self.allergies = allergies
        self.isChild = isChild
        self.wishlist = wishlist
        self.shoeSize = shoeSize
        self.clothingSize = clothingSize
        self.favouriteTreat = favouriteTreat
        self.appleUserId = appleUserId
        self.appleEmail = appleEmail
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.name = try container.decode(String.self, forKey: .name)
        self.role = try container.decode(String.self, forKey: .role)
        self.birthDate = try container.decode(Date.self, forKey: .birthDate)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
        self.allergies = try container.decodeIfPresent(String.self, forKey: .allergies)
        self.isChild = try container.decodeIfPresent(Bool.self, forKey: .isChild) ?? false
        self.wishlist = try container.decodeIfPresent([WishlistItem].self, forKey: .wishlist) ?? []
        self.shoeSize = try container.decodeIfPresent(String.self, forKey: .shoeSize)
        self.clothingSize = try container.decodeIfPresent(String.self, forKey: .clothingSize)
        self.favouriteTreat = try container.decodeIfPresent(String.self, forKey: .favouriteTreat)
        self.appleUserId = try container.decodeIfPresent(String.self, forKey: .appleUserId)
        self.appleEmail = try container.decodeIfPresent(String.self, forKey: .appleEmail)
    }

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

        if calendar.startOfDay(for: birthdayThisYear) < calendar.startOfDay(for: now) {
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

import Foundation
import Combine

@MainActor
class StorageManager: ObservableObject {
    static let shared = StorageManager()

    @Published var members: [Member] = []
    @Published var events: [FamilyEvent] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var quotes: [FamilyQuote] = []
    @Published var contacts: [EmergencyContact] = []
    @Published var posts: [PhotoPost] = []

    private let membersFile = "tribu_members.json"
    private let eventsFile = "tribu_events.json"
    private let shoppingFile = "tribu_shopping.json"
    private let quotesFile = "tribu_quotes.json"
    private let contactsFile = "tribu_contacts.json"
    private let postsFile = "tribu_posts.json"

    init() {
        loadAllData()
    }

    private func getDocumentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func loadAllData() {
        loadMembers()
        loadEvents()
        loadShopping()
        loadQuotes()
        loadContacts()
        loadPosts()
    }

    // MARK: - Members
    private func loadMembers() {
        let url = getDocumentsURL().appendingPathComponent(membersFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Member].self, from: data) {
            self.members = decoded
        } else {
            // Initial Seed Data
            let calendar = Calendar.current
            var dateMemere = DateComponents(); dateMemere.year = 1942; dateMemere.month = 12; dateMemere.day = 5
            var datePapa = DateComponents(); datePapa.year = 1968; datePapa.month = 4; datePapa.day = 18
            var dateMaman = DateComponents(); dateMaman.year = 1970; dateMaman.month = 9; dateMaman.day = 22
            var dateLucas = DateComponents(); dateLucas.year = 2016; dateLucas.month = 12; dateLucas.day = 14

            self.members = [
                Member(
                    name: "Mémère Denise",
                    role: "Grand-mère",
                    birthDate: calendar.date(from: dateMemere) ?? Date(),
                    phone: "0612345678",
                    allergies: nil,
                    isChild: false,
                    wishlist: [
                        WishlistItem(title: "Charentaises chaudes (taille 38)", priceEstimate: "35€"),
                        WishlistItem(title: "Boîte de chocolats fins pralinés", priceEstimate: "20€", isReservedBy: "Marc-Alban")
                    ]
                ),
                Member(
                    name: "Papa",
                    role: "Père",
                    birthDate: calendar.date(from: datePapa) ?? Date(),
                    phone: "0698765432",
                    isChild: false,
                    wishlist: [
                        WishlistItem(title: "Livre d'histoire économique et bourse", priceEstimate: "24€"),
                        WishlistItem(title: "Set de couteaux japonais", priceEstimate: "75€")
                    ]
                ),
                Member(
                    name: "Maman",
                    role: "Mère",
                    birthDate: calendar.date(from: dateMaman) ?? Date(),
                    phone: "0611223344",
                    isChild: false,
                    wishlist: [
                        WishlistItem(title: "Écharpe cachemire beige", priceEstimate: "50€", isReservedBy: "Papa")
                    ]
                ),
                Member(
                    name: "Lucas",
                    role: "Fils / Petit-fils",
                    birthDate: calendar.date(from: dateLucas) ?? Date(),
                    allergies: "Arachides (attention)",
                    isChild: true,
                    wishlist: [
                        WishlistItem(title: "Lego Vaisseau spatial", priceEstimate: "45€"),
                        WishlistItem(title: "Jeu Switch Pokémon", priceEstimate: "49€", isReservedBy: "Mémère Denise")
                    ]
                )
            ]
            saveMembers()
        }
    }

    func saveMembers() {
        let url = getDocumentsURL().appendingPathComponent(membersFile)
        if let encoded = try? JSONEncoder().encode(members) {
            try? encoded.write(to: url)
        }
        NotificationManager.shared.scheduleBirthdayNotifications(for: members)
    }

    func addMember(_ member: Member) {
        members.append(member)
        saveMembers()
    }

    // MARK: - Events
    private func loadEvents() {
        let url = getDocumentsURL().appendingPathComponent(eventsFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([FamilyEvent].self, from: data) {
            self.events = decoded
        } else {
            let calendar = Calendar.current
            var noelComp = DateComponents(); noelComp.year = 2026; noelComp.month = 12; noelComp.day = 24; noelComp.hour = 19; noelComp.minute = 30
            let noelDate = calendar.date(from: noelComp) ?? Date()

            self.events = [
                FamilyEvent(
                    title: "Grand Réveillon de Noël 2026 🎄",
                    date: noelDate,
                    location: "Chez Mémère Denise",
                    description: "Chacun ramène sa spécialité ! Touchez pour réserver un plat.",
                    items: [
                        EventTaskItem(title: "Apéritif & Toasts au saumon fumé", category: "Apéritif", assignedToName: "Marc-Alban", isCompleted: true),
                        EventTaskItem(title: "Foie Gras maison & Pain d'épices", category: "Entrée", assignedToName: "Papa", isCompleted: true),
                        EventTaskItem(title: "Chapon rôti & Marrons chauds", category: "Plat", assignedToName: "Mémère Denise", isCompleted: true),
                        EventTaskItem(title: "Plateau de 5 fromages de nos régions", category: "Fromage", assignedToName: nil, isCompleted: false),
                        EventTaskItem(title: "Bûche Pâtissière Chocolat-Praliné", category: "Dessert", assignedToName: "Maman", isCompleted: true),
                        EventTaskItem(title: "Champagne brut & Bulles de fête", category: "Boisson", assignedToName: nil, isCompleted: false)
                    ]
                )
            ]
            saveEvents()
        }
    }

    func saveEvents() {
        let url = getDocumentsURL().appendingPathComponent(eventsFile)
        if let encoded = try? JSONEncoder().encode(events) {
            try? encoded.write(to: url)
        }
    }

    // MARK: - Shopping
    private func loadShopping() {
        let url = getDocumentsURL().appendingPathComponent(shoppingFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            self.shoppingItems = decoded
        } else {
            self.shoppingItems = [
                ShoppingItem(name: "Pain de campagne (2 miches)", category: "Épicerie", quantity: "2", addedByName: "Mémère", isBought: false),
                ShoppingItem(name: "Lait entier bio & Beurre doux", category: "Frais", quantity: "6L", addedByName: "Maman", isBought: true),
                ShoppingItem(name: "Clémentines de Corse", category: "Fruits & Légumes", quantity: "2 kg", addedByName: "Marc-Alban", isBought: false),
                ShoppingItem(name: "Couches bébé taille 4", category: "Bébé", quantity: "1 paquet", addedByName: "Maman", isBought: false),
                ShoppingItem(name: "Café en grains", category: "Épicerie", quantity: nil, addedByName: "Papa", isBought: true)
            ]
            saveShopping()
        }
    }

    func saveShopping() {
        let url = getDocumentsURL().appendingPathComponent(shoppingFile)
        if let encoded = try? JSONEncoder().encode(shoppingItems) {
            try? encoded.write(to: url)
        }
    }

    // MARK: - Quotes
    private func loadQuotes() {
        let url = getDocumentsURL().appendingPathComponent(quotesFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([FamilyQuote].self, from: data) {
            self.quotes = decoded
        } else {
            self.quotes = [
                FamilyQuote(
                    quoteText: "Mémère, est-ce que le Père Noël il a des lunettes pour voir s'il y a du verglas sur le toit ?",
                    authorName: "Lucas (5 ans)",
                    context: "En regardant la météo devant la cheminée",
                    dateString: "Noël 2021",
                    likesCount: 9
                ),
                FamilyQuote(
                    quoteText: "La bourse c'est comme le rôti : si tu sors trop tôt c'est pas cuit, si tu sors trop tard c'est cramé !",
                    authorName: "Papa",
                    context: "Au déjeuner du dimanche",
                    dateString: "Octobre 2026",
                    likesCount: 7
                )
            ]
            saveQuotes()
        }
    }

    func saveQuotes() {
        let url = getDocumentsURL().appendingPathComponent(quotesFile)
        if let encoded = try? JSONEncoder().encode(quotes) {
            try? encoded.write(to: url)
        }
    }

    // MARK: - Contacts
    private func loadContacts() {
        let url = getDocumentsURL().appendingPathComponent(contactsFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            self.contacts = decoded
        } else {
            self.contacts = [
                EmergencyContact(title: "Médecin traitant (Dr. Martin)", detail: "02 35 12 34 56", isPhone: true),
                EmergencyContact(title: "Pédiatre de Lucas (Dr. Leroy)", detail: "02 35 78 90 12", isPhone: true),
                EmergencyContact(title: "Code Wi-Fi Maison Mémère", detail: "FamilleMillet2026!", isPhone: false),
                EmergencyContact(title: "SAMU / Urgence Médicale", detail: "15", isPhone: true),
                EmergencyContact(title: "Pharmacie de garde", detail: "3237", isPhone: true)
            ]
            saveContacts()
        }
    }

    func saveContacts() {
        let url = getDocumentsURL().appendingPathComponent(contactsFile)
        if let encoded = try? JSONEncoder().encode(contacts) {
            try? encoded.write(to: url)
        }
    }

    // MARK: - Posts
    private func loadPosts() {
        let url = getDocumentsURL().appendingPathComponent(postsFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([PhotoPost].self, from: data) {
            self.posts = decoded
        } else {
            self.posts = [
                PhotoPost(
                    authorName: "Marc-Alban",
                    caption: "Magnifique dimanche en famille au jardin, Mémère était aux anges ❤️",
                    dateString: "Il y a 2 jours",
                    likesCount: 6
                )
            ]
            savePosts()
        }
    }

    func savePosts() {
        let url = getDocumentsURL().appendingPathComponent(postsFile)
        if let encoded = try? JSONEncoder().encode(posts) {
            try? encoded.write(to: url)
        }
    }
}

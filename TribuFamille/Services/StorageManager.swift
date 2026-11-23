import Foundation
import Combine
import SwiftUI

@MainActor
class StorageManager: ObservableObject {
    static let shared = StorageManager()

    // MARK: - Published State
    @Published var members: [Member] = []
    @Published var events: [FamilyEvent] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var quotes: [FamilyQuote] = []
    @Published var contacts: [EmergencyContact] = []
    @Published var posts: [PhotoPost] = []
    
    // Auth & Tribu State
    @Published var currentMember: Member?
    @Published var tribeCode: String = ""
    @Published var tribeName: String = ""
    @Published var tribePassword: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var isSyncing: Bool = false
    @Published var syncError: String? = nil

    private let membersFile = "tribu_members.json"
    private let eventsFile = "tribu_events.json"
    private let shoppingFile = "tribu_shopping.json"
    private let quotesFile = "tribu_quotes.json"
    private let contactsFile = "tribu_contacts.json"
    private let postsFile = "tribu_posts.json"
    
    private let loggedInKey = "tribu_is_logged_in"
    private let currentMemberKey = "tribu_current_member_data"
    private let tribeCodeKey = "tribu_family_code"
    private let tribeNameKey = "tribu_family_name"
    private let tribePasswordKey = "tribu_family_password"

    init() {
        restoreSession()
        loadAllLocalData()
        
        if isLoggedIn && !tribeCode.isEmpty {
            Task {
                await pullFromCloud()
            }
        }
    }

    // MARK: - Session & Identity
    private func restoreSession() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: loggedInKey)
        self.tribeCode = UserDefaults.standard.string(forKey: tribeCodeKey) ?? ""
        self.tribeName = UserDefaults.standard.string(forKey: tribeNameKey) ?? ""
        self.tribePassword = UserDefaults.standard.string(forKey: tribePasswordKey) ?? ""

        if let data = UserDefaults.standard.data(forKey: currentMemberKey),
           let decoded = try? JSONDecoder().decode(Member.self, from: data) {
            self.currentMember = decoded
        }
    }

    func saveSession() {
        UserDefaults.standard.set(isLoggedIn, forKey: loggedInKey)
        UserDefaults.standard.set(tribeCode, forKey: tribeCodeKey)
        UserDefaults.standard.set(tribeName, forKey: tribeNameKey)
        UserDefaults.standard.set(tribePassword, forKey: tribePasswordKey)

        if let member = currentMember, let encoded = try? JSONEncoder().encode(member) {
            UserDefaults.standard.set(encoded, forKey: currentMemberKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentMemberKey)
        }
    }

    func logout() {
        self.currentMember = nil
        self.isLoggedIn = false
        self.tribeCode = ""
        self.tribeName = ""
        self.tribePassword = ""
        self.members = []
        self.events = []
        self.shoppingItems = []
        self.quotes = []
        self.contacts = []
        
        UserDefaults.standard.removeObject(forKey: loggedInKey)
        UserDefaults.standard.removeObject(forKey: currentMemberKey)
        UserDefaults.standard.removeObject(forKey: tribeCodeKey)
        UserDefaults.standard.removeObject(forKey: tribeNameKey)
        UserDefaults.standard.removeObject(forKey: tribePasswordKey)
        
        // Supprimer aussi les fichiers locaux de cache
        deleteLocalData()
    }

    // MARK: - Onboarding : Créer une Tribu
    func createFamily(
        name: String,
        code: String,
        password: String,
        creatorName: String,
        creatorRole: String,
        birthDate: Date = Date(),
        shoeSize: String? = nil,
        clothingSize: String? = nil,
        favouriteTreat: String? = nil,
        phone: String? = nil
    ) async throws {
        let newMember = Member(
            name: creatorName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: creatorRole,
            birthDate: birthDate,
            phone: phone,
            isChild: creatorRole.contains("Enfant") || creatorRole.contains("Fils") || creatorRole.contains("Fille"),
            shoeSize: shoeSize,
            clothingSize: clothingSize,
            favouriteTreat: favouriteTreat
        )

        let payload = try await CloudSyncService.shared.createFamily(
            name: name,
            code: code,
            password: password,
            creator: newMember
        )

        // Appliquer l'état local
        self.currentMember = newMember
        self.tribeCode = payload.code
        self.tribeName = payload.name
        self.tribePassword = payload.password
        self.isLoggedIn = true
        self.members = payload.members
        self.events = payload.events
        self.shoppingItems = payload.shoppingItems
        self.quotes = payload.quotes
        self.contacts = payload.contacts

        saveSession()
        saveAllLocalData()
    }

    // MARK: - Onboarding : Rejoindre une Tribu
    func joinFamily(
        code: String,
        password: String,
        userName: String,
        userRole: String,
        birthDate: Date = Date(),
        shoeSize: String? = nil,
        clothingSize: String? = nil,
        favouriteTreat: String? = nil,
        phone: String? = nil
    ) async throws {
        let member = Member(
            name: userName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: userRole,
            birthDate: birthDate,
            phone: phone,
            isChild: userRole.contains("Enfant") || userRole.contains("Fils") || userRole.contains("Fille"),
            shoeSize: shoeSize,
            clothingSize: clothingSize,
            favouriteTreat: favouriteTreat
        )

        let payload = try await CloudSyncService.shared.joinFamily(
            code: code,
            password: password,
            member: member
        )

        self.currentMember = member
        self.tribeCode = payload.code
        self.tribeName = payload.name
        self.tribePassword = payload.password
        self.isLoggedIn = true
        self.members = payload.members
        self.events = payload.events
        self.shoppingItems = payload.shoppingItems
        self.quotes = payload.quotes
        self.contacts = payload.contacts

        saveSession()
        saveAllLocalData()
    }

    // MARK: - Mise à jour du Profil Personnel
    func updateCurrentMember(
        name: String,
        role: String,
        phone: String?,
        shoeSize: String?,
        clothingSize: String?,
        favouriteTreat: String?
    ) {
        guard var current = currentMember else { return }
        current.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        current.role = role
        current.phone = phone
        current.shoeSize = shoeSize
        current.clothingSize = clothingSize
        current.favouriteTreat = favouriteTreat

        self.currentMember = current
        if let idx = members.firstIndex(where: { $0.id == current.id }) {
            members[idx] = current
        } else {
            members.append(current)
        }

        saveSession()
        saveMembers()
        syncWithCloud()
    }

    // MARK: - Synchronisation Cloud Bidirectionnelle
    func pullFromCloud() async {
        guard !tribeCode.isEmpty else { return }
        self.isSyncing = true
        do {
            if let payload = try await CloudSyncService.shared.fetchFamily(code: tribeCode) {
                self.tribeName = payload.name
                self.members = payload.members
                self.events = payload.events
                self.shoppingItems = payload.shoppingItems
                self.quotes = payload.quotes
                self.contacts = payload.contacts
                saveAllLocalData()
            }
            self.isSyncing = false
            self.syncError = nil
        } catch {
            self.isSyncing = false
            self.syncError = error.localizedDescription
            print("Erreur de synchronisation pull: \(error)")
        }
    }

    func syncWithCloud() {
        guard !tribeCode.isEmpty else { return }
        let payload = FamilyPayload(
            code: tribeCode,
            name: tribeName,
            password: tribePassword,
            members: members,
            events: events,
            shoppingItems: shoppingItems,
            quotes: quotes,
            contacts: contacts,
            updatedAt: Date()
        )

        Task {
            do {
                try await CloudSyncService.shared.saveFamily(payload: payload)
            } catch {
                print("Erreur de synchronisation push: \(error)")
            }
        }
    }

    // MARK: - Local File Storage (Documents)
    private func getDocumentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func loadAllLocalData() {
        loadMembers()
        loadEvents()
        loadShopping()
        loadQuotes()
        loadContacts()
    }

    func saveAllLocalData() {
        saveMembers()
        saveEvents()
        saveShopping()
        saveQuotes()
        saveContacts()
    }

    private func deleteLocalData() {
        let fm = FileManager.default
        let dir = getDocumentsURL()
        [membersFile, eventsFile, shoppingFile, quotesFile, contactsFile, postsFile].forEach { file in
            let path = dir.appendingPathComponent(file)
            try? fm.removeItem(at: path)
        }
    }

    // MARK: - Members
    private func loadMembers() {
        let url = getDocumentsURL().appendingPathComponent(membersFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Member].self, from: data) {
            self.members = decoded
        } else {
            self.members = []
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
        syncWithCloud()
    }

    // MARK: - Events
    private func loadEvents() {
        let url = getDocumentsURL().appendingPathComponent(eventsFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([FamilyEvent].self, from: data) {
            self.events = decoded
        } else {
            self.events = []
        }
    }

    func saveEvents() {
        let url = getDocumentsURL().appendingPathComponent(eventsFile)
        if let encoded = try? JSONEncoder().encode(events) {
            try? encoded.write(to: url)
        }
    }

    func addEvent(_ event: FamilyEvent) {
        events.append(event)
        saveEvents()
        syncWithCloud()
    }

    func updateEvent(_ event: FamilyEvent) {
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
            saveEvents()
            syncWithCloud()
        }
    }

    // MARK: - Shopping
    private func loadShopping() {
        let url = getDocumentsURL().appendingPathComponent(shoppingFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            self.shoppingItems = decoded
        } else {
            self.shoppingItems = []
        }
    }

    func saveShopping() {
        let url = getDocumentsURL().appendingPathComponent(shoppingFile)
        if let encoded = try? JSONEncoder().encode(shoppingItems) {
            try? encoded.write(to: url)
        }
    }

    func addShoppingItem(_ item: ShoppingItem) {
        shoppingItems.append(item)
        saveShopping()
        syncWithCloud()
    }

    func toggleShoppingItem(_ item: ShoppingItem) {
        if let idx = shoppingItems.firstIndex(where: { $0.id == item.id }) {
            shoppingItems[idx].isBought.toggle()
            saveShopping()
            syncWithCloud()
        }
    }

    func deleteShoppingItem(_ item: ShoppingItem) {
        shoppingItems.removeAll(where: { $0.id == item.id })
        saveShopping()
        syncWithCloud()
    }

    // MARK: - Wishlist
    func addWish(to memberId: String, wish: WishlistItem) {
        if let idx = members.firstIndex(where: { $0.id == memberId }) {
            members[idx].wishlist.append(wish)
            saveMembers()
            syncWithCloud()
        }
    }

    func toggleReserveWish(for memberId: String, wishId: String, by reservedByName: String) {
        if let mIdx = members.firstIndex(where: { $0.id == memberId }),
           let wIdx = members[mIdx].wishlist.firstIndex(where: { $0.id == wishId }) {
            if members[mIdx].wishlist[wIdx].isReservedBy == nil {
                members[mIdx].wishlist[wIdx].isReservedBy = reservedByName
            } else if members[mIdx].wishlist[wIdx].isReservedBy == reservedByName {
                members[mIdx].wishlist[wIdx].isReservedBy = nil
            }
            saveMembers()
            syncWithCloud()
        }
    }

    // MARK: - Quotes
    private func loadQuotes() {
        let url = getDocumentsURL().appendingPathComponent(quotesFile)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([FamilyQuote].self, from: data) {
            self.quotes = decoded
        } else {
            self.quotes = []
        }
    }

    func saveQuotes() {
        let url = getDocumentsURL().appendingPathComponent(quotesFile)
        if let encoded = try? JSONEncoder().encode(quotes) {
            try? encoded.write(to: url)
        }
    }

    func addQuote(_ quote: FamilyQuote) {
        quotes.insert(quote, at: 0)
        saveQuotes()
        syncWithCloud()
    }

    func likeQuote(_ quote: FamilyQuote) {
        if let idx = quotes.firstIndex(where: { $0.id == quote.id }) {
            quotes[idx].likesCount += 1
            saveQuotes()
            syncWithCloud()
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
                EmergencyContact(title: "SAMU / Urgence Médicale", detail: "15", isPhone: true),
                EmergencyContact(title: "Pharmacie de garde", detail: "3237", isPhone: true)
            ]
        }
    }

    func saveContacts() {
        let url = getDocumentsURL().appendingPathComponent(contactsFile)
        if let encoded = try? JSONEncoder().encode(contacts) {
            try? encoded.write(to: url)
        }
    }

    func addContact(_ contact: EmergencyContact) {
        contacts.append(contact)
        saveContacts()
        syncWithCloud()
    }
}

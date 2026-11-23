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

    static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

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

        if let data = UserDefaults.standard.data(forKey: currentMemberKey) {
            if let decoded = try? Self.jsonDecoder.decode(Member.self, from: data) {
                self.currentMember = decoded
            } else if let fallback = try? JSONDecoder().decode(Member.self, from: data) {
                self.currentMember = fallback
            }
        }

        // Si le décodage a échoué mais qu'on a le prénom sauvegardé
        if self.currentMember == nil && self.isLoggedIn {
            if let savedName = UserDefaults.standard.string(forKey: "tribu_current_member_name"), !savedName.isEmpty {
                let savedId = UserDefaults.standard.string(forKey: "tribu_current_member_id") ?? UUID().uuidString
                let savedRole = UserDefaults.standard.string(forKey: "tribu_current_member_role") ?? "Membre"
                self.currentMember = Member(id: savedId, name: savedName, role: savedRole, birthDate: Date())
            }
        }
    }

    func saveSession() {
        UserDefaults.standard.set(isLoggedIn, forKey: loggedInKey)
        UserDefaults.standard.set(tribeCode, forKey: tribeCodeKey)
        UserDefaults.standard.set(tribeName, forKey: tribeNameKey)
        UserDefaults.standard.set(tribePassword, forKey: tribePasswordKey)

        if let member = currentMember {
            UserDefaults.standard.set(member.id, forKey: "tribu_current_member_id")
            UserDefaults.standard.set(member.name, forKey: "tribu_current_member_name")
            UserDefaults.standard.set(member.role, forKey: "tribu_current_member_role")
            if let encoded = try? Self.jsonEncoder.encode(member) {
                UserDefaults.standard.set(encoded, forKey: currentMemberKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: currentMemberKey)
            UserDefaults.standard.removeObject(forKey: "tribu_current_member_id")
            UserDefaults.standard.removeObject(forKey: "tribu_current_member_name")
            UserDefaults.standard.removeObject(forKey: "tribu_current_member_role")
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

    // MARK: - Connexion Directe avec Apple ID
    func loginWithAppleID(
        appleUserId: String,
        fullName: PersonNameComponents?,
        email: String?,
        familyCode: String = "MILLET-2026",
        familyPassword: String = "2121.bmw"
    ) async throws {
        let targetCode = familyCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "MILLET-2026" : familyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let targetPassword = familyPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "2121.bmw" : familyPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        var resolvedName = ""
        if let given = fullName?.givenName, !given.isEmpty {
            resolvedName = given
            if let fam = fullName?.familyName, !fam.isEmpty {
                resolvedName += " \(fam)"
            }
        }

        if resolvedName.isEmpty {
            resolvedName = UserDefaults.standard.string(forKey: "tribu_apple_name_\(appleUserId)") ?? ""
        }
        if resolvedName.isEmpty {
            resolvedName = UserDefaults.standard.string(forKey: "tribu_current_member_name") ?? ""
        }
        if resolvedName.isEmpty {
            let dev = UIDevice.current.name
            if dev.contains("de ") {
                resolvedName = dev.components(separatedBy: "de ").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Marc"
            } else {
                resolvedName = "Marc"
            }
        }

        UserDefaults.standard.set(resolvedName, forKey: "tribu_apple_name_\(appleUserId)")
        UserDefaults.standard.set(appleUserId, forKey: "tribu_apple_user_id")
        if let email = email {
            UserDefaults.standard.set(email, forKey: "tribu_apple_email")
        }

        var payload = try? await CloudSyncService.shared.fetchFamily(code: targetCode)
        if payload == nil {
            let creator = Member(
                name: resolvedName,
                role: "Père",
                birthDate: Calendar.current.date(byAdding: .year, value: -28, to: Date()) ?? Date(),
                appleUserId: appleUserId,
                appleEmail: email
            )
            payload = try await CloudSyncService.shared.createFamily(
                name: "Famille \(resolvedName)",
                code: targetCode,
                password: targetPassword,
                creator: creator
            )
        }

        guard var currentPayload = payload else {
            throw FamilyError.notFound
        }

        if !currentPayload.password.isEmpty && currentPayload.password != targetPassword {
            throw FamilyError.invalidPassword
        }

        var me: Member
        if let existing = currentPayload.members.first(where: {
            ($0.appleUserId != nil && $0.appleUserId == appleUserId) ||
            $0.name.lowercased() == resolvedName.lowercased()
        }) {
            me = existing
            if me.appleUserId == nil {
                me.appleUserId = appleUserId
                if let idx = currentPayload.members.firstIndex(where: { $0.id == me.id }) {
                    currentPayload.members[idx] = me
                }
            }
        } else {
            me = Member(
                name: resolvedName,
                role: "Membre",
                birthDate: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
                appleUserId: appleUserId,
                appleEmail: email
            )
            currentPayload.members.append(me)
            try await CloudSyncService.shared.saveFamily(payload: currentPayload)
        }

        self.currentMember = me
        self.tribeCode = currentPayload.code
        self.tribeName = currentPayload.name
        self.tribePassword = currentPayload.password
        self.members = currentPayload.members
        self.events = currentPayload.events
        self.shoppingItems = currentPayload.shoppingItems
        self.quotes = currentPayload.quotes
        self.contacts = currentPayload.contacts
        self.isLoggedIn = true

        saveSession()
        saveAllLocalDataInternal()
        NotificationManager.shared.scheduleBirthdayNotifications(for: self.members)
    }

    // MARK: - Connexion Express iPhone / Face ID
    func quickLoginWithDevice(
        familyCode: String = "MILLET-2026",
        familyPassword: String = "2121.bmw"
    ) async throws {
        let savedAppleId = UserDefaults.standard.string(forKey: "tribu_apple_user_id") ?? "apple_device_\(UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString)"
        try await loginWithAppleID(
            appleUserId: savedAppleId,
            fullName: nil,
            email: UserDefaults.standard.string(forKey: "tribu_apple_email"),
            familyCode: familyCode,
            familyPassword: familyPassword
        )
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

        if let existing = payload.members.first(where: { $0.id == member.id || $0.name.lowercased() == member.name.lowercased() }) {
            self.currentMember = existing
        } else {
            self.currentMember = member
        }
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
        birthDate: Date? = nil,
        phone: String? = nil,
        shoeSize: String? = nil,
        clothingSize: String? = nil,
        favouriteTreat: String? = nil
    ) {
        guard var current = currentMember else { return }
        current.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        current.role = role
        if let birthDate = birthDate {
            current.birthDate = birthDate
        }
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

                // Mettre à jour l'identité du membre courant depuis le cloud
                if let myId = currentMember?.id, let cloudMember = payload.members.first(where: { $0.id == myId }) {
                    self.currentMember = cloudMember
                } else if let myName = currentMember?.name, let cloudMember = payload.members.first(where: { $0.name.lowercased() == myName.lowercased() }) {
                    self.currentMember = cloudMember
                } else if currentMember == nil, let first = payload.members.first {
                    self.currentMember = first
                }

                saveSession()
                saveAllLocalDataInternal()
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

    private func saveAllLocalDataInternal() {
        let dir = getDocumentsURL()
        if let encoded = try? Self.jsonEncoder.encode(members) {
            try? encoded.write(to: dir.appendingPathComponent(membersFile))
        }
        if let encoded = try? Self.jsonEncoder.encode(events) {
            try? encoded.write(to: dir.appendingPathComponent(eventsFile))
        }
        if let encoded = try? Self.jsonEncoder.encode(shoppingItems) {
            try? encoded.write(to: dir.appendingPathComponent(shoppingFile))
        }
        if let encoded = try? Self.jsonEncoder.encode(quotes) {
            try? encoded.write(to: dir.appendingPathComponent(quotesFile))
        }
        if let encoded = try? Self.jsonEncoder.encode(contacts) {
            try? encoded.write(to: dir.appendingPathComponent(contactsFile))
        }
        NotificationManager.shared.scheduleBirthdayNotifications(for: members)
    }

    func saveAllLocalData() {
        saveAllLocalDataInternal()
        syncWithCloud()
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
        if let data = try? Data(contentsOf: url) {
            if let decoded = try? Self.jsonDecoder.decode([Member].self, from: data) {
                self.members = decoded
            } else if let fallback = try? JSONDecoder().decode([Member].self, from: data) {
                self.members = fallback
            }
        }
    }

    func saveMembers() {
        let url = getDocumentsURL().appendingPathComponent(membersFile)
        if let encoded = try? Self.jsonEncoder.encode(members) {
            try? encoded.write(to: url)
        }
        NotificationManager.shared.scheduleBirthdayNotifications(for: members)
        syncWithCloud()
    }

    func addMember(_ member: Member) {
        members.append(member)
        saveMembers()
    }

    // MARK: - Events
    private func loadEvents() {
        let url = getDocumentsURL().appendingPathComponent(eventsFile)
        if let data = try? Data(contentsOf: url) {
            if let decoded = try? Self.jsonDecoder.decode([FamilyEvent].self, from: data) {
                self.events = decoded
            } else if let fallback = try? JSONDecoder().decode([FamilyEvent].self, from: data) {
                self.events = fallback
            }
        }
    }

    func saveEvents() {
        let url = getDocumentsURL().appendingPathComponent(eventsFile)
        if let encoded = try? Self.jsonEncoder.encode(events) {
            try? encoded.write(to: url)
        }
        syncWithCloud()
    }

    func addEvent(_ event: FamilyEvent) {
        events.append(event)
        saveEvents()
    }

    func updateEvent(_ event: FamilyEvent) {
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
            saveEvents()
        }
    }

    // MARK: - Shopping
    private func loadShopping() {
        let url = getDocumentsURL().appendingPathComponent(shoppingFile)
        if let data = try? Data(contentsOf: url) {
            if let decoded = try? Self.jsonDecoder.decode([ShoppingItem].self, from: data) {
                self.shoppingItems = decoded
            } else if let fallback = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
                self.shoppingItems = fallback
            }
        }
    }

    func saveShopping() {
        let url = getDocumentsURL().appendingPathComponent(shoppingFile)
        if let encoded = try? Self.jsonEncoder.encode(shoppingItems) {
            try? encoded.write(to: url)
        }
        syncWithCloud()
    }

    func addShoppingItem(_ item: ShoppingItem) {
        shoppingItems.append(item)
        saveShopping()
    }

    func toggleShoppingItem(_ item: ShoppingItem) {
        if let idx = shoppingItems.firstIndex(where: { $0.id == item.id }) {
            shoppingItems[idx].isBought.toggle()
            saveShopping()
        }
    }

    func deleteShoppingItem(_ item: ShoppingItem) {
        shoppingItems.removeAll(where: { $0.id == item.id })
        saveShopping()
    }

    // MARK: - Wishlist
    func addWish(to memberId: String, wish: WishlistItem) {
        if let idx = members.firstIndex(where: { $0.id == memberId }) {
            members[idx].wishlist.append(wish)
            saveMembers()
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
        }
    }

    // MARK: - Quotes
    private func loadQuotes() {
        let url = getDocumentsURL().appendingPathComponent(quotesFile)
        if let data = try? Data(contentsOf: url) {
            if let decoded = try? Self.jsonDecoder.decode([FamilyQuote].self, from: data) {
                self.quotes = decoded
            } else if let fallback = try? JSONDecoder().decode([FamilyQuote].self, from: data) {
                self.quotes = fallback
            }
        }
    }

    func saveQuotes() {
        let url = getDocumentsURL().appendingPathComponent(quotesFile)
        if let encoded = try? Self.jsonEncoder.encode(quotes) {
            try? encoded.write(to: url)
        }
        syncWithCloud()
    }

    func addQuote(_ quote: FamilyQuote) {
        quotes.insert(quote, at: 0)
        saveQuotes()
    }

    func likeQuote(_ quote: FamilyQuote) {
        if let idx = quotes.firstIndex(where: { $0.id == quote.id }) {
            quotes[idx].likesCount += 1
            saveQuotes()
        }
    }

    // MARK: - Contacts
    private func loadContacts() {
        let url = getDocumentsURL().appendingPathComponent(contactsFile)
        if let data = try? Data(contentsOf: url) {
            if let decoded = try? Self.jsonDecoder.decode([EmergencyContact].self, from: data) {
                self.contacts = decoded
            } else if let fallback = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
                self.contacts = fallback
            }
        } else {
            self.contacts = [
                EmergencyContact(title: "SAMU / Urgence Médicale", detail: "15", isPhone: true),
                EmergencyContact(title: "Pharmacie de garde", detail: "3237", isPhone: true)
            ]
        }
    }

    func saveContacts() {
        let url = getDocumentsURL().appendingPathComponent(contactsFile)
        if let encoded = try? Self.jsonEncoder.encode(contacts) {
            try? encoded.write(to: url)
        }
        syncWithCloud()
    }

    func addContact(_ contact: EmergencyContact) {
        contacts.append(contact)
        saveContacts()
    }
}

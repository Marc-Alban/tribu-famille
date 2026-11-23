import Foundation

enum FamilyError: LocalizedError {
    case alreadyExists
    case notFound
    case invalidPassword
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .alreadyExists:
            return "Une tribu avec ce code existe déjà. Choisissez un autre code ou rejoignez-la !"
        case .notFound:
            return "Aucune tribu trouvée avec ce code. Vérifiez l'orthographe du code."
        case .invalidPassword:
            return "Le mot de passe secret de la tribu est incorrect."
        case .networkError(let msg):
            return "Erreur de connexion : \(msg)"
        }
    }
}

struct FamilyPayload: Codable {
    var code: String
    var name: String
    var password: String
    var members: [Member]
    var events: [FamilyEvent]
    var shoppingItems: [ShoppingItem]
    var quotes: [FamilyQuote]
    var contacts: [EmergencyContact]
    var updatedAt: Date
}

class CloudSyncService {
    static let shared = CloudSyncService()
    
    private let bucketId = "P833f71v3R6LamYz7qYmSk"
    private let baseURL = "https://kvdb.io"
    
    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    private func familyKey(for code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return "family_\(clean)"
    }
    
    // MARK: - Récupération depuis le Cloud
    func fetchFamily(code: String) async throws -> FamilyPayload? {
        let key = familyKey(for: code)
        guard let url = URL(string: "\(baseURL)/\(bucketId)/\(key)") else {
            throw FamilyError.networkError("URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FamilyError.networkError("Réponse serveur invalide")
        }
        
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw FamilyError.networkError("Code erreur serveur : \(httpResponse.statusCode)")
        }
        
        do {
            let payload = try jsonDecoder.decode(FamilyPayload.self, from: data)
            return payload
        } catch {
            print("Erreur décodage FamilyPayload: \(error)")
            return nil
        }
    }
    
    // MARK: - Sauvegarde sur le Cloud
    func saveFamily(payload: FamilyPayload) async throws {
        let key = familyKey(for: payload.code)
        guard let url = URL(string: "\(baseURL)/\(bucketId)/\(key)") else {
            throw FamilyError.networkError("URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var updated = payload
        updated.updatedAt = Date()
        request.httpBody = try jsonEncoder.encode(updated)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FamilyError.networkError("Échec de synchronisation distante")
        }
    }
    
    // MARK: - Création d'une nouvelle Tribu
    func createFamily(name: String, code: String, password: String, creator: Member) async throws -> FamilyPayload {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 1. Vérifier si le code existe déjà
        if let existing = try? await fetchFamily(code: cleanCode), existing != nil {
            throw FamilyError.alreadyExists
        }
        
        let newFamily = FamilyPayload(
            code: cleanCode,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password.trimmingCharacters(in: .whitespacesAndNewlines),
            members: [creator],
            events: [],
            shoppingItems: [],
            quotes: [],
            contacts: [
                EmergencyContact(title: "SAMU / Urgence Médicale", detail: "15", isPhone: true),
                EmergencyContact(title: "Pharmacie de garde", detail: "3237", isPhone: true)
            ],
            updatedAt: Date()
        )
        
        try await saveFamily(payload: newFamily)
        return newFamily
    }
    
    // MARK: - Rejoindre une Tribu existante avec mot de passe
    func joinFamily(code: String, password: String, member: Member) async throws -> FamilyPayload {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let existing = try await fetchFamily(code: cleanCode) else {
            throw FamilyError.notFound
        }
        
        guard existing.password == cleanPassword else {
            throw FamilyError.invalidPassword
        }
        
        var updated = existing
        // Si le membre n'est pas encore présent dans la liste, on l'ajoute
        if !updated.members.contains(where: { $0.id == member.id || ($0.name.lowercased() == member.name.lowercased() && $0.role == member.role) }) {
            updated.members.append(member)
        }
        
        try await saveFamily(payload: updated)
        return updated
    }
}

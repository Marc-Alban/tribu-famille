import SwiftUI

struct GazetteView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var isMemereMode = false
    @State private var showAddQuoteModal = false
    @State private var newQuoteText = ""
    @State private var newQuoteAuthor = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // TOGGLE MODE MÉMÈRE
                Button(action: {
                    withAnimation { isMemereMode.toggle() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text(isMemereMode ? "Mode Mémère Activé (Gros Textes)" : "Activer Mode Mémère")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isMemereMode ? .white : Color(red: 0.65, green: 0.71, blue: 0.99))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isMemereMode ? Color(red: 0.31, green: 0.27, blue: 0.90) : Color(red: 0.12, green: 0.16, blue: 0.23))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.39, green: 0.40, blue: 0.95), lineWidth: 1)
                    )
                }

                // CITATIONS & MOTS D'ENFANTS
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("💬 Les Perles & Mots d'Enfants")
                            .font(.system(size: isMemereMode ? 20 : 16, weight: .heavy))
                            .foregroundColor(.white)
                        Spacer()
                        Button("+ Noter") {
                            showAddQuoteModal = true
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.65, green: 0.71, blue: 0.99))
                    }

                    ForEach(storage.quotes) { quote in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\"\(quote.quoteText)\"")
                                .font(.system(size: isMemereMode ? 18 : 14, weight: .medium))
                                .italic()
                                .foregroundColor(.white)
                            Text("— \(quote.authorName) • \(quote.context)")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.06, green: 0.09, blue: 0.16))
                        .cornerRadius(10)
                        .overlay(
                            Rectangle()
                                .frame(width: 3)
                                .foregroundColor(.orange),
                            alignment: .leading
                        )
                    }
                }
                .padding(14)
                .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                )

                // TROUSSEAU PRATIQUE & SANTÉ
                VStack(alignment: .leading, spacing: 10) {
                    Text("🏥 Trousseau & Numéros Utiles")
                        .font(.system(size: isMemereMode ? 20 : 16, weight: .heavy))
                        .foregroundColor(.white)

                    ForEach(storage.contacts) { contact in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.title)
                                    .font(.system(size: isMemereMode ? 16 : 13, weight: .bold))
                                    .foregroundColor(.white)
                                Text(contact.detail)
                                    .font(.system(size: isMemereMode ? 15 : 12))
                                    .foregroundColor(Color(red: 0.65, green: 0.71, blue: 0.99))
                            }
                            Spacer()
                            if contact.isPhone {
                                Button(action: {
                                    if let url = URL(string: "tel:\(contact.detail.filter { !" ".contains($0) })") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Color(red: 0.31, green: 0.27, blue: 0.90))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding(14)
                .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                )

                // MUR PHOTO
                VStack(alignment: .leading, spacing: 10) {
                    Text("📸 Journal de Famille")
                        .font(.system(size: isMemereMode ? 20 : 16, weight: .heavy))
                        .foregroundColor(.white)

                    ForEach(storage.posts) { post in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Circle()
                                    .fill(Color.pink)
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Text(String(post.authorName.prefix(1)))
                                            .foregroundColor(.white)
                                            .font(.system(size: 14, weight: .bold))
                                    )
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(post.authorName)
                                        .font(.system(size: isMemereMode ? 18 : 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(post.dateString)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                            }

                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.06, green: 0.09, blue: 0.16))
                                    .frame(height: 140)
                                VStack(spacing: 6) {
                                    Text("📸 👨‍👩‍👧‍👦")
                                        .font(.system(size: 32))
                                    Text("Photo de famille partagée")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }

                            Text("\"\(post.caption)\"")
                                .font(.system(size: isMemereMode ? 18 : 14))
                                .italic()
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddQuoteModal) {
            addQuoteSheet
        }
    }

    private var addQuoteSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("La réplique culte")) {
                    TextField("Ce qui a été dit...", text: $newQuoteText)
                    TextField("Qui a dit ça ? (ex: Lucas (4 ans), Tonton...)", text: $newQuoteAuthor)
                }
            }
            .navigationTitle("Noter un Mot d'Enfant")
            .navigationBarItems(
                leading: Button("Annuler") { showAddQuoteModal = false },
                trailing: Button("Garder") {
                    guard !newQuoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let quote = FamilyQuote(
                        quoteText: newQuoteText,
                        authorName: newQuoteAuthor.isEmpty ? "Famille" : newQuoteAuthor,
                        context: "Au repas",
                        dateString: "Aujourd'hui"
                    )
                    storage.quotes.insert(quote, at: 0)
                    storage.saveQuotes()
                    newQuoteText = ""
                    newQuoteAuthor = ""
                    showAddQuoteModal = false
                }
            )
        }
    }
}

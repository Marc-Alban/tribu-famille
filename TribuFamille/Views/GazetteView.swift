import SwiftUI

struct GazetteView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var isMemereMode = false
    @State private var showAddQuoteModal = false
    @State private var showWifiCopiedAlert = false
    @State private var newQuoteText = ""
    @State private var newQuoteAuthor = ""
    @State private var newQuoteContext = ""

    private let wifiPassword = "FamilleWillet2026!"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // TOP HEADER
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ESPACE FAMILLE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .tracking(1.5)

                        Text("Gazette & Coin Mémère")
                            .font(.system(size: isMemereMode ? 26 : 22, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // SENIOR MODE TOGGLE
                    Button(action: {
                        withAnimation(.spring()) {
                            isMemereMode.toggle()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: isMemereMode ? "eyeglasses" : "textformat.size")
                                .font(.system(size: 13, weight: .bold))
                            Text(isMemereMode ? "Mode Normal" : "Mode Senior")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(isMemereMode ? .black : Color(red: 0.96, green: 0.62, blue: 0.04))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isMemereMode ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color(red: 0.12, green: 0.16, blue: 0.23))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.4), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // 1. CARTE LE MOT DE LÉO (FIGMA SCREEN #4)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            Text("LE MOT DE LÉO")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .tracking(1)
                        }

                        Spacer()

                        Button(action: {
                            showAddQuoteModal = true
                        }) {
                            Text("+ Noter un mot")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        }
                    }

                    Text("« Mémère, elle fait les meilleurs câlins du monde entier. »")
                        .font(.system(size: isMemereMode ? 22 : 17, weight: .bold, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                        .lineSpacing(4)

                    HStack {
                        Text("Léo, 6 ans • Dimanche dernier")
                            .font(.system(size: isMemereMode ? 14 : 12))
                            .foregroundColor(.gray)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "heart.circle.fill")
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            Text("12")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.09, green: 0.12, blue: 0.19))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                // AUTRES MOTS D'ENFANTS SI DISPONIBLES
                if storage.quotes.count > 0 {
                    VStack(spacing: 8) {
                        ForEach(storage.quotes.prefix(2)) { quote in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\"\(quote.quoteText)\"")
                                        .font(.system(size: isMemereMode ? 16 : 13))
                                        .italic()
                                        .foregroundColor(.white)
                                    Text("— \(quote.authorName) • \(quote.context)")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(red: 0.07, green: 0.09, blue: 0.15))
                            .cornerRadius(10)
                            .overlay(
                                Rectangle()
                                    .frame(width: 3)
                                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04)),
                                alignment: .leading
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 2. SOUVENIR DE LA SEMAINE (PHOTO DE NOËL)
                VStack(alignment: .leading, spacing: 10) {
                    Text("SOUVENIR DE LA SEMAINE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.gray)
                        .tracking(1)

                    ZStack(alignment: .bottomLeading) {
                        // CADRE PHOTO CHALEUREUX
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.22, green: 0.14, blue: 0.10),
                                        Color(red: 0.14, green: 0.10, blue: 0.18),
                                        Color(red: 0.08, green: 0.10, blue: 0.16)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 180)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                    Text("🕯️ 🎄 🍽️ 🥂")
                                        .font(.system(size: 34))
                                    Text("Table de fête familiale")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                            )

                        // BADGE AMBER
                        HStack {
                            Spacer()
                            Text("Noël 2026")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .cornerRadius(6)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Tous réunis à Noël ❤️")
                            .font(.system(size: isMemereMode ? 18 : 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Un beau moment à garder précieusement.")
                            .font(.system(size: isMemereMode ? 14 : 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.09, green: 0.12, blue: 0.19))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                // 3. LE TROUSSEAU D'URGENCE (ACCÈS RAPIDE FIGMA SCREEN #4)
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACCÈS RAPIDE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.gray)
                            .tracking(1)

                        Text("Le trousseau d'urgence")
                            .font(.system(size: isMemereMode ? 19 : 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // LIGNE 1: URGENCES 15
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.85, green: 0.18, blue: 0.18).opacity(0.2))
                                .frame(width: 42, height: 42)
                            Image(systemName: "cross.case.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.95, green: 0.25, blue: 0.25))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Urgences médicales")
                                .font(.system(size: isMemereMode ? 16 : 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Appeler immédiatement")
                                .font(.system(size: isMemereMode ? 13 : 11))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            callNumber("15")
                        }) {
                            Text("15")
                                .font(.system(size: isMemereMode ? 20 : 16, weight: .black))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 36)
                                .background(Color(red: 0.85, green: 0.18, blue: 0.18))
                                .cornerRadius(8)
                        }
                    }
                    .padding(10)
                    .background(Color(red: 0.07, green: 0.09, blue: 0.15))
                    .cornerRadius(12)

                    // LIGNE 2: DR MARTIN
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.06, green: 0.72, blue: 0.50).opacity(0.18))
                                .frame(width: 42, height: 42)
                            Image(systemName: "phone.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.06, green: 0.72, blue: 0.50))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Docteur Martin")
                                .font(.system(size: isMemereMode ? 16 : 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Médecin de famille")
                                .font(.system(size: isMemereMode ? 13 : 11))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            callNumber("02 35 12 34 56")
                        }) {
                            Text("Appeler")
                                .font(.system(size: isMemereMode ? 14 : 12, weight: .bold))
                                .foregroundColor(Color(red: 0.06, green: 0.72, blue: 0.50))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color(red: 0.06, green: 0.72, blue: 0.50).opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                    .padding(10)
                    .background(Color(red: 0.07, green: 0.09, blue: 0.15))
                    .cornerRadius(12)

                    // LIGNE 3: CLAIRE / MARC-ALBAN (CONTACT PRIORITAIRE)
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.18))
                                .frame(width: 42, height: 42)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Claire & Marc-Alban")
                                .font(.system(size: isMemereMode ? 16 : 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Contact prioritaire")
                                .font(.system(size: isMemereMode ? 13 : 11))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            callNumber("06 12 34 56 78")
                        }) {
                            Text("Appeler")
                                .font(.system(size: isMemereMode ? 14 : 12, weight: .bold))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                    .padding(10)
                    .background(Color(red: 0.07, green: 0.09, blue: 0.15))
                    .cornerRadius(12)

                    // LIGNE 4: CODE WI-FI MAISON
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.40, green: 0.45, blue: 0.95).opacity(0.18))
                                .frame(width: 42, height: 42)
                            Image(systemName: "wifi")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.60, green: 0.65, blue: 1.0))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wi-Fi de la maison")
                                .font(.system(size: isMemereMode ? 16 : 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Livebox-Willet (WPA3)")
                                .font(.system(size: isMemereMode ? 13 : 11))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            UIPasteboard.general.string = wifiPassword
                            showWifiCopiedAlert = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 10))
                                Text("Copier")
                                    .font(.system(size: isMemereMode ? 14 : 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color(red: 0.18, green: 0.24, blue: 0.35))
                            .cornerRadius(8)
                        }
                    }
                    .padding(10)
                    .background(Color(red: 0.07, green: 0.09, blue: 0.15))
                    .cornerRadius(12)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.09, green: 0.12, blue: 0.19))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddQuoteModal) {
            addQuoteSheet
        }
        .alert("Code Wi-Fi copié !", isPresented: $showWifiCopiedAlert) {
            Button("Super", role: .cancel) {}
        } message: {
            Text("Le mot de passe du Wi-Fi (\(wifiPassword)) a été copié dans ton presse-papier.")
        }
    }

    private func callNumber(_ number: String) {
        let clean = number.filter { "0123456789+".contains($0) }
        if let url = URL(string: "tel:\(clean)") {
            UIApplication.shared.open(url)
        }
    }

    private var addQuoteSheet: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12)
                    .ignoresSafeArea()

                Form {
                    Section(header: Text("La pépite ou réplique").foregroundColor(.gray)) {
                        TextField("Ce qui a été dit...", text: $newQuoteText)
                            .foregroundColor(.white)
                        TextField("Qui a dit ça ? (ex: Lucas (6 ans), Mémère)", text: $newQuoteAuthor)
                            .foregroundColor(.white)
                        TextField("Contexte (ex: À table devant le rôti)", text: $newQuoteContext)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(red: 0.09, green: 0.12, blue: 0.19))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Noter un mot d'enfant")
            .navigationBarItems(
                leading: Button("Annuler") { showAddQuoteModal = false }
                    .foregroundColor(.gray),
                trailing: Button("Garder") {
                    guard !newQuoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let quote = FamilyQuote(
                        quoteText: newQuoteText.trimmingCharacters(in: .whitespaces),
                        authorName: newQuoteAuthor.isEmpty ? "Famille" : newQuoteAuthor,
                        context: newQuoteContext.isEmpty ? "Au repas de famille" : newQuoteContext,
                        dateString: "Aujourd'hui"
                    )
                    storage.quotes.insert(quote, at: 0)
                    storage.saveQuotes()
                    newQuoteText = ""
                    newQuoteAuthor = ""
                    newQuoteContext = ""
                    showAddQuoteModal = false
                }
                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                .font(.system(size: 16, weight: .bold))
            )
        }
    }
}

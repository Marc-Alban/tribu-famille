import SwiftUI
import AuthenticationServices
import LocalAuthentication

// MARK: - ActivityView (Share Sheet natif iOS)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ContentView: View {
    @EnvironmentObject var storage: StorageManager
    @EnvironmentObject var notifications: NotificationManager
    @State private var selectedTab = 0
    @State private var showProfileSheet = false
    @State private var showShareSheet = false
    @State private var showCopiedAlert = false

    var inviteMessage: String {
        """
        Rejoins notre tribu "\(storage.tribeName)" sur l'application Tribu Famille ! 🎄✨

        1. Installe l'application sur ton iPhone via TestFlight :
        (Lien TestFlight ou invitation Apple)

        2. Connecte-toi avec tes identifiants privés :
        • Code Tribu : \(storage.tribeCode)
        • Mot de passe secret : \(storage.tribePassword)

        À tout de suite dans notre espace privé de famille !
        """
    }

    var body: some View {
        Group {
            if !storage.isLoggedIn {
                WelcomeAuthView()
            } else {
                mainAppView
            }
        }
        .preferredColorScheme(.dark)
    }

    private var mainAppView: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.10)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // TOP HEADER FIGMA STYLE & LUXE
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(storage.tribeName.isEmpty ? "Tribu Famille" : storage.tribeName)
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Button(action: {
                                UIPasteboard.general.string = storage.tribeCode
                                showCopiedAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Text(storage.tribeCode)
                                        .font(.system(size: 10, weight: .bold))
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.system(size: 8))
                                }
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.15))
                                .cornerRadius(6)
                            }
                        }

                        if let current = storage.currentMember {
                            Text("Connecté : \(current.name) (\(current.role))")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        } else {
                            Text("\(storage.members.count) membre(s)")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    // BOUTON INVITER
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11, weight: .bold))
                            Text("Inviter")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(red: 0.12, green: 0.16, blue: 0.23))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.3), lineWidth: 1)
                        )
                    }

                    // MON COMPTE (AVATAR PERSONNEL - CENTRÉ ET ALIGNÉ)
                    Button(action: {
                        showProfileSheet = true
                    }) {
                        ZStack(alignment: .center) {
                            Circle()
                                .fill(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .frame(width: 38, height: 38)
                            Text(String((storage.currentMember?.name ?? "M").prefix(1)).uppercased())
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.black)
                                .frame(width: 38, height: 38, alignment: .center)
                        }
                        .frame(width: 38, height: 38)
                        .contentShape(Circle())
                        .overlay(
                            Circle()
                                .fill(Color(red: 0.06, green: 0.72, blue: 0.50))
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(Color(red: 0.04, green: 0.06, blue: 0.10), lineWidth: 2))
                                .offset(x: 1, y: 1),
                            alignment: .bottomTrailing
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)

                // MAIN TAB VIEW
                TabView(selection: $selectedTab) {
                    BirthdaysView()
                        .tabItem {
                            Label("Fêtes", systemImage: "sparkles")
                        }
                        .tag(0)

                    EventsView()
                        .tabItem {
                            Label("Agenda", systemImage: "calendar")
                        }
                        .tag(1)

                    ShoppingView()
                        .tabItem {
                            Label("Courses", systemImage: "cart.fill")
                        }
                        .tag(2)

                    WishlistView()
                        .tabItem {
                            Label("Cadeaux", systemImage: "gift.fill")
                        }
                        .tag(3)

                    GazetteView()
                        .tabItem {
                            Label("Gazette", systemImage: "heart.fill")
                        }
                        .tag(4)
                }
                .accentColor(Color(red: 0.96, green: 0.62, blue: 0.04)) // Or Ambré
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            UserProfileSheet()
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [inviteMessage])
        }
        .alert("Code copié !", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Le code \(storage.tribeCode) a été copié. Partagez-le avec le mot de passe secret à vos proches pour qu'ils rejoignent votre tribu !")
        }
        .refreshable {
            await storage.pullFromCloud()
        }
    }
}

// MARK: - ÉCRAN MON PROFIL PERSONNEL (AUCUNE USURPATION)
struct UserProfileSheet: View {
    @EnvironmentObject var storage: StorageManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editName = ""
    @State private var editRole = "Parent"
    @State private var editBirthDate = Date()
    @State private var editPhone = ""
    @State private var editShoeSize = ""
    @State private var editClothingSize = ""
    @State private var editFavouriteTreat = ""
    @State private var showLogoutConfirm = false
    @State private var showShareModal = false

    private let rolesList = ["Père", "Mère", "Fils", "Fille", "Grand-mère", "Grand-père", "Tante", "Oncle", "Cousin", "Cousine", "Ami(e)"]

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.15).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // EN-TÊTE AVATAR
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.96, green: 0.62, blue: 0.04))
                                    .frame(width: 64, height: 64)
                                Text(String((storage.currentMember?.name ?? "M").prefix(1)).uppercased())
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                            }

                            Text(storage.currentMember?.name ?? "Mon Compte")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Text("Rôle : \(storage.currentMember?.role ?? "Membre")")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        }
                        .padding(.top, 10)

                        // SECTION 1 : MES INFOS PERSONNELLES
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MES INFORMATIONS PERSONNELLES")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .tracking(1)

                            VStack(spacing: 10) {
                                customTextField(title: "Mon Prénom", text: $editName)
                                
                                HStack {
                                    Text("Mon Rôle")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Picker("Rôle", selection: $editRole) {
                                        ForEach(rolesList, id: \.self) { role in
                                            Text(role).tag(role)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                }
                                .padding(12)
                                .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                                .cornerRadius(12)

                                HStack {
                                    Text("Date de naissance")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    DatePicker("", selection: $editBirthDate, in: ...Date(), displayedComponents: .date)
                                        .labelsHidden()
                                        .accentColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                }
                                .padding(12)
                                .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                                .cornerRadius(12)

                                customTextField(title: "Mon Numéro de Téléphone", text: $editPhone, placeholder: "06...")
                                customTextField(title: "Ma Pointure de chaussures", text: $editShoeSize, placeholder: "Ex: 42")
                                customTextField(title: "Ma Taille de vêtements", text: $editClothingSize, placeholder: "Ex: M, 38, L...")
                                customTextField(title: "Mon Péché mignon / Douceur", text: $editFavouriteTreat, placeholder: "Ex: Chocolat praliné, Tarte tatin...")

                                Button(action: saveProfile) {
                                    Text("Enregistrer mes modifications")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                        .cornerRadius(10)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)

                        // SECTION 2 : NOTRE TRIBU FAMILLE
                        VStack(alignment: .leading, spacing: 12) {
                            Text("NOTRE TRIBU FAMILLE")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .tracking(1)

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Nom de la Tribu :")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(storage.tribeName)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }

                                HStack {
                                    Text("Code Famille :")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(storage.tribeCode)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                }

                                HStack {
                                    Text("Mot de passe secret :")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(storage.tribePassword)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }

                                Divider().background(Color(red: 0.14, green: 0.20, blue: 0.28))

                                Text("Membres inscrits (\(storage.members.count)) :")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)

                                ForEach(storage.members) { m in
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(m.id == storage.currentMember?.id ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color.gray.opacity(0.3))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Text(String(m.name.prefix(1)))
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(m.id == storage.currentMember?.id ? .black : .white)
                                            )

                                        VStack(alignment: .leading, spacing: 1) {
                                            HStack {
                                                Text(m.name)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                                if m.id == storage.currentMember?.id {
                                                    Text("(Moi)")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                                }
                                            }
                                            Text(m.role)
                                                .font(.system(size: 11))
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .font(.system(size: 13))
                        }
                        .padding(16)
                        .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)

                        // BOUTON DÉCONNEXION
                        Button(action: {
                            showLogoutConfirm = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Se déconnecter de ce profil")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitle("Mon Profil", displayMode: .inline)
            .navigationBarItems(trailing: Button("Fermer") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear(perform: loadCurrentData)
            .alert("Confirmer la déconnexion", isPresented: $showLogoutConfirm) {
                Button("Annuler", role: .cancel) {}
                Button("Déconnexion", role: .destructive) {
                    storage.logout()
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Vous pourrez vous reconnecter à tout moment avec votre identité et les codes de votre tribu.")
            }
        }
    }

    private func loadCurrentData() {
        if let current = storage.currentMember {
            editName = current.name
            editRole = current.role
            editBirthDate = current.birthDate
            editPhone = current.phone ?? ""
            editShoeSize = current.shoeSize ?? ""
            editClothingSize = current.clothingSize ?? ""
            editFavouriteTreat = current.favouriteTreat ?? ""
        }
    }

    private func saveProfile() {
        storage.updateCurrentMember(
            name: editName,
            role: editRole,
            birthDate: editBirthDate,
            phone: editPhone.isEmpty ? nil : editPhone,
            shoeSize: editShoeSize.isEmpty ? nil : editShoeSize,
            clothingSize: editClothingSize.isEmpty ? nil : editClothingSize,
            favouriteTreat: editFavouriteTreat.isEmpty ? nil : editFavouriteTreat
        )
        presentationMode.wrappedValue.dismiss()
    }

    private func customTextField(title: String, text: Binding<String>, placeholder: String = "") -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
            TextField(placeholder.isEmpty ? title : placeholder, text: text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(10)
                .background(Color(red: 0.06, green: 0.08, blue: 0.13))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1))
        }
    }
}

// MARK: - ÉCRAN DE BIENVENUE, CRÉATION & REJOINDRE UNE TRIBU
struct WelcomeAuthView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var mode = 1 // 0: Créer une Tribu, 1: Rejoindre une Tribu
    @State private var showAdvancedOptions = true
    
    // Identité personnelle
    @State private var myName = "Marc"
    @State private var myRole = "Fils"
    @State private var myBirthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var myPhone = ""
    @State private var myShoeSize = ""
    @State private var myClothingSize = ""
    @State private var myFavouriteTreat = ""
    
    // Tribu
    @State private var newTribeName = "Famille Millet"
    @State private var inputCode = "MILLET-2026"
    @State private var inputPassword = "2121.bmw"
    
    // Feedback
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    private let roles = ["Père", "Mère", "Fils", "Fille", "Grand-mère", "Grand-père", "Tante", "Oncle", "Cousin", "Cousine"]

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.10)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // LOGO & TITRE
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.96, green: 0.62, blue: 0.04), Color(red: 0.85, green: 0.40, blue: 0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                                .shadow(color: Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.35), radius: 12)

                            Image(systemName: "person.3.sequence.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.black)
                        }

                        Text("Tribu Famille")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.white)

                        Text("L'espace intime & privé de notre famille.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 20)

                    // 1. CARTE CONNEXION APPLE ID & FACE ID DIRECTE
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            Text("CONNEXION APPLE ID")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .tracking(1)
                        }

                        Text("Connectez-vous directement avec votre iPhone : votre compte est reconnu instantanément sans ressaisir vos informations.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineSpacing(2)

                        // BOUTON OFFICIEL SIGN IN WITH APPLE
                        SignInWithAppleButton(
                            .continue,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleAppleSignInResult(result)
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(12)

                        // BOUTON EXPRESS FACE ID / LOCAL AUTH
                        Button(action: handleQuickFaceID) {
                            HStack(spacing: 8) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 17, weight: .bold))
                                Text("Accès Rapide Face ID")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color(red: 0.12, green: 0.16, blue: 0.23))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.35), lineWidth: 1)
                            )
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.4), lineWidth: 1))
                    .padding(.horizontal, 16)

                    // TOGGLE OPTIONS MANUELLES
                    Button(action: {
                        withAnimation(.spring()) {
                            showAdvancedOptions.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: showAdvancedOptions ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            Text(showAdvancedOptions ? "Masquer les options manuelles" : "Options manuelles / Autre code Tribu")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    }
                    .padding(.top, 4)

                    if showAdvancedOptions {
                    // 1. MON IDENTITÉ PERSONNELLE
                    VStack(alignment: .leading, spacing: 12) {
                        Text("1. QUI ÊTES-VOUS ?")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .tracking(1)

                        VStack(spacing: 10) {
                            inputRow(label: "Votre Prénom", text: $myName, placeholder: "Ex: Marc")

                            HStack {
                                Text("Votre Rôle")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("Rôle", selection: $myRole) {
                                    ForEach(roles, id: \.self) { role in
                                        Text(role).tag(role)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            }
                            .padding(10)
                            .background(Color(red: 0.06, green: 0.08, blue: 0.13))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1))

                            HStack {
                                Text("Date de naissance")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                DatePicker("", selection: $myBirthDate, in: ...Date(), displayedComponents: .date)
                                    .labelsHidden()
                                    .accentColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            }
                            .padding(10)
                            .background(Color(red: 0.06, green: 0.08, blue: 0.13))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1))

                            HStack(spacing: 8) {
                                inputRow(label: "Pointure", text: $myShoeSize, placeholder: "Ex: 42")
                                inputRow(label: "Vêtements", text: $myClothingSize, placeholder: "Ex: L, 40")
                            }

                            inputRow(label: "Péché mignon (optionnel)", text: $myFavouriteTreat, placeholder: "Ex: Tarte Tatin, Marrons...")
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1))
                    .padding(.horizontal, 16)

                    // 2. CHOIX : CRÉER OU REJOINDRE UNE TRIBU
                    VStack(alignment: .leading, spacing: 12) {
                        Text("2. VOTRE ESPACE FAMILIAL")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .tracking(1)

                        Picker("Choix", selection: $mode) {
                            Text("Créer une Tribu").tag(0)
                            Text("Rejoindre ma Tribu").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        if mode == 0 {
                            // FORMULAIRE CRÉATION DE TRIBU
                            VStack(spacing: 10) {
                                inputRow(label: "Nom de votre Tribu", text: $newTribeName, placeholder: "Ex: Famille Millet")
                                inputRow(label: "Code Tribu unique souhaité", text: $inputCode, placeholder: "Ex: MILLET-2026")
                                secureRow(label: "Mot de passe secret de la tribu", text: $inputPassword, placeholder: "Pour sécuriser l'accès privé")

                                Button(action: handleCreateFamily) {
                                    if isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Créer notre Tribu et Démarrer")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .cornerRadius(12)
                                .disabled(isLoading)
                            }
                            .padding(.top, 4)
                        } else {
                            // FORMULAIRE REJOINDRE UNE TRIBU
                            VStack(spacing: 10) {
                                inputRow(label: "Code Tribu (fourni par votre proche)", text: $inputCode, placeholder: "Ex: MILLET-2026")
                                secureRow(label: "Mot de passe secret de la tribu", text: $inputPassword, placeholder: "Mot de passe de la famille")

                                Button(action: handleJoinFamily) {
                                    if isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Rejoindre la Tribu")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .cornerRadius(12)
                                .disabled(isLoading)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1))
                    .padding(.horizontal, 16)
                    }

                    Spacer().frame(height: 20)
                }
            }
        }
        .alert("Information", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Une erreur est survenue.")
        }
    }

    private func inputRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
            TextField(placeholder, text: text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(10)
                .background(Color(red: 0.06, green: 0.08, blue: 0.13))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1))
        }
    }

    private func secureRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
            SecureField(placeholder, text: text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(10)
                .background(Color(red: 0.06, green: 0.08, blue: 0.13))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1))
        }
    }

    // MARK: - Handlers Apple Sign In & Face ID
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let appleUserId = appleCredential.user
                let fullName = appleCredential.fullName
                let email = appleCredential.email

                isLoading = true
                Task {
                    do {
                        try await storage.loginWithAppleID(
                            appleUserId: appleUserId,
                            fullName: fullName,
                            email: email,
                            familyCode: inputCode.isEmpty ? "MILLET-2026" : inputCode,
                            familyPassword: inputPassword.isEmpty ? "2121.bmw" : inputPassword
                        )
                        isLoading = false
                    } catch {
                        isLoading = false
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    }
                }
            }
        case .failure(let error):
            let authErr = error as? ASAuthorizationError
            if authErr?.code == .canceled {
                return
            }
            errorMessage = "Connexion Apple ID non aboutie : \(error.localizedDescription). Vous pouvez aussi utiliser le bouton Face ID ou entrer directement vos identifiants ci-dessous."
            showErrorAlert = true
        }
    }

    private func handleQuickFaceID() {
        let context = LAContext()
        var authError: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            let reason = "Authentifiez-vous pour accéder à votre Tribu Famille"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalError in
                DispatchQueue.main.async {
                    if success {
                        self.performQuickLogin()
                    } else {
                        if let laError = evalError as? LAError, laError.code == .userCancel || laError.code == .appCancel {
                            return
                        }
                        self.errorMessage = "Authentification Face ID non confirmée. Vous pouvez utiliser vos identifiants ci-dessous."
                        self.showErrorAlert = true
                    }
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            let reason = "Authentifiez-vous avec le code de votre iPhone"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        self.performQuickLogin()
                    }
                }
            }
        } else {
            performQuickLogin()
        }
    }

    private func performQuickLogin() {
        isLoading = true
        Task {
            do {
                try await storage.quickLoginWithDevice(
                    familyCode: inputCode.isEmpty ? "MILLET-2026" : inputCode,
                    familyPassword: inputPassword.isEmpty ? "2121.bmw" : inputPassword
                )
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func handleCreateFamily() {
        guard !myName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Veuillez renseigner votre prénom."
            showErrorAlert = true
            return
        }
        guard !newTribeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Veuillez renseigner le nom de votre tribu."
            showErrorAlert = true
            return
        }
        guard !inputCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Veuillez choisir un code pour la tribu."
            showErrorAlert = true
            return
        }
        guard !inputPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Veuillez définir un mot de passe secret."
            showErrorAlert = true
            return
        }

        isLoading = true
        Task {
            do {
                try await storage.createFamily(
                    name: newTribeName,
                    code: inputCode,
                    password: inputPassword,
                    creatorName: myName,
                    creatorRole: myRole,
                    birthDate: myBirthDate,
                    shoeSize: myShoeSize.isEmpty ? nil : myShoeSize,
                    clothingSize: myClothingSize.isEmpty ? nil : myClothingSize,
                    favouriteTreat: myFavouriteTreat.isEmpty ? nil : myFavouriteTreat,
                    phone: myPhone.isEmpty ? nil : myPhone
                )
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func handleJoinFamily() {
        guard !myName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Veuillez renseigner votre prénom."
            showErrorAlert = true
            return
        }
        guard !inputCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Veuillez renseigner le code de la tribu."
            showErrorAlert = true
            return
        }
        guard !inputPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Veuillez renseigner le mot de passe secret."
            showErrorAlert = true
            return
        }

        isLoading = true
        Task {
            do {
                try await storage.joinFamily(
                    code: inputCode,
                    password: inputPassword,
                    userName: myName,
                    userRole: myRole,
                    birthDate: myBirthDate,
                    shoeSize: myShoeSize.isEmpty ? nil : myShoeSize,
                    clothingSize: myClothingSize.isEmpty ? nil : myClothingSize,
                    favouriteTreat: myFavouriteTreat.isEmpty ? nil : myFavouriteTreat,
                    phone: myPhone.isEmpty ? nil : myPhone
                )
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

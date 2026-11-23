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
        .sheet(isPresented: $storage.showOnboardingBirthdaySheet) {
            OnboardingBirthdaySheet()
        }
        .preferredColorScheme(.dark)
    }

    private var mainAppView: some View {
        ZStack {
            Color(red: 0.043, green: 0.059, blue: 0.098)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // TOP HEADER WILLET FAMILY STYLE LUXE
                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        // BADGE LOGO W
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.071, green: 0.094, blue: 0.149))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.5), lineWidth: 1)
                                )
                            Text("W")
                                .font(.system(size: 18, weight: .black, design: .serif))
                                .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.043))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(storage.tribeName.isEmpty ? "Willet Family" : storage.tribeName)
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Button(action: {
                                    UIPasteboard.general.string = storage.tribeCode
                                    showCopiedAlert = true
                                }) {
                                    HStack(spacing: 3) {
                                        Text(storage.tribeCode)
                                            .font(.system(size: 9, weight: .bold))
                                        Image(systemName: "doc.on.doc.fill")
                                            .font(.system(size: 8))
                                    }
                                    .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.043))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.15))
                                    .cornerRadius(6)
                                }
                            }

                            HStack(spacing: 5) {
                                Circle()
                                    .fill(Color(red: 0.063, green: 0.725, blue: 0.506))
                                    .frame(width: 6, height: 6)

                                if let current = storage.currentMember {
                                    Text("Connecté : \(current.name) (\(current.role))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(red: 0.580, green: 0.643, blue: 0.722))
                                } else {
                                    Text("\(storage.members.count) membre(s)")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(red: 0.580, green: 0.643, blue: 0.722))
                                }
                            }
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
                        .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.043))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(red: 0.071, green: 0.094, blue: 0.149))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.3), lineWidth: 1)
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
    @State private var editAllergies = ""
    @State private var editTribeName = ""
    @State private var editTribePassword = ""
    @State private var showSavedAlert = false
    @State private var showLogoutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var showShareModal = false
    @State private var showJoinOtherSheet = false
    @State private var otherTribeCode = ""
    @State private var otherTribePassword = ""
    @State private var joinErrorMessage: String? = nil
    @State private var isJoining = false

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
                                customTextField(title: "Allergies & Préférences", text: $editAllergies, placeholder: "Ex: Sans gluten, Végétarien, Noix...")
                            }
                        }
                        .padding(16)
                        .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)

                        // SECTION 2 : NOTRE TRIBU FAMILLE
                        VStack(alignment: .leading, spacing: 14) {
                            Text("PARAMÈTRES DE NOTRE TRIBU FAMILLE")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .tracking(1)

                            VStack(spacing: 12) {
                                customTextField(title: "Nom de la Tribu", text: $editTribeName)

                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Code Famille de partage")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.gray)
                                        Text(storage.tribeCode)
                                            .font(.system(.subheadline, design: .monospaced))
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                    }
                                    Spacer()
                                    Button(action: {
                                        UIPasteboard.general.string = storage.tribeCode
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                            Text("Copier")
                                        }
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.15))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(12)
                                .background(Color(red: 0.06, green: 0.08, blue: 0.13))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1))

                                customTextField(title: "Mot de passe secret de la Tribu", text: $editTribePassword, placeholder: "Mot de passe")

                                Button(action: {
                                    showJoinOtherSheet = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.2.badge.gearshape")
                                        Text("Rejoindre ou basculer vers une autre Tribu...")
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.top, 4)

                                Divider().background(Color(red: 0.14, green: 0.20, blue: 0.28))

                                Text("Membres de la tribu (\(storage.members.count)) :")
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

                        // BOUTON ENREGISTRER TOUT
                        Button(action: saveAllChanges) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Enregistrer les modifications")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .cornerRadius(12)
                            .shadow(color: Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.3), radius: 8)
                        }
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
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.12))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)

                        // BOUTON SUPPRESSION DE COMPTE & RGPD (APPLE GUIDELINE 5.1.1)
                        Button(action: {
                            showDeleteAccountConfirm = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text("Supprimer mon compte et mes données")
                            }
                            .font(.system(size: 13, weight: .bold))
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
            .navigationBarTitle("Mon Profil & Réglages", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Enregistrer") {
                    saveAllChanges()
                }.foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04)).fontWeight(.bold),
                trailing: Button("Fermer") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear(perform: loadCurrentData)
            .alert("Modifications enregistrées", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Vos informations personnelles et paramètres de tribu ont bien été mis à jour.")
            }
            .alert("Confirmer la déconnexion", isPresented: $showLogoutConfirm) {
                Button("Annuler", role: .cancel) {}
                Button("Déconnexion", role: .destructive) {
                    storage.logout()
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Vous pourrez vous reconnecter à tout moment avec votre identité et les codes de votre tribu.")
            }
            .alert("Supprimer définitivement votre compte", isPresented: $showDeleteAccountConfirm) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    storage.deleteCurrentAccount()
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Conformément au RGPD et aux règles Apple, votre profil et toutes vos données associées seront définitivement supprimés.")
            }
            .sheet(isPresented: $showJoinOtherSheet) {
                joinOtherTribeView
            }
        }
    }

    private var joinOtherTribeView: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.15).ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Rejoindre une Tribu existante")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Entrez le code famille et le mot de passe partagés par un membre de votre famille.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        customTextField(title: "Code Famille", text: $otherTribeCode, placeholder: "Ex: MILLET-2026")
                        customTextField(title: "Mot de passe secret", text: $otherTribePassword, placeholder: "Mot de passe")
                    }
                    .padding(.horizontal)

                    if let err = joinErrorMessage {
                        Text(err)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }

                    Button(action: handleJoinOtherTribe) {
                        if isJoining {
                            ProgressView().tint(.black)
                        } else {
                            Text("Rejoindre cette Tribu")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isJoining || otherTribeCode.isEmpty)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationBarTitle("Rejoindre une Tribu", displayMode: .inline)
            .navigationBarItems(trailing: Button("Annuler") { showJoinOtherSheet = false })
        }
    }

    private func handleJoinOtherTribe() {
        guard !otherTribeCode.isEmpty else { return }
        isJoining = true
        joinErrorMessage = nil
        Task {
            do {
                try await storage.joinFamily(
                    code: otherTribeCode,
                    password: otherTribePassword,
                    userName: editName.isEmpty ? (storage.currentMember?.name ?? "Membre") : editName,
                    userRole: editRole,
                    birthDate: editBirthDate,
                    shoeSize: editShoeSize.isEmpty ? nil : editShoeSize,
                    clothingSize: editClothingSize.isEmpty ? nil : editClothingSize,
                    favouriteTreat: editFavouriteTreat.isEmpty ? nil : editFavouriteTreat,
                    phone: editPhone.isEmpty ? nil : editPhone
                )
                await MainActor.run {
                    isJoining = false
                    showJoinOtherSheet = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isJoining = false
                    joinErrorMessage = "Impossible de rejoindre : vérifiez le code et le mot de passe."
                }
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
            editAllergies = current.allergies ?? ""
        }
        editTribeName = storage.tribeName
        editTribePassword = storage.tribePassword
    }

    private func saveAllChanges() {
        storage.updateCurrentMember(
            name: editName,
            role: editRole,
            birthDate: editBirthDate,
            phone: editPhone.isEmpty ? nil : editPhone,
            shoeSize: editShoeSize.isEmpty ? nil : editShoeSize,
            clothingSize: editClothingSize.isEmpty ? nil : editClothingSize,
            favouriteTreat: editFavouriteTreat.isEmpty ? nil : editFavouriteTreat,
            allergies: editAllergies.isEmpty ? nil : editAllergies
        )
        storage.updateTribeSettings(name: editTribeName, password: editTribePassword)
        showSavedAlert = true
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

// MARK: - ÉCRAN DE CONNEXION EXCLUSIF APPLE ID (ZERO FORMULAIRE)
struct WelcomeAuthView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            Color(red: 0.043, green: 0.059, blue: 0.098)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // LOGO CREST & IDENTITY (WILLET FAMILY FIGMA LUXE)
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.071, green: 0.094, blue: 0.149))
                            .frame(width: 88, height: 88)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.961, green: 0.620, blue: 0.043), lineWidth: 2)
                            )
                            .shadow(color: Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.25), radius: 16)

                        Text("W")
                            .font(.system(size: 42, weight: .black, design: .serif))
                            .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.043))
                    }

                    VStack(spacing: 6) {
                        Text("Willet Family")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(Color(red: 0.973, green: 0.980, blue: 0.988))

                        Text("Conciergerie privée & espace intime de notre famille")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.580, green: 0.643, blue: 0.722))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()

                // HERO CARTE ACTIONS OFFICIELLES (ZERO FORMULAIRE)
                VStack(spacing: 16) {
                    // BADGE REASSURANCE
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.063, green: 0.725, blue: 0.506))
                        Text("Accès sécurisé réservé aux membres de la famille")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.063, green: 0.725, blue: 0.506))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.063, green: 0.725, blue: 0.506).opacity(0.12))
                    .cornerRadius(20)

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
                    .frame(height: 52)
                    .cornerRadius(14)
                    .disabled(isLoading)

                    // BOUTON EXPRESS FACE ID
                    Button(action: handleQuickFaceID) {
                        HStack(spacing: 8) {
                            Image(systemName: "faceid")
                                .font(.system(size: 18, weight: .bold))
                            Text("Accès Rapide Face ID")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.043))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.071, green: 0.094, blue: 0.149))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.4), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading)

                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.961, green: 0.620, blue: 0.043)))
                            Text("Connexion sécurisée en cours...")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.580, green: 0.643, blue: 0.722))
                        }
                        .padding(.top, 4)
                    }

                    Text("Vos informations sont reconnues automatiquement sans mot de passe.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.392, green: 0.455, blue: 0.545))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(20)
                .background(Color(red: 0.071, green: 0.094, blue: 0.149))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(red: 0.118, green: 0.161, blue: 0.231), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .alert("Connexion", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Une erreur est survenue lors de l'authentification.")
        }
    }

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
                            email: email
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
            errorMessage = "Connexion Apple ID non aboutie : \(error.localizedDescription)."
            showErrorAlert = true
        }
    }

    private func handleQuickFaceID() {
        let context = LAContext()
        var authError: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            let reason = "Authentifiez-vous pour accéder à votre espace Willet Family"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalError in
                DispatchQueue.main.async {
                    if success {
                        self.performQuickLogin()
                    } else {
                        if let laError = evalError as? LAError, laError.code == .userCancel || laError.code == .appCancel {
                            return
                        }
                        self.errorMessage = "Authentification Face ID non confirmée."
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
                try await storage.quickLoginWithDevice()
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

// MARK: - FEUILLE DE CONFIRMATION DE DATE DE NAISSANCE (1 SEULE FOIS)
struct OnboardingBirthdaySheet: View {
    @EnvironmentObject var storage: StorageManager
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var role = "Fils"

    private let roles = ["Fils", "Fille", "Père", "Mère", "Grand-mère", "Grand-père", "Tante", "Oncle", "Cousin", "Cousine"]

    var body: some View {
        ZStack {
            Color(red: 0.071, green: 0.094, blue: 0.149).ignoresSafeArea()

            VStack(spacing: 20) {
                // Crest
                ZStack {
                    Circle()
                        .fill(Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "sparkles")
                        .font(.system(size: 26))
                        .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.043))
                }
                .padding(.top, 16)

                VStack(spacing: 4) {
                    Text("Bienvenue dans la Tribu, \(storage.currentMember?.name ?? "Marc") !")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("Pour configurer vos alertes d'anniversaires et les surprises de la famille :")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.580, green: 0.643, blue: 0.722))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 14) {
                    // Rôle
                    HStack {
                        Text("Mon Rôle")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("Rôle", selection: $role) {
                            ForEach(roles, id: \.self) { r in
                                Text(r).tag(r)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(Color(red: 0.961, green: 0.620, blue: 0.043))
                    }
                    .padding(12)
                    .background(Color(red: 0.043, green: 0.059, blue: 0.098))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.118, green: 0.161, blue: 0.231), lineWidth: 1))

                    // Date de naissance
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date de naissance")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.580, green: 0.643, blue: 0.722))

                        DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxHeight: 140)
                            .clipped()
                    }
                    .padding(12)
                    .background(Color(red: 0.043, green: 0.059, blue: 0.098))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.118, green: 0.161, blue: 0.231), lineWidth: 1))
                }
                .padding(.horizontal, 16)

                Button(action: {
                    storage.completeOnboardingProfile(birthDate: birthDate, role: role)
                }) {
                    Text("Valider et Accéder à ma Famille")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.961, green: 0.620, blue: 0.043))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

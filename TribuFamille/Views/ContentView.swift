import SwiftUI

struct ContentView: View {
    @EnvironmentObject var storage: StorageManager
    @EnvironmentObject var notifications: NotificationManager
    @State private var selectedTab = 0
    @State private var showProfileSwitcher = false
    @State private var showCopiedAlert = false

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
                // TOP HEADER FIGMA STYLE
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Willet Family")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.white)

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
                            Text("Connecté en tant que \(current.name) (\(current.role))")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        } else {
                            Text("\(storage.members.count) membres dans la tribu")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    // PROFIL AVATAR & SWITCHER
                    Button(action: {
                        showProfileSwitcher = true
                    }) {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.96, green: 0.62, blue: 0.04))
                                    .frame(width: 34, height: 34)
                                Text(String((storage.currentMember?.name ?? "W").prefix(1)))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        .padding(4)
                        .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
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
                .accentColor(Color(red: 0.96, green: 0.62, blue: 0.04)) // Amber gold
            }
        }
        .sheet(isPresented: $showProfileSwitcher) {
            profileSwitchSheet
        }
        .alert("Code copié !", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Le code \(storage.tribeCode) a été copié. Envoie-le par SMS ou WhatsApp à la famille pour qu'ils rejoignent l'application !")
        }
    }

    private var profileSwitchSheet: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.15).ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Changer de profil")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)

                    Text("Choisis qui utilise l'application actuellement :")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(storage.members) { member in
                                Button(action: {
                                    storage.selectMember(member)
                                    showProfileSwitcher = false
                                }) {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(member.isChild ? Color.orange : Color(red: 0.96, green: 0.62, blue: 0.04))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(String(member.name.prefix(1)))
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.black)
                                            )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(member.name)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.white)
                                            Text(member.role)
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()

                                        if storage.currentMember?.id == member.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(red: 0.11, green: 0.14, blue: 0.22))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(storage.currentMember?.id == member.id ? Color.green : Color.clear, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Button("Déconnexion") {
                        storage.logout()
                        showProfileSwitcher = false
                    }
                    .foregroundColor(.red)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.bottom, 20)
                }
            }
            .navigationBarItems(trailing: Button("Fermer") { showProfileSwitcher = false })
        }
    }
}

// MARK: - ÉCRAN DE BIENVENUE & CONNEXION
struct WelcomeAuthView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var inputCode = "WILLET-2026"
    @State private var showNewMemberModal = false
    @State private var newName = ""
    @State private var newRole = "Parent"

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.10)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // LOGO WILLET FAMILY
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.96, green: 0.62, blue: 0.04), Color(red: 0.85, green: 0.40, blue: 0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.4), radius: 15)

                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.black)
                    }

                    Text("Willet Family")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)

                    Text("L'application privée et bienveillante de notre tribu.")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                // QUI ES-TU CE SOIR ?
                VStack(alignment: .leading, spacing: 12) {
                    Text("QUI ES-TU CE SOIR ?")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(storage.members) { member in
                                Button(action: {
                                    storage.selectMember(member)
                                }) {
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(member.isChild ? Color.orange : Color(red: 0.96, green: 0.62, blue: 0.04))
                                            .frame(width: 54, height: 54)
                                            .overlay(
                                                Text(String(member.name.prefix(1)))
                                                    .font(.system(size: 22, weight: .black))
                                                    .foregroundColor(.black)
                                            )

                                        Text(member.name)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)

                                        Text(member.role)
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 85, height: 110)
                                    .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // CONNEXION APPLE / CODE TRIBU
                VStack(spacing: 12) {
                    Button(action: {
                        if let first = storage.members.first {
                            storage.selectMember(first)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Continuer avec Apple (Face ID)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)

                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.3))
                        Text("OU REJOINDRE").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                        Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.3))
                    }
                    .padding(.horizontal, 30)

                    HStack(spacing: 8) {
                        TextField("Code Tribu", text: $inputCode)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                            )

                        Button(action: {
                            if let first = storage.members.first {
                                storage.selectMember(first)
                            }
                        }) {
                            Text("Rejoindre")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
        }
    }
}

import SwiftUI

struct BirthdaysView: View {
    @EnvironmentObject var storage: StorageManager
    @EnvironmentObject var notifications: NotificationManager
    @State private var showAddModal = false
    @State private var selectedMemberForSizes: Member? = nil

    // Form states
    @State private var newName = ""
    @State private var newRole = "Membre"
    @State private var newBirthDate = Date()
    @State private var newPhone = ""
    @State private var newAllergies = ""
    @State private var isChild = false

    var sortedMembers: [Member] {
        storage.members.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
    }

    var nextMember: Member? {
        sortedMembers.first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // TITRE ÉCRAN FIGMA STYLE
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(storage.tribeName.isEmpty ? "TRIBU FAMILLE" : storage.tribeName.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.gray)
                            .tracking(1)

                        Text("Anniversaires & Alertes")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    Spacer()

                    Button(action: {
                        showAddModal = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                if sortedMembers.isEmpty {
                    // ÉTAT VIDE QUAND AUCUN ANNIVERSAIRE
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        Text("Aucun anniversaire renseigné")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Ajoutez les dates de naissance de vos proches pour être alerté automatiquement à l'avance et ne jamais oublier.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Button(action: { showAddModal = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Ajouter un anniversaire")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .background(Color(red: 0.08, green: 0.10, blue: 0.16))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                } else if let next = nextMember {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PROCHAIN ANNIVERSAIRE")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                                Text(next.daysUntilBirthday == 0 ? "AUJOURD'HUI ! 🎂" : "Plus que \(next.daysUntilBirthday) jours !")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(.white)

                                Text("Pensez au gâteau préféré de \(next.name.components(separatedBy: " ").first ?? next.name)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.2))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "birthday.cake.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            }
                        }

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.96, green: 0.62, blue: 0.04))
                                    .frame(width: 48, height: 48)
                                Text(String(next.name.prefix(1)))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(next.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                Text("\(next.role) • Fêtera ses \(next.nextAge) ans")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                                Text("J-\(next.daysUntilBirthday) avant la fête")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                Button(action: {
                                    sendWishMessage(for: next)
                                }) {
                                    Text("Souhaiter")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    selectedMemberForSizes = next
                                }) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                        .padding(7)
                                        .background(Color(red: 0.12, green: 0.16, blue: 0.23))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0.08, green: 0.10, blue: 0.16))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                }

                // LISTE DES PROCHAINS À FÊTER
                if sortedMembers.count > 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("À VENIR")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                                Text("Les prochains à fêter")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text("\(sortedMembers.count) dates")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }

                        VStack(spacing: 8) {
                            ForEach(sortedMembers.dropFirst()) { member in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(member.isChild ? Color.orange.opacity(0.8) : Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.8))
                                            .frame(width: 42, height: 42)
                                        Text(String(member.name.prefix(1)))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.black)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)

                                        Text("\(member.role) • \(member.nextAge) ans")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)

                                        Text("J-\(member.daysUntilBirthday) avant la fête")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                    }

                                    Spacer()

                                    HStack(spacing: 6) {
                                        Button(action: {
                                            sendWishMessage(for: member)
                                        }) {
                                            Text("Souhaiter")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                                .cornerRadius(8)
                                        }

                                        Button(action: {
                                            selectedMemberForSizes = member
                                        }) {
                                            Image(systemName: "tag.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                                .padding(6)
                                                .background(Color(red: 0.12, green: 0.16, blue: 0.23))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color(red: 0.08, green: 0.10, blue: 0.16))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                    // BANNIÈRE RAPPELS ACTIVÉS (FIGMA)
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rappels activés")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Une alerte 3 jours avant chaque date et le Jour J à 9h00")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(red: 0.06, green: 0.18, blue: 0.12))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddModal) {
            addMemberSheet
        }
        .sheet(item: $selectedMemberForSizes) { member in
            memberSizesSheet(for: member)
        }
    }

    private func memberSizesSheet(for member: Member) -> some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.2))
                                .frame(width: 60, height: 60)
                            Text(String(member.name.prefix(1)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        }

                        Text(member.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text(member.role)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 12) {
                        sizeRow(icon: "shoeprints.fill", title: "Pointure", value: member.shoeSize ?? "Non renseigné")
                        sizeRow(icon: "tshirt.fill", title: "Taille Vêtements", value: member.clothingSize ?? "Non renseigné")
                        sizeRow(icon: "birthday.cake.fill", title: "Gâteau / Friandise", value: member.favouriteTreat ?? "Non renseigné")
                        if let allergies = member.allergies, !allergies.isEmpty {
                            sizeRow(icon: "exclamationmark.triangle.fill", title: "Allergies", value: allergies, isWarning: true)
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Fiche & Tailles")
            .navigationBarItems(
                trailing: Button("Fermer") { selectedMemberForSizes = nil }
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
            )
        }
    }

    private func sizeRow(icon: String, title: String, value: String, isWarning: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isWarning ? .red : Color(red: 0.96, green: 0.62, blue: 0.04))
                .frame(width: 28)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isWarning ? .red : .white)
        }
        .padding(.vertical, 4)
    }

    private var addMemberSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Identité")) {
                    TextField("Prénom", text: $newName)
                    TextField("Rôle (Grand-mère, Père, Fils...)", text: $newRole)
                    DatePicker("Date de naissance", selection: $newBirthDate, displayedComponents: .date)
                    Toggle("C'est un enfant (sans smartphone)", isOn: $isChild)
                }

                Section(header: Text("Santé & Contact (Optionnel)")) {
                    TextField("Numéro de téléphone", text: $newPhone)
                        .keyboardType(.phonePad)
                    TextField("Allergies alimentaires", text: $newAllergies)
                }
            }
            .navigationTitle("Nouveau Membre")
            .navigationBarItems(
                leading: Button("Annuler") { showAddModal = false },
                trailing: Button(action: addMember) {
                    Text("Ajouter")
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                }
            )
        }
    }

    private func addMember() {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let member = Member(
            name: newName,
            role: newRole,
            birthDate: newBirthDate,
            phone: newPhone.isEmpty ? nil : newPhone,
            allergies: newAllergies.isEmpty ? nil : newAllergies,
            isChild: isChild
        )
        storage.addMember(member)
        showAddModal = false
    }

    private func sendWishMessage(for member: Member) {
        let text = "Joyeux anniversaire \(member.name) ! 🎉 Plein de bonheur pour tes \(member.nextAge) ans ! Bisous de toute la tribu ❤️"
        if let phone = member.phone, !phone.trimmingCharacters(in: .whitespaces).isEmpty, let url = URL(string: "sms:\(phone)&body=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        } else {
            let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(av, animated: true, completion: nil)
            }
        }
    }
}

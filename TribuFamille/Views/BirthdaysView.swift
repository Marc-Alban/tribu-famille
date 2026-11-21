import SwiftUI

struct BirthdaysView: View {
    @EnvironmentObject var storage: StorageManager
    @EnvironmentObject var notifications: NotificationManager
    @State private var showAddModal = false

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
                // HERO PROCHAIN ANNIVERSAIRE
                if let next = nextMember {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                                Text("PROCHAIN ANNIVERSAIRE")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                            Text(next.daysUntilBirthday == 0 ? "AUJOURD'HUI ! 🎂" : "Dans \(next.daysUntilBirthday) jours")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.26, green: 0.22, blue: 0.79))
                                .cornerRadius(12)
                        }

                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.39, green: 0.40, blue: 0.95))
                                    .frame(width: 56, height: 56)
                                Text(String(next.name.prefix(1)))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(next.name)
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.white)

                                Text("Fêtera ses \(next.nextAge) ans (\(next.role))")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.78, green: 0.82, blue: 0.99))

                                Text(next.nextBirthday.formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalized)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack(spacing: 10) {
                            Button(action: {
                                sendWishMessage(for: next)
                            }) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Lui Souhaiter")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.06, green: 0.73, blue: 0.51))
                                .cornerRadius(12)
                            }

                            Button(action: {
                                notifications.sendTestNotification(name: next.name, age: next.nextAge)
                            }) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                    Text("Tester Alerte")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.78, green: 0.82, blue: 0.99))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.19, green: 0.18, blue: 0.51))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.12, green: 0.11, blue: 0.29))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 0.22, green: 0.19, blue: 0.64), lineWidth: 1)
                    )
                }

                // LISTE DES ANNIVERSAIRES
                HStack {
                    Text("Calendrier de la Famille")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(storage.members.count) membres")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.top, 6)

                ForEach(sortedMembers) { member in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(member.isChild ? Color.orange : Color(red: 0.31, green: 0.27, blue: 0.90))
                                .frame(width: 44, height: 44)
                            Text(String(member.name.prefix(1)))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(member.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                if member.isChild {
                                    Text("Enfant")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.15))
                                        .cornerRadius(6)
                                }
                            }

                            Text("\(member.role) • Aura \(member.nextAge) ans")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)

                            if let allergies = member.allergies, !allergies.isEmpty {
                                Text("⚠️ \(allergies)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text("\(member.daysUntilBirthday)")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(Color(red: 0.65, green: 0.71, blue: 0.99))
                            Text("JOURS")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.06, green: 0.09, blue: 0.16))
                        .cornerRadius(10)

                        Button(action: {
                            sendWishMessage(for: member)
                        }) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 34, height: 34)
                                .background(Color(red: 0.19, green: 0.18, blue: 0.51))
                                .clipShape(Circle())
                        }
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
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddModal) {
            addMemberSheet
        }
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
                trailing: Button("Ajouter") {
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
            )
        }
    }

    private func sendWishMessage(for member: Member) {
        let text = "Joyeux anniversaire \(member.name) ! 🎉 Plein de bonheur pour tes \(member.nextAge) ans ! Bisous de toute la tribu ❤️"
        if let phone = member.phone, let url = URL(string: "sms:\(phone)&body=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
}

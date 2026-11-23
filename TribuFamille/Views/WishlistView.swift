import SwiftUI

struct WishlistView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var showAddWishModal = false
    @State private var targetMember: Member?
    @State private var newWishTitle = ""
    @State private var newWishPrice = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // TOP HEADER
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CADEAUX & SURPRISES")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .tracking(1.5)

                        Text("Idées Cadeaux Secrètes")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color(red: 0.12, green: 0.16, blue: 0.23))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.18, green: 0.24, blue: 0.35), lineWidth: 1)
                            )
                        Image(systemName: "gift.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // EXPLANATION HERO CARD
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Comment ça marche ?")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("Réservez un cadeau en secret : la personne garde la surprise, mais les autres membres savent que c'est déjà pris !")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                .padding(14)
                .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                // LISTE DES MEMBRES ET LEURS SOUHAITS
                ForEach(storage.members) { member in
                    VStack(alignment: .leading, spacing: 12) {
                        // Header Membre
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Text(String(member.name.prefix(1)))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pour \(member.name)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text(member.role)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button(action: {
                                targetMember = member
                                showAddWishModal = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Idée")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.12, green: 0.16, blue: 0.23))
                                .cornerRadius(6)
                            }
                        }

                        Divider()
                            .background(Color(red: 0.14, green: 0.20, blue: 0.28))

                        if member.wishlist.isEmpty {
                            Text("Aucune idée notée. Touchez '+ Idée' pour glisser une suggestion !")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .italic()
                                .padding(.vertical, 4)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(member.wishlist) { wish in
                                    HStack(spacing: 10) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(wish.title)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)

                                            HStack(spacing: 6) {
                                                if let price = wish.priceEstimate, !price.isEmpty {
                                                    Text(price)
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(Color(red: 0.06, green: 0.72, blue: 0.50))
                                                }

                                                if let reserved = wish.isReservedBy {
                                                    Text("🔒 Réservé par \(reserved)")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                                }
                                            }
                                        }

                                        Spacer()

                                        Button(action: {
                                            toggleReservation(member: member, wish: wish)
                                        }) {
                                            if let _ = wish.isReservedBy {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "checkmark")
                                                    Text("Réservé")
                                                }
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color(red: 0.06, green: 0.72, blue: 0.50))
                                                .cornerRadius(8)
                                            } else {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "gift")
                                                    Text("Je prends")
                                                }
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(10)
                                    .background(Color(red: 0.07, green: 0.09, blue: 0.15))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddWishModal) {
            addWishSheet
        }
    }

    private var addWishSheet: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12)
                    .ignoresSafeArea()

                Form {
                    Section(header: Text("Nouvelle idée pour \(targetMember?.name ?? "la famille")").foregroundColor(.gray)) {
                        TextField("Idée de cadeau (ex: Livre, Parfum, Pull en laine...)", text: $newWishTitle)
                            .foregroundColor(.white)
                        TextField("Prix indicatif (ex: ~25€)", text: $newWishPrice)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(red: 0.09, green: 0.12, blue: 0.19))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ajouter un cadeau")
            .navigationBarItems(
                leading: Button("Annuler") { showAddWishModal = false }
                    .foregroundColor(.gray),
                trailing: Button("Ajouter") {
                    guard let member = targetMember, !newWishTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    if let idx = storage.members.firstIndex(where: { $0.id == member.id }) {
                        let item = WishlistItem(
                            title: newWishTitle.trimmingCharacters(in: .whitespaces),
                            priceEstimate: newWishPrice.isEmpty ? nil : newWishPrice,
                            link: nil,
                            isReservedBy: nil
                        )
                        storage.members[idx].wishlist.append(item)
                        storage.saveMembers()
                    }
                    newWishTitle = ""
                    newWishPrice = ""
                    showAddWishModal = false
                }
                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                .font(.system(size: 16, weight: .bold))
            )
        }
    }

    private func toggleReservation(member: Member, wish: WishlistItem) {
        guard let mIdx = storage.members.firstIndex(where: { $0.id == member.id }),
              let wIdx = storage.members[mIdx].wishlist.firstIndex(where: { $0.id == wish.id }) else { return }

        let myName = storage.currentMember?.name ?? "Moi"
        let current = storage.members[mIdx].wishlist[wIdx].isReservedBy
        withAnimation {
            storage.members[mIdx].wishlist[wIdx].isReservedBy = (current == nil) ? myName : nil
        }
        storage.saveMembers()
    }
}

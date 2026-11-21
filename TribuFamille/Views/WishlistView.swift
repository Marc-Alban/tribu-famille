import SwiftUI

struct WishlistView: View {
    @EnvironmentObject var storage: StorageManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Idées Cadeaux Secrètes 🎁")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                    Text("🔒 Réservez un cadeau en secret : la personne garde la surprise, mais les autres savent que c'est déjà pris !")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(storage.members) { member in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Liste de \(member.name)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.yellow)
                            Spacer()
                            Text("(\(member.role))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 4)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(red: 0.14, green: 0.20, blue: 0.28)),
                            alignment: .bottom
                        )

                        if member.wishlist.isEmpty {
                            Text("Aucun souhait noté pour l'instant.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(member.wishlist) { wish in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(wish.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)

                                        if let price = wish.priceEstimate {
                                            Text("Env. \(price)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.green)
                                        }

                                        if let reserved = wish.isReservedBy {
                                            Text("🔒 Réservé par : \(reserved)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.orange)
                                        }
                                    }

                                    Spacer()

                                    Button(action: {
                                        toggleReservation(member: member, wish: wish)
                                    }) {
                                        Text(wish.isReservedBy != nil ? "Déjà réservé" : "Je m'en occupe")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(wish.isReservedBy != nil ? .yellow : .white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(wish.isReservedBy != nil ? Color(red: 0.19, green: 0.18, blue: 0.51) : Color(red: 0.31, green: 0.27, blue: 0.90))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.vertical, 4)
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
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    private func toggleReservation(member: Member, wish: WishlistItem) {
        guard let mIdx = storage.members.firstIndex(where: { $0.id == member.id }),
              let wIdx = storage.members[mIdx].wishlist.firstIndex(where: { $0.id == wish.id }) else { return }

        let current = storage.members[mIdx].wishlist[wIdx].isReservedBy
        storage.members[mIdx].wishlist[wIdx].isReservedBy = (current == nil) ? "Marc-Alban (Secret)" : nil
        storage.saveMembers()
    }
}

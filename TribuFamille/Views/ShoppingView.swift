import SwiftUI

struct ShoppingView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var showAddModal = false
    @State private var newName = ""
    @State private var newCategory = "Épicerie"
    @State private var newQty = ""
    @State private var filterCategory: String? = nil

    private let categories = ["Épicerie", "Frais", "Fruits & Légumes", "Bébé & Maison"]

    private var itemsLeft: Int {
        storage.shoppingItems.filter { !$0.isBought }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // TOP HEADER
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("LISTE PARTAGÉE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .tracking(1.5)

                        Text("Courses de la Tribu")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // ICONE SAC
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.12, green: 0.16, blue: 0.23))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.18, green: 0.24, blue: 0.35), lineWidth: 1)
                            )

                        Image(systemName: "bag.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                        if itemsLeft > 0 {
                            Text("\(itemsLeft)")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.black)
                                .padding(4)
                                .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .clipShape(Circle())
                                .offset(x: 14, y: -14)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // HERO CARD: MARCHÉ DE LA PLACE
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.18))
                                .frame(width: 46, height: 46)
                            Image(systemName: "basket.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("AUJOURD'HUI")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .tracking(1)

                            Text("Marché & Supermarché")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)

                            Text("\(itemsLeft) articles restants • Triés par rayon")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.09, green: 0.12, blue: 0.19))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                // LISTE DE COURSES TITLE + BOUTON RAPIDE
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LISTE DE COURSES")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.gray)
                            .tracking(1)
                        Text("Pour toute la famille")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button(action: {
                        showAddModal = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .frame(width: 32, height: 32)
                            .background(Color(red: 0.12, green: 0.16, blue: 0.23))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.4), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)

                // PAR RAYONS (Aisles)
                VStack(spacing: 14) {
                    ForEach(categories, id: \.self) { cat in
                        let catItems = storage.shoppingItems.filter { item in
                            if cat == "Bébé & Maison" {
                                return item.category == "Bébé" || item.category == "Maison" || item.category == "Bébé & Maison"
                            }
                            return item.category == cat
                        }

                        if !catItems.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                // Header Rayon
                                HStack {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(categoryColor(cat))
                                            .frame(width: 7, height: 7)
                                        Text(cat.uppercased())
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundColor(.gray)
                                            .tracking(1)
                                    }

                                    Spacer()

                                    Text(aisleLabel(cat))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(red: 0.40, green: 0.45, blue: 0.55))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(red: 0.12, green: 0.16, blue: 0.23))
                                        .cornerRadius(4)
                                }
                                .padding(.horizontal, 4)

                                // Rows
                                VStack(spacing: 6) {
                                    ForEach(catItems) { item in
                                        Button(action: {
                                            toggleShopping(item: item)
                                        }) {
                                            HStack(spacing: 12) {
                                                // CHECKBOX
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(item.isBought ? Color(red: 0.06, green: 0.72, blue: 0.50) : Color.gray.opacity(0.5), lineWidth: 1.5)
                                                        .frame(width: 22, height: 22)

                                                    if item.isBought {
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(Color(red: 0.06, green: 0.72, blue: 0.50))
                                                            .frame(width: 22, height: 22)
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(.black)
                                                    }
                                                }

                                                // INFOS
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.name)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(item.isBought ? .gray : .white)
                                                        .strikethrough(item.isBought, color: .gray)

                                                    if !item.addedByName.isEmpty {
                                                        Text("Ajouté par \(item.addedByName)")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.gray.opacity(0.8))
                                                    }
                                                }

                                                Spacer()

                                                // QUANTITÉ
                                                if let qty = item.quantity, !qty.isEmpty {
                                                    Text(qty)
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundColor(item.isBought ? .gray : Color(red: 0.96, green: 0.62, blue: 0.04))
                                                        .padding(.horizontal, 7)
                                                        .padding(.vertical, 3)
                                                        .background(Color(red: 0.14, green: 0.18, blue: 0.26))
                                                        .cornerRadius(6)
                                                }
                                            }
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(item.isBought ? Color(red: 0.06, green: 0.10, blue: 0.14) : Color(red: 0.09, green: 0.12, blue: 0.19))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // BOUTON AJOUTER UN ARTICLE EN GRAND (FIGMA STYLE)
                Button(action: {
                    showAddModal = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Ajouter un article")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .cornerRadius(12)
                    .shadow(color: Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.3), radius: 8, y: 3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                // ACTION: EFFACER ARTICLES COCHÉS
                if storage.shoppingItems.contains(where: { $0.isBought }) {
                    Button(action: {
                        withAnimation {
                            storage.shoppingItems.removeAll { $0.isBought }
                            storage.saveShopping()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Nettoyer les articles achetés")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddModal) {
            addShoppingSheet
        }
    }

    private func categoryColor(_ cat: String) -> Color {
        switch cat {
        case "Épicerie":
            return Color(red: 0.96, green: 0.62, blue: 0.04) // Amber
        case "Frais":
            return Color(red: 0.20, green: 0.60, blue: 0.95) // Blue
        case "Fruits & Légumes":
            return Color(red: 0.06, green: 0.72, blue: 0.50) // Emerald
        default:
            return Color(red: 0.70, green: 0.40, blue: 0.90) // Purple
        }
    }

    private func aisleLabel(_ cat: String) -> String {
        switch cat {
        case "Épicerie": return "ALLÉE 3"
        case "Frais": return "ALLÉE 4"
        case "Fruits & Légumes": return "ENTRÉE"
        default: return "ALLÉE 1"
        }
    }

    private var addShoppingSheet: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12)
                    .ignoresSafeArea()

                Form {
                    Section(header: Text("Article à acheter").foregroundColor(.gray)) {
                        TextField("Nom (ex: Café moulu, Clémentines...)", text: $newName)
                            .foregroundColor(.white)
                        TextField("Quantité (ex: 2 bouteilles, 1 kg)", text: $newQty)
                            .foregroundColor(.white)

                        Picker("Rayon", selection: $newCategory) {
                            Text("Épicerie").tag("Épicerie")
                            Text("Frais").tag("Frais")
                            Text("Fruits & Légumes").tag("Fruits & Légumes")
                            Text("Bébé & Maison").tag("Bébé & Maison")
                        }
                    }
                    .listRowBackground(Color(red: 0.09, green: 0.12, blue: 0.19))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Nouvel Article")
            .navigationBarItems(
                leading: Button("Annuler") { showAddModal = false }
                    .foregroundColor(.gray),
                trailing: Button("Ajouter") {
                    guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let author = storage.currentMember?.name ?? "Moi"
                    let item = ShoppingItem(
                        name: newName.trimmingCharacters(in: .whitespaces),
                        category: newCategory,
                        quantity: newQty.isEmpty ? nil : newQty,
                        addedByName: author
                    )
                    storage.shoppingItems.append(item)
                    storage.saveShopping()
                    newName = ""
                    newQty = ""
                    showAddModal = false
                }
                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                .font(.system(size: 16, weight: .bold))
            )
        }
    }

    private func toggleShopping(item: ShoppingItem) {
        guard let idx = storage.shoppingItems.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            storage.shoppingItems[idx].isBought.toggle()
        }
        storage.saveShopping()
    }
}

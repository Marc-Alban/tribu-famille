import SwiftUI

struct ShoppingView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var showAddModal = false
    @State private var newName = ""
    @State private var newCategory = "Épicerie"
    @State private var newQty = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Courses de la Tribu")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                        Text("Cochez au magasin au fur et à mesure !")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        showAddModal = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Article")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.31, green: 0.27, blue: 0.90))
                        .cornerRadius(8)
                    }
                }

                ForEach(storage.shoppingItems) { item in
                    Button(action: {
                        toggleShopping(item: item)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: item.isBought ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(item.isBought ? .green : .gray)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .strikethrough(item.isBought, color: .gray)

                                    if let qty = item.quantity, !qty.isEmpty {
                                        Text("(\(qty))")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.orange)
                                    }
                                }

                                Text("Demandé par \(item.addedByName) • Rayon \(item.category)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(item.isBought ? Color(red: 0.06, green: 0.20, blue: 0.15) : Color(red: 0.09, green: 0.12, blue: 0.19))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(item.isBought ? Color.green.opacity(0.4) : Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddModal) {
            addShoppingSheet
        }
    }

    private var addShoppingSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Article à acheter")) {
                    TextField("Ex: Lait, Beurre, Pommes, Pain...", text: $newName)
                    TextField("Quantité (ex: 2 packs, 1 kg)", text: $newQty)
                    Picker("Rayon", selection: $newCategory) {
                        Text("Épicerie").tag("Épicerie")
                        Text("Frais").tag("Frais")
                        Text("Fruits & Légumes").tag("Fruits & Légumes")
                        Text("Bébé").tag("Bébé")
                        Text("Maison").tag("Maison")
                    }
                }
            }
            .navigationTitle("Ajouter aux Courses")
            .navigationBarItems(
                leading: Button("Annuler") { showAddModal = false },
                trailing: Button("Ajouter") {
                    guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let item = ShoppingItem(
                        name: newName,
                        category: newCategory,
                        quantity: newQty.isEmpty ? nil : newQty,
                        addedByName: "Marc-Alban"
                    )
                    storage.shoppingItems.insert(item, at: 0)
                    storage.saveShopping()
                    newName = ""
                    newQty = ""
                    showAddModal = false
                }
            )
        }
    }

    private func toggleShopping(item: ShoppingItem) {
        guard let idx = storage.shoppingItems.firstIndex(where: { $0.id == item.id }) else { return }
        storage.shoppingItems[idx].isBought.toggle()
        storage.saveShopping()
    }
}

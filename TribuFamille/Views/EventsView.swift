import SwiftUI

struct EventsView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var showAddItemModal = false
    @State private var newItemTitle = ""
    @State private var newItemCategory = "Plat"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(storage.events) { event in
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(.white)
                                Text("📍 \(event.location)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                showAddItemModal = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Ajouter")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.06, green: 0.73, blue: 0.51))
                                .cornerRadius(8)
                            }
                        }

                        Text(event.description)
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.78, green: 0.82, blue: 0.99))

                        VStack(spacing: 8) {
                            ForEach(event.items) { item in
                                Button(action: {
                                    toggleItem(event: event, item: item)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(item.isCompleted ? .green : .gray)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                                .strikethrough(item.isCompleted, color: .gray)

                                            if let assigned = item.assignedToName {
                                                Text("Pris en charge par : \(assigned)")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.green)
                                            } else {
                                                Text("À prendre (Touchez pour réserver)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(item.isCompleted ? Color(red: 0.06, green: 0.20, blue: 0.15) : Color(red: 0.06, green: 0.09, blue: 0.16))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(item.isCompleted ? Color.green.opacity(0.4) : Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0.09, green: 0.12, blue: 0.19))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddItemModal) {
            addItemSheet
        }
    }

    private var addItemSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Chose à apporter pour le repas")) {
                    TextField("Ex: Foie gras, Vin blanc, Bûche...", text: $newItemTitle)
                    Picker("Rayon / Catégorie", selection: $newItemCategory) {
                        Text("Apéritif").tag("Apéritif")
                        Text("Entrée").tag("Entrée")
                        Text("Plat").tag("Plat")
                        Text("Fromage").tag("Fromage")
                        Text("Dessert").tag("Dessert")
                        Text("Boisson").tag("Boisson")
                    }
                }
            }
            .navigationTitle("Ajouter au Menu")
            .navigationBarItems(
                leading: Button("Annuler") { showAddItemModal = false },
                trailing: Button("Ajouter") {
                    guard !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    if let firstIndex = storage.events.indices.first {
                        let item = EventTaskItem(title: newItemTitle, category: newItemCategory)
                        storage.events[firstIndex].items.append(item)
                        storage.saveEvents()
                    }
                    newItemTitle = ""
                    showAddItemModal = false
                }
            )
        }
    }

    private func toggleItem(event: FamilyEvent, item: EventTaskItem) {
        guard let eventIdx = storage.events.firstIndex(where: { $0.id == event.id }),
              let itemIdx = storage.events[eventIdx].items.firstIndex(where: { $0.id == item.id }) else { return }

        let current = storage.events[eventIdx].items[itemIdx].isCompleted
        storage.events[eventIdx].items[itemIdx].isCompleted = !current
        storage.events[eventIdx].items[itemIdx].assignedToName = (!current) ? "Marc-Alban" : nil
        storage.saveEvents()
    }
}

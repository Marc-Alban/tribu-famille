import SwiftUI

struct EventsView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var viewMode = 0 // 0: Repas de Noël, 1: Calendrier Mensuel
    @State private var showAddItemModal = false
    @State private var showAddEventModal = false
    @State private var newItemTitle = ""
    @State private var newItemCategory = "Plat"
    @State private var selectedDate = Date()
    
    // New Event states
    @State private var newEventTitle = ""
    @State private var newEventLocation = ""
    @State private var newEventDate = Date()
    @State private var newEventCategory = "Repas"

    var currentEvent: FamilyEvent? {
        storage.events.first
    }

    var completedCount: Int {
        currentEvent?.items.filter { $0.isCompleted }.count ?? 0
    }

    var totalCount: Int {
        currentEvent?.items.count ?? 1
    }

    var progressPercent: Double {
        Double(completedCount) / Double(max(totalCount, 1))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // TITRE ÉCRAN
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ÉVÉNEMENT FAMILIAL")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.gray)
                            .tracking(1)

                        Text(viewMode == 0 ? "Repas de Noël" : (viewMode == 1 ? "Dépenses & Pot" : "Calendrier"))
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    Spacer()

                    // SÉLECTEUR DE VUE
                    Picker("Vue", selection: $viewMode) {
                        Text("Repas").tag(0)
                        Text("Dépenses").tag(1)
                        Text("Mois").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                if viewMode == 0 {
                    // ==========================================
                    // MODE 0 : REPAS DE NOËL (FIGMA SCREEN 2)
                    // ==========================================
                    if let event = currentEvent {
                        // CARTE ÉVÉNEMENT VIP
                        HStack(spacing: 14) {
                            // BADGE DATE ORANGE
                            VStack(spacing: 2) {
                                Text(eventMonthString(event.date))
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.black)
                                Text(eventDayString(event.date))
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundColor(.black)
                            }
                            .frame(width: 58, height: 58)
                            .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .cornerRadius(14)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(eventTimeString(event.date))
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                                Text(event.title)
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(.white)

                                Text("📍 \(event.location) • \(event.attendeesCount) personnes")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(Color(red: 0.08, green: 0.10, blue: 0.16))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)

                        // BARRE DE PROGRESSION PRÉPARATIFS
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Préparatifs")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(completedCount) sur \(totalCount) prêts")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red: 0.14, green: 0.20, blue: 0.28))
                                        .frame(height: 7)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.green)
                                        .frame(width: geo.size.width * progressPercent, height: 7)
                                }
                            }
                            .frame(height: 7)
                        }
                        .padding(.horizontal, 16)

                        // LISTE "QUI RAMÈNE QUOI ?"
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ORGANISATION")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                                    Text("Qui ramène quoi ?")
                                        .font(.system(size: 16, weight: .heavy))
                                        .foregroundColor(.white)
                                }
                                Spacer()

                                Button(action: {
                                    showAddItemModal = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                }
                            }

                            VStack(spacing: 8) {
                                ForEach(event.items) { item in
                                    Button(action: {
                                        toggleItem(event: event, item: item)
                                    }) {
                                        HStack(spacing: 12) {
                                            // CHECKBOX VERTE OU CERCLE VIDE
                                            ZStack {
                                                Circle()
                                                    .fill(item.isCompleted ? Color.green : Color.clear)
                                                    .frame(width: 22, height: 22)
                                                    .overlay(
                                                        Circle().stroke(item.isCompleted ? Color.green : Color.gray, lineWidth: 1.5)
                                                    )

                                                if item.isCompleted {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 11, weight: .black))
                                                        .foregroundColor(.black)
                                                }
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.title)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .strikethrough(item.isCompleted, color: .gray)

                                                if let assigned = item.assignedToName {
                                                    Text("Apporté par \(assigned)")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(.green)
                                                } else {
                                                    Text("⚡ À pourvoir • Touchez pour réserver")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                                }
                                            }

                                            Spacer()

                                            // AVATAR OU PASTILLE
                                            ZStack {
                                                Circle()
                                                    .fill(item.isCompleted ? Color.green.opacity(0.2) : Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.2))
                                                    .frame(width: 28, height: 28)
                                                Text(String((item.assignedToName ?? "?").prefix(1)))
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(item.isCompleted ? .green : Color(red: 0.96, green: 0.62, blue: 0.04))
                                            }
                                        }
                                        .padding(12)
                                        .background(item.isCompleted ? Color(red: 0.05, green: 0.12, blue: 0.10) : Color(red: 0.08, green: 0.10, blue: 0.16))
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(item.isCompleted ? Color.green.opacity(0.3) : Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                                        )
                                    }
                                }
                            }

                            // BOUTON ACTION FIGMA AMBRE
                            Button(action: {
                                showAddItemModal = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Ajouter ma contribution")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                                .cornerRadius(14)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    } else {
                        // ÉTAT VIDE REPAS & ÉVÉNEMENTS
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            Text("Aucun événement planifié")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text("Créez le prochain repas de fête, réveillon ou rassemblement pour organiser qui apporte quoi !")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            Button(action: { showAddEventModal = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                    Text("Créer un événement")
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
                        .padding(.bottom, 24)
                    }
                } else if viewMode == 1 {
                    // ==========================================
                    // MODE 1 : DÉPENSES & POT COMMUN
                    // ==========================================
                    expensesView
                } else {
                    // ==========================================
                    // MODE 2 : CALENDRIER DU MOIS INTERACTIF
                    // ==========================================
                    monthlyCalendarView
                }
            }
        }
        .sheet(isPresented: $showAddItemModal) {
            addItemSheet
        }
        .sheet(isPresented: $showAddEventModal) {
            addEventSheet
        }
    }

    // MARK: - Vue Dépenses & Pot Commun
    private var expensesView: some View {
        VStack(spacing: 16) {
            // HERO RECAP
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("CAGNOTTE & ÉQUILIBRAGE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    Spacer()
                    Text("Noël 2026")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                }

                Text("Total engagé : 240 €")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)

                Text("Équilibrage automatique : ~30 € par adulte")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color(red: 0.08, green: 0.10, blue: 0.16))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 16)

            // LISTE DES DÉPENSES EFFECTUÉES
            VStack(alignment: .leading, spacing: 10) {
                Text("DÉTAIL DES ACHATS RÉALISÉS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.gray)

                VStack(spacing: 8) {
                    expenseRow(title: "Dinde fermière & Champagne", buyer: "Marc-Alban (Papa)", amount: "140 €", balance: "+50 €", isPositive: true)
                    expenseRow(title: "Fromages AOP & Pains spéciaux", buyer: "Camille (Maman)", amount: "40 €", balance: "Doit 10 €", isPositive: false)
                    expenseRow(title: "Bûche pâtissière & Chocolats", buyer: "Mémère Denise", amount: "60 €", balance: "Équilibré", isPositive: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func expenseRow(title: String, buyer: String, amount: String, balance: String, isPositive: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Avancé par \(buyer) • Total \(amount)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(balance)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(isPositive ? Color(red: 0.06, green: 0.72, blue: 0.50) : Color(red: 0.96, green: 0.62, blue: 0.04))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isPositive ? Color(red: 0.06, green: 0.72, blue: 0.50) : Color(red: 0.96, green: 0.62, blue: 0.04)).opacity(0.15))
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color(red: 0.09, green: 0.12, blue: 0.19))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
        )
    }

    // MARK: - Vue Calendrier Mois
    private var monthlyCalendarView: some View {
        VStack(spacing: 16) {
            // MOIS & FLÈCHES
            HStack {
                Text("Décembre 2026")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    showAddEventModal = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Événement")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)

            // JOURS DE LA SEMAINE
            HStack {
                ForEach(["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            // GRILLE DES JOURS (DÉCEMBRE 2026 : Débute un mardi)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Offset lundi
                Text("").frame(height: 38)

                ForEach(1...31, id: \.self) { day in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(day == 24 ? Color(red: 0.96, green: 0.62, blue: 0.04) : (day == 5 ? Color.orange.opacity(0.3) : Color(red: 0.08, green: 0.10, blue: 0.16)))
                            .frame(height: 38)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(day == 24 ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                            )

                        VStack(spacing: 2) {
                            Text("\(day)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(day == 24 ? .black : .white)

                            HStack(spacing: 2) {
                                if day == 5 {
                                    Circle().fill(Color.orange).frame(width: 4, height: 4) // Anniv Mémère
                                }
                                if day == 10 {
                                    Circle().fill(Color.orange).frame(width: 4, height: 4) // Anniv Léa
                                }
                                if day == 14 {
                                    Circle().fill(Color.orange).frame(width: 4, height: 4) // Anniv Lucas
                                }
                                if day == 24 {
                                    Circle().fill(Color.black).frame(width: 4, height: 4) // Noël
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            // LISTE DES ÉVÉNEMENTS DU MOIS
            VStack(alignment: .leading, spacing: 10) {
                Text("ÉVÉNEMENTS EN DÉCEMBRE")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                VStack(spacing: 8) {
                    calendarEventRow(dateText: "5 Déc.", title: "🎂 Anniversaire Mémère Denise (84 ans)", color: .orange)
                    calendarEventRow(dateText: "10 Déc.", title: "🎂 Anniversaire Léa (9 ans)", color: .orange)
                    calendarEventRow(dateText: "14 Déc.", title: "🎂 Anniversaire Lucas (8 ans)", color: .orange)
                    calendarEventRow(dateText: "24 Déc.", title: "🎄 Grand Réveillon de Noël chez Mamie", color: Color(red: 0.96, green: 0.62, blue: 0.04))
                    calendarEventRow(dateText: "31 Déc.", title: "🎉 Saint-Sylvestre en famille", color: .green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
    }

    private func calendarEventRow(dateText: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(dateText)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(color)
                .frame(width: 55, alignment: .leading)

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.10, blue: 0.16))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
        )
    }

    // MARK: - Modals
    private var addItemSheet: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.15).ignoresSafeArea()

                Form {
                    Section(header: Text("Plat ou boisson à apporter").foregroundColor(.gray)) {
                        TextField("Ex: Saumon fumé, Vin blanc, Salade...", text: $newItemTitle)
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
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Proposer au Repas")
            .navigationBarItems(
                leading: Button("Annuler") { showAddItemModal = false },
                trailing: Button(action: addMealItem) {
                    Text("Ajouter")
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                }
            )
        }
    }

    private func addMealItem() {
        guard !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        if let firstIndex = storage.events.indices.first {
            let myName = storage.currentMember?.name ?? "Moi"
            let item = EventTaskItem(title: newItemTitle, category: newItemCategory, assignedToName: myName, isCompleted: true)
            storage.events[firstIndex].items.append(item)
            storage.saveEvents()
        }
        newItemTitle = ""
        showAddItemModal = false
    }

    private var addEventSheet: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.15).ignoresSafeArea()

                Form {
                    Section(header: Text("Détails de l'événement").foregroundColor(.gray)) {
                        TextField("Titre (ex: Déjeuner dimanche, Vacances)", text: $newEventTitle)
                        TextField("Lieu (ex: Chez Mémère, Restaurant)", text: $newEventLocation)
                        DatePicker("Date & Heure", selection: $newEventDate)
                        Picker("Type", selection: $newEventCategory) {
                            Text("Repas").tag("Repas")
                            Text("Fête").tag("Fête")
                            Text("Vacances").tag("Vacances")
                            Text("Garde").tag("Garde")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Nouvel Événement")
            .navigationBarItems(
                leading: Button("Annuler") { showAddEventModal = false },
                trailing: Button(action: addNewEvent) {
                    Text("Créer")
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                }
            )
        }
    }

    private func addNewEvent() {
        guard !newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let event = FamilyEvent(
            title: newEventTitle,
            date: newEventDate,
            location: newEventLocation.isEmpty ? "Maison" : newEventLocation,
            description: "Événement partagé avec toute la tribu.",
            category: newEventCategory
        )
        storage.events.append(event)
        storage.saveEvents()
        newEventTitle = ""
        showAddEventModal = false
    }

    private func toggleItem(event: FamilyEvent, item: EventTaskItem) {
        guard let eventIdx = storage.events.firstIndex(where: { $0.id == event.id }),
              let itemIdx = storage.events[eventIdx].items.firstIndex(where: { $0.id == item.id }) else { return }

        let current = storage.events[eventIdx].items[itemIdx].isCompleted
        let myName = storage.currentMember?.name ?? "Moi"
        storage.events[eventIdx].items[itemIdx].isCompleted = !current
        storage.events[eventIdx].items[itemIdx].assignedToName = (!current) ? myName : nil
        storage.saveEvents()
    }

    private func eventMonthString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "MMM"
        return f.string(from: date).uppercased()
    }

    private func eventDayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd"
        return f.string(from: date)
    }

    private func eventTimeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE • HH'h'mm"
        return f.string(from: date).uppercased()
    }
}

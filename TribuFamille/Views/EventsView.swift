import SwiftUI

struct EventsView: View {
    @EnvironmentObject var storage: StorageManager
    @State private var viewMode = 0 // 0: Agenda Famille, 1: Budget & Dépenses, 2: Calendrier Mensuel
    @State private var selectedFilterCategory = "Tous"
    @State private var showAddItemModal = false
    @State private var showAddEventModal = false
    @State private var targetEventForNewItem: FamilyEvent? = nil
    @State private var expandedEventIds: Set<String> = []
    
    // Add Item states
    @State private var newItemTitle = ""
    @State private var newItemCategory = "Plat"
    
    // Add Event states
    @State private var newEventTitle = ""
    @State private var newEventLocation = ""
    @State private var newEventDate = Date()
    @State private var newEventCategory = "Repas"
    @State private var newEventAttendees = 8
    
    private let filterCategories = ["Tous", "Repas", "Fête", "Vacances", "Sortie", "Garde"]

    var sortedEvents: [FamilyEvent] {
        let events = storage.events.sorted(by: { $0.date < $1.date })
        if selectedFilterCategory == "Tous" {
            return events
        }
        return events.filter { $0.category.lowercased() == selectedFilterCategory.lowercased() }
    }

    var nextUpcomingEvent: FamilyEvent? {
        storage.events.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }.sorted(by: { $0.date < $1.date }).first ?? storage.events.first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // TITRE ÉCRAN
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(storage.tribeName.isEmpty ? "TRIBU FAMILLE" : storage.tribeName.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.gray)
                            .tracking(1)

                        Text(viewMode == 0 ? "Agenda de la Tribu" : (viewMode == 1 ? "Budget & Dépenses" : "Calendrier"))
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()

                    // SÉLECTEUR DE VUE
                    Picker("Vue", selection: $viewMode) {
                        Text("Agenda").tag(0)
                        Text("Budget").tag(1)
                        Text("Mois").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 210)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                if viewMode == 0 {
                    // ==========================================
                    // MODE 0 : AGENDA DE LA FAMILLE COMPLET
                    // ==========================================
                    agendaView
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
        .onAppear {
            // Auto-expand next upcoming event
            if let next = nextUpcomingEvent {
                expandedEventIds.insert(next.id)
            }
        }
    }

    // MARK: - Vue Agenda Complet
    private var agendaView: some View {
        VStack(spacing: 16) {
            // BARRE D'ACTIONS : FILTRES & BOUTON CRÉER
            VStack(spacing: 10) {
                HStack {
                    Text("\(storage.events.count) ÉVÉNEMENT\(storage.events.count > 1 ? "S" : "") AU PROGRAMME")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        .tracking(1)

                    Spacer()

                    Button(action: {
                        newEventDate = Date().addingTimeInterval(3600 * 24)
                        showAddEventModal = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Ajouter")
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

                // CHIPS DE FILTRE
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filterCategories, id: \.self) { cat in
                            Button(action: {
                                selectedFilterCategory = cat
                            }) {
                                Text(cat)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(selectedFilterCategory == cat ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedFilterCategory == cat ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color(red: 0.08, green: 0.10, blue: 0.16))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedFilterCategory == cat ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // LISTE DES ÉVÉNEMENTS
            if sortedEvents.isEmpty {
                emptyAgendaCard
            } else {
                VStack(spacing: 14) {
                    ForEach(sortedEvents) { event in
                        eventAgendaCard(event: event)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Carte Événement dans l'Agenda
    private func eventAgendaCard(event: FamilyEvent) -> some View {
        let isExpanded = expandedEventIds.contains(event.id)
        let completed = event.items.filter { $0.isCompleted }.count
        let total = event.items.count
        let progress = total > 0 ? (Double(completed) / Double(total)) : 0.0
        let countdown = countdownString(for: event.date)

        return VStack(alignment: .leading, spacing: 12) {
            // EN-TÊTE ÉVÉNEMENT
            HStack(spacing: 12) {
                // BADGE DATE ORANGE
                VStack(spacing: 2) {
                    Text(eventMonthString(event.date))
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.black)
                    Text(eventDayString(event.date))
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.black)
                }
                .frame(width: 52, height: 52)
                .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(eventTimeString(event.date))
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)

                        Text(countdown)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(countdown.contains("Aujourd'hui") ? .green : Color(red: 0.96, green: 0.62, blue: 0.04))
                    }

                    Text(event.title)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text("📍 \(event.location)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .lineLimit(1)

                        Text("•")
                            .foregroundColor(.gray)

                        Text("👥 \(event.attendeesCount) pers.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // MENU ACTIONS & DÉPLIEMENT
                VStack(alignment: .trailing, spacing: 6) {
                    Menu {
                        Button(role: .destructive, action: {
                            storage.deleteEvent(event)
                        }) {
                            Label("Supprimer l'événement", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(6)
                    }

                    Button(action: {
                        if isExpanded {
                            expandedEventIds.remove(event.id)
                        } else {
                            expandedEventIds.insert(event.id)
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    }
                }
            }

            // BARRE DE PROGRESSION PRÉPARATIFS (SI ITEMS)
            if total > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Préparatifs : \(completed)/\(total) prêts")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(progress == 1.0 ? .green : Color(red: 0.96, green: 0.62, blue: 0.04))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(red: 0.14, green: 0.20, blue: 0.28))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(progress == 1.0 ? Color.green : Color(red: 0.96, green: 0.62, blue: 0.04))
                                .frame(width: geo.size.width * progress, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
            }

            // DÉTAIL DÉPLIABLE : QUI RAMÈNE QUOI
            if isExpanded {
                Divider().background(Color(red: 0.14, green: 0.20, blue: 0.28))

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("QUI RAMÈNE QUOI ?")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                        Spacer()

                        Button(action: {
                            targetEventForNewItem = event
                            showAddItemModal = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Ajouter")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        }
                    }

                    if event.items.isEmpty {
                        Text("Aucun élément noté. Touchez 'Ajouter' pour noter qui apporte le vin, le dessert, les plats...")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 4)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(event.items) { item in
                                Button(action: {
                                    toggleItem(event: event, item: item)
                                }) {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(item.isCompleted ? Color.green : Color.clear)
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Circle().stroke(item.isCompleted ? Color.green : Color.gray, lineWidth: 1.5)
                                                )

                                            if item.isCompleted {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10, weight: .black))
                                                    .foregroundColor(.black)
                                            }
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                                .strikethrough(item.isCompleted, color: .gray)

                                            if let assigned = item.assignedToName {
                                                Text("Apporté par \(assigned)")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.green)
                                            } else {
                                                Text("⚡ À pourvoir • Touchez pour réserver")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                                            }
                                        }

                                        Spacer()

                                        Text(item.category)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color(red: 0.14, green: 0.20, blue: 0.28))
                                            .cornerRadius(6)
                                    }
                                    .padding(10)
                                    .background(item.isCompleted ? Color(red: 0.05, green: 0.12, blue: 0.10) : Color(red: 0.06, green: 0.08, blue: 0.13))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.08, green: 0.10, blue: 0.16))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
        )
    }

    private var emptyAgendaCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
            Text("Aucun événement dans l'agenda")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("Planifiez un repas de famille, un anniversaire, une réunion ou des vacances pour synchroniser toute la tribu !")
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: { showAddEventModal = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Créer le premier événement")
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

    // MARK: - Vue Dépenses & Pot Commun
    private var expensesView: some View {
        VStack(spacing: 16) {
            if let event = nextUpcomingEvent {
                // HERO RECAP
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ORGANISATION & REPAS")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                        Spacer()
                        Text(event.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                    }

                    let completed = event.items.filter { $0.isCompleted }.count
                    Text("\(completed) sur \(max(event.items.count, 1)) préparatifs prêts")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)

                    Text("📍 \(event.location) • \(event.attendeesCount) participants")
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

                // LISTE DES PLATS & PARTICIPATIONS
                VStack(alignment: .leading, spacing: 10) {
                    Text("DÉTAIL DES PARTICIPATIONS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.gray)

                    if event.items.isEmpty {
                        VStack(spacing: 8) {
                            Text("Aucun plat ou participation noté pour le moment.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .italic()
                            Button(action: {
                                targetEventForNewItem = event
                                showAddItemModal = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Proposer le premier plat")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(red: 0.08, green: 0.10, blue: 0.16))
                        .cornerRadius(12)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(event.items) { item in
                                expenseRow(
                                    title: item.title,
                                    buyer: item.assignedToName ?? "Membre",
                                    amount: item.category,
                                    balance: item.isCompleted ? "Prêt ✓" : "À préparer",
                                    isPositive: item.isCompleted
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            } else {
                emptyAgendaCard
            }
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
                Text(currentMonthHeader)
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

            // GRILLE DES JOURS
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(1...31, id: \.self) { day in
                    let hasEv = storage.events.contains(where: { Calendar.current.component(.day, from: $0.date) == day })
                    let hasBday = storage.members.contains(where: { Calendar.current.component(.day, from: $0.birthDate) == day })

                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(hasEv ? Color(red: 0.96, green: 0.62, blue: 0.04) : (hasBday ? Color.orange.opacity(0.3) : Color(red: 0.08, green: 0.10, blue: 0.16)))
                            .frame(height: 38)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(hasEv ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color(red: 0.14, green: 0.20, blue: 0.28), lineWidth: 1)
                            )

                        VStack(spacing: 2) {
                            Text("\(day)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(hasEv ? .black : .white)

                            HStack(spacing: 2) {
                                if hasBday {
                                    Circle().fill(hasEv ? Color.black : Color.orange).frame(width: 4, height: 4)
                                }
                                if hasEv {
                                    Circle().fill(Color.black).frame(width: 4, height: 4)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            // LISTE DES ÉVÉNEMENTS RÉELS ET ANNIVERSAIRES
            VStack(alignment: .leading, spacing: 10) {
                Text("ÉVÉNEMENTS & FÊTES DE LA FAMILLE")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))

                if storage.events.isEmpty && storage.members.isEmpty {
                    Text("Aucun événement ou anniversaire renseigné pour le moment.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .italic()
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(storage.events) { event in
                            calendarEventRow(
                                dateText: eventDayAndMonth(event.date),
                                title: "📅 \(event.title) (\(event.location))",
                                color: Color(red: 0.96, green: 0.62, blue: 0.04)
                            )
                        }

                        ForEach(storage.members) { member in
                            calendarEventRow(
                                dateText: eventDayAndMonth(member.birthDate),
                                title: "🎂 Anniversaire \(member.name) (\(member.nextAge) ans)",
                                color: .orange
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
    }

    private var currentMonthHeader: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: Date()).capitalized
    }

    private func eventDayAndMonth(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMM"
        return f.string(from: date)
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
            .navigationTitle("Ajouter au Repas")
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
        let targetId = targetEventForNewItem?.id ?? storage.events.first?.id
        guard let targetId = targetId,
              let eventIdx = storage.events.firstIndex(where: { $0.id == targetId }) else { return }

        let myName = storage.currentMember?.name ?? "Moi"
        let item = EventTaskItem(title: newItemTitle, category: newItemCategory, assignedToName: myName, isCompleted: true)
        storage.events[eventIdx].items.append(item)
        storage.saveEvents()
        
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
                        TextField("Lieu (ex: Maison familiale, Restaurant...)", text: $newEventLocation)
                        DatePicker("Date & Heure", selection: $newEventDate)
                        Picker("Type", selection: $newEventCategory) {
                            Text("Repas").tag("Repas")
                            Text("Fête").tag("Fête")
                            Text("Vacances").tag("Vacances")
                            Text("Sortie").tag("Sortie")
                            Text("Garde").tag("Garde")
                        }
                        Stepper("Participants prévus : \(newEventAttendees)", value: $newEventAttendees, in: 1...50)
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
            category: newEventCategory,
            attendeesCount: newEventAttendees
        )
        storage.addEvent(event)
        expandedEventIds.insert(event.id)
        newEventTitle = ""
        newEventLocation = ""
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

    private func countdownString(for date: Date) -> String {
        let cal = Calendar.current
        let startToday = cal.startOfDay(for: Date())
        let startTarget = cal.startOfDay(for: date)
        let diff = cal.dateComponents([.day], from: startToday, to: startTarget).day ?? 0
        if diff == 0 {
            return "Aujourd'hui"
        } else if diff == 1 {
            return "Demain"
        } else if diff > 1 {
            return "Dans \(diff) jours"
        } else {
            return "Passé"
        }
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

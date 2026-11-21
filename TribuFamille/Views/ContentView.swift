import SwiftUI

struct ContentView: View {
    @EnvironmentObject var storage: StorageManager
    @EnvironmentObject var notifications: NotificationManager
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.10)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // TOP HEADER
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("Tribu Famille")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.white)

                            Text("MILLET")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(Color(red: 0.78, green: 0.82, blue: 0.99))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(red: 0.19, green: 0.18, blue: 0.51))
                                .cornerRadius(6)
                        }

                        Text("\(storage.members.count) membres • Code : FAM-MILLET")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "person.3.fill")
                        .foregroundColor(Color(red: 0.39, green: 0.40, blue: 0.95))
                        .font(.system(size: 18))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)

                // MAIN CONTENT TABVIEW
                TabView(selection: $selectedTab) {
                    BirthdaysView()
                        .tabItem {
                            Label("Anniversaires", systemImage: "calendar")
                        }
                        .tag(0)

                    EventsView()
                        .tabItem {
                            Label("Fêtes & Noël", systemImage: "gift.fill")
                        }
                        .tag(1)

                    ShoppingView()
                        .tabItem {
                            Label("Courses", systemImage: "cart.fill")
                        }
                        .tag(2)

                    WishlistView()
                        .tabItem {
                            Label("Cadeaux", systemImage: "sparkles")
                        }
                        .tag(3)

                    GazetteView()
                        .tabItem {
                            Label("Mémère", systemImage: "heart.fill")
                        }
                        .tag(4)
                }
                .accentColor(Color(red: 0.39, green: 0.40, blue: 0.95))
            }
        }
        .preferredColorScheme(.dark)
    }
}

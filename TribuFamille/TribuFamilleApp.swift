import SwiftUI
import UserNotifications

@main
struct TribuFamilleApp: App {
    @StateObject private var storage = StorageManager.shared
    @StateObject private var notifications = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storage)
                .environmentObject(notifications)
                .onAppear {
                    notifications.requestPermission()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active && storage.isLoggedIn && !storage.tribeCode.isEmpty {
                        Task {
                            await storage.pullFromCloud()
                        }
                    }
                }
        }
    }
}

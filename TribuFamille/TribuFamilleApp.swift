import SwiftUI
import UserNotifications

@main
struct TribuFamilleApp: App {
    @StateObject private var storage = StorageManager.shared
    @StateObject private var notifications = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storage)
                .environmentObject(notifications)
                .onAppear {
                    notifications.requestPermission()
                }
        }
    }
}

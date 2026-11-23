import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized: Bool = false

    init() {
        checkPermission()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }

    func scheduleBirthdayNotifications(for members: [Member]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for member in members {
            let nextDate = member.nextBirthday

            // 1. Notification le Jour J à 9h00
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: nextDate)
            dateComponents.hour = 9
            dateComponents.minute = 0

            let contentDayJ = UNMutableNotificationContent()
            contentDayJ.title = "🎂 C'est l'anniversaire de \(member.name) !"
            contentDayJ.body = "Aujourd'hui \(member.name) fête ses \(member.nextAge) ans ! Envoie-lui un petit mot affectueux."
            contentDayJ.sound = .default

            let triggerDayJ = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let requestDayJ = UNNotificationRequest(identifier: "bday_\(member.id)_j0", content: contentDayJ, trigger: triggerDayJ)
            UNUserNotificationCenter.current().add(requestDayJ)

            // 2. Notification J-3 (3 jours avant - Conforme Bannière UI)
            if let jMinus3 = Calendar.current.date(byAdding: .day, value: -3, to: nextDate), jMinus3 > Date() {
                var compJ3 = Calendar.current.dateComponents([.year, .month, .day], from: jMinus3)
                compJ3.hour = 9
                compJ3.minute = 0

                let contentJ3 = UNMutableNotificationContent()
                contentJ3.title = "🎁 Anniversaire de \(member.name) dans 3 jours !"
                contentJ3.body = "\(member.name) aura bientôt \(member.nextAge) ans. As-tu pensé à son cadeau ?"
                contentJ3.sound = .default

                let triggerJ3 = UNCalendarNotificationTrigger(dateMatching: compJ3, repeats: false)
                let requestJ3 = UNNotificationRequest(identifier: "bday_\(member.id)_j3", content: contentJ3, trigger: triggerJ3)
                UNUserNotificationCenter.current().add(requestJ3)
            }
        }
    }

    func sendTestNotification(name: String, age: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🎂 Anniversaire de \(name) (Test Tribu)"
        content.body = "Alerte : \(name) fête ses \(age) ans ! Ouvre l'app pour lui souhaiter en 1 clic."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

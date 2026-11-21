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

            // 2. Notification J-7 (7 jours avant)
            if let jMinus7 = Calendar.current.date(byAdding: .day, value: -7, to: nextDate), jMinus7 > Date() {
                var compJ7 = Calendar.current.dateComponents([.year, .month, .day], from: jMinus7)
                compJ7.hour = 9
                compJ7.minute = 0

                let contentJ7 = UNMutableNotificationContent()
                contentJ7.title = "🎁 Anniversaire de \(member.name) dans 7 jours"
                contentJ7.body = "\(member.name) aura bientôt \(member.nextAge) ans. As-tu pensé à son cadeau ?"
                contentJ7.sound = .default

                let triggerJ7 = UNCalendarNotificationTrigger(dateMatching: compJ7, repeats: false)
                let requestJ7 = UNNotificationRequest(identifier: "bday_\(member.id)_j7", content: contentJ7, trigger: triggerJ7)
                UNUserNotificationCenter.current().add(requestJ7)
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

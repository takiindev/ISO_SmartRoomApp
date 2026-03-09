import SwiftUI
import UIKit

// MARK: - Notifications
extension Notification.Name {
    static let forceAuthenticationCheck = Notification.Name("forceAuthenticationCheck")
    static let forceLogout = Notification.Name("forceLogout")
}

@main
struct SmartRoomApp: App {

    @Environment(\.scenePhase) private var scenePhase

    init() {
        print("SmartRoomApp initialized")
        // KHÔNG xóa token ở đây! Token phải được giữ lại để auto-login
    }

    var body: some Scene {
        WindowGroup {
            AuthenticationWrapper()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                print("App active - check auth")
                NotificationCenter.default.post(name: .forceAuthenticationCheck, object: nil)
            default:
                break
            }
        }
    }
}

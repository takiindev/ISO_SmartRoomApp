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
        // Xóa token khi app mới launch (kill app trước đó)
        print("🔄 App init - clearing token")
        TokenManager.shared.clearToken()
    }

    var body: some Scene {
        WindowGroup {
            AuthenticationWrapper()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                print("✅ App active - check auth")
                NotificationCenter.default.post(name: .forceAuthenticationCheck, object: nil)
            default:
                break
            }
        }
    }
}
